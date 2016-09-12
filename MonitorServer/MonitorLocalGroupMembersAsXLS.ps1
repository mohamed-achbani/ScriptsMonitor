<# SYNOPSIS 
      Export Local Group Members
   DESCRIPTION 
      Export Local Group Members
	  Out-File : .\Report\MonitorLocalGroupMembers-date.xlsx  
   NOTES 
      Author  : Mohamed ACHBANI 
   SYNTAXE
	  .\MonitorLocalGroupMembersAsXLS.ps1
#> 

#clear screan
cls

$Excel				 = New-Object -ComObject Excel.Application
$Excel.visible 		 = $False
$Excel.DisplayAlerts = $false
$ExcelWorkbooks 	 = $Excel.Workbooks.Add()
$Sheet 				 = $ExcelWorkbooks.Worksheets.Item(1)
$datesave			 = (get-date).ToString(‘yyyy-MM-dd’)
$save 				 = "" + $(get-location) + "\report\MonitorLocalGroupMembers-" + $datesave + ".xlsx" 
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

		$Sheet.Cells.Item($intRow,1) = "SERVEUR NAME"
		$Sheet.Cells.Item($intRow,2) = $machine
		
		$Sheet.Cells.Item($intRow,1).Font.Bold = $True
		$Sheet.Cells.Item($intRow,2).Font.Bold = $True
		$intRow ++		
		
		$query = "select * from win32_pingstatus where address = '$machine'"
		$result = Get-WmiObject -query $query
		
		if ($result.protocoladdress) {		
			try {
				
				$Mbs = (Get-LocalGroupMembers -ComputerName $machine -GroupName  "Administrateurs")
				
				foreach($Mb in $Mbs.Members	)
				{
					$Sheet.Cells.Item($intRow,1) = $Mb
					$intRow ++
				}				
				$intRow ++			
			}	
			catch { 
				$err = $Error[0].Exception ; 
				write-host "Error : [$machine] -- "  $err.Message -ForegroundColor "red"; 
				continue ; 
			} ; 
		}	
		else 
		{
			$intRow++
			$Sheet.Cells.Item($intRow,1) = "$machine ne répond pas"
			$fgColor = 50
			$Sheet.Cells.item($intRow,1).Interior.ColorIndex = $fgColor
			$intRow ++
			$intRow ++	
		}	
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
