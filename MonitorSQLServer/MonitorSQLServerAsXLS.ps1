# SYNOPSIS 
#      Monitor Backup SQL Server 
#   DESCRIPTION 
#      Monitor Backup SQL Server
#	  Out-File : .\Report\MonitorSQLServerReport-yyyy-mm-dd.xlsx  
#   NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell Version 2.0, SMO assembly 
#	   Date    : 14-01-2016
#   SYNTAXE
#	  .\MonitorSQLServerAsXLS.ps1
####### 

#clear screan
cls

$Excel				 = New-Object -ComObject Excel.Application
$Excel.visible 		 = $False
$Excel.DisplayAlerts = $false
$ExcelWorkbooks 	 = $Excel.Workbooks.Add()
$Sheet 				 = $ExcelWorkbooks.Worksheets.Item(1)
$datesave			 = (get-date).ToString(‘yyyy-MM-dd’)
$save 				 = "" + $(get-location) + "\report\MonitorSQLServerReport-" + $datesave + ".xlsx" 
$intRow = 1

#	
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
Write-host "Save file in $save"
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
				write-host "Info : [$serverName] -- Start monitor SQL Server"  -ForegroundColor "green"	
				$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $serverName; 					
			
				# Create head for each instance				
				$Sheet.Cells.Item($intRow,1) = "INSTANCE NAME:"
				$Sheet.Cells.Item($intRow,2) = $serverName				
				$Sheet.Cells.Item($intRow,1).Font.Bold = $True
				$Sheet.Cells.Item($intRow,2).Font.Bold = $True				
			
				$dbs = $srv.Databases					
				# Get versions SQL Server					
				$edition	= $srv.Edition
				$version 	= $srv.VersionString
				$product	= $srv.ProductLevel 
				$sqlversion = "$edition $version $product"	
				
				$Sheet.Cells.Item($intRow,3) = "Version:"
				$Sheet.Cells.Item($intRow,4) = $sqlversion
							
				$Sheet.Cells.Item($intRow,3).Font.Bold = $True
				$Sheet.Cells.Item($intRow,4).Font.Bold = $True
							
				$intRow++
				$Sheet.Cells.Item($intRow,1) = "DATABASE NAME"
				$Sheet.Cells.Item($intRow,2) = "RECOVERY MODEL"
				$Sheet.Cells.Item($intRow,3) = "SIZE (MB)"
				$Sheet.Cells.Item($intRow,4) = "SPACE AVAILABLE (MB)"
				$Sheet.Cells.Item($intRow,5) = "DATA DRIVE"
				$Sheet.Cells.Item($intRow,6) = "SPACE AVAILABLE ON DISK (GB)"
				$Sheet.Cells.Item($intRow,7) = "MIRROR STATUS"
				$Sheet.Cells.Item($intRow,8) = "LOG SIZE (MB)"
		
				for ($col = 1; $col –le 8; $col++)
				{
					$Sheet.Cells.Item($intRow,$col).Font.Bold = $True
					$Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 48
					$Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 34
				}		
				$intRow++
				# Get information for each database
				foreach ($db in $dbs)
				{				
					if ($db.isaccessible -eq $true) {	
						$name = $db.name
						$model = $db.recoverymodel
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
						foreach ($log in $logfiles)
						{
							$logsize = $log.size/1KB
							$logsize = [math]::Round($logsize, 2)
						}

						$dbSpaceAvailable = $db.SpaceAvailable/1KB
						$dbSpaceAvailable = "{0:N2}" -f $dbSpaceAvailable

						$Sheet.Cells.Item($intRow, 1) = $db.Name
						$Sheet.Cells.Item($intRow, 2) = $modelname
						$Sheet.Cells.Item($intRow, 3) = "{0:N2}" -f $db.Size
						
						if ($dbSpaceAvailable -eq 0.00)
						{
							$fgColor = 38
						}
						else
						{
							$fgColor = 0
						}

						$Sheet.Cells.Item($intRow, 4) = $dbSpaceAvailable
						$Sheet.Cells.item($intRow, 4).Interior.ColorIndex = $fgColor

						$dblocation = $db.primaryfilepath
						$dblocation = $dblocation.split(":")

						$dbdrive = $dblocation[0]
						$drives = Get-WmiObject -ComputerName $ComputerName Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
						
						foreach($drive in $drives)
						{
							$size1 = $drive.size / 1GB
							$size = "{0:N2}" -f $size1
							$free1 = $drive.freespace / 1GB
							$free = "{0:N2}" -f $free1
							$ID = $drive.DeviceID
							$a = $free1 / $size1 * 100
							$b = "{0:N2}" -f $a

							if ($dbdrive -eq "C")
							{
								$fgColor = 38
							}
							else
							{
								$fgColor = 0
							}

							$Sheet.Cells.Item($intRow,5) = $dbdrive
							$Sheet.Cells.item($intRow, 5).Interior.ColorIndex = $fgColor

							if ($id -like "$dbdrive*")
							{
								if ($free1 -lt 5)
								{
									$fgColor = 38
								}
								else
								{
									$fgColor = 0
								}
								if (($ID -eq "C:") -and ($free1 -lt 1))
								{
									$fgColor = 38
								}
								$Sheet.Cells.Item($intRow,6) = $free1
								$Sheet.Cells.item($intRow, 6).Interior.ColorIndex = $fgColor
							}
						}
						if($version -like "*2000*")
							{$mirrorstate = 0}
						else
						{
							$mirrorstate = $db.MirroringStatus
						}
						if ($mirrorstate -eq 0)
						{
							$mirror = "No Mirror"
						}
						if ($mirrorstate -eq 1)
							{$mirror = "Suspended"
						}
						if($mirrorstate -eq 5)
						{
							$mirror = "Synchronized"
						}
						if ($mirrorstate -eq 1)
						{
							$fgcolor = 38
						}
						else
						{
							$fgcolor = 0
						}
						
						$Sheet.Cells.Item($intRow,7) = $mirror
						$Sheet.Cells.item($intRow, 7).Interior.ColorIndex = $fgColor

						if ($logsize -gt 500)
						{
							$fgColor = 38
						}
						else
						{
							$fgColor = 0
						}
						$Sheet.Cells.Item($intRow,8) = $logsize
						$Sheet.Cells.item($intRow, 8).Interior.ColorIndex = $fgColor
						$intRow ++	
					}	
				}
				$intRow ++			
		
				# Check backups
				$Sheet.Cells.Item($intRow,1) = "DATABASE NAME"
				$Sheet.Cells.Item($intRow,2) = "LAST FULL BACKUP"
				$Sheet.Cells.Item($intRow,3) = "LAST LOG BACKUP"
				$Sheet.Cells.Item($intRow,4) = "FULL BACKUP AGE(DAYS)"
				$Sheet.Cells.Item($intRow,5) = "LOG BACKUP AGE(HOURS)"
		
				for ($col = 1; $col –le 5; $col++)
				{
					$Sheet.Cells.Item($intRow,$col).Font.Bold = $True
					$Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 48
					$Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 34
				}
				$intRow++	
								
				#Get information backup for each database
				$dbs = $srv.Databases
				foreach ($db in $dbs)
				{
					if ($db.isaccessible -eq $true) {	
						if ($db.Name -ne “tempdb”) 
						{			
							$NumDaysSinceLastFullBackup = ((Get-Date) – $db.LastBackupDate).Days
							$NumDaysSinceLastLogBackup = ((Get-Date) – $db.LastLogBackupDate).TotalHours
							if($db.LastBackupDate -eq "1/1/0001 12:00 AM")
							{
								$fullBackupDate=”Jamais sauvegardé”
								$fgColor3=”red”
							}
							else
							{
								$fullBackupDate=”{0:g}” -f $db.LastBackupDate
							}
							$Sheet.Cells.Item($intRow, 1) = $db.Name
							$Sheet.Cells.Item($intRow, 2) = $fullBackupDate
							$fgColor3=”green”
							
							if ($db.RecoveryModel.Tostring() -eq “SIMPLE”)
							{
								$logBackupDate=”N/A”
								$NumDaysSinceLastLogBackup=”N/A”
							}
							else
							{				
								if($db.LastLogBackupDate -eq "1/1/0001 12:00 AM")
								{
									$logBackupDate=”Jamais sauvegardé”
								}	
								else
								{
									$logBackupDate= “{0:g}” -f $db.LastLogBackupDate
								}
							}
							$Sheet.Cells.Item($intRow, 3) = $logBackupDate
							
							if ($NumDaysSinceLastFullBackup -gt 0)
							{
								$fgColor = 3
							}
							else
							{
								$fgColor = 50
							}
							$Sheet.Cells.Item($intRow, 4) = $NumDaysSinceLastFullBackup
							$Sheet.Cells.item($intRow, 4).Interior.ColorIndex = $fgColor
							$Sheet.Cells.Item($intRow, 5) = $NumDaysSinceLastLogBackup
							$intRow ++
						}
					}	
				}	
				$intRow ++						
				$srv.Dispose;
			}	
			catch { 
				$err = $Error[0].Exception ; 
				write-host "Error : [$serverName] -- "  $err.Message  -ForegroundColor "red"; 
				write-host ""
				$srv.Dispose;	
				continue ; 
			} ; 			
		}	
		$intRow ++
	}
}	

$Sheet.UsedRange.EntireColumn.AutoFit()
$ExcelWorkbooks.SaveAs($save)
$ExcelWorkbooks.Close()
$Excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel) | Out-Null

Write-host "Complete!" -ForegroundColor "green"

