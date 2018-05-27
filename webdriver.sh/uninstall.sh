#!/bin/sh
#
# Web Driver Manager Uninstall Script
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

printf '0:Uninstalling NVIDIA drivers...\n'

FS_ALLOWED=false
/usr/bin/touch /System \
        && FS_ALLOWED=true

function silent() {
	
	# $@: args... 
	
	"$@" > /dev/null
	return $?
	
}

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

printf '10:Uninstalling NVIDIA drivers...\n'

# shellcheck disable=SC2086
silent /bin/rm -rf "${REMOVE_LIST[@]}"
silent /usr/sbin/kextcache -clear-staging
silent /usr/sbin/pkgutil --forget com.nvidia.web-driver
sleep 1

printf '50:Updating caches...\n'

silent /usr/sbin/kextcache -i /
silent /usr/bin/touch /Library/Extensions
silent /usr/sbin/nvram -d nvda_drv

printf '100:Uninstall finished. You should reboot now.\n'
