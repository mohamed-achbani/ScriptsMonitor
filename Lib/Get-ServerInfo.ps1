# SYNOPSIS 
#      Get Server information
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
# 	   Date : 23-10-2013	
#########

Function Get-ServerInfo
{
	Param($ServerName = $env:COMPUTERNAME)

	# Get ComputerSystem info
	function getComputerSystem 
	{
		Param($ComputerName) 		
		return  gwmi -query "select * from Win32_ComputerSystem" -computername $ComputerName | 
			select Name, Model, Manufacturer, Description, DNSHostName,
			Domain, DomainRole, PartOfDomain, NumberOfProcessors,
			SystemType, @{Name="TotalPhysicalMemory(Mo)";Expression={$_.TotalPhysicalMemory/1MB}}, UserName, Workgroup
	}


	# Get OperatingSystem info
	function getOperatingSystem 
	{
		Param($ComputerName)
		return  gwmi -query "select * from Win32_OperatingSystem" -computername $ComputerName | 
			select Name, Version
	}   
	   
	# Get PhysicalMemory info
	function getPhysicalMemory 
	{
        Param($ComputerName) 
		return  gwmi -query "select * from Win32_PhysicalMemory" -computername $ComputerName | 
			select Name,
			@{Name="Capacity(GB)";Expression={$_.Capacity/1GB}},
			DeviceLocator , Tag 	
	}		

	# Get LogicalDisk info
	function getLogicalDisk  
	{
		Param($ComputerName) 
    	return  gwmi -query "select * from Win32_LogicalDisk where DriveType=3" -computername $ComputerName | 
		select Name, 
		@{Name="Size";Expression={$_.Size/1GB}},
		@{Name="FreeSpace";Expression={$_.Freespace/1GB}}   
	}	
	
	try {		
			
		Write-Host -foregroundcolor GREEN "System Information"
		getComputerSystem -ComputerName $ServerName
		
		Write-Host -foregroundcolor GREEN "Operating Information"
		getOperatingSystem -ComputerName $ServerName
		
		Write-Host -foregroundcolor GREEN "Physical Information"
		getPhysicalMemory -ComputerName $ServerName
		
		Write-Host -foregroundcolor GREEN "Logical Information"
		getLogicalDisk -ComputerName $ServerName
					
	}
	catch { 
		$err = $Error[0].Exception ; 
		write-host "Error : [$ServerName]  -- "  $err.Message -ForegroundColor "red"; 
		continue ; 
	} ; 	
}
