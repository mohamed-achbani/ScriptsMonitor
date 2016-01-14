#!/usr/bin/perl -w 

# 	   
# DESCRIPTION 
#	Check MSSQL jobs status.
# NOTES 
#	Auteur  : Mohamed ACHBANI 
#	Date 	: 05-01-2016	
# SYNTAXE
#	check_mssql_jobs.pl -H <host> [-P <port>] [-d <database>] [-u <username>] [-p <password>]
#	   
######### 

use strict;
use Getopt::Long;
use DBI;

# Nagios specific
use lib "/srv/eyesofnetwork/nagios/plugins";
use utils qw(%ERRORS $TIMEOUT);
#my $TIMEOUT = 15;
#my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

my $o_host;
# Default port SQL Server
my $o_port = "1433";
my $o_db ="msdb";
my $o_user="check_eon";
my $o_pw="";

my $jobState = "";
my $jobName = "";
my $runTime = "";
my $jobStatus = "";
my $result = "";

my $countOk = 0;
my $countError = 0;
my $countTotal = 0;

sub print_usage {
    print "\n";
    print "Usage: check_mssql_jobs.pl -H <host> [-P <port>] [-d <database>] [-u <username>] [-p <password>] \n";
    print "\n";    
}

sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions(
        'H:s'   => \$o_host,
        'P:s'   => \$o_port,
        'd:s'   => \$o_db,
        'u:s'   => \$o_user,
        'p:s'   => \$o_pw		
        );
    if (!defined ($o_host) || !defined ($o_db) || !defined ($o_user) || !defined ($o_pw)) { print_usage(); exit $ERRORS{"UNKNOWN"}};
}


########## DEBUT #######

check_options();

my $exit_val;

# Connect to database
my $dbh = DBI->connect("dbi:Sybase:server=$o_host:$o_port","$o_user","$o_pw") or exit $ERRORS{"UNKNOWN"};

$dbh->do("use $o_db");

my $sth=$dbh->prepare( ";WITH CTE_MostRecentJobRun AS  
 (  
 SELECT job_id,run_status,run_date,run_time  
 ,RANK() OVER (PARTITION BY job_id ORDER BY run_date DESC,run_time DESC) AS Rnk  
 FROM sysjobhistory  
 WHERE step_id=0  
 )  
SELECT 
  run_status   
  ,name  AS [Job Name]
  ,CONVERT(VARCHAR,DATEADD(S,(run_time/10000)*60*60 /* hours */  
  +((run_time - (run_time/10000) * 10000)/100) * 60 /* mins */  
  + (run_time - (run_time/100) * 100)  /* secs */,  
  CONVERT(DATETIME,RTRIM(run_date),113)),100) AS [Time Run] 
 ,CASE WHEN enabled=1 THEN 'Enabled'  
     ELSE 'Disabled'  
  END [Job Status]  
FROM     CTE_MostRecentJobRun MRJR  
JOIN     sysjobs SJ  
ON       MRJR.job_id=sj.job_id  
WHERE    Rnk = 1  
ORDER BY run_status desc ,name;");
	
$sth->execute;

# By Default status UNKNOWN
$exit_val = $ERRORS{"UNKNOWN"};
while (my @row = $sth->fetchrow_array) {
	
			$jobState	= $row["0"];        
			$jobName	= $row["1"];			
			$runTime 	= $row["2"];			
			$jobStatus	= $row["3"];			
			if ($jobState == 1) {				
				$result 	= $result . $jobName . " : Success" . " ; Time : " . $runTime . " ; Status : " . $jobStatus ."\n";				
				$countOk	= $countOk + 1;
			}			
			if ($jobState == 0) {			
				$countError	= $countError + 1;
				$result 	= $result . $jobName . " : Failed" . "  ; Time : " . $runTime . " ; Status : " . $jobStatus ."\n";				
			}
			$countTotal	= $countTotal + 1;
}
	
$exit_val=$ERRORS{"OK"} if ( $jobState == 1);
$exit_val=$ERRORS{"CRITICAL"} if ( $jobState == 0 );

print "$countOk / $countTotal  SQL Server jobs ran succesfully.\n" ;
print "$result\n";
print "| 'Total Jobs'=$countTotal, 'OK Jobs'=$countOk, 'Failed Jobs'=$countError"

# Close the database
$dbh->disconnect;

exit $exit_val;

