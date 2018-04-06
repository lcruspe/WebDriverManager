try
        do shell script "/usr/sbin/kextcache -clear-staging; touch /Library/Extensions; nvram nvda_drv=1%00" with administrator privileges
        on error errorNumber
        return false
end try
return true
