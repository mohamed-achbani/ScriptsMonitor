# SYNOPSIS 
#     Searching Windows Error log (Application And System)
#   DESCRIPTION 
#     Searching Windows Error log (erreur) after : sysdate - n days
#	  Out-File : .\Report\ServerWindows<LogName>Errorlog_<ComputerName>-<yyyy-mm-dd>.html 
#   NOTES 
#      Author  : Mohamed ACHBANI
#      Requires: PowerShell
#	   Date	   : 14-01-2016       
#   SYNTAXE
#	  .\MonitorServerReadLogsWindows.ps1
#### 

cls

# List servers name
$servers = @(Import-Csv ".\servers.csv")

$style = "<" + "style>"  
$style = $style + "TABLE{border:1px solid black; border-collapse: collapse;}" 
$style = $style + "TH{border:1px solid black;background-color:black;color:white;}" 
$style = $style + "TD{border:1px solid black;}" 
$style = $style + "</" + "style>" 

$date = ( get-date ).ToString(‘yyyy-MM-dd’)
$dateAfter  = (get-date).AddDays(-7)
$dateAfterAsString  = $dateAfter.ToString(‘dd/MM/yyyy’)
$Search = "Erreur"

# Analyse for every servers
Write-host "In progress ..."
foreach ($entry in $servers)
{	
	$ComputerName = $entry.Name
	if ($ComputerName -ne $null) {
		write-host "Info : [$ComputerName] -- Start check errors in [Application log] with date after : $dateAfterAsString"  -ForegroundColor "green"	
		$logs = Get-EventLog -ComputerName $ComputerName -After $dateAfter  Application  
		$logs = $logs | where {$_.EntryType -eq "Error"} 
		$logs = $logs | Select-Object EventId,Message,Source,TimeGenerated 
		$logs | ConvertTo-Html -head $style | Out-File ".\Report\ServerWindowsApplicationErrorlog_$ComputerName-$date.html"
		
		write-host "Info : [$ComputerName] -- Start check errors in [System log] with date after : $dateAfterAsString"  -ForegroundColor "green"	
		$logs = Get-EventLog -ComputerName $ComputerName -After $dateAfter  System  	
		$logs = $logs | where {$_.EntryType -eq "Error"} 
		$logs = $logs | Select-Object EventId,Message,Source,TimeGenerated 
		$logs | ConvertTo-Html -head $style | Out-File ".\Report\ServerWindowsSystemErrorlog_$ComputerName-$date.html"		
		write-host ""	
	}	
}	

#
write-host ""			
Write-host "Complete!" -ForegroundColor "green"
