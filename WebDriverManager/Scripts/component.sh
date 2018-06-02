#!/bin/bash
#
# $1: Extracted package directory (output one level up)
# $2: Drivers component directory name (from distribution.xml)
# $3: New drivers component pkg filename (output)

cd "$1/.."

# Payload
/usr/bin/gunzip -dc < "$1/$2/Payload" > "$1/../payload.cpio"
/bin/mkdir drivers-root
( cd drivers-root
/usr/bin/cpio -i < "$1/../payload.cpio" )

# Scripts
/usr/bin/gunzip -dc < "$1/$2/Scripts" > "$1/../scripts.cpio"
/bin/mkdir scripts
( cd scripts
/usr/bin/cpio -i < "$1/../scripts.cpio" )

# Build
/usr/bin/pkgbuild --root drivers-root --scripts scripts --identifier com.nvidia.web-driver "$3"

# Clean up
/bin/rm payload.cpio
/bin/rm scripts.cpio
/bin/rm -rf drivers-root
/bin/rm -rf scripts
