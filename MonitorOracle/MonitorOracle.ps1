# SYNOPSIS 
#      Monitor Oracle 
#   DESCRIPTION 
#      Monitor Oracle Information (version, database space, tablespace usage ...), oralce user must be SYS.   
#   NOTES 
#      Author : Mohamed ACHBANI
#	   Requires: PowerShell, ODP assembly
#	   Date : 2013 	
#   SYNTAXE
#	  .\MonitorOracle.ps1 
##### 

Param ( 	
	[String] $pTNS  = "",
	[String] $pMonitorDetail  = $false
)

#Clear screan
cls

# Enviroment
Set-Variable CONFIG_VERSION "0.4" -option constant
$config_xml = "" + $(get-location)+"\conf\oraconfig.xml"
$oraclemetadata = "" + $(get-location)+"\conf\orametadata.xml"

# Read Configuration oracle_config.xml
$oracleconfig= [xml] ( get-content $config_xml)

# Read Configuration metadata.xml
$oraclemetadata= [xml] ( get-content $oraclemetadata)

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

# Load the ODP assembly  
[Reflection.Assembly]::LoadFile("C:\ORACLE\Ora11_x64\odp.net\bin\2.x\Oracle.DataAccess.dll") | out-null

# Database 
foreach ($db in $oracleconfig.oracle.db) {				
	try {					
		$TNS=$db.TNS				
		$userid=$db.userid
		$pwd=$db.pwd
		$versionNumber=$db.VERSION		
		if (($userid -ne "") -and (($TNS -eq $pTNS) -or ($pTNS -eq ""))) { 					
				
			#Connect to Oracle 
			$constr = "User Id=$userId;Password=$pwd;Data Source=$TNS;DBA Privilege=SYSDBA;"			
			$conn= New-Object Oracle.DataAccess.Client.OracleConnection($constr)
			$conn.Open()
			$command = New-Object Oracle.DataAccess.Client.OracleCommand( $sql,$conn)
			Write-Host ""
			$name = "Database information overview  [$TNS]".PadRight(100)
			Write-Host $name @Title			
			#-----------------				
			#Check Version
			$1 = "Version".PadRight(100)
			$command.CommandText = 'select * from v$version'
			$reader=$command.ExecuteReader()
			$reader.read() | out-null
			$version = $reader.GetString(0).PadRight(50)	   
			Write-host $1 @Header 	
			Write-Host "$($version)" 
			Write-Host ""
			$reader.close()
			
			#-----------------				
			#Startup Time
			$1 = "Startup Time".PadRight(100)
			$command.CommandText = 'SELECT to_char(startup_time,''DD/MM/YYYY HH24:MI:SS''), to_char(round(sysdate-startup_time))||'' Days(s)'' from v$instance'
			$reader=$command.ExecuteReader()
			$reader.read() | out-null
			$StartupTime = $reader.GetString(0).PadRight(30)	   
			$UpTime 	 = $reader.GetString(1).PadRight(20)	   
			Write-host $1 @Header 	
			Write-Host "$($StartupTime) | $($UpTime)" 
			Write-Host ""
			$reader.close()								
			
			#-----------------				
			#ArchiveLog Mode
			$1 = "ArchiveLog Mode".PadRight(50)
			$command.CommandText = 'SELECT log_mode from v$database'
			$reader=$command.ExecuteReader()
			$reader.read() | out-null
			$ArchiveLogMode = $reader.GetString(0).PadRight(50)	   
			Write-host $1 @Header 	
			Write-Host "$($ArchiveLogMode)" 
			Write-Host ""
			$reader.close()								
			
			#-----------------				
			#Check Error (sysdate-1)
			$1 = "Error(s) (since 1 day)".PadRight(100)
			Write-host $1 @Header 			
			if ($versionNumber -eq "11"){				
				$command.CommandText = 'SELECT to_char(ORIGINATING_TIMESTAMP,''dd/mm/yyyy hh24:mi:ss'') date_id, message_text FROM X$DBGALERTEXT WHERE originating_timestamp > systimestamp - 1 AND regexp_like(message_text, ''(ORA-|error)'')'
				$reader=$command.ExecuteReader()
				$i=0
				while ($reader.read()) {
					$Date_err	 = $reader.GetString(0).PadRight(20)	   
					$Message_err = $reader.GetString(1).PadRight(130)												
					if ($Message_err.trim() -like "ORA-00600*" -or $Message_err.trim() -like "*Fatal*")
						{Write-Host "$($Date_err.trim()) | $($Message_err.trim())" @Bad}					
					else 
						{Write-Host "$($Date_err.trim()) | $($Message_err.trim())"@Problem}					
					
					Write-Host "-----------------------------------------------------------"
					$i = $i + 1	
				}	
				if ($i -eq 0) {Write-Host "No Error"@Good}		
				Write-Host ""
				$reader.close()			
			}
			else {
				Write-Host "check error manualy : Oracle Database version $versionNumber ([DBGALERTEXT] not supported)" @Bad
				Write-Host ""
			}		
			
			#Check database corruption			
			$1 = "Database corruption".PadRight(100)
			$command.CommandText = 'select FILE#, CORRUPTION_TYPE from V$DATABASE_BLOCK_CORRUPTION'
			$reader=$command.ExecuteReader()
			$i=0			
			Write-host $1 @Header 	
			while ($reader.read()) {
				$File = $reader.GetDecimal(0).ToString().PadRight(30)
				$CorruptionType	 = $reader.GetString(1).PadRight(10)	   
				Write-Host "$($File) | $($CorruptionType)" @Bad
				$i = $i + 1	
			}	
			if ($i -eq 0) {Write-Host "No Error"@Good}		
			Write-Host ""			
			$reader.close()
			
			#Check Space
			$1 = "Database Size".PadRight(20)
			$2 = "Used Space".PadRight(20)	
			$3 = "Free Space".PadRight(20)	
			$command.CommandText = 'select	round(sum(used.bytes) / 1024 / 1024 / 1024 ) || '' GB'' "Database Size"
			,	round(sum(used.bytes) / 1024 / 1024 / 1024 ) - 
				round(free.p / 1024 / 1024 / 1024) || '' GB'' "Used space"
			,	round(free.p / 1024 / 1024 / 1024) || '' GB'' "Free space"
			from    (select	bytes
				from	v$datafile
				union	all
				select	bytes
				from 	v$tempfile
				union 	all
				select 	bytes
				from 	v$log) used
			,	(select sum(bytes) as p
				from dba_free_space) free
			group by free.p'
			$reader = $command.ExecuteReader()
			Write-host $1 "|" $2 "|" $3 @Header 	
			while ($reader.read()) {
				$DatabaseSize=$reader.GetString(0).PadRight(20)	   
				$UsedSpace=$reader.GetString(1).PadRight(20)	      
				$FreeSpace=$reader.GetString(2).PadRight(20)	     		
				Write-Host "$($DatabaseSize) | $($UsedSpace) | $($FreeSpace)" 
			}
			Write-Host ""	
			$reader.close()
			
			#Check Tablespace Usage
			$1 = "Tablespace Name".PadRight(30)
			$2 = "Bytes used".PadRight(20)	
			$3 = "Bytes free".PadRight(20)	
			$4 = "Largest".PadRight(20)	
			$5 = "Percent used".PadRight(20)	
			$6 = "Autoextensible".PadRight(20)	
			$7 = "Increment by".PadRight(20)	
			$command.CommandText = 'select T1.TABLESPACE_NAME,
			round(T1.BYTES / 1024 / 1024 ) || '' MB'' as "bytes_used (Mb)",
			round(T2.BYTES /1024 / 1024 ) || '' MB''  as "bytes_free (Mb)",
			round(T2.largest /1024 /1024 ) || '' MB'' as "largest (Mb)",
			round(((T1.BYTES-T2.BYTES)/T1.BYTES)*100,2) || ''%'' percent_used,			
			T1.AUTOEXTENSIBLE,
			round((T3.BLOCK_SIZE*T1.INCREMENT_BY)/1024/1024,2) || '' MB'' as "increment_by (Mb)"
			from
			(
			select TABLESPACE_NAME, AUTOEXTENSIBLE,INCREMENT_BY,
			sum(BYTES) BYTES
			from dba_data_files
			group by TABLESPACE_NAME,AUTOEXTENSIBLE,INCREMENT_BY
			)
			T1,
			(
			select TABLESPACE_NAME,
			sum(BYTES) BYTES ,
			max(BYTES) largest
			from dba_free_space
			group by TABLESPACE_NAME
			)
			T2,
			(
			select TABLESPACE_NAME,BLOCK_SIZE
			from dba_tablespaces			
			)
			T3
			where T1.TABLESPACE_NAME=T2.TABLESPACE_NAME
			AND T1.TABLESPACE_NAME=T3.TABLESPACE_NAME
			AND T2.TABLESPACE_NAME=T3.TABLESPACE_NAME
			order by ((T1.BYTES-T2.BYTES)/T1.BYTES) desc'
			$reader = $command.ExecuteReader()
			Write-host $1 "|" $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $7  @Header 	
			while ($reader.read()) {	
				$TablespaceName=$reader.GetString(0).PadRight(30)   
				$UsedSpace=$reader.GetString(1).PadRight(20)  
				$FreeSpace=$reader.GetString(2).PadRight(20)   
				$Largest=$reader.GetString(3).PadRight(20)   
				$PercentUsed=$reader.GetString(4).PadRight(20)  
				$Autoextensible=$reader.GetString(5).PadRight(20) 
				$IncrementBy=$reader.GetString(6).PadRight(20) 
				Write-Host "$($TablespaceName) | $($UsedSpace) | $($FreeSpace) | $($Largest) | " -nonewline; 
				if ($Autoextensible.trim() -eq "YES") 
				{Write-Host "$($PercentUsed) | $($Autoextensible) | $($IncrementBy)" @Good}
				else 
				{Write-Host "$($PercentUsed) | $($Autoextensible) | $($IncrementBy)" @Bad}
			}
			Write-Host "" 
			$reader.close()
			
			#-----------------
			# SQL Database		
			if ($pMonitorDetail -eq $true) {
				foreach ($dbsql in $oraclemetadata.oracle.db) {
					$name = $dbsql.name
					[String] $SQL = $dbsql.sql										
					$command.CommandText = $SQL
					$reader = $command.ExecuteReader()							
					Write-Host $name @Title
					for ($i=0;$i -lt $reader.FieldCount;$i++) {
						$Result	= $Result + $reader.GetName($i).PadRight(30)  						
					}		
					Write-Host $Result  @Header
					
					$Result  = ""
					while($reader.read()) {
						$i = 0					
						while ($i -lt ($reader.FieldCount)) {									
							if (($reader.GetDataTypeName($i) -eq "NUMBER") -or ($reader.GetDataTypeName($i) -eq "DECIMAL"))
								{ $Result = $Result + $reader.GetDecimal($i).ToString().PadRight(30) }
							else 
								{ $Result = $Result + $reader.GetString($i).PadRight(30) }							
							$i = $i + 1							
						}
						Write-Host 	$Result	
						$Result = ""						
					}
					Write-Host "" 
					$reader.close()
				}
			}	
			#Close the connection				
			$conn.Close()
			$conn.dispose()
			write-host ""
			write-host "_________________________________________________________________________________________________________________________________________________"				
			write-host ""
		}				
	}	
	catch {		
		$err = $Error[0].Exception ; 
		write-host "Error : [$TNS] -- "  $err.Message  -ForegroundColor "red"
		write-host "_______________________________________________________________________________________________________________________________________"
		write-host ""
		continue ; 			
	}		
}
	
