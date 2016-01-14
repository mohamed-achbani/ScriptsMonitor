# SYNOPSIS 
#      Modify date file (CreationTime, LastAccessTime, LastWriteTime)
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell
#	   Date	   : 14-01-2016
######### 

Param (
		[Parameter(mandatory=$true)]
		[string]$Path,
		[array]$includeFile = @("*.log","*.txt")
	)
  
Function Set-FileTimeStamps
{
 Param (
    [Parameter(mandatory=$true)]
    [system.io.fileinfo]$file, 
    [datetime]$date = (Get-Date)
	)
	
    Get-ChildItem -Path $file | ForEach-Object 	{
		$_.CreationTime 	= $date
		$_.LastAccessTime 	= $date
		$_.LastWriteTime 	= $date 
	}
} 

if (Test-Path $Path ) {
	# Setting new date on file selected.
	$files = Get-childitem -path $Path -Recurse -Include $includeFile
	Foreach($file in $files) 
	 { 
	  Try 
		{  
		    Set-FileTimeStamps -file $file
		} 
		Catch [System.Exception] 
		{
			"Error when setting date for $file"
		} 		
	 }
}
