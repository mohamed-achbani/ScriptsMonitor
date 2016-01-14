# SYNOPSIS 
#      Get SQL Version
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
# 	   Date : 19-11-2014	
#########

Function Get-VersionSQL
{
	Param (
		$ComputerName = $env:COMPUTERNAME		
	)	
	try {						
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
		# load the SQL SMO assembly
		[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null;		
		
		$SqlInfo = @()
		foreach ($currInstance in $localInstances) {
			try {	
				# Server SQL SharePoint 2013 (port : 20101 et 20102)
				$port = ""
				if (($ComputerName -eq "SI-FORTNER") -or ($ComputerName -eq "SI-JOHNNY")) {
					if ($currInstance -eq "SPSDATA") {
						$port = ",20101"
					}
					if ($currInstance -eq "POWERPIVOT") {
						$port = ",20102"
					}							
				}	
				if ($currInstance -eq "MSSQLSERVER") {
					$serverName = "$ComputerName$port"
				} else {
					$serverName = "$ComputerName\$currInstance$port"
				}			
				
				$server = New-Object -typeName Microsoft.SqlServer.Management.Smo.Server -argumentList "$serverName"
				$tempSqlInfo = "" | Select Version,Edition,fullVer,majVer,minVer,Build,Arch,Level,Root,Instance				
				[string]$tempSqlInfo.fullVer = $server.information.VersionString.toString()
				[string]$tempSqlInfo.Edition = $server.information.Edition.toString()
				[int]$tempSqlInfo.majVer = $server.version.Major
				[int]$tempSqlInfo.minVer = $server.version.Minor
				[int]$tempSqlInfo.build = $server.version.Build
				switch ($tempSqlInfo.majVer) {
					8 {[string]$tempSqlInfo.Version = "SQL Server 2000"}
					9 {[string]$tempSqlInfo.Version = "SQL Server 2005"}
					10 {if ($tempSqlInfo.minVer -eq 0 ) {
								[string]$tempSqlInfo.Version = "SQL Server 2008"
							} else {
								[string]$tempSqlInfo.Version = "SQL Server 2008 R2"
							}
						}
					11 {[string]$tempSqlInfo.Version = "SQL Server 2012"}	
					default {[string]$tempSqlInfo.Version = "Unknown"}
				}
				[string]$tempSqlInfo.Arch = $server.information.Platform.toString()
				[string]$tempSqlInfo.Level = $server.information.ProductLevel.toString()
				[string]$tempSqlInfo.Root = $server.information.RootDirectory.toString()
				[string]$tempSqlInfo.Instance = $currInstance
				$SqlInfo += $tempSqlInfo						
				$server.Dispose;
			} catch	{
				$err = $Error[0].Exception ; 
				write-host "Error : [$serverName] -- " $err.Message -ForegroundColor "red"; 				
				$server.Dispose;				
				continue ; 
			}  
		}		
		return 	$sqlInfo;	
	}	
	catch { 
		$err = $Error[0].Exception ; 
		write-host "Error : [$ComputerName] -- " $err.Message -ForegroundColor "red"; 		
		return $null; 
	} ; 	
}	