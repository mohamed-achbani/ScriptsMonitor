# SYNOPSIS 
#      Monitor JOB SQL Server 
#   DESCRIPTION 
#      Monitor JOB SQL Server#	
#   NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell Version 2.0, SMO assembly 
#   SYNTAXE
#	  .\MonitorSQLServerCheckJobs.ps1
####

#clear screan
cls

Function Get-ColorSplat
    {
        $C1 = @{ForegroundColor="Green";BackgroundColor="DarkGreen"}
        $C2 = @{ForegroundColor="blue";BackgroundColor="DarkYellow"}
        $C3 = @{ForegroundColor="White";BackgroundColor="DarkRed"}
        $C4 = @{ForegroundColor="Blue";BackgroundColor="Gray"}
         
        New-Variable -Name "Good" -Value $C1 -Scope 1
        New-Variable -Name "Problem" -Value $C2 -Scope 1
        New-Variable -Name "Bad" -Value $C3 -Scope 1
        New-Variable -Name "Header" -Value $C4 -Scope 1
    } 
	
#Head 
$HeadJobName = "Job Name".PadRight(110)
$HeadJobStatus = "Status".PadRight(10)
$HeadJobLastRun = "LastRunDate".PadRight(20)	
$HeadCurrentRunStatus = "CurrentStatus".PadRight(25)	
	
# List servers name
$servers = @(Import-Csv ".\servers.csv")

# Reference to SMO 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO'); 
# Referenced by SMO, so also requiered. 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo'); 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc'); 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended'); 
 
## Get color
Get-ColorSplat		
				
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
				$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $serverName; 
				$jobs = $srv.JobServer.Jobs												
				write-host ""
				write-host ""																		
				write-host "______________________________________________________________________________________"
				write-host ""
				write-host "JOBS - INSTANCE NAME : $serverName"					
				write-host "______________________________________________________________________________________"
				write-host ""									
				Write-host $HeadJobName "|" $HeadJobStatus "|" $HeadJobLastRun "|" $HeadCurrentRunStatus @Header 														
				foreach ($job in $jobs)
				{	
					$Name = $job.Name.PadRight(110).Substring(0,110)
					$LastRunOutcome = $job.LastRunOutcome.ToString().PadRight(10)
					$LastRunDate = $job.LastRunDate.ToString().PadRight(20)	
					$CurrentRunStatus = $job.CurrentRunStatus.ToString().PadRight(25)						
					If ($job.LastRunOutcome -eq "Succeeded") 
						{ Write-Host "$($Name) | $($LastRunOutcome) | $($LastRunDate) | $($CurrentRunStatus)" @Good }						
					Else
						{ Write-Host "$($Name) | $($LastRunOutcome) | $($LastRunDate) | $($CurrentRunStatus)" @Bad }	
				}		
				write-host ""					
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

#
write-host ""
Write-host "Complete!" -ForegroundColor "green"

