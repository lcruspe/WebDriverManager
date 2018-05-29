#!/bin/sh

ERROR=0

/usr/sbin/kextcache -clear-staging || ERROR=1
/usr/bin/touch /Library/Extensions
/usr/sbin/nvram nvda_drv=1%00

exit $ERROR
