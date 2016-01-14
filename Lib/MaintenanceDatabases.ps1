# SYNOPSIS 
#     MaintenanceDatabases.
# 	   
# DESCRIPTION 
#     Function Checkdb :
#			Powershell DBCC Checkdb.
#	   		If database name equals tempdb or database status is not accessible, DBCC CheckDB is not possible.
#	  Function RebuildIndexes :
#			Powershell rebuild indexes.
#			Check to make sure the database is not a system database, is accessible, is not read only
#			Check index is not XML indexes
#	  Function ChangeRecoveryModel :
#			Powershell change recoverymodel to simple or full for all databases except databases system.
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
# 	   Date    : 20-11-2014	
#
# SYNTAXE
#	   Checkdb				[-ServerName ServerName] [-ShowDetail ShowDetail] [-DatabaseName ServerName] 
#	   RebuildIndexes		[-ServerName ServerName] [-DatabaseName ServerName] 
#	   ChangeRecoveryModel	[-ServerName ServerName] [-RecoveryModel RecoveryModel] [-Change Change]
#
# SAMPLE 	  
#	   $servers = @(Get-Content ".\servers.txt")
#	   $servers | %{ ChangeRecoveryModel $_ } 
#	   Checkdb -ServerName localhost -ShowDetail $false
#	   RebuildIndexes -ServerName localhost
#	   ChangeRecoveryModel -ServerName localhost -RecoveryModel Simple -Change $True
######### 

function Checkdb
{
    param (
        [parameter(Mandatory = $true)][string]$ServerName,
		[Boolean] $ShowDetails = $True,
		[String]$DatabaseName 
    )
    try {										
		# Reference to SMO 
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null; 
		# Reference to System.Data.SqlClient 
		[reflection.assembly]::LoadWithPartialName("System.Data.SqlClient") | out-null; 
		
		$ServerName = $ServerName.toupper()	
		# get instances based on services
		$localInstances = @()
		[array]$captions = gwmi win32_service -computerName $ServerName | ?{$_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe"} | %{$_.Caption}
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
				if ($currInstance -eq "MSSQLSERVER") {	$ServerInstance = "$ServerName"	} 
				else { $ServerInstance = "$ServerName\$currInstance"}																			
				$srv = New-Object -typeName Microsoft.SqlServer.Management.Smo.Server -argumentList "$ServerInstance"
				$srv.ConnectionContext.StatementTimeout = 0;						
				$connString = "Server=$ServerInstance;Integrated Security=SSPI;Database=master"
				$masterConn = new-object ('System.Data.SqlClient.SqlConnection') $connString
				$masterCmd = new-object System.Data.SqlClient.SqlCommand 
				$masterCmd.Connection = $masterConn				
				$masterCmd.CommandTimeout = 0;
				$masterConn.Open()					
				#DBCC CHECKDB for all databases of ServerInstance
				foreach ($db in $srv.Databases) 
				{ 	
				try	
					{
						$database=$db.Name
						if (($db.isaccessible -eq $true) -and ($DatabaseName -eq "" -or $database -eq $DatabaseName)) {							
							if ($database -ne “tempdb”) {							
								$masterCmd.CommandText = "DBCC CHECKDB([$database]) WITH TABLERESULTS"										
								$reader = $masterCmd.ExecuteReader()									
								$NbErrors = 0
								if ($reader.HasRows -eq $true) {						
									while ($reader.Read()) {
										$messageText = $reader["MessageText"]			
										if ($reader["Level"] -gt 10) { 
											$NbErrors++;	
											if ($ShowDetails -eq $true) { Write-Host "DBCC_ERRORS : " $messageText -backgroundcolor Yellow -foregroundcolor Red }								
										} 
										else { if ($ShowDetails -eq $true) { Write-Host $messageText } }
									}  
									$reader.Close()					
								}													
								if ($NbErrors -gt 0) { Write-Host "Error : [$ServerInstance] - Database : [$database] , $NbErrors Error(s) " -backgroundcolor Yellow -foregroundcolor Red }
								else { Write-Host "Info : [$ServerInstance] - Database : [$database] , $NbErrors Error(s) " -backgroundcolor Green -foregroundcolor Blue }
							}							
						} 
					}	
					catch {
						$err = $Error[0].Exception ; 
						write-host "Error : [$ServerInstance] [$database]-- " $err.Message -ForegroundColor "red"; 																					
						continue ; 
					}  									
				}				
				$masterConn.Close() 				
				$srv.Dispose;
			} catch	{
				$err = $Error[0].Exception ; 
				write-host "Error : [$ServerInstance] -- " $err.Message -ForegroundColor "red"; 												
				$masterConn.Close()
				$srv.Dispose;					
				continue ; 
			}  		
		}
	}
	catch {
		$err = $Error[0].Exception ; 
		write-host "Error : [$ServerName] -- " $err.Message -ForegroundColor "red"; 								
		continue ; 
	}  	
}			

function RebuildIndexes
{
    param (
        [parameter(Mandatory = $true)][string]$ServerName,
		[String]$DatabaseName 
    )
    try {										
		# Reference to SMO 
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null; 
		$ServerName = $ServerName.toupper()	
		# get instances based on services
		$localInstances = @()
		[array]$captions = gwmi win32_service -computerName $ServerName | ?{$_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe"} | %{$_.Caption}
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
				if ($currInstance -eq "MSSQLSERVER") {	$ServerInstance = "$ServerName"	} 
				else { $ServerInstance = "$ServerName\$currInstance"}																			
				$srv = New-Object -typeName Microsoft.SqlServer.Management.Smo.Server -argumentList "$ServerInstance"
				$srv.ConnectionContext.StatementTimeout = 0;
				#Reindex for all databases
				foreach ($db in $srv.Databases) {
				try {					
					  #Database is not a system database, and is accessible
					  if (($db.IsSystemObject -ne $True) -and ($db.IsAccessible -eq $True) -and ($db.ReadOnly -eq $False) -and ($DatabaseName -eq "" -or $db.Name -eq $DatabaseName)) {						
							$Database = $db.Name
							$DatabaseId = [string]$db.ID
							$Tables = $db.Tables
							foreach ($Table in $Tables) {
								# Store the table name for reporting
								$TableName = $Table.Name
								$TablesId = [string]$Table.ID
								$Indexes = $Table.Indexes
								foreach ($Index in $Indexes) {
								try {
										# Index is not XML indexes
										if ($Index.IsXmlIndex -eq $False) {									
											$IndexInfos = $Index.EnumFragmentation(); 
											$IndexInfos | ForEach-Object { 
												$IndexName = $_.Index_Name;
												$Average_Fragmentation = [math]::Round($_.AverageFragmentation); 
											};	 
											if ($Average_Fragmentation -gt 30) {
												# Rebuild index - fragmentation > 30%										
												Write-Host "Database :"$Database " Table :"$TableName "Index :"$IndexName " is Fragmented "$Average_Fragmentation "% = > Rebuild"	-backgroundcolor Yellow -foregroundcolor Red
												$index.Rebuild()
											} elseif ($Average_Fragmentation -gt 10) {
												# Reorg index - fragmentation > 10%
												Write-Host "Database :"$Database " Table :"$TableName "Index :"$IndexName " is Not Fragmented "$Average_Fragmentation "% = > Reorganize and Update Statistics" -backgroundcolor Green -foregroundcolor Blue										
												$index.Reorganize()
												# Update statistics										
												$index.UpdateStatistics("FullSCAN")
											} else { 
												Write-Host "Database :"$Database " Table :"$TableName "Index :"$IndexName " Fragmentation "$Average_Fragmentation "% = > Nothing to do" 
											}
										}
									}
									catch	{
										$err = $Error[0].Exception ; 
										Write-Host "Error : [$ServerInstance] Database :" $Database " Table :"$TableName "Index :"$IndexName " -- "$err.Message -ForegroundColor "red"; 																											
										continue ;					
									}
								}
							}
						}
					}
					catch	{
						$err = $Error[0].Exception ; 
						Write-Host "Error : [$ServerInstance] Database :" $Database " Table :"$TableName "Index :"$IndexName " -- "$err.Message -ForegroundColor "red"; 																											
						continue ;					
					}
				}	
				$srv.Dispose
				Write-Host "End"
			} catch	{
				$err = $Error[0].Exception ; 
				write-host "Error : [$ServerInstance] -- " $err.Message -ForegroundColor "red"; 																
				$srv.Dispose;					
				continue ; 
			}  		
		}
	}
	catch {
		$err = $Error[0].Exception ; 
		write-host "Error : [$ServerName] -- " $err.Message -ForegroundColor "red"; 								
		continue ; 
	}  	
}			


function ChangeRecoveryModel
{
    param (
        [parameter(Mandatory = $true)][string]$ServerName,
		[string]$RecoveryModel = "Simple",
		[Boolean] $ChangeToSimple = $False
    )
    try {										
		# Reference to SMO 
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null; 
		$ServerName = $ServerName.toupper()	
		# get instances based on services
		$localInstances = @()
		[array]$captions = gwmi win32_service -computerName $ServerName | ?{$_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe"} | %{$_.Caption}
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
				if ($currInstance -eq "MSSQLSERVER") {	$ServerInstance = "$ServerName"	} 
				else { $ServerInstance = "$ServerName\$currInstance"}																			
				$srv = New-Object -typeName Microsoft.SqlServer.Management.Smo.Server -argumentList "$ServerInstance"
				$srv.ConnectionContext.StatementTimeout = 0;						
				Write-Host " Initial RecoveryModel : ["$ServerInstance"]"
				$srv.Databases | where {$_.IsSystemObject -eq $false} | select Name, RecoveryModel | Format-Table
				if ($ChangeToSimple -eq $True) {
					#Change RecoveryModel To Simple
					if ($RecoveryModel -eq "Simple") { 
						$srv.Databases | where {$_.IsSystemObject -eq $false} | foreach {$_.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple; $_.Alter()}
					}
					#Change RecoveryModel To Full
					elseif ($RecoveryModel -eq "Full") {
						$srv.Databases | where {$_.IsSystemObject -eq $false} | foreach {$_.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Full; $_.Alter()}
					}
					Write-Host "After change RecoveryModel : ["$ServerInstance"]"
					$srv.Databases | where {$_.IsSystemObject -eq $false} | select Name, RecoveryModel | Format-Table
				}
				$srv.Dispose;					
			} 
			catch {
				$err = $Error[0].Exception ; 
				write-host "Error : [$ServerInstance] -- " $err.Message -ForegroundColor "red"; 																
				$srv.Dispose;					
				continue ; 
			}  		
		}
	}
	catch {
		$err = $Error[0].Exception ; 
		write-host "Error : [$ServerName] -- " $err.Message -ForegroundColor "red"; 								
		continue ; 
	}  	
}		


