# 	   
#   DESCRIPTION 
#		Check tnsping.
#   NOTES 
#	Auteur  : Mohamed ACHBANI 
#	Date 	: 16-09-2015	
#   SYNTAXE
#		check_tnsping -targetHostname [targetHostname] -serviceName [serviceName] -retry [retry]  
#	 	return : ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3);  
######### 
Param(
  [string]$targetHostname = "",
  [string]$serviceName = "",  
  [Int]$retry = 5
)

#  by default return status 'UNKNOWN'
$status = 3

if ($serviceName -eq "" -or $targetHostname -eq "") 
	{
		write-Host "Parameter not found"
	} 
else 
	{	
		#ping target hostname
		$status=get-wmiobject win32_pingstatus -Filter "Address='$targetHostname'" | Select-Object statuscode

		if($status.statuscode -eq 0)
			{
				$tnsping = "tnsping"
				$resultat = & $tnsping $serviceName $retry
				if ($resultat -match "OK"){
					write-Host "Server name $targetHostname is REACHABLE - Oracle service $serviceName is OK"
					$i = 1
					while ($i -le $retry)
						{
							write-Host $resultat[10+$i] 				
							$i++
						} 						
					$status = 0	
				} 
				else {
					write-Host "Oracle service $serviceName is CRITICAL"					
					$status = 2	
				}		
			}
		else
			{
				write-Host "Server name $targetHostname is NOT REACHABLE"
			}
	}		
	
exit $status


