#!/usr/bin/perl -w 

# 	   
#   DESCRIPTION 
#		Check backups jobs veeam.
#   NOTES 
#	Auteur  : Mohamed ACHBANI 
#	Date 	: 04-09-2015	
#   SYNTAXE
#		check_backup_veeam_by_job.pl -H <host> [-P <port>] [-d <database>] [-u <username>] [-p <password>] [-t <typeBackup>]
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
my $o_port="1433";
my $o_db="Veeambackup";
my $o_user="check_eon";
my $o_pw="";

my $o_target="A"; # Target backup (Disk, Tape or All)
my $state="";
my $jobName="";
my $result="";
my $targetType="";
my $countError=0;
my $countWarning=0;
my $countTotal=0;
my $countErrorDisk=0;
my $countErrorTape=0;
my $targetBackup1="";
my $targetBackup2="";
my $typeBackup1="";
my $typeBackup2="";

sub print_usage {
    print "\n";
    print "Usage: check_backup_veeam_by_job.pl -H <host> [-P <port>] [-d <database>] [-u <username>] [-p <password>] [-t <typeBackup>] \n";
    print "\n";    
}

sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions(
        'H:s'   => \$o_host,
        'P:s'   => \$o_port,
        'd:s'   => \$o_db,
        'u:s'   => \$o_user,
        'p:s'   => \$o_pw,
		't:s'   => \$o_target
        );
    if (!defined ($o_host) || !defined ($o_db) || !defined ($o_user) || !defined ($o_pw)) { print_usage(); exit $ERRORS{"UNKNOWN"}};
}


########## DEBUT #######

check_options();

my $exit_val;

# Connect to database
my $dbh = DBI->connect("dbi:Sybase:server=$o_host:$o_port","$o_user","$o_pw") or exit $ERRORS{"UNKNOWN"};

$dbh->do("use $o_db");

my $sth=$dbh->prepare( "SELECT 
	[BJobs].latest_result,
	[BJobs].name,
	[BJobs].target_type
	FROM 	
	[BJobs]	
	WHERE 
	[BJobs].is_deleted = 0
	and [BJobs].schedule_enabled = 1
	and [BJobs].target_type in (?,?)		
	and [BJobs].type in (?,?)	
	ORDER BY 
	[BJobs].latest_result,[BJobs].name;");

if ($o_target eq "A") {	
	$targetBackup1 = 0;$targetBackup2 = 4;
	$typeBackup1= 0;$typeBackup2 = 28;
	$sth->bind_param( 1, $targetBackup1 );
	$sth->bind_param( 2, $targetBackup2 );
	$sth->bind_param( 3, $typeBackup1 );
	$sth->bind_param( 4, $typeBackup2 );
} elsif ($o_target eq "D") {	
	$targetBackup1 = 0;$targetBackup2 = 0;
	$typeBackup1= 0;$typeBackup2= 0;	
	$sth->bind_param( 1, $targetBackup1 );
	$sth->bind_param( 2, $targetBackup2 );
	$sth->bind_param( 3, $typeBackup1 );
	$sth->bind_param( 4, $typeBackup2 );
} elsif ($o_target eq "T") {	
	$targetBackup1 = 4;$targetBackup2 = 4;
	$typeBackup1 = 28;$typeBackup2 = 28;
	$sth->bind_param( 1, $targetBackup1 );
	$sth->bind_param( 2, $targetBackup2 );
	$sth->bind_param( 3, $typeBackup1 );
	$sth->bind_param( 4, $typeBackup2 );
} else {	
	print "Backup VEEAM - Unknown backup type (A=All, D=Disk, T=Tape) \n";
	exit $ERRORS{"UNKNOWN"};
}	
	
$sth->execute;

# By Default status UNKNOWN
$exit_val = $ERRORS{"UNKNOWN"};
while (my @row = $sth->fetchrow_array) {
			$state		= $row["0"];        
			$jobName	= $row["1"];			
			$targetType = $row["2"];			

			$countTotal	= $countTotal + 1;			
						
			if ($state == -1) {				
				$result 	= $result . $jobName . " : Unknown\n";				
			}
			if ($state == 0) {				
				$result 	= $result . $jobName . " : Success\n";				
			}
			if ($state == 1) {
				$countWarning = $countWarning + 1;				
				$result 	= $result . $jobName . " : Warning\n";				
			}
			if ($state == 2) {
				if ($targetType == 0) {
					$countErrorDisk = $countErrorDisk + 1;
				}
				if ($targetType == 4) {
					$countErrorTape = $countErrorTape + 1;
				}
				$countError	= $countError + 1;
				$result 	= $result . $jobName . " : Failed\n";
			}			
}
	
$exit_val=$ERRORS{"OK"} if ( $state == 0 or $state == 1 );
$exit_val=$ERRORS{"CRITICAL"} if ( $state == 2 );

if ($o_target eq "A") {	
	print "All Backup VEEAM - $countErrorDisk job erreur (Backup Disk) - $countErrorTape job erreur (Backup Tape) - $countWarning job warning - Total job  (scheduled): $countTotal \n";
} elsif  ($o_target eq "D") {
	print "Disk Backup VEEAM - $countErrorDisk job erreur (Backup Disk) - $countWarning job warning - Total job  (scheduled): $countTotal \n";
} elsif  ($o_target eq "T"){
	print "Tape Backup VEEAM - $countErrorTape job erreur (Backup Tape) - $countWarning job warning - Total job  (scheduled): $countTotal \n";
} else {
	print "Backup VEEAM - Unknown backup type \n";
}	

print "Job Name status :  \n" ;
print "$result";

# Close the database
$dbh->disconnect;

exit $exit_val;

