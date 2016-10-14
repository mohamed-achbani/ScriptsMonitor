#
# SYNOPSIS 
#      Remove IIS logfile 
#   DESCRIPTION 
#      Module: Powershell script to clean IIS log files
#    NOTES 
#      Author   : Mohamed ACHBANI 
#	   Date 	: 03-10-2016	
#   SYNTAXE
#	  Remove-IISFiles -RetentionDay 80
# 	  return : ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2);  
#

param (
	[int]$RetentionDay = 80
)

	###############################################################################
	## Global variables
	###############################################################################
	$Script:StartingTime = (Get-Date)

	$Script:ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
	$Script:ScriptName = "Remove-IISFiles"

	$Script:logDirectory = $ScriptPath.TrimEnd('\')
	$Script:logFileName  = $logDirectory + "\$($ScriptName).log"

	###############################################################################
	## Global functions
	###############################################################################
	
	Function Write-Log
	{
		param (
		[string]$Message = [string]::Empty,
		[ConsoleColor]$Color = [ConsoleColor]::White,
		[switch]$NoConsoleOutput,
		[switch]$NoLogOutput,
		[switch]$NewLine
		)
		
		$local:currentDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

		if([string]::IsNullOrEmpty($Message))
		{
			if (!$NoConsoleOutput) {
				Write-Host
			}
			if (!$NoLogOutput) {
				Add-Content $Script:logFilename -Value ("$local:currentDate --")	
			}
		}
		else
		{
			if (!$NoConsoleOutput) {
				Write-Host $($Message) -Foreground $Color
			}
			if (!$NoLogOutput) {
				Add-Content $Script:logFilename -Value $("$local:currentDate --`t$Message")
			}
		}
		
		if($NewLine) {
			if (!$NoConsoleOutput) {
				Write-Host
			}
			if (!$NoLogOutput) {
				Add-Content $Script:logFilename -Value ("")	
			}
		}
	}

	Function Open-Log
	{
		Write-Log -Message ("") -NoConsoleOutput
		clear-Content $Script:logFilename
		Write-Log -Message ("START Script **************************************************************") -NoConsoleOutput -NewLine
	}

	Function Close-Log
	{
		Write-Log -Message ("END Script ****************************************************************") -NoConsoleOutput  -NewLine
		Write-Log -Message ("`nOutput saved in log file $($logFilename)") -Color Gray -NoLogOutput
	}


	function CleanTempLogfiles ()
	{	
	
	param ($FilePath, $days )
			
		Foreach ($File in Get-ChildItem -Path $FilePath *.log -Recurse)		
		{
			if (!$File.PSIsContainerCopy) 
			{
				if ($File.LastWriteTime -lt ($(Get-Date).Adddays(-$days))) 
				{
					remove-item -path "$($File.fullname)" -force -Recurse
					Write-Log -Message "Removed logfile: $($File.fullname)" -Newline				
				}
			}
		} 
	}	

	
	Function Start-Script
	{
		Open-Log
	}

	Function End-Script
	{
		Close-Log
	}
	
	Function Exit-Script
	{
		param (
			[int]$ExitCode = 0,
			[string]$ExitMessage = [string]::Empty,
			[bool]$ConsoleOutputOnly = $false
		)
	
    if(![String]::IsNullOrEmpty($ExitMessage)) {
	    if($ExitCode -eq 0) {
		    # OK exit
		    if($ConsoleOutputOnly) {
			    Write-Log -Message ($ExitMessage) -Color Green -NoLogOutput -NewLine
		    }
		    else {
			    Write-Log -Message ($ExitMessage) -Color Green -NewLine
		    }
	    }
	    elseif ($ExitCode -eq 1) {
		    #WARNING exit
		    if($ConsoleOutputOnly) {
			    Write-Log -Message ($ExitMessage) -Color Yellow -NoLogOutput -NewLine
		    }
		    else {
			    Write-Log -Message ($ExitMessage) -Color Yellow -NewLine
		    }
	    }
		elseif ($ExitCode -eq 2) {
		    #CRITICAL exit
		    if($ConsoleOutputOnly) {
			    Write-Log -Message ($ExitMessage) -Color Yellow -NoLogOutput -NewLine
		    }
		    else {
			    Write-Log -Message ($ExitMessage) -Color Yellow -NewLine
		    }
	    }
	    else{
		    #UNKNOWN exit
		    if($ConsoleOutputOnly) {
			    Write-Log -Message ($ExitMessage) -Color Red -NoLogOutput -NewLine
		    }
		    else {
			    Write-Log -Message ($ExitMessage) -Color Red -NewLine
		    }
	    }
    }
	
    $local:EndingTime = (Get-Date)
    $local:elapsedTime = $(($EndingTime-$StartingTime).totalseconds)
    if($ConsoleOutputOnly) {
		Write-Log -Message ("Script duration: $elapsedTime seconds") -NoLogOutput
	}
	else {
		Write-Log -Message ("Script duration: $elapsedTime seconds")
	}

	if(!$ConsoleOutputOnly) { Close-Log }
	
	$Error.Clear()
	exit ($ExitCode)
}
	
	
	########################################################################

	Start-Script

	Write-Log -Message "Loading WebAdministration shell module..." -NewLine
	try
	{
		Set-Executionpolicy RemoteSigned	
		Import-Module WebAdministration
	}
	catch
	{
		Write-Log -Message "...Failed!" -Color Red -NewLine
		Exit-Script -ExitCode 2 -ExitMessage "Error when loading WebAdministration shell module.`n"
	}
	Write-Log -Message "...Done" -Color Green -Newline
		
	Write-Log -Message "Removing IIS-logs keeping last $RetentionDay days"-Newline
	foreach($WebSite in $(get-website))  {    

		$logFile="$($Website.logFile.directory)".replace("%SystemDrive%",$env:SystemDrive)

		Write-Log -Message "$($WebSite.name) [$logfile]" -Newline		
		
		if (Test-Path -Path ($logFile)) {		
			CleanTempLogfiles -FilePath $logFile -days $RetentionDay
		}			
	}  

	Exit-Script