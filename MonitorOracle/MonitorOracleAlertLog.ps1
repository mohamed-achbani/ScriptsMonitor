# SYNOPSIS 
#      Monitor Oracle Alert Log
#   DESCRIPTION 
#      Monitor Oracle Alert Log (check error ORA-)   
#   NOTES 
#      Author  : Mohamed ACHBANI
#      Requires: PowerShell
#	   Date	   : 14-01-2016
#   SYNTAXE
#	  .\MonitorOracleAlertLog.ps1
##### 

Param ( 
		[String] $scope = "DB",
		[String] $pTNS 	= ""		
)


Function Get-ColorSplat
    {
        $C1 = @{ForegroundColor="black";BackgroundColor="Yellow"}
        $C2 = @{ForegroundColor="White";BackgroundColor="DarkRed"} 
		$C3 = @{ForegroundColor="Blue";BackgroundColor="Gray"}		
 
        New-Variable -Name "Problem" -Value $C1 -Scope 1
        New-Variable -Name "Bad" -Value $C2 -Scope 1    
		New-Variable -Name "Header" -Value $C3 -Scope 1         		
    } 

#Head 
$HeadErrorCode = "Error Code".PadRight(25)
$HeadErrorText = "Error Text".PadRight(145)
	
# Get color
Get-ColorSplat	

# Clear screan
cls

##--------------------------------------------------------------------------
# Open up the logfile using the paratage $ adminstrative share background_dump_dest
# Parameter <background_dump_dest>
##--------------------------------------------------------------------------

write-host "In progress ..."  

# Enviroment
Set-Variable CONFIG_VERSION "0.4" -option constant
$config_xml="" + $(get-location)+"\conf\oraconfig.xml"

# Read Configuration
$oracleconfig= [xml] ( get-content $config_xml)

#Check if the XML file has the correct version
if ( $oracleconfig.oracle.HasAttribute("version") ) {
	$xml_script_version=$oracleconfig.oracle.getAttribute("version")
	if ( $CONFIG_VERSION.equals( $xml_script_version)) {
		write-host "Info -- XML configuration with the right version::  $CONFIG_VERSION "
	}
	else {
		throw "Configuration xml file version is wrong, found: $xml_script_version but need :: $CONFIG_VERSION !"
	}
 }
else {
	throw "Configuration xml file version info missing, please check the xml and add the version attribte to <oracle> !"
}


# Database 
if ($scope -eq "DB") {
	foreach ($db in $oracleconfig.oracle.db) {
		try {
			$dest=$db.dest
			$max_lines_read=$db.max_lines_read			
			$TNS=$db.TNS			
			if (($dest -ne "" ) -and (($TNS -eq $pTNS) -or ($pTNS -eq ""))) {		
				write-host "Info : [$TNS] -- Monitor Oracle Log ($max_lines_read)"  -ForegroundColor "green"
				Write-host $HeadErrorCode "|" $HeadErrorText @Header
				$text = Get-Content -path $dest  | Select-Object -last $max_lines_read			
				$text = $text | Select-String  -pattern  "ORA-" -Context 0, ($1.count)
				if ($text -ne $null) {
					foreach ($line in $text) {
						$String = $line.ToString()				
						$Pos = $String.IndexOf(":")				
						if ($Pos -gt 0) {
							$ErrorCode = $String.Substring(0,$Pos).PadRight(25)											
							$ErrorText = $String.Substring($string.Length-($string.Length-$Pos-1)).PadRight(145)
							if ($ErrorCode -like 'ORA-600*') {						
								Write-Host "$($ErrorCode) | $($ErrorText) " @Bad 						
							} elseif ($ErrorCode -like 'ORA-*') {						
								Write-Host "$($ErrorCode) | $($ErrorText) " @Problem 
							}
						}	
					}
				}
				write-host ""
			}
		}
		catch {
			$err = $Error[0].Exception ; 
			write-host "Error : [$TNS] -- "  $err.Message  -ForegroundColor "red"
		}
	}
}

 

 
 