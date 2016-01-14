# SYNOPSIS 
#      List Task on Windows Server
#   DESCRIPTION 
#      List Task on Windows Server
#	  Out-File : .\Report\ServerWindowsTask_<ComputerName>-<yyyy-mm-dd>.html 
#   NOTES 
#      Author  : Mohamed ACHBANI      
#      Requires: PowerShell
#	   Date	   : 14-01-2016     
#   SYNTAXE
#	  .\MonitorServerTask.ps1
##### 

cls

# List servers name
$servers = @(Import-Csv ".\servers.csv")
$date = ( get-date ).ToString(‘yyyy-MM-dd’)

Function Get-ColorSplat
    {
        $C1 = @{ForegroundColor="Green";BackgroundColor="DarkGreen"}
        $C2 = @{ForegroundColor="black";BackgroundColor="Yellow"}
        $C3 = @{ForegroundColor="White";BackgroundColor="DarkRed"}
        $C4 = @{ForegroundColor="Blue";BackgroundColor="Gray"}
         
        New-Variable -Name "Good" -Value $C1 -Scope 1
        New-Variable -Name "Problem" -Value $C2 -Scope 1
        New-Variable -Name "Bad" -Value $C3 -Scope 1
        New-Variable -Name "Header" -Value $C4 -Scope 1
    } 

#Head 
$HeadTaskName = "Nom".PadRight(80)
$HeadLastRunTime = "Date dernière exécution".PadRight(25)	
$HeadLastTaskResult = "Résultat".PadRight(20)	
$HeadEnabled = "Actif".PadRight(10)	

# Get color
Get-ColorSplat

# Analyse for every servers
Write-host "In progress ..."
foreach ($entry in $servers)
{	
	$ComputerName = $entry.Name
	if ($ComputerName -ne $null) {	
		try {			
			write-host "INFO : [$ComputerName] " -ForegroundColor "yellow"			
			$Schedule = new-object -com("Schedule.Service") 
			$Schedule.connect($ComputerName) 
			$Tasks = $Schedule.getfolder("\").gettasks(0) 			
			$Tasks = $Tasks | Select-Object $ComputerName, Name, LastRunTime, LastTaskResult, Enabled
			
			if ($ptrace -eq "O") {			
				$TasksLog  = $Tasks | Out-File ".\Report\ServerWindowsTask_$date.log" -Append -Force
				write-host "LOG : [$ComputerName] -- Log information in ServerWindowsTask_$date.log" 
			} else {		
				Write-host $HeadTaskName "|" $HeadLastRunTime "|" $HeadLastTaskResult "|" $HeadEnabled  @Header 					
				foreach ($Task in $Tasks) {		
					if ($Task.Name -ne $null) {
						$Name = $Task.Name.PadRight(80)						
						$LastRunTime = $Task.LastRunTime.ToString().PadRight(25)
						$LastTaskResult = $Task.LastTaskResult
						$Enabled = $Task.Enabled.ToString().PadRight(10)
						$rcode = [Convert]::ToString($LastTaskResult, 16).Insert(0,"0x").ToString().PadRight(20)
						if (($LastTaskResult -eq 0) -and ($Enabled.trim() -eq "True")) {
							Write-Host "$($Name) | $($LastRunTime) | $($rcode) | $($Enabled)" @Good 
						}						
						else {
							if ($Enabled.trim() -eq "True"){ 
								Write-Host "$($Name) | $($LastRunTime) | $($rcode) | $($Enabled)" @Bad 
							}								
							else { 
								Write-Host "$($Name) | $($LastRunTime) | $($rcode) | $($Enabled)" @Problem
							}								
						}		
					}		
				}
				write-host ""
			}				
			write-host ""
		} catch { 
				$err = $Error[0].Exception ; 
				write-host "ERROR : [$ComputerName] -- "  $err.Message  -ForegroundColor "red";
				write-host "";	
				continue ; 
			} ; 	
	}	
}	
#
write-host ""			
Write-host "Complete!" -ForegroundColor "green"



