#!/usr/bin/perl -w 

# 	   
#   DESCRIPTION 
#		Check the backup veeam status by VM.
#   NOTES 
#	Auteur  : Mohamed ACHBANI 
#	Date 	: 11-01-2016	
#   SYNTAXE
#		check_backup_veeam_by_object.pl -H <host> -S <Server> [-P <port>] [-d <database>] [-u <username>] [-p <password>]
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
my $o_server;
my $o_port="1433";
my $o_db="Veeambackup";
my $o_user="check_eon";
my $o_pw="";

my $state=-1;
my $objectName="";
my $creationTimeBackup="";
my $endTimeBackup="";
my $durationAsSeconds=0;
my $totalSizeGo=0;
my $result="";
my $perfdata="";

sub print_usage {
    print "\n";
    print "Usage: check_backup_veeam_by_object.pl -H <host> -S <Server> [-P <port>] [-d <database>] [-u <username>] [-p <password>] \n";
    print "\n";    
}

sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions(
        'H:s'   => \$o_host,
		'S:s'   => \$o_server,
        'P:s'   => \$o_port,
        'd:s'   => \$o_db,
        'u:s'   => \$o_user,
        'p:s'   => \$o_pw		
        );
    if (!defined ($o_host) || !defined ($o_server)) { print_usage(); exit $ERRORS{"UNKNOWN"}};
}


sub convert_time {
  my $time = shift;
  my $days = int($time / 86400);
  $time -= ($days * 86400);
  my $hours = int($time / 3600);
  $time -= ($hours * 3600);
  my $minutes = int($time / 60);
  my $seconds = $time % 60;

  $days = $days < 1 ? '' : $days .' days, ';
  $hours = $hours < 1 ? '' : $hours .' hours ';
  $minutes = $minutes < 1 ? '' :  $minutes . ' minutes ';
  $seconds = $seconds < 1 ? '' :  $seconds . ' seconds ';
  $time = $days . $hours . $minutes . $seconds ;
  return $time;
}


########## DEBUT #######

check_options();

my $exit_val;

# Connect to database
my $dbh = DBI->connect("dbi:Sybase:server=$o_server:$o_port","$o_user","$o_pw") or exit $ERRORS{"UNKNOWN"};

$dbh->do("use $o_db");

my $sth=$dbh->prepare( "SELECT
			tasks.status statusAsCode,-- 0=ok;2=critical;3=warning;others=unknow
			tasks.object_name as Vm,
			tasks.creation_time as creation_time_backup, 
			CASE tasks.end_time
				WHEN '1900-01-01 00:00:00.000' THEN getdate()
				ELSE tasks.end_time
			END	as end_time_backup, 
			CASE tasks.end_time
				WHEN '1900-01-01 00:00:00.000' THEN DATEDIFF(second, tasks.creation_time, getdate())
				ELSE DATEDIFF(second, tasks.creation_time, tasks.end_time) 
			END as durationAsSeconds,	
			tasks.total_size/1024/1024/1024 as total_size_go
			FROM [Backup.Model.BackupTaskSessions] as tasks
			WHERE tasks.object_name=?			
			AND tasks.creation_time = (
				SELECT max([Backup.Model.BackupTaskSessions].creation_time) 
				FROM [Backup.Model.BackupTaskSessions] 
				WHERE tasks.object_name=[Backup.Model.BackupTaskSessions].object_name
				);"
		);
	
$sth->bind_param( 1, $o_host );
$sth->execute;

# By Default status UNKNOWN
$exit_val = $ERRORS{"UNKNOWN"};
while (my @row = $sth->fetchrow_array) {
			$state					= $row["0"];        
			$objectName				= $row["1"];			
			$creationTimeBackup		= $row["2"];
			$endTimeBackup			= $row["3"];			
			$durationAsSeconds		= $row["4"];
			$totalSizeGo			= $row["5"];	
							
			if ($state == 0) {				
				$result 	= $objectName . " status : Success finished at ". $endTimeBackup . " duration " . convert_time($durationAsSeconds);
			}	
			elsif ($state == 2) {
				$result 	= $objectName . " status : Failed finished at ". $endTimeBackup . " duration " . convert_time($durationAsSeconds);
			}	
			elsif ($state == 3) {
				$result 	= $objectName . " status : Warning finished at ". $endTimeBackup . " duration " . convert_time($durationAsSeconds);
			}				
			else {
				$result 	= $objectName . " status : Unknown finished at ". $endTimeBackup . " duration " . convert_time($durationAsSeconds);
			}			
			$perfdata = "'total_size_go'=$totalSizeGo"
					
}

# Return OK if a VM is not present in Veeam backup.
if ($state == -1) {	
	$result 	= $o_host . " : not backuped";	
	$perfdata = "'total_size_go'=$totalSizeGo";	
}	

$exit_val=$ERRORS{"OK"} if ( $state == 0 or $state == -1 );
$exit_val=$ERRORS{"WARNING"} if ( $state == 3);
$exit_val=$ERRORS{"CRITICAL"} if ( $state == 2 );
$exit_val=$ERRORS{"UNKNOWN"} if ( $state > 3 );

print "$result";
print "| $perfdata\n";

# Close the database
$dbh->disconnect;

exit $exit_val;

