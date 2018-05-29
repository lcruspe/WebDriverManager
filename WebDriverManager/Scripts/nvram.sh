#!/bin/sh

if /usr/sbin/nvram nvda_drv | /usr/bin/grep -E "nvda_drv[[:space:]]1%00$|nvda_drv[[:space:]]1$"; then
        /usr/sbin/nvram -d nvda_drv || exit 1
else
        /usr/sbin/nvram nvda_drv=1%00 || exit 1
fi
