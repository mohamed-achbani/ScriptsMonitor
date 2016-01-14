# SYNOPSIS 
#      Get Machine and connected Username
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
# 	   Date : 10-10-2013	
#########

Function Get-MachineAndUserName
{
    Param(
        $MachineName = $env:COMPUTERNAME        
    )
		
		$PingStatus = Gwmi Win32_PingStatus -Filter "Address = '$MachineName'" |
		Select-Object StatusCode
		If ($PingStatus.StatusCode -eq 0)	{
			$GetWMIObject = Get-WMIObject Win32_ComputerSystem -Computername $MachineName
			$UserName 	= $GetWMIObject.UserName
			#$IPaddr 	= $GetWMIObject.Win32_NetworkAdapterConfiguration			
			Write-Host $MachineName" "$Username" "$IPaddr -Fore "Green"
		}			
		Else{
			Write-Host $MachineName -Fore "Red"
		} 
	
}