<# SYNOPSIS 
      Monitor Oracle Corruption Database for Oracle 11g and higher"
   DESCRIPTION 
      Monitor Oracle Corruption Database (logical and physical)   
   NOTES 
      Author: Mohamed ACHBANI
	  Date: 11-02-2016
   SYNTAXE
	  .\MonitorOracleCorruption.ps1 
#> 

Param ( 	
	[String] $pTNS  = ""	
)

#Clear screan
cls

# Enviroment
Set-Variable CONFIG_VERSION "0.4" -option constant
$config_xml = "" + $(get-location)+"\conf\oraconfig.xml"

# Read Configuration oracle_config.xml
$oracleconfig= [xml] ( get-content $config_xml)

#Put your ORACLE_HOME
$ORACLE_HOME="C:\ORACLE\Ora11"

write-host "In progress ..." 
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

Function Get-ColorSplat
    {
        $C1 = @{ForegroundColor="Green";BackgroundColor="DarkGreen"}
        $C2 = @{ForegroundColor="Blue";BackgroundColor="Yellow"}
        $C3 = @{ForegroundColor="White";BackgroundColor="DarkRed"}
        $C4 = @{ForegroundColor="Blue";BackgroundColor="Gray"}
        $C5 = @{ForegroundColor="black";BackgroundColor="DarkYellow"}
		
        New-Variable -Name "Good" -Value $C1 -Scope 1
        New-Variable -Name "Problem" -Value $C2 -Scope 1
        New-Variable -Name "Bad" -Value $C3 -Scope 1
        New-Variable -Name "Header" -Value $C4 -Scope 1
		New-Variable -Name "Title" -Value $C5 -Scope 1
    } 
	
# Get color
Get-ColorSplat

$rman_script="VALIDATE CHECK LOGICAL DATABASE;"
Set-Content -Path "validatedatabase_11g.rman" -value $rman_script

# Database 
foreach ($db in $oracleconfig.oracle.db) {				
	try {					
		$TNS=$db.TNS				
		$userid=$db.userid
		$pwd=$db.pwd
		
		if (($userid -ne "") -and (($TNS -eq $pTNS) -or ($pTNS -eq ""))) { 
			$sql_connect_string="$userid/$pwd@$TNS as sysdba"
			$rman_connect_string = "$userid/$pwd@$TNS"
			
			#check version of database
			$isversion11=@'
			set pagesize 0 
			set feedback off
			select count(*) from v$version where banner like '%11g%';
			quit
'@| & "$ORACLE_HOME\bin\sqlplus" -s "$sql_connect_string"
			$isversion11=$isversion11.Trim()
			
			if ($isversion11 -eq 1) {				
				#check database corruption
				$starttime=get-date
				& $ORACLE_HOME\bin\rman target=$rman_connect_string nocatalog cmdfile="validatedatabase_11g.rman" 2>&1 | foreach-object { write-host "RMAN OUT::",$_.ToString() }
				$endtime=get-date
				$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)				
				##check if database is corrupted
				$iscorrupted=@'
				set pagesize 0 
				set feedback off
				select count(*) from v$database_block_corruption;
				quit
'@| & "$ORACLE_HOME\bin\sqlplus" -s "$sql_connect_string"
	$iscorrupted=$iscorrupted.Trim()
				#
				if ($iscorrupted -eq 1) {
					Write-host "Database is corrupted"  @Bad
				} else {
					Write-host "Database is not corrupted"  @Good
				}				
				Write-host "Result -- Finish Detect Corrupt of DB::", $TNS,"at::",  $duration, "Minutes"  @Header
				Write-host "------------------------------------------------------------------------------------------------------"	@Header				
			}
		}
		
	}	
	catch {
		$err = $Error[0].Exception ; 
		write-host "Error : [$TNS] -- "  $err.Message  -ForegroundColor "red"
		Write-host "------------------------------------------------------------------------------------------------------"	@Header
		write-host ""
		continue ; 			
	}		
}
	
