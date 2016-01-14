# SYNOPSIS 
#      Get-InstancesSQL
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
# 	   Date    : 19-11-2014	
#########

function Get-InstancesSQL() { 

 Param(
        $ComputerName = $env:COMPUTERNAME
    )

	# get instances based on services
	$instanceslist = @()
	[array]$captions = gwmi win32_service -computerName $ComputerName | ?{$_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe"} | %{$_.Caption}
	foreach ($caption in $captions) {
		if ($caption -eq "MSSQLSERVER") {
			$instanceslist += "MSSQLSERVER"
		} else {
			$temp = $caption | %{$_.split(" ")[-1]} | %{$_.trimStart("(")} | %{$_.trimEnd(")")}
			$instanceslist += $temp
		}
	}	
	return $instanceslist; 
} 
		