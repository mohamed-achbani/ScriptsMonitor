# SYNOPSIS 
#      Ping host
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
# 	   Date : 19-11-2014	
######### 

Function Pinghost  ([string] $Hostname )
{
	$status=get-wmiobject win32_pingstatus -Filter "Address='$Hostname'" | Select-Object statuscode
	Write-Host ""
	if($status.statuscode -eq 0)
		{write-host $Hostname is REACHABLE -background "GREEN" -foreground "BLACk"}
	else
		{write-host $Hostname is NOT reachable -background "RED" -foreground "BLACk"}
}
