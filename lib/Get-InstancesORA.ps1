# SYNOPSIS 
#      Get-InstancesORA
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
# 	   Date    : 19-11-2014	
#########

function Get-InstancesORA() { 

 Param(
        $ComputerName = $env:COMPUTERNAME
    )

	BEGIN { 
		# get instances based on services
		$instanceslist = @(); 
		$services = @{ 
			Class = "Win32_Service"; 
			Namespace = "root\cimv2"; 
			Filter = "Name Like 'OracleService%'"; 
			ComputerName = $ComputerName; 
		} 
	} 

	PROCESS { 
		Get-WmiObject @services | foreach-object { 
			$servicename = $_.Name; 		
			$instances = $servicename -replace "OracleService", ""; 		
			$instanceslist += $instances; 
		} 
	 } 

	 END { 
	   return $instanceslist; 
	}
} 
