#!/bin/bash
#
# $1: Extracted package directory (output one level up)
# $2: Drivers component directory name (from distribution.xml)
# $3: New drivers component pkg filename (output)

cd "$1/.."

# Payload
gunzip -dc < "$1/$2/Payload" > "$1/../payload.cpio"
mkdir drivers-root
( cd drivers-root
cpio -i < "$1/../payload.cpio" )

# Scripts
gunzip -dc < "$1/$2/Scripts" > "$1/../scripts.cpio"
mkdir scripts
( cd scripts
cpio -i < "$1/../scripts.cpio" )

# Build
pkgbuild --root drivers-root --scripts scripts --identifier com.nvidia.web-driver "$3"

# Clean up
rm payload.cpio
rm scripts.cpio
rm -rf drivers-root
rm -rf scripts
