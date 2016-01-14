# SYNOPSIS 
#      Shrink log SQL Server 
#   DESCRIPTION 
#      Shrink log SQL Server (Size greater than 100 MB)
#	  Out-File : .\Report\MonitorSQLServerShrinkLog-yyyy-mm-dd.log
#   NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell Version 2.0, SMO assembly 
#	   Date    : 14-01-2016
#   SYNTAXE
#	  .\MonitorSQLServerShrinkLog.ps1
######

#clear screan
cls

# List servers name
$servers = @(Import-Csv ".\servers.csv") 

# Reference to SMO 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO'); 
# Referenced by SMO, so also requiered. 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo'); 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc'); 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended'); 
 
# Analyse for every servers
Write-host "In progress ..."
foreach ($entry in $servers)
{
    $ComputerName = $entry.Name    	
	if ($ComputerName -ne $null) {			
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
			try {	
				if ($currInstance -eq "MSSQLSERVER") {
					$serverName = "$ComputerName"
				} else {
					$serverName = "$ComputerName\$currInstance"
				}			
				write-host "Info : [$serverName] -- Start monitor log SQL Server"  -ForegroundColor "green"	
				$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $serverName; 	
				$dbs = $srv.Databases			
				write-host ""
				write-host ""
				write-host "____________________________________________________________________________________"
				write-host ""
				write-host "LOG SIZE - INSTANCE NAME : $serverName"					
				write-host "____________________________________________________________________________________"
				write-host ""
				foreach ($db in $dbs)
				{
					$name = $db.name
					$model = $db.recoverymodel
					# 1 = Full, 2 = "Bulk Logged, 3 = Simple
					if ($model -eq 1)
					{
						$modelname = "Full"
					}
					elseif ($model -eq 2)
					{
						$modelname = "Bulk Logged"
					}
					elseif ($model -eq 3)
					{
						$modelname = "Simple"
					}					
					$logfiles = $db.LogFiles
					$readOnly = $db.ReadOnly
					$status	  =	$db.Status	
					$isaccessible = $db.isaccessible
																							
					write-host "	******************************************************"
					write-host "	DATABASE NAME  	: "$name " (size in MB)"	
					write-host "	RECOVERY MODEL 	: "$modelname
					write-host "	READ ONLY	: "$readOnly	
					write-host "	STATUS	        : "$status
					write-host "	ACCESSIBLE      : "$isaccessible
					if ($isaccessible -eq $true) {					
						$dbsize = $db.FileGroups['PRIMARY'].Files[0].Size/1KB
						$dbsize = [math]::Round($dbsize)
						$logsize = $db.LogFiles[0].Size/1KB
						$logsize = [math]::Round($logsize)													
						write-host "	BEFORE LOG SHRINK "
						write-host "	    DATA FILE SIZE : " $dbsize 
						# Size greater than 100 MB						
						if ($logsize -gt 100) {							
							Write-Host -foregroundcolor RED "	    LOG FILE SIZE  : " $logsize															
						} else {
							write-host "	    LOG FILE SIZE  : " $logsize 
						}	
						write-host ""
					
						# Shrink only database with "Simple" recovery model and "no read only" and log file > "100 MB"
						if ($logsize -gt 100 -and  $model -eq 3 -and !$readOnly )
						{								
							$logfiles[0].Shrink(1, [Microsoft.SqlServer.Management.Smo.ShrinkMethod]::TruncateOnly)
							$logfiles[0].Refresh()
						}	
						$dbsize = $db.FileGroups['PRIMARY'].Files[0].Size/1KB
						$dbsize = [math]::Round($dbsize)
						$logsize = $db.LogFiles[0].Size/1KB
						$logsize = [math]::Round($logsize)								
						write-host "	AFTER LOG SHRINK "
						write-host "	    DATA FILE SIZE : " $dbsize 
						if ($logsize -gt 100) {
							Write-Host -foregroundcolor RED "	    LOG FILE SIZE  : " $logsize								
						} else {
							write-host "	    LOG FILE SIZE  : " $logsize
						}																														
						write-host ""				
					}											
				}			
				write-host ""
				write-host "	______________________________________________________"
				write-host ""
				write-host "	DISK & SQL SERVICE - SERVER : $ComputerName"
				write-host "	______________________________________________________"				
				write-host ""
				write-host ""
				Get-ServiceSQL -ComputerName $ComputerName
				write-host ""
				Get-DiskInfo -ComputerName $ComputerName					
				$srv.Dispose;
			}				
			catch { 
				$err = $Error[0].Exception ; 
				write-host "Error : [$serverName] -- "  $err.Message  -ForegroundColor "red"; 					
				$srv.Dispose;
				continue ; 			
			} ; 
		}			
	}		
}

##
write-host ""			
Write-host "Complete!" -ForegroundColor "green"

if ($ptrace -eq "O") {
	Stop-Transcript
}
