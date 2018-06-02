#!/bin/sh

/usr/bin/touch /Library/Extensions || exit 1
/usr/sbin/nvram nvda_drv=1%00
