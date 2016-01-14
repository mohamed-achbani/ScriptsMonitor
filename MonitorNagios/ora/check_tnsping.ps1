# 	   
#   DESCRIPTION 
#		check tnsping with response time in msec.
#   NOTES 
#	Auteur  : Mohamed ACHBANI 
#	Date 	: 16-09-2015	
#   SYNTAXE
#		check_tnsping -serviceName [serviceName] [-hostname hostname] [-retry retry]  [-w warningTimeMsec] -c [criticalTimeMsec]"
#	 	return : ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3);  
######### 
Param(
  [String]$serviceName,  
  [String]$hostname = $env:COMPUTERNAME,
  [Int]$retry = 1,
  [Int]$w = 1000,
  [Int]$c = 3000
)

# By default return status 'UNKNOWN'
$status=3;
$message="";
$rc="`n";
[int]$time=0;
[int]$maxTime=0;
# Perf Data.
$perfdata="";

if ($serviceName -eq "") {
		$message = "Usage : check_tnsping -serviceName [serviceName] [-hostname hostname] [-retry retry]  [-w warningTimeMsec] -c [criticalTimeMsec]";
		write-host $message;
		exit $status;
} 

# ping target hostname
$status=get-wmiobject win32_pingstatus -Filter "Address='$hostname'" | Select-Object statuscode

if($status.statuscode -eq 0) {
		$tnsping = "tnsping"
		$resultat = & $tnsping $serviceName $retry
		if ($resultat -match "OK"){					
			$i = 1
			while ($i -le $retry)
				{
					$resultatMess = $resultatMess + $resultat[10+$i] + $rc
					$time = $resultat[10+$i] | %{$_.split(" ")[1]} | %{$_.trimStart("(")} | %{$_.trimEnd(")")}
					$i++
					if ($time -gt $maxTime) { $maxTime = $time}							
				} 						
		
			if ($maxtime -gt $c) {
				$message =  "Oracle service $serviceName response time is CRITICAL : $maxTime msec";
				$status = 2
			} elseif ($maxtime -gt $w) {
				$message =  "Oracle service $serviceName response time is WARNING : $maxTime msec";
				$status = 1	
			} else {
				$message = "Oracle service $serviceName is OK : $maxTime msec";
				$status = 0
			}					
		} 
		else {
			$message =  "Oracle service $serviceName is CRITICAL";					
			$status = 2	
		}						
} else {
	$message = "Server name $hostname is NOT REACHABLE - Oracle service $serviceName is UNKNOWN";				
}

$perfdata = "'tnsping_msec'=$maxTime";
write-host "$message$rc$resultatMess | $perfdata";
exit $status;



