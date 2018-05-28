#!/bin/sh

/usr/sbin/kextcache -clear-staging
/usr/bin/touch /Library/Extensions
/usr/sbin/nvram nvda_drv=1%00
