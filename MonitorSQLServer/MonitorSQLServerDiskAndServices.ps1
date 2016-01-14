# SYNOPSIS 
#      Monitor Disk and Services SQL Server 
#   DESCRIPTION 
#      Monitor Disk and Services SQL Server
#	  Out-File : .\Report\MonitorSQLServerDiskAndServices-yyyy-mm-dd.log  
#   NOTES 
#      Author  : Mohamed ACHBANI 
#	   Requires: PowerShell Version 2.0
#	   Date    : 14-01-2016
#   SYNTAXE
#	  .\MonitorSQLServerDiskAndServices.ps1
#### 

#clear screan
cls

# List servers name
$servers = @(Import-Csv ".\servers.csv") 

# Analyse for every servers
Write-host "In progress ..."
foreach ($entry in $servers)
{    
	$machine    = $entry.Name    
 	
	$query = "select * from win32_pingstatus where address = '$machine'"
	$result = Get-WmiObject -query $query
	
	try {
		if ($machine -ne $null) {				
			write-host ""
			write-host "__________________________________________________________________________________________"
			write-host ""
			write-host "DISK & SQL SERVICE - SERVER : $machine"
			write-host "__________________________________________________________________________________________"
			write-host ""
			Get-ServiceSQL -ComputerName $machine
			write-host ""
			Get-DiskInfo -ComputerName $machine
		}	
	}
	catch { 
		$err = $Error[0].Exception ; 
		write-host "Error :  [$machine] -- "  $err.Message -ForegroundColor "red";	
		write-host ""
		continue ; 
		} ; 
}

#
write-host ""			
Write-host "Complete!" -ForegroundColor "green"
