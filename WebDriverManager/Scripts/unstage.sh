#!/bin/sh

/bin/rm -rf /Library/StagedExtensions/Library/Extensions/NVDA*Web* \
        /Library/StagedExtensions/Library/Extensions/GeForce*Web* \
        /Library/GPUBundles/GeForce*Web*
/usr/bin/touch /Library/Extensions
/usr/sbin/nvram nvda_drv=1%00
