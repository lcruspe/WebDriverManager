#!/bin/bash
#
# $1: Extracted package directory (output one level up)
# $2: Output package file name

cd "$1/.."
/usr/bin/productbuild --distribution "$1/Distribution" --resources "$1/Resources" "$2"
