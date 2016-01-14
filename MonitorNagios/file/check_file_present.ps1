# 	   
#   DESCRIPTION 
#		Check check_file_present.ps1
#   NOTES 
#		Auteur  : Mohamed ACHBANI 
	#	Date 	: 05-01-2016
#   SYNTAXE
#		check_file_present -file [fileName] -days [days] -sizeKo [sizeKo]
#	 	return : ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3);  
######### 

Param(
  [string]$file,
  [int]$days = 1,
  [decimal]$sizeKo = 1  
)

[decimal] $sizeFileAsKo = 0
[decimal] $sizeFileAsMb = 0
[String] $msg = ""
[String] $msgStatus	= ""
[String] $perfdata = ""

# By default return status 'UNKNOWN'
$status = 3
$fileName 	= $file;
$Now 		= Get-Date
$date 		= $Now.AddDays(-$days)	


if (Test-Path $fileName ) {
	$present = $true;
}
else {
	$present = $false;
}

if ($present) {	
	$fileDesc 		= Get-ChildItem $fileName;
	$sizeFileAsKo 	= [math]::Round(($fileDesc.Length/1024));
	$sizeFileAsMb	= [math]::Round(($fileDesc.Length/1024/1024));
	$dateFile 		= $fileDesc.LastWriteTime;	
	$dateCreationFile = $fileDesc.CreationTime;	
	$dateFileAsString = ($fileDesc.LastWriteTime).ToString('dd/MM/yyyy HH:mm:ss');	
	
	# Difference before LastWriteTime and CreationTime.
	$TimeDiff = New-TimeSpan  $dateCreationFile $dateFile
	$TimeDiffSeconds = [math]::Round($TimeDiff.TotalSeconds)
	
	$msgStatus	= "OK: "
	$msg 		= "$fileName exist with size $sizeFileAsKo Ko ($sizeFileAsMb Mb) and date $dateFileAsString"	
	$perfdata	= "'Time in seconds'=$TimeDiffSeconds"
	$status 	= 0
		
	if ($sizeFileAsKo -le $sizeKo) {
		$msgStatus = "WARNING for size file: "
		$status = 1	
	}	
	    
	if ($dateFile -lt $date) {		
		$msgStatus = "WARNING for date file: "
		$status = 1
	}
	
	if (($dateFile -lt $date) -and ($sizeFileAsKo -le $sizeKo)) {
		$msgStatus = "WARNING for size and date file: "
		$status = 1
	}
	
	
} else {
	$msgStatus = "CRITICAL: "
	$msg = "$fileName not exist"
	$status = 2
}

Write-Host "$msgStatus $msg | $perfdata";
exit $status;


# TODO Return time (time created - timemodified)