<# SYNOPSIS 
      Monitor server session
   DESCRIPTION 
      Monitor server session and send mail to administrator
   NOTES 
      Author : Mohamed ACHBANI 
	  Date   : 26-09-2016
   SYNTAXE
	  .\MonitorServerSession.ps1
#> 

#clear screan
cls

$today = (get-date).ToString('G')

$subject = "ACTIVE SERVER SESSIONS REPORT - " + $today 
$priority = "Normal" 
$smtpServer = "serverSmtp" 
$emailFrom = "name@domaine.fr" 
$emailTo = "name@domaine.fr" 
 
$SessionList = "ACTIVE SERVER SESSIONS REPORT - " + $today + "`n`n" 
 

# List servers name
$servers = @(Import-Csv ".\servers.csv")

ForEach ($Server in $Servers) { 
    $ServerName = $Server.Name 	 
	if ($ServerName -ne $NULL) {
		$queryResults = (qwinsta /server:$ServerName | foreach { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv)  
		ForEach ($queryResult in $queryResults) { 				
			$RDPUser = $queryResult.UTILISATEUR 
			$sessionType = $queryResult.SESSION 			
			 If (($RDPUser -match "[a-z]") -and ($RDPUser -ne $NULL) -and ($sessionType -like 'rdp*')) {  					 
				$SessionList = $SessionList + "`n`n" + "[" + $ServerName + "] logged in by <" + $RDPUser + "> on <" + $sessionType +">"
			} 
		} 
	}	
} 
 
Send-MailMessage -To $emailTo -Subject $subject -Body $SessionList -SmtpServer $smtpServer -From $emailFrom -Priority $priority 

$SessionList 
 