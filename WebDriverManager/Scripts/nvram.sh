#!/bin/sh

if /usr/sbin/nvram nvda_drv | /usr/bin/grep -E "nvda_drv[[:space:]]1%00$|nvda_drv[[:space:]]1$"; then
        /usr/sbin/nvram -d nvda_drv
else
        /usr/sbin/nvram nvda_drv=1%00
fi
