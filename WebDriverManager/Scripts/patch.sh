#!/bin/sh

# $1: Target macOS version

TARGET_BUILD="$1"
KEXTS=("/Library/Extensions/NVDAStartupWeb.kext" "/Library/Extensions/NVDAEGPUSupport.kext")
KEY=":IOKitPersonalities:NVDAStartup:NVDARequiredOS"
INFO="Contents/Info.plist"
ERROR=0
CHANGES=0

for KEXT in "${KEXTS[@]}"; do
        if [[ -f "${KEXT}/${INFO}" ]]; then
                NVDA_REQUIRED_OS=$(/usr/libexec/PlistBuddy -c "Print ${KEY}" "${KEXT}/${INFO}") || (( ERROR += 1 ))
                if [[ $NVDA_REQUIRED_OS == "$TARGET_BUILD" ]]; then
                        continue
                else
                        (( CHANGES += 1 ))
                        /usr/libexec/PlistBuddy -c "Set ${KEY} ${TARGET_BUILD}" "${KEXT}/${INFO}" || (( ERROR += 1 ))
                fi
        fi
done

(( CHANGES == 0 && ERROR == 0)) && exit 248
/usr/bin/touch /Library/Extensions
exit $ERROR
