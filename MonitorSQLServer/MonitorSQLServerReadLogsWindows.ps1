# SYNOPSIS 
#      Searching SQL Windows Error log
#   DESCRIPTION 
#     Searching SQL Windows Error log (MSSQL*) after (sysdate-7)
#	  Out-File : .\Report\SQLWindowsServerErrorlog_ComputerName-yyyy-mm-dd.html  
#   NOTES 
#      Author  : Mohamed ACHBANI       
#	   Date    : 14-01-2016
#   SYNTAXE
#	  .\MonitorSQLServerReadLogsWindows.ps1
###### 

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
$Search = "MSSQL" 

# Analyse for every servers
Write-host "In progress ..."
foreach ($entry in $servers)
{	
	$ComputerName = $entry.Name
	if ($ComputerName -ne $null) {
		write-host "Info : [$ComputerName] -- Start check errors $Search in application log with date after : $dateAfterAsString"  -ForegroundColor "green"	
		$logs = Get-EventLog -ComputerName $ComputerName -After $dateAfter  Application  | where {$_.Source -like "*$Search*"} 
		$logs = $logs | where {$_.EntryType -eq "Error"} 
		$logs = $logs | Select-Object EventId,Message,Source,TimeGenerated 
		$logs | ConvertTo-Html -head $style | Out-File ".\Report\SQLWindowsErrorLog_$ComputerName-$date.html"
	}	
}	
#

write-host ""			
Write-host "Complete!" -ForegroundColor "green"
