COLUMN thread#             FORMAT 999      HEADING 'Thrd#'
COLUMN sequence#           FORMAT 99999    HEADING 'Seq#'
COLUMN first_change#                       HEADING 'SCN Low#'
COLUMN next_change#                        HEADING 'SCN High#'
COLUMN archive_name        FORMAT a50      HEADING 'Log File'
COLUMN first_time          FORMAT a20      HEADING 'Switch Time'
COLUMN name                FORMAT a30      HEADING 'Archive Log'
SET LINES 132 FEEDBACK OFF VERIFY OFF
START title132 "Log History Report"
SPOOL &&db\_log_hist
SELECT
     X.recid,a.thread#,
     a.sequence#,a.first_change#,
     a.switch_change#,
     TO_CHAR(a.first_time,'DD-MON-YYYY HH24:MI:SS') first_time,x.name
FROM
 v$loghist a, v$archived_log x
WHERE
  a.first_time>
   (SELECT b.first_time-1
   FROM v$loghist b WHERE b.switch_change# =
    (SELECT MAX(c.switch_change#) FROM v$loghist c)) AND
     x.recid(+)=a.sequence#;
SPOOL OFF
SET LINES 80 VERIFY ON FEEDBACK ON
CLEAR COLUMNS
CLEAR BREAKS
TTITLE OFF
