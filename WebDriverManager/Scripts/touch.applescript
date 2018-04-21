try
        do shell script "/usr/bin/touch /Library/Extensions; nvram nvda_drv=1%00" with administrator privileges
        on error errorNumber
        return false
end try
return true
