# 	   
#   DESCRIPTION 
#		Check Nagios script : check_database_size.ps1 for Microsoft Exchange (2010 - 2013)
#   NOTES 
#		Auteur  : Mohamed ACHBANI 
# 		Requires: PowerShell Version 2.0,  Microsoft.Exchange.Management.PowerShell.E2010
#		Date 	: 19-01-2016
#   SYNTAXE
#		./check_database_size.ps1 [-Server ServerName] [-w ValueIn%] [-c ValueIn%]
#	 	return : ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3);  
######### 

Param(
    $Server = $env:COMPUTERNAME,
	$w = 15,
	$c = 5
)

# Set the status to UNKNOWN. ('UNKNOWN'=>3).
$Status = 3;
# Perf Data.
$perfdata = "";
# Message for nagios description.
$Message = "";
# Database Size.
$DBTotalSizeAsGB = 0;
# Database Name;
$DBName = "";
# Database File location.
$DBfilePath = "";

if ((Get-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction:SilentlyContinue) -eq $null) {
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010;
}

# Set the status to OK.('OK'=>0).
$Status = 0;
# Get Mailbox Database Size and Available New Mailbox Space
$dbs = Get-MailboxDatabase -Server $Server -Status | select Name, Edbfilepath, DatabaseSize;

foreach ($db in $dbs)
{
	$DBName = $db.Name;
	$DBfilePath = $db.Edbfilepath.pathname;
    $DBfilePath = $DBfilePath.split(":")[0]+":";    
    $DBSizeAsGB = $db.DatabaseSize.ToGB();

	# Total DatabaseSize To GB used for perfdata.
	$DBTotalSizeAsGB = $DBTotalSizeAsGB + $DBSizeAsGB;
	
	# Get free space on driver for each database.
	$drive = Get-WmiObject Win32_LogicalDisk -ComputerName $Server | Where-Object {$_.DeviceID -eq $DBfilePath}						
	$percentFree = [Math]::Round(($drive.freeSpace / $drive.size) * 100, 2); 
	$freeSpaceGB = [Math]::Round($drive.freeSpace / 1073741824, 2);   
		
	# Set message for nagios description.
	$Message = $Message + " Database Name = " + $DBName + "; DatabaseSize = " + $DBSizeAsGB +" GB; Drive = " + $Drive.DeviceID + "; FreeSpace = " + $freeSpaceGB + " GB;`n" ;
	
	if ($status -lt 2) {		
		if ($percentFree -lt $w) {
				# Set the status to WARNING.('WARNING'=>1).
				$status = 1;
		}
		if ($percentFree -lt $c) {		
				# Set the status to CRITICAL.('CRITICAL'=>2).
				$status = 2;
		}
	}	
}

$perfdata = "'DBTotalSizeAsGB'=$DBTotalSizeAsGB";

if ($status -eq 0) {
	Write-Host "OK: "$Message" | "$perfdata;
} elseif ($status -eq 1) {	
	Write-Host "WARNING: "$Message" | "$perfdata;
} elseif ($status -eq 2) {	
	Write-Host "CRITICAL: "$Message" | "$perfdata;
} else {
	Write-Host "UNKNOWN: Unable to determinate database size";
}

exit $status;

