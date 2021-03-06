#Source all the functions in use
$psdir = "" + $(get-location)
$psfunction = "" + $(get-location) + "\lib\"
Set-Location $psfunction

. ./SqlExec.ps1
. ./Get-DiskInfo.ps1 
. ./Get-ServerInfo.ps1 
. ./Get-ServiceSQL.ps1 
. ./Get-VersionSQL.ps1
. ./Get-ServiceORA.ps1
. ./Get-InstancesORA.ps1
. ./Get-InstancesSQL.ps1
. ./Get-MachineNameAndUserName.ps1
. ./Pinghost.ps1
. ./BackupDatabases.ps1
. ./MaintenanceDatabases.ps1
. ./Send-Mail.ps1
. ./BackupTablesToBcpFiles.ps1
. ./Get-LocalGroupMembers.ps1

#Source all the scripts in use
Set-Location $psdir

write-host "*********************************"
write-host "*********************************"
write-host "Custom Profile Loaded"
write-host "*********************************"
write-host "*********************************"
