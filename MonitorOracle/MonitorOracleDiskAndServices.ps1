# SYNOPSIS 
#      Monitor Windows Server Oracle (Disk and Services)
# DESCRIPTION 
#      Monitor Windows Server Oracle (Disk and Services)
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
#	   Date	   : 14-01-2016
# SYNTAXE
#	  .\MonitorOracleDiskAndServices.ps1
#	  
######

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
	
	if ($result.protocoladdress) {
		try {
			if ($machine -ne $null) {				
				write-host ""
				write-host "__________________________________________________________________________________"
				write-host ""
				write-host "DISK & ORACLE SERVICE INFORMATION - SERVER : "$machine 
				write-host "__________________________________________________________________________________"
				write-host ""
				write-host ""
				Get-ServiceORA -ComputerName $machine
				write-host ""
				Get-DiskInfo -ComputerName $machine
			}	
		}
		catch { 
			$err = $Error[0].Exception ; 
			write-host "Error : [$machine] -- "  $err.Message  -ForegroundColor "red"
			write-host ""
			continue ; 
			} ; 
		} 
		else {	
			write-host ""
			write-host "[$machine] -- ne répond pas"  -ForegroundColor "red"			
		}			
}

write-host ""			
Write-host "Complete!" -ForegroundColor "green"

