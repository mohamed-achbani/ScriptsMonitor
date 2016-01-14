# SYNOPSIS 
#      Get Information Disk 
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
# 	   Date : 10-09-2014	
#########

Function Get-DiskInfo
{
    Param(
        $ComputerName = $env:COMPUTERNAME,
        [Switch]$PassThru
    )
  
    Function Get-ColorSplat
    {
        
		$C1 = @{ForegroundColor="Blue";BackgroundColor="Green"}
        $C2 = @{ForegroundColor="Blue";BackgroundColor="Yellow"}
        $C3 = @{ForegroundColor="Blue";BackgroundColor="Red"}        
		$C4 = @{ForegroundColor="Blue";BackgroundColor="Gray"}		
         
        New-Variable -Name "Good" -Value $C1 -Scope 1
        New-Variable -Name "Problem" -Value $C2 -Scope 1
        New-Variable -Name "Bad" -Value $C3 -Scope 1
        New-Variable -Name "Header" -Value $C4 -Scope 1
    } 
 
    Function Write-ColorOutput
    {
 
        Param($DiskInfo)
		
		Write-Host ""
        # Display the headers.
        Write-host "DiskInfo | SizeGB      | FreeSpaceGB" @Header 
 
        # Display the data.
        ForEach ($D in $DiskInfo)
        {
            $DeviceID = $D.DeviceID.PadRight(6)
            $SGB = $D.Size.ToString().PadRight(6).Remove(5)
            $FGB = $D.FreeSpace.ToString().PadRight(6).Remove(5)		
            If ($D.FreeSpace -ge 5)
            { Write-Host "$($DeviceID)   | $($SGB)       | $($FGB)" @Good }
            ElseIf (($D.FreeSpace -lt 5) -and ($D.FreeSpace -GE 2))
            { Write-Host "$($DeviceID)   | $($SGB)       | $($FGB)" @Problem }
            Else
            { Write-Host "$($DeviceID)   | $($SGB)       | $($FGB)" @Bad }
 
        }
    }
 
    Get-ColorSplat
 
    try {
		$DiskInfo = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputerName | Where-Object {$_.DriveType -eq 3} |
		Select-Object -Property DeviceID,
		@{Name="Size";Expression={$_.Size/1GB}},
		@{Name="FreeSpace";Expression={$_.Freespace/1GB}}     
	 	 
		Write-ColorOutput -DiskInfo $DiskInfo	 
	}	
	catch { 
		$err = $Error[0].Exception ; 
		write-host "Error : [$ComputerName] -- "  $err.Message -ForegroundColor "red";  		
		continue ; 
	} ; 
}
