 <# SYNOPSIS 
      Monitor users session
   DESCRIPTION 
       Monitor users session
   NOTES 
      Author  : Mohamed ACHBANI 
	  Date : 26-09-2016
   SYNTAXE
	  check_users_session.ps1 -wSessions [wSessions] -cSessions [cSessions] 
	  return : ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3);  
#> 

Param(
  $wSessions=0,
  $cSessions=1
)

# By default return status 'UNKNOWN'.
$status=3;
$Session = "Total RDP active(s) session(s)";
$count = 0;

$queryResults = (qwinsta /server:localhost | foreach { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv) ;	
ForEach ($queryResult in $queryResults) { 		
	$RDPUser = $queryResult.UTILISATEUR;
	$sessionType = $queryResult.SESSION; 					
	 If (($RDPUser -ne $NULL) -and ($sessionType -like 'rdp-tcp#*')) { 
		$count = $count + 1;
		$SessionList = $SessionList + " " + $RDPUser;
	} 
} 

# WARNING (COUNT > $wSessions)
if ($count -gt $wSessions) { $status = 1}

# CRITICAL (COUNT > $cSessions)
if ($count -gt $cSessions) { $status = 2}

# OK (COUNT = 0)
if ($count -eq 0) { $status = 0; $SessionList = "NONE";}

write-host "$Session : $count `n User(s) : $SessionList"

exit $status;