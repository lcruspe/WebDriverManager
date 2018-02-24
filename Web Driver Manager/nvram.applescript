try
	do shell script "if nvram nvda_drv | grep 1%00; then nvram -d nvda_drv; else nvram nvda_drv=1%00; fi" with administrator privileges
on error errorNumber
	return false
end try
return true
