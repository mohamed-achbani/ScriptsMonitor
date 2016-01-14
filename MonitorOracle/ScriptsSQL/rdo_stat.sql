SET PAGES 56 LINES 78 VERIFY OFF FEERemote DBACK OFF
START title80 "Redo Latch Statistics"
SPOOL &&db\_redo_stat
COLUMN name      FORMAT a30          HEADING Name
COLUMN percent   FORMAT 999.999      HEADING Percent
COLUMN total                         HEADING Total
SELECT
     l2.name,
     immediate_gets+gets Total,
     immediate_gets "Immediates",
     misses+immediate_misses "Total Misses",
     DECODE (100.*(GREATEST(misses+immediate_misses,1)/
     GREATEST(immediate_gets+gets,1)),100,0) Percent
FROM
     v$latch l1,
     v$latchname l2
WHERE
     l2.name like '%redo%'
     and l1.latch#=l2.latch# ;
TTITLE OFF
CLEAR COLUMNS
CLEAR BREAKS
