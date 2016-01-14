#!/bin/sh
###########################################################################
# Script Name :   duplicatedatabase
# Author      :   ACHBANI Mohamed 
# Date        :   23-06-2012
# Version     :   1.1
# Use         :   To duplicates TARGET database using 'ACTIVE' feature.
###########################################################################

DATE_STAMP=`date '+%Y%m%d'`
TIME_STAMP=`date '+%H%M'`
DATE_START=`date`
NOW=$DATE_STAMP.$TIME_STAMP
thin_line="------------------------------------------------------------------------"
blank_line="                                                                         "
SCRIPTNAME=`basename $0`

###########################################################################
# Parameters 
###########################################################################

echo "SID de la cible (orcl): "
read TARGET_SID
echo "TNS de la cible (ORCL): "
read TARGET_TNS
echo "SID du clone : "
read ORACLE_SID
echo "TNS du clone : "
read AUXILIARY_TNS
echo "Password SYS de la cible : "
read target_syspwd
echo "Password SYS du clone : "
read auxiliary_syspwd
echo "Clone archivelog mode N/Y (N) : "
read ARCHIVELOG
echo "Adresse mail : "
read EMAIL_ADDRESS

if [ "$ARCHIVELOG" = "" ]; then
   ARCHIVELOG=N           
fi
if [ "$TARGET_SID" = "" ]; then
   TARGET_SID=orcl
fi
if [ "$TARGET_TNS" = "" ]; then
   TARGET_TNS=ORCL
fi

echo ${thin_line} 
echo " Duplicate target database with this parameters "
echo ${thin_line} 
echo "SID de la cible (orcl) : " ${TARGET_SID} 
echo "TNS de la cible (ORCL) : " ${TARGET_TNS} 
echo "SID du clone : " ${ORACLE_SID} 
echo "TNS du clone : " ${AUXILIARY_TNS} 
echo "Clone archivelog mode N/Y (N) : "${ARCHIVELOG} 
echo "Adresse mail : " ${EMAIL_ADDRESS} 
echo ${thin_line} 
echo ${blank_line}                                                                      

###########################################################################
# Variable d'environnement			  			  
###########################################################################

ORACLE_BASE="/u01/app/oracle"
ORACLE_HOME="/u01/app/oracle/product/11.2.0/db1"
LD_LIBRARY_PATH="$ORACLE_HOME/lib"
export ORACLE_BASE ORACLE_HOME LD_LIBRARY_PATH ORACLE_SID

PFILE=${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora
LOG_BACKUP=$SCRIPTNAME.$ORACLE_SID.$NOW.log
_connect="sys/${target_syspwd}@${TARGET_TNS} auxiliary sys/${auxiliary_syspwd}@${AUXILIARY_TNS}"

###########################################################################
# Duplication de base avec RMAN
###########################################################################

echo ${thin_line}                                  
echo "        Connecting to AUXILIARY database ${ORACLE_SID} to shutdown"               
echo ${thin_line}                                                                       
$ORACLE_HOME/bin/sqlplus "/ as sysdba" << SQLPLUS_SESSION
shutdown abort
exit
SQLPLUS_SESSION
echo ${blank_line}                                                                      

echo ${thin_line}                                                                       
echo "        Connecting to AUXILIARY database ${ORACLE_SID} to startup nomount"        
echo ${thin_line}                                                                       
$ORACLE_HOME/bin/sqlplus "/ as sysdba" << SQLPLUS_SESSION
startup force nomount pfile='${PFILE}';
exit
SQLPLUS_SESSION
echo ${blank_line}                                                                      

echo ${thin_line}                                                                       
echo "        Duplicating database ${TARGET_SID} to ${ORACLE_SID}"                      
echo ${thin_line}                                                                       
${ORACLE_HOME}/bin/rman target ${_connect} log=${LOG_BACKUP} << RMAN_SESSION
duplicate target database to ${ORACLE_SID} from active database;
exit
RMAN_SESSION

if [ "$ARCHIVELOG" = "N" ]; then
	echo ${thin_line}                                  
	echo "        Connecting to AUXILIARY database ${ORACLE_SID} to open with noarchivelog"               
	echo ${thin_line}                                                                       
	$ORACLE_HOME/bin/sqlplus "/ as sysdba" << SQLPLUS_SESSION
	shutdown immediate
	startup mount;
	alter database noarchivelog;
	alter database open;
	exit
	SQLPLUS_SESSION
	echo ${blank_line}                                                                      
fi

ERROR_DUPLICATE=N
grep -i ERROR $LOG_BACKUP && ERROR_DUPLICATE="Y"
if [ "$ERROR_DUPLICATE" = "Y" ]; then
	echo "RMAN - ERROR while cloning."                                                      
	echo "Target database: ${TARGET_SID} -- Auxiliary database: ${ORACLE_SID}"              
	MESSAGE="RMAN - Database cloning unsuccessful - $ORACLE_SID."
else
	echo "RMAN - Database duplicated/cloned successfully."                                  
	echo "Target database: ${TARGET_SID} -- Auxiliary database: ${ORACLE_SID}"              
	MESSAGE="RMAN - Database cloning successful - $ORACLE_SID."
fi

echo ${blank_line}                                                                      
DATE_END=`date`
echo ${thin_line}                                                                       
echo "        Start Time: $DATE_START"                                                  
echo "        End Time: $DATE_END"                                                      
echo ${thin_line}                                                                       
echo ${blank_line}                                                                      

if [ "$EMAIL_ADDRESS" != "" ]; then
	mail -s "$MESSAGE"  $EMAIL_ADDRESS < ${LOG_BACKUP}
fi