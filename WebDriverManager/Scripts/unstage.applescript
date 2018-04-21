try
        do shell script "/bin/rm -rf /Library/StagedExtensions/Library/Extensions/NVDA*Web* /Library/StagedExtensions/Library/Extensions/GeForce*Web* /Library/GPUBundles/GeForce*Web*; touch /Library/Extensions; nvram nvda_drv=1%00" with administrator privileges
        on error errorNumber
        return false
end try
return true
