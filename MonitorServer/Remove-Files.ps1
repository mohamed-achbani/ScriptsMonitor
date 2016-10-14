#
# SYNOPSIS 
#      Remove file 
#   DESCRIPTION 
#      Module: Powershell script to clean files
#    NOTES 
#      Author   : Mohamed ACHBANI 
#	   Date 	: 07-10-2016	
#   SYNTAXE
#	  Remove-Files -FilesArray "c:\test\;*.log;1","c:\temp\;*.txt;2"
# 	  return : ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2);  
#

param (
	[String[]]$FilesArray = $null	
)

	###############################################################################
	## Global variables
	###############################################################################
	$Script:StartingTime = (Get-Date)

	$Script:ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
	$Script:ScriptName = "Remove-Files"

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
	
	param ($FilePath, $Extention, $days )
		
		Foreach ($File in Get-ChildItem -Path $FilePath $Extention )		
		{
			if (!$File.PSIsContainerCopy) 
			{
				if ($File.LastWriteTime -lt ($(Get-Date).Adddays(-$days))) 
				{
					remove-item -path "$($File.fullname)" -force
					Write-Log -Message "Removed file: $($File.fullname)" -Newline				
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
		
	
	ForEach ( $FileArray in $FilesArray ) 
	{
		
		$FileDir 	=  ($FileArray -split ";")[0].substring(0)
		$Extention 	=  ($FileArray -split ";")[1].substring(0)
		$Retention 	=  ($FileArray -split ";")[2].substring(0)			
		
		Write-Log -Message "Removing File [$FileDir]  with extention [$Extention] keeping last [$Retention] days"-Newline			
		if ( Test-Path -Path ($FileDir) ) {		
			CleanTempLogfiles -FilePath $FileDir -Extention $Extention -Days $Retention
		} else {
			Write-Log -Message "Errors : [$FileDir] not found" -Newline	-Color red
		}
	}
	Exit-Script