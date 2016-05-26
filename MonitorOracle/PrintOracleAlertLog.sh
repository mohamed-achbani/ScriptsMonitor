#!/usr/bin/ksh
# DESCRIPTION: THIS TOOL ALLOWS YOU TO FIND ORA ON ALERT LOG
##############################################################




if [ $# -lt 1 ] ; then
echo "Missing arguments"
echo "$0 [ERROR] [NUMBER OF LINES TO PRINT => FACULTATIF]"
echo "print_error.ksh ORA-00600"
echo "to see each db restart: $0 [start|stop] "
return 1 ; fi

# FIND BDUMP DIRECTORY
sqlplus -s "/ as sysdba" > /tmp/file.lst << !
set head off
select value from v\$parameter where name = 'background_dump_dest' ;
!
export DIR=$(cat /tmp/file.lst)

# TEST ORACLE_SID
if [[ -n $ORACLE_SID ]] ; then echo "" >> /dev/null ; else print "Thanks to set the ORACLE_SID \n"; exit 1 ; fi

export ALERTLOG=$DIR/alert_${ORACLE_SID}.log
#export ALERTLOG=$1
export ERROR=$1

echo "************************************************************************"
echo "*                                                                      *"
printf "* %-50s    %s   *\n" "CHECK $ERROR" "on $ORACLE_SID "
echo "*                                                                      *"
echo "************************************************************************"

if [[ $ERROR = "start" ]] ; then export ERROR="normal" ; export LINE=1 ; fi
if [[ $ERROR = "stop" ]] ; then export ERROR="Shutting down instance (" ; export LINE=1 ; fi

# PARAMETER 2 FACULTATIF
if [[ -n $2 ]] ;
then
        export LINE=$2
else
        # SET DEFAULT NUMBER OF LINE FOR THE FOLLOWING ERROR
        if [[ $ERROR = "ORA-" ]] ; then LINE=0 ; fi
        if [[ $ERROR = "ORA-00060" || $ERROR = "ORA-3136" ]] ; then LINE=1 ; fi
        if [[ $ERROR = "ORA-00600" || $ERROR = "ORA-07445" ]] ; then LINE=2 ; fi
        if [[ $ERROR = "ORA-01555" ]] ; then LINE=3 ; fi
        if [[ $ERROR = "ORA-03113" ]] ; then LINE=4 ; fi
fi

cat $ALERTLOG | \
gawk -v "E=$ERROR" -v "Z=$LINE" '{TT[NR]=$0} END{for(i=1;i<=NR; i++) \
{ if ( index(TT[i],E) != 0 ) { for (j=Z ; j>=0 ; j--) {print TT[i-j]} printf ("\n") }}}'

# DELETE TEMPORARY FILE
rm /tmp/file.lst

#END