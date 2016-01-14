# SYNOPSIS 
#      Get SQL Service
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
# 	   Date    : 19-11-2014	
#########

Function Get-ServiceSQL
{
    Param(
        $ComputerName = $env:COMPUTERNAME
    )
	
	try {
		$servicesSQL = "Select * from win32_service where name like 'MSSQLSERVER%' or  name like 'SQLSERVERAGENT%' or name like '%SQL%$%' or name like '%REPORTSERVER%'"
		Get-WmiObject -ComputerName $ComputerName -query $servicesSQL |	foreach-object {		
		if ($_.state -eq "stopped" ) { 
			Write-Host -foregroundcolor RED $_.name " is $($_.state)" 
		} else { 
			Write-Host -foregroundcolor GREEN $_.name " is $($_.state)"
			}
		}
	}	
	catch { 
		$err = $Error[0].Exception ; 
		write-host "Error : [$ComputerName] -- " $err.Message -ForegroundColor "red"; 
		write-host ""
		continue ; 
	} ; 
}	