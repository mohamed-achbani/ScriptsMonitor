# SYNOPSIS 
#      Searching SQL Error Log 
#   DESCRIPTION 
#      Searching SQL Error Log 
#	  Reading last days current SQL Error Log 
#	  Out-File : .\Report\SQLServerErrorlog_ComputerName-Instance-yyyy-mm-dd.html  
#   NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell Version 2.0, SMO assembly 
#	   Date    : 14-01-2016
#   SYNTAXE
#	  .\MonitorSQLServerReadLogsSQL.ps1
############ 

cls

# List servers name
$servers = @(Import-Csv ".\servers.csv") 
	
# Reference to SMO 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO'); 
# Referenced by SMO, so also requiered. 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo'); 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc'); 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended'); 
			
$style = "<" + "style>"  
$style = $style + "TABLE{border:1px solid black; border-collapse: collapse;}" 
$style = $style + "TH{border:1px solid black;background-color:black;color:white;}" 
$style = $style + "TD{border:1px solid black;}" 
$style = $style + "</" + "style>" 

$date = ( get-date ).ToString(‘yyyy-MM-dd’)
$logDate = (get-date).AddDays(-1)

if ($Search -eq "")  {
	$Search = "Error"
}

# Analyse for every servers
Write-host "In progress ..."
foreach ($entry in $servers)
{		
	$ComputerName = $entry.Name
	if ($ComputerName -ne $null) {
		$ComputerName = $ComputerName.toupper()
		# get instances based on services
		$localInstances = @()
		[array]$captions = gwmi win32_service -computerName $ComputerName | ?{$_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe"} | %{$_.Caption}
		foreach ($caption in $captions) {
			if ($caption -eq "MSSQLSERVER") {
				$localInstances += "MSSQLSERVER"
			} else {
				$temp = $caption | %{$_.split(" ")[-1]} | %{$_.trimStart("(")} | %{$_.trimEnd(")")}
				$localInstances += $temp
			}
		}		
		foreach ($currInstance in $localInstances) {
			try 
			{	
				if ($currInstance -eq "MSSQLSERVER") {
					$serverName = "$ComputerName"
				} else {
					$serverName = "$ComputerName\$currInstance"
				}			
				write-host "Info : [$serverName] -- Start check [$Search] in SQL Server"  -ForegroundColor "green"	
				$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $serverName; 
				$Results = $srv.ReadErrorLog(0) | where-object {$_.Text -like "*$Search*" -and $_.LogDate -gt $logDate} | 
					select LogDate, ProcessInfo, Text | 
					ConvertTo-Html -head $style | 
					Out-File ".\Report\SQLServerErrorlog_$ComputerName-$currInstance-$date.html"					
				$srv.Dispose;				
			}	
			catch {
				$err = $Error[0].Exception ; 
				write-host "Error : [$serverName]  -- "  $err.Message  -ForegroundColor "red";
				write-host ""				
				continue ; 
			}								
		} 
	}					
}	

#
write-host ""			
Write-host "Complete!" -ForegroundColor "green"
