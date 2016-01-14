# SYNOPSIS 
#      SQL Execute statement
#      Works with SQL Server 2005 and higher version.
# NOTES 
#      Author  : Mohamed ACHBANI 
#      Requires: PowerShell, SMO assembly 
#	   Date	   : 14-01-2016
######### 

function SqlExec( $Server, $Database, $Query, $IntegratedSecurity = $true, $Uid = $null , $Pwd = $null){ 

	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection 

	if ($IntegratedSecurity -eq $true) { 
		$SqlConnection.ConnectionString = "Server = $Server; Database = $Database; Integrated Security = $IntegratedSecurity" 
	} 
	else {
		$SqlConnection.ConnectionString = "Server = $Server; Database = $Database; Integrated Security = $IntegratedSecurity; UID = $Uid; Password = $Pwd"
	}	

	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = $Query
	$SqlCmd.Connection = $SqlConnection

	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter 
	$SqlAdapter.SelectCommand = $SqlCmd

	$DataSet = New-Object System.Data.DataSet
	$SqlAdapter.Fill($DataSet)
	$SqlAdapter | Out-Null

	$SqlConnection.Close() 

	return $DataSet.Tables[0]

}