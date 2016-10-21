<# SYNOPSIS 
      Check TSM schedule error
   DESCRIPTION 
      This script check TSM schedule error
   NOTES 
      Author : Mohamed ACHBANI  
	  Date : 19-10-2016
   SYNTAXE
	  .\tsm_schedule_error.ps1
	  return : ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3);  
#> 

# By default return status 'UNKNOWN'.
$ExitCode = 3
$msg = "UNKNOWN: Error in script - this should not happen "
cd "C:\Program Files\Tivoli\TSM\baclient"

$errors=./dsmadmc.exe -id=admin -password=admin -comma -dataonly=yes "q event * * t=c begind=today-1 begint=now endd=today endt=now ex=yes"

if ($errors -like '*No match found using this criteria*') {
	$ExitCode = 0
	$msg = "OK:  $errors" 
} else {
	$ExitCode = 2
	$msg = "CRITICAL: $errors"
}

write-host $msg
exit($ExitCode)

