#!/bin/bash
#
# $1: Extracted package directory (output one level up)
# $2: Drivers component directory name (from distribution.xml)
# $3: New drivers component pkg filename (output)

cd "$1/.."
gunzip -dc < "$1/$2/Payload" > "$1/../payload.cpio"
mkdir drivers-root
( cd drivers-root
cpio -i < "$1/../payload.cpio" )
pkgbuild --root drivers-root --scripts "$1/$2/Scripts" --identifier com.nvidia.web-driver "$3"
rm payload.cpio
rm -rf drivers-root
