# SYNOPSIS 
#      Backup databases with bcp	   
#   DESCRIPTION 
#      Backup databases. Export Tables Format BDD. (if accessible = false or IsSystemObject = true then a log backup isn't possible). 
#   NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell, SMO assembly 
# 	   Date : 14-01-2016	
#   SYNTAXE
#	   .\backupTablesToBcpFiles.ps1 [-ServerName ServerName] [-DatabasesName DatabasesName] [-TablesName TablesName] [-Dir Dir] 
#		Import data : Truncate table, execute bcp tablename in filename.bdd -S localhost -T -N -E
######### 

Function backupTablesToBcpFiles
{
	Param(
			$ServerName = $env:COMPUTERNAME,
			$DatabasesName = $null,
			$TablesName = $null,
			$Dir = $null					
		)
	  
	# Configuration variables. 
	[string]$server  = $ServerName;  # Server instance name. 
	[string]$folder  = $Dir;      	 # Folder to backup to. If empty the default backup folder is used. 
	[string]$pattern = "\w";     	 # Regex pattern for database names. By Default use "\w" for all databases.
	
	# Reference to SMO 
	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null; 
	# Referenced by SMO, so also requiered. 
	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo') | out-null; 
	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc') | out-null; 
	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') | out-null; 
	 
	$srv = New-Object -typeName Microsoft.SqlServer.Management.Smo.Server -argumentList "$server"
	$srv.ConnectionContext.StatementTimeout = 0;
	
	# If folder isn't defined use the default backup directory. 
	If ($folder -eq "") 
		{ $folder = $srv.Settings.BackupDirectory + "\"; }; 
	
	$folder_sv =  $folder;
	
	# If database is defined. 
	IF ($DatabasesName -ne $null) 
	{ $pattern = $DatabasesName; }; 
	
	$ts = (Get-Date -format yyyy-MM-dd_HH-mm-ss); 
	Write-host -foregroundcolor "GREEN" ($ts + " : [" + $server + "] : Started Export Tables in $folder"); 
	
	
	foreach ($db in $srv.Databases) 
	{ 	
		# Backup only if the database name matches the regex pattern. 
		# Non need to backup TempDB and database Offline (is not accessible).	
		IF ((![regex]::IsMatch($db.Name, $pattern)) -or ($db.Name -eq "tempdb") -or ($db.isaccessible -eq $false) -or ($db.IsSystemObject -eq $true) ) 
		{ continue; }; 
		
		$folder = $folder_sv;
		# Creating a folder with Database name 
		$folder = $folder + $db.Name + "\";		
		# Creating a folder if it does not exists
		if(!(Test-Path -Path $folder )){
			New-Item -ItemType directory -Path $folder | Out-Null;
		}		
		
		# Start purge backup process.
		$ts = (Get-Date -format yyyy-MM-dd_HH-mm-ss); 		
		Write-Output ($ts + " : [" +$db.Name + "] : Start purge backup : $folder");	
		Get-ChildItem $folder *.*  
		Get-ChildItem $folder *.* | Remove-Item -Force	
		# End purge backup process. 
		$ts = (Get-Date -format yyyy-MM-dd_HH-mm-ss); 
		Write-Output ($ts + " : [" + $db.Name + "] : End purge backup ");
					
		# Export Tables To Bcp Files.	
		$ts = (Get-Date -format yyyy-MM-dd_HH-mm-ss); 				
			$Tables = $db.Tables
			foreach ($Table in $Tables) {
				$Schema = $Table.Schema
				$Name = $Table.Name 	
				if (($Name -eq $TablesName)	 -or ($TablesName -eq $null)) {
					$BcpFlags = "-T -N -E"
					$TableName = "["+$db.Name+"].["+$Schema+"].["+$Name+"]"; 				
					$FileName = '"' + $folder + $Name + '.bdd"'; 				
					$bcpCall = "bcp.exe " + $TableName + " out " + $FileName+" -S " + $Server + " " + $BcpFlags ;
									
					Write-Output ($ts + " : [" + $TableName + "] : Export Tables To Bcp Files"); 	
					Invoke-Expression $bcpCall; 
				}	
			}				
	}
	$srv.Dispose;
	
	$ts = (Get-Date -format yyyy-MM-dd_HH-mm-ss); 
	Write-host -foregroundcolor "GREEN" ($ts + " : [" + $server + "] : Finished Export Tables ");
}