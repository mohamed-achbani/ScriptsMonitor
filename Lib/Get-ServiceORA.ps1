# SYNOPSIS 
#      Get ORACLE Version
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
# 	   Date : 19-11-2014	
#########

Function Get-ServiceORA
{
    Param(
        $ComputerName = $env:COMPUTERNAME
    )
	
	try {
		$servicesORA = "Select * from win32_service where name like '%ORACLE%'"
		Get-WmiObject -ComputerName $ComputerName -query $servicesORA |	foreach-object {		
		if ($_.state -eq "stopped" ) { 
			Write-Host -foregroundcolor RED $_.name " is $($_.state)" 
		} else { 
			Write-Host -foregroundcolor GREEN $_.name " is $($_.state)"
			}
		}
	}
	catch { 
		$err = $Error[0].Exception ; 
		write-host "Error : [$ComputerName] -- "  $err.Message -ForegroundColor "red";  		
		continue ; 
	} ; 	
}	