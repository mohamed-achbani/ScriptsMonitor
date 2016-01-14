# SYNOPSIS 
#      Backup databases
# 	   Verify the backup status of backup files. Same like RESTORE VERIFYONLY.	
#   DESCRIPTION 
#      Backup databases (if accessible = false, then a log backup isn't possible). 
# 	   Verify the backup status of backup files. Same like RESTORE VERIFYONLY.	
#	   The backup name is the same name of database.
#      Works with SQL Server 2005 and higher version.
#   NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell, SMO assembly 
# 	   Date : 14-01-2016	
#   SYNTAXE
#	   .\BackupDatabase.ps1 [-ServerName ServerName] [-DatabasesName DatabasesName] [-Dir Dir] [-DeleteOldBackup boolean] [-RenameOldBackup boolean] [-VerifyOnly boolean] [-Init boolean] [-Shrinklog boolean]
######### 

Function backupdatabase
{
	Param(
			$ServerName = $env:COMPUTERNAME,
			$DatabasesName = $null,
			$Dir = $null,
			$DeleteOldBackup = $false,
			$RenameOldBackup = $true,
			$VerifyOnly = $true,
			$Init = $true,
			$Shrinklog = $true
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
	Write-host -foregroundcolor "GREEN" ($ts + " : [" + $server + "] : Started backup in $folder"); 
	
	foreach ($db in $srv.Databases) 
	{ 	
		# Backup only if the database name matches the regex pattern. 
		# Non need to backup TempDB and database Offline (is not accessible).	
		IF ((![regex]::IsMatch($db.Name, $pattern)) -or ($db.Name -eq "tempdb") -or ($db.isaccessible -eq $false)) 
		{ continue; }; 
		
		$folder = $folder_sv;
		# Creating a folder with Database name 
		$folder = $folder + $db.Name + "\";		
		# Creating a folder if it does not exists
		if(!(Test-Path -Path $folder )){
			New-Item -ItemType directory -Path $folder | Out-Null;
		}		
		
		#Rename old backup (*.bak-->*.vieille)
		if ($RenameOldBackup -eq $true) {
			Get-ChildItem $folder *.vieille | Remove-Item -Force	
			# Start rename backup process.
			$ts = (Get-Date -format yyyy-MM-dd_HH-mm-ss); 		
			Write-Output ($ts + " : [" +$db.Name + "] : Start rename backup : $folder");	
			Get-ChildItem $folder *.bak  			
			get-ChildItem $folder -Filter "*.bak" -Recurse | Move-Item -destination  {$folder + $_.name -replace '.bak','.vieille' }
			# End rename backup process. 
			$ts = (Get-Date -format yyyy-MM-dd_HH-mm-ss); 
			Write-Output ($ts + " : [" + $db.Name + "] : End Rename backup ");
		}			
		
		#Delete old backup (*.bak)
		if ($DeleteOldBackup -eq $true) {
			# Start purge backup process.
			$ts = (Get-Date -format yyyy-MM-dd_HH-mm-ss); 		
			Write-Output ($ts + " : [" +$db.Name + "] : Start purge backup : $folder");	
			Get-ChildItem $folder *.bak  
			Get-ChildItem $folder *.bak | Remove-Item -Force	
			# End purge backup process. 
			$ts = (Get-Date -format yyyy-MM-dd_HH-mm-ss); 
			Write-Output ($ts + " : [" + $db.Name + "] : End purge backup ");
		}	
			
		
		# Database backup.	
		$ts = (Get-Date -format yyyy-MM-dd_HH-mm-ss); 
		Write-Output ($ts + " : [" + $db.Name + "] : Full backup"); 
		 
		$bak = New-Object ("Microsoft.SqlServer.Management.Smo.Backup"); 
		$bak.Action = "DATABASE"; 
		$bak.Database = $db.Name; 	    
		$bak.MediaDescription = "Disk"
		$bak.BackupSetName = $db.Name + " Backup"
        $bak.Devices.AddDevice($folder + $db.Name + "_full.bak", "File"); 
		$bak.BackupSetDescription = "Full backup of " + $db.Name + " " + $ts; 
		# 0 = full backup. 
		$bak.Incremental = 0; 		
		if ($Init -eq $true) {
			 $bak.Initialize = $true;	 
		}
		$bak.Checksum = $true;
		  
		# Starting full backup process. 
		$bak.SqlBackup($srv); 
		$bak.Dispose;
				
		# Restore database verifyonly		
		if ($VerifyOnly -eq $true) {
			$dbRestore = new-object ("Microsoft.SqlServer.Management.Smo.Restore")
			$file = $folder + $db.Name + "_full.bak"			
			$dbRestore.Devices.AddDevice($file, "File")
			if (!($dbRestore.SqlVerify($server))){
				Write-Output ($ts + " : [" + $db.Name + "] : Full backup status : ERROR"); 	
			} else {
				Write-Output ($ts + " : [" + $db.Name + "] : Full backup status : OK"); 	
			}
			$dbRestore.Dispose;
		}	
				
		# If recovery model = simple, then a log backup isn't possible. If ($db.Databaseoptions.RecoveryModel -eq "Simple") (version 2005)
		If (($db.RecoveryModel -eq 3) -or ($db.Databaseoptions.RecoveryModel -eq "Simple")) 
		{ continue; } 
		 
		# Log backup. 
		$ts = Get-Date -format yyyy-MM-dd_HH-mm-ss; 	
		Write-Output ($ts + " : [" + $db.Name + "] : Log backup"); 
		 
		$log = New-Object ("Microsoft.SqlServer.Management.Smo.Backup"); 
		$log.Action = "LOG"; 
		$log.Database = $db.Name; 
		$log.MediaDescription = "Disk"
		$log.BackupSetName = $db.Name + " Backup log"
		$log.Devices.AddDevice($folder + $db.Name + "_log.bak", "File"); 
		$log.BackupSetDescription = "Log backup of " + $db.Name + " " + $ts; 		
		$log.Checksum = $true;
			
		# Truncated log after backup. 
		$log.LogTruncation = "TRUNCATE"; 
			 
		# Start the log backup process. 
		$log.SqlBackup($srv); 
		$log.Dispose;
		
		# Shrinked log after backup (minimum size 100M)		
		if ($Shrinklog -eq $true) {
			$logfiles = $db.LogFiles			
			$logfiles[0].Shrink(100, [Microsoft.SqlServer.Management.Smo.ShrinkMethod]::TruncateOnly)
			$logfiles[0].Refresh()
		}	
				
		# Restore log verifyonly		
		if ($VerifyOnly -eq $true) {
			$dbRestore = new-object ("Microsoft.SqlServer.Management.Smo.Restore")
			# verifyonly Backup Log			
			$file = $folder + $db.Name + "_log.bak"
			$dbRestore.Devices.AddDevice($file, "File")
			if (!($dbRestore.SqlVerify($server))){
				Write-Output ($ts + " : [" + $db.Name + "] : Log backup status : ERROR"); 	
			} else {
				Write-Output ($ts + " : [" + $db.Name + "] : Log backup status : OK"); 	
			}
			$dbRestore.Dispose;
		}
	}; 
	 
	$srv.Dispose;
	
	$ts = (Get-Date -format yyyy-MM-dd_HH-mm-ss); 
	Write-host -foregroundcolor "GREEN" ($ts + " : [" + $server + "] : Finished backup ");
}