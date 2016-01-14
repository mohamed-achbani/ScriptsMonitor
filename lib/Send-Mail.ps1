# SYNOPSIS 
#      Send mail
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
# 	   Date : 19-11-2014	
######### 

function Send-Mail
{
    param (
		[String]$smtpserver,
        [String]$FromAddress,
		[String]$ToAddress,
		[String]$Subject,
		[String]$Body,
		[String]$Attachment
    )
	
	$smtp = new-object Net.Mail.SmtpClient($smtpserver) 
	$message = new-object System.Net.Mail.MailMessage  $FromAddress, $ToAddress
	
	$Today = ((Get-Date).dateTime).tostring()	
	$message.IsBodyHtml = $True 		
	if ($Subject -ne $null) { $message.Subject = "$Subject - $Today"}	
	if ($Attachment -ne "") { $message.Attachments.Add($Attachment) }	
	if ($Body -ne $null) { $message.Body = $Body }	
	
	$smtp.Send($message) 
}