# SYNOPSIS 
#      Monitor Windows Server : Check Oracle Error Log 
#   DESCRIPTION 
#      Monitor Windows Server : Check Oracle Error Log (ORA*) after sysdate - 7
#   NOTES 
#      Author : Mohamed ACHBANI  
#      Requires: PowerShell
#	   Date	   : 14-01-2016
#   SYNTAXE
#	  .\MonitorOracleReadLogsWindows.ps1
#### 

#clear screan
cls


# List servers name
$serverORA = @(Get-Content ".\serversORA.txt")

$style = "<" + "style>"  
$style = $style + "TABLE{border:1px solid black; border-collapse: collapse;}" 
$style = $style + "TH{border:1px solid black;background-color:black;color:white;}" 
$style = $style + "TD{border:1px solid black;}" 
$style = $style + "</" + "style>" 

$date = ( get-date ).ToString(‘yyyy-MM-dd’)
$dateAfter  = (get-date).AddDays(-7)
$dateAfterAsString  = $dateAfter.ToString(‘dd/MM/yyyy’)
$Search = "ORA" 

# Analyse for every servers
Write-host "In progress ..."
foreach ($entry in $serverORA)
{	
	$ComputerName = $entry.Name
	if ($ComputerName -ne $null) {
		try{
			write-host "Info : [$ComputerName] -- Start check errors $Search in application log with date after : $dateAfterAsString"  -ForegroundColor "green"	
			$logs = Get-EventLog -ComputerName $ComputerName -After $dateAfter  Application  | where {$_.Source -like "*$Search*"} 
			$logs = $logs | where {$_.EntryType -eq "Error"} 
			$logs = $logs | Select-Object EventId,Message,Source,TimeGenerated 
			$logs | ConvertTo-Html -head $style | Out-File ".\Report\ORAWindowsErrorLog_$ComputerName-$date.html"
		}	
		catch { 
			$err = $Error[0].Exception ; 
			write-host "Error : [$ComputerName] -- "  $err.Message  -ForegroundColor "red"
			write-host ""
			continue ; 
		} ; 
	}	
}	

write-host ""			
Write-host "Complete!" -ForegroundColor "green"