COLUMN first_change# FORMAT 99999999  HEADING Change#
COLUMN group#        FORMAT 9,999     HEADING Grp#
COLUMN thread#       FORMAT 999       HEADING Th#
COLUMN sequence#     FORMAT 999,999   HEADING Seq#
COLUMN members       FORMAT 999       HEADING Mem
COLUMN archived      FORMAT a4        HEADING Arc?
COLUMN first_time    FORMAT a21       HEADING 'Switch|Time'
BREAK ON thread#
SET PAGES 60 LINES 131 FEEDBACK OFF
START title132 'Current Redo Log Status'
SPOOL &&db\_log_stat
SELECT thread#,group#,sequence#,bytes,
       members,archived,
       status,first_change#,
       TO_CHAR(first_time, 'DD-MM-YYYY HH24:MI:SS') first_time
  FROM sys.v_$log
  ORDER BY
       thread#,
       group#;
SPOOL OFF
SET PAGES 22 LINES 80 FEEDBACK ON
CLEAR BREAKS
CLEAR COLUMNS
TTILE OFF
