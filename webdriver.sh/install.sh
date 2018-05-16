#!/bin/sh
#
# Web Driver Manager Install Script
# Copyright © 2017-2018 vulgo
#
# Derived from webdriver.sh
# https://github.com/vulgo/webdriver.sh
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#



# Arguments

REMOTE_URL="$1"
REMOTE_CHECKSUM="$2"
STAGE_BUNDLES="$3"



# Variables

EXTRACTED_DRIVERS_BUNDLE_MATCHES_STRING="NVWebDrivers.pkg"
STARTUP_KEXT="/Library/Extensions/NVDAStartupWeb.kext"
GREP="/usr/bin/grep"
UUIDGEN="/usr/bin/uuidgen"
SET_NVRAM="/usr/sbin/nvram nvda_drv=1%00"
UNSET_NVRAM="/usr/sbin/nvram -d nvda_drv"
KEXT_ALLOWED=false
FS_ALLOWED=false
TMP_DIR=$(/usr/bin/mktemp -dt webdriver)
INSTALLER_PKG="${TMP_DIR}/$($UUIDGEN)"
EXTRACTED_PKG_DIR="${TMP_DIR}/$($UUIDGEN)"
DRIVERS_PKG="$(/usr/bin/dirname "$0")/com.nvidia.web-driver.pkg"
DRIVERS_ROOT="${TMP_DIR}/$($UUIDGEN)"

shopt -s nullglob extglob
# shellcheck disable=SC2064
trap "/bin/rm -rf $TMP_DIR; /bin/rm -f $DRIVERS_PKG; exit" SIGINT SIGTERM SIGHUP



# Get SIP status

/usr/bin/csrutil status | \
	$GREP -qiE -e "status: disabled|signing: disabled" \
	&& KEXT_ALLOWED=true

/usr/bin/touch /System \
	&& FS_ALLOWED=true



# Functions

function silent() {
	
	# $@: args... 
	
	"$@" > /dev/null
	return $?
	
}


function error() {
	
	# $1: message, $2: exit_code
	
	silent /bin/rm -rf "$TMP_DIR"
	silent /bin/rm -f "$DRIVERS_PKG"
	
	if [[ -z $2 ]]; then
		
		printf 'Error:%s\n' "$1"
		
	else
		
		printf 'Error:%s (%s)\n' "$1" "$2"
		
	fi
	
	exit 1
	
}



# Check root

[[ $(/usr/bin/id -u) != "0" ]] \
	&& error "We are not running as root"



# Required arguments

! [[ $REMOTE_URL ]] \
	&& error "Missing argument 1 for remote URL"

! [[ $REMOTE_CHECKSUM ]] \
	&& error "Missing argument 2 for remote checksum"



# Check URL

REMOTE_HOST=$(printf '%s' "$REMOTE_URL" | /usr/bin/awk -F/ '{print $3}')

! silent /usr/bin/host "$REMOTE_HOST" \
	&& error "Unable to resolve host, check your URL"

HEADERS=$(/usr/bin/curl -I "$REMOTE_URL" 2>&1) \
	|| error "Failed to download HTTP headers"

$GREP -qe "octet-stream" <<< "$HEADERS" \
	|| printf "Unexpected HTTP content type" 1>&2



# Download

printf '10:Downloading package...\n'

/usr/bin/curl --connect-timeout 15 -s -o "$INSTALLER_PKG" "$REMOTE_URL" \
	|| error "Failed to download package" $?



# Checksum

LOCAL_CHECKSUM=$(/usr/bin/shasum -a 512 "$INSTALLER_PKG" | /usr/bin/awk '{print $1}')

[[ $LOCAL_CHECKSUM != "$REMOTE_CHECKSUM" ]] \
	&& error "SHA512 verification failed"



# Unflatten

printf '35:Extracting...\n'

/usr/sbin/pkgutil --expand "$INSTALLER_PKG" "$EXTRACTED_PKG_DIR" \
	|| error "Failed to extract package" $?

DIRS=("$EXTRACTED_PKG_DIR"/*"$EXTRACTED_DRIVERS_BUNDLE_MATCHES_STRING")

if [[ ${#DIRS[@]} -eq 1 && -d ${DIRS[0]} ]]; then
	
        DRIVERS_COMPONENT_DIR=${DIRS[0]}
	
else
	
        error "Failed to find pkgutil output directory"
	
fi



# Extract drivers

mkdir "$DRIVERS_ROOT"

/usr/bin/gunzip -dc < "${DRIVERS_COMPONENT_DIR}/Payload" > "${DRIVERS_ROOT}/tmp.cpio" \
	|| error "Failed to extract package" $?

cd "$DRIVERS_ROOT" \
	|| error "Failed to find drivers root directory" $?

/usr/bin/cpio -i < "${DRIVERS_ROOT}/tmp.cpio" \
	|| error "Failed to extract package" $?

silent /bin/rm -f "${DRIVERS_ROOT}/tmp.cpio"

[[ ! -d ${DRIVERS_ROOT}/Library/Extensions || ! -d ${DRIVERS_ROOT}/System/Library/Extensions ]] \
	&& error "Unexpected directory structure after extraction"



# User-approved kernel extension loading

cd "$DRIVERS_ROOT" \
	|| error "Failed to find drivers root directory" $?

KEXT_INFO_PLISTS=(./Library/Extensions/*.kext/Contents/Info.plist)

declare -a BUNDLES APPROVED_BUNDLES

for PLIST in "${KEXT_INFO_PLISTS[@]}"; do
	
	BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$PLIST")
	
	[[ $BUNDLE_ID ]] \
		&& BUNDLES+=("$BUNDLE_ID")
	
done

if $FS_ALLOWED; then
	
	# Approve kexts
	
	function sql_add_kext() {
	
		SQL+="insert or replace into kext_policy (team_id, bundle_id, allowed, developer_name, flags) "
		SQL+="values (\"6KR3T733EC\",\"${1}\",1,\"NVIDIA Corporation\",1); "
	
	}
	
	printf '50:Approving extensions...\n'
	
	for BUNDLE_ID in "${BUNDLES[@]}"; do
		
		sql_add_kext "$BUNDLE_ID"
		
	done
	
	sql_add_kext "com.nvidia.CUDA"
	
	/usr/bin/sqlite3 /private/var/db/SystemPolicyConfiguration/KextPolicy <<< "$SQL" \
		|| printf "sqlite3 exit code %s" "$?" 1>&2
	
else
	
	# Get unapproved bundle IDs
	
	printf '40:Examining extensions...\n'
	QUERY="select bundle_id from kext_policy where team_id=\"6KR3T733EC\" and (flags=1 or flags=8)"
	APPROVED_BUNDLES_STRING="$(/usr/bin/sqlite3 /private/var/db/SystemPolicyConfiguration/KextPolicy "$QUERY")"
	APPROVED_BUNDLES=($APPROVED_BUNDLES_STRING)
	
	for MATCH in "${APPROVED_BUNDLES[@]}"; do
		
		for index in "${!BUNDLES[@]}"; do
			
			[[ ${BUNDLES[index]} == "$MATCH" ]] \
				&& unset "BUNDLES[index]";
			
		done;
		
	done
	
	UNAPPROVED_BUNDLES=$(printf "%s" "${BUNDLES[@]}")
	
fi


		
# Uninstall

if $FS_ALLOWED; then

	REMOVE_LIST=(/Library/Extensions/GeForce*Web* \
		/Library/Extensions/NVDA*Web* \
		/System/Library/Extensions/GeForce*Web* \
		/Library/GPUBundles/GeForce*Web* \
		/System/Library/Extensions/NVDA*Web*)
			
else
	
	REMOVE_LIST=(/Library/Extensions/GeForce*Web* \
		/Library/Extensions/NVDA*Web* \
		/System/Library/Extensions/GeForce*Web* \
		/System/Library/Extensions/NVDA*Web*)
			
fi

# shellcheck disable=SC2086
silent /bin/rm -rf "${REMOVE_LIST[@]}"

/usr/sbin/kextcache -clear-staging
silent /usr/sbin/pkgutil --forget com.nvidia.web-driver



# Install

if ! $FS_ALLOWED; then
	
	WANTS_KEXTCACHE=false
	silent /bin/rm -f "$DRIVERS_PKG"
	silent /usr/bin/pkgbuild --identifier com.nvidia.web-driver --root "$DRIVERS_ROOT" "$DRIVERS_PKG"
	
	[[ ! $KEXT_ALLOWED && ! -z $UNAPPROVED_BUNDLES ]] \
		&& printf "Don't restart until this process is complete."  1>&2
	
	printf '50:Installing...\n'
	
	silent /usr/sbin/installer -allowUntrusted -pkg "$DRIVERS_PKG" -target / \
		|| error "installer error" $?
	
else
	
	WANTS_KEXTCACHE=true
	printf '60:Installing...\n'
	/usr/bin/rsync -r "${DRIVERS_ROOT}"/* /
	
	if (( STAGE_BUNDLES == 1 )); then
	
		silent /bin/mkdir -p /Library/GPUBundles
		silent /usr/bin/rsync -r /System/Library/Extensions/GeForce*Web*.bundle /Library/GPUBundles
	
	fi
	
fi



# Check extensions are loadable

silent /sbin/kextload "$STARTUP_KEXT" # kextload returns 27 when a kext hasn't been approved yet

if [[ $? -eq 27 ]]; then
	
	WANTS_KEXTCACHE=true
	printf '70:Allow NVIDIA Corporation to continue...\n'
	
	while ! silent /usr/bin/kextutil -tn "$STARTUP_KEXT"; do
		
		sleep 5
		
	done
	
	printf '75:Installing...\n'
	
fi

! $WANTS_KEXTCACHE \
	&& printf '90:Installing...\n'


# Update caches and NVRAM

silent /sbin/kextload \
	/Library/Extensions/NVDA* \
	/Library/Extensions/GeForce* \
	/System/Library/Extensions/AppleHDA.kext

if $WANTS_KEXTCACHE; then
	
	printf '80:Updating Caches...\n'
	/usr/sbin/kextcache -i /

fi

/usr/bin/touch /Library/Extensions

$SET_NVRAM



# Exit

silent /bin/rm -rf "$TMP_DIR"
silent /bin/rm -f "$DRIVERS_PKG"
printf '100:Installation complete. You should reboot now.\n'
