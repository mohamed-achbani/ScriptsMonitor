# SYNOPSIS 
#      Monitor Server (Windows)
#   DESCRIPTION 
#      Monitor Server (Windows)
#   NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
#	   Date	   : 14-01-2016
#   SYNTAXE
#	  .\MonitorServerDisk.ps1
##### 

#clear screan
cls

# List servers name
$servers = @(Import-Csv ".\servers.csv")

# Analyse for every servers
Write-host "In progress ..."
foreach ($entry in $servers)
{
    # By default
	$machine = $entry.Name	    
		
	try {
		if ($machine -ne $null) {				
			write-host ""
			write-host "_______________________________________________________________________________"
			write-host ""
			write-host "DISK INFORMATION - SERVER : $machine"
			write-host "_______________________________________________________________________________"
			write-host ""
			write-host ""
			Get-DiskInfo -ComputerName $machine
		}	
	}
	catch { 
		$err = $Error[0].Exception ; 
		write-host "Error : [$machine] -- "  $err.Message -ForegroundColor "red"; 
		write-host ""
		continue ; 
	} ; 			
}

#
write-host ""			
Write-host "Complete!" -ForegroundColor "green"
