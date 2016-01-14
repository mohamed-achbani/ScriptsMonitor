# 	   
#   DESCRIPTION 
#		check_ps : Get number of processes with total memory usage.
#   NOTES 
#	Auteur  : Mohamed ACHBANI 
#	Date 	: 16-09-2015	
#   SYNTAXE
#		check_ps -process [process] -wInstances [$wInstances] -cInstances [$cInstances]
#	 	return : ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3);  
######### 

Param(
  [string]$process,
  $wInstances=5,
  $cInstances=10 
)


# By default return status 'UNKNOWN'.
$status=3;
$message="";
$msgStatus="";
$rc="`n";
# PerfData.
$perfdata="";

# Memory usage in MB.
$MemoryAsMB = 0;
$totalMemoryAsMB = 0;

if ($process -eq "") {
		$message = "Usage : check_ps -process [process] [-wInstances wInstances] [-cInstances cInstances]";
		write-host $message;
		exit $status;
} 

# Get number of processes
$Instances = @();
$Instances = @(Get-Process $process -ErrorAction 0).Count;
if ($Instances -gt 0) {
	
	$proclist = Get-Process  $process
	foreach ($ps in $proclist) 
	{
		$ps | Add-Member -type NoteProperty -name UserID -value ((Get-WmiObject -class win32_process |
				where{$_.ProcessID -eq $ps.id}).getowner()).user
		$ps | Add-Member -type NoteProperty -name PercentCPU -value (get-wmiobject Win32_PerfFormattedData_PerfProc_Process | 
				where{$_.IDProcess -eq $ps.id}).PercentProcessorTime
	}	
	
	if ($Instances -gt $cInstances) {
		$msgStatus = "CRITICAL: Process: $process - maximum number of processes exceeded: $Instances, w=$wInstances, c=$cInstances";
		$status = 2
	} elseif ($Instances -gt $wInstances){
		$msgStatus = "WARNING: Process: $process - maximum number of processes exceeded: $Instances, w=$wInstances, c=$cInstances";		
		$status = 1
	} else {
		$msgStatus = "OK: Process: $process - Number of instances: $Instances, w=$wInstances, c=$cInstances";
		$status = 0
	}	
	
	foreach ($p in $proclist ) {		
		$MemoryAsMB = [math]::round(($p.PM/1mb));
		$totalMemoryAsMB = $totalMemoryAsMB + $MemoryAsMB;		
		$message = $message + "Process: " + $p.Name + ",User: " + $p.UserID + ",CPU: " + $p.PercentCPU + "%,PM : " + $MemoryAsMB + " MB" + $rc;	
	}	
	
} else {
	# No Instance for this process. Return UNKNOWN.
	$msgStatus = "UNKNOWN: Process: $process - No instance";
	$status=3;
}

$perfdata = "'Instances'=$Instances 'Total_Memory_in_MB'=$totalMemoryAsMB";
write-host $msgStatus$rc$message "|" $perfdata;
exit $status;


