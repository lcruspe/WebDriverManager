#!/bin/sh

# $1 boot-args

/usr/sbin/nvram boot-args="$1" || exit 1
