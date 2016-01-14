# SYNOPSIS 
#      Monitor Windows Server
#   DESCRIPTION 
#      Monitor Windows Server
#	  Out-File : .\Report\MonitorServerReport-date.xlsx  
#   NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
#	   Date	   : 14-01-2016
#   SYNTAXE
#	  .\MonitorServerAsXLS.ps1
####### 

#clear screan
cls

$Excel				 = New-Object -ComObject Excel.Application
$Excel.visible 		 = $False
$Excel.DisplayAlerts = $false
$ExcelWorkbooks 	 = $Excel.Workbooks.Add()
$Sheet 				 = $ExcelWorkbooks.Worksheets.Item(1)
$datesave			 = (get-date).ToString(‘yyyy-MM-dd’)
$save 				 = "" + $(get-location) + "\report\MonitorServerReport-" + $datesave + ".xlsx" 
$intRow = 1

# List servers name
$servers = @(Import-Csv ".\servers.csv")

# Analyse for every servers
Write-host "In progress ..."
Write-host "Save file in $save"

foreach ($entry in $servers)
{  
 	$machine = $entry.Name
	if ($machine -ne $null) {
		
		$machine    = $machine.toupper()

		$Sheet.Cells.Item($intRow,1) = "SERVEUR NAME:"
		$Sheet.Cells.Item($intRow,2) = $machine
						
	
		$Sheet.Cells.Item($intRow,1).Font.Bold = $True
		$Sheet.Cells.Item($intRow,2).Font.Bold = $True
		
		try {
			$build = @{n="Build";e={$_.BuildNumber}}
			$SPNumber = @{n="SPNumber";e={$_.CSDVersion}}
			$sku = @{n="SKU";e={$_.OperatingSystemSKU}}
			$hostname = @{n="HostName";e={$_.CSName}}

			$Win32_OS = Get-WmiObject Win32_OperatingSystem -computer $machine | select $build,$SPNumber,Caption,$sku,$hostname, servicepackmajorversion
			$OS = $Win32_OS.Caption
			$servicepack = $Win32_OS.servicepackmajorversion
			
			$Sheet.Cells.Item($intRow,4) = "OS : $OS Service Pack: $servicepack"
			$Sheet.Cells.Item($intRow,4).Font.Bold = $True	
			
			$physCount = new-object hashtable
			$Win32_cpu = Get-WmiObject -class win32_processor -computer $machine
			$Win32_cpu |%{$physCount[$_.SocketDesignation] = 1}
			$NbCPUs = $physCount.count
			
			$Sheet.Cells.Item($intRow,5) = "Nb Processeurs : $NbCPUs"
			$Sheet.Cells.Item($intRow,5).Font.Bold = $True	
						
			$intRow++
			$Sheet.Cells.Item($intRow,1) = "DATA DRIVE"
			$Sheet.Cells.Item($intRow,2) = "VOLUME NAME"
			$Sheet.Cells.Item($intRow,3) = "SIZE (GB)"	
			$Sheet.Cells.Item($intRow,4) = "SPACE AVAILABLE ON DISK (GB)"
		
			for ($col = 1; $col –le 4; $col++)
			{
				$Sheet.Cells.Item($intRow,$col).Font.Bold = $True
				$Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 48
				$Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 34
			}
			$intRow++		
					
			$drives = Get-WmiObject -ComputerName $machine Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}

			foreach($drive in $drives)
			{
				$size1 = $drive.size / 1GB
				$size = "{0:N2}" -f $size1
				$free1 = $drive.freespace / 1GB
				$free = "{0:N2}" -f $free1
				$ID = $drive.DeviceID
				$a = $free1 / $size1 * 100
				$b = "{0:N2}" -f $a

				if ($ID -eq "C:")
				{
					$fgColor = 38
				}
				else
				{
					$fgColor = 0
				}

				$Sheet.Cells.Item($intRow,1) = $ID
				$Sheet.Cells.item($intRow,1).Interior.ColorIndex = $fgColor
				$Sheet.Cells.Item($intRow,2) = $drive.VolumeName
				$Sheet.Cells.Item($intRow,3) = $size
				
				if ($free1 -lt 5)
				{
					$fgColor = 38
				}
				else
				{
					$fgColor = 0
				}
				if (($ID -eq "C:") -and ($free1 -lt 1))
				{
					$fgColor = 38
				}
				
				$Sheet.Cells.Item($intRow,4) = $free
				$Sheet.Cells.item($intRow,4).Interior.ColorIndex = $fgColor		
				$intRow ++		
			}				
			$intRow ++			
		}	
		catch { 
			$err = $Error[0].Exception ; 
			write-host "Error : [$machine] -- "  $err.Message -ForegroundColor "red"; 
			continue ; 
		} ; 
		
		$intRow ++	
	}	
}

$Sheet.UsedRange.EntireColumn.AutoFit()
$ExcelWorkbooks.SaveAs($save)
$ExcelWorkbooks.Close()
$Excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel) | Out-Null

####################################################################
Write-host "Complete!" -ForegroundColor "green"
