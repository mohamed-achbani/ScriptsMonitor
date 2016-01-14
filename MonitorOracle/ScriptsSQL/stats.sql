set linesize   185
set pagesize  1000
set trimout     on
set trimspool   on
Set Feedback   off
set timing     off
set verify     off


Set Heading  Off
Set Termout  Off

Column Var_DB_LAST_ANALYZED_IND new_value Var_DB_LAST_ANALYZED_IND noprint

Select
       to_char(max(last_analyzed), 'DD-MM-YYYY HH24:MI')  Var_DB_LAST_ANALYZED_IND
  from
       dba_indexes
 where
       owner not in ('SYS', 'SYSTEM', 'DBSNMP', 'EXFSYS', 'MDSYS', 'OLAPSYS', 'WMSYS', 'TSMSYS', 'CTXSYS', 'SYSMAN', 'ORACLE_OCM', 'MDSYS', 'ORDSYS', 'OUTLN', 'XDB')
;

Column Var_DB_LAST_ANALYZED_TAB new_value Var_DB_LAST_ANALYZED_TAB noprint

Select
       to_char(max(last_analyzed), 'DD-MM-YYYY HH24:MI')  Var_DB_LAST_ANALYZED_TAB
  from
       dba_tables
 where
       owner not in ('SYS', 'SYSTEM', 'DBSNMP', 'EXFSYS', 'MDSYS', 'OLAPSYS', 'WMSYS', 'TSMSYS', 'CTXSYS', 'SYSMAN', 'ORACLE_OCM', 'MDSYS', 'ORDSYS', 'OUTLN', 'XDB')
;

Set Termout  On
Set Heading  On

clear breaks

prompt

prompt -- ----------------------------------------------------------------------- ---

prompt --   Statistics                                                            ---

prompt -- ----------------------------------------------------------------------- ---

prompt


column owner          format a25          heading  "Owner"
column table_owner    format a25          heading  "Owner"
column last_analyzed  format a20          heading  "Last|Analyzed"
column last_action    format a20          heading  "Last|Actions"
column nb             format 999,999,999  heading  "Count"
column nb_ins         format 999,999,999  heading  "Count|Inserts"
column nb_upd         format 999,999,999  heading  "Count|Updates"
column nb_del         format 999,999,999  heading  "Count|Deletes"
column MBytes         format 9999999      heading  'Size(Mb)'
column SBytes         format 9999999      heading  'Size(Mb)'
column sbp            format 990.9        heading  "%Calc."

set Heading  Off
Set Feedback Off
Set Verify   Off

column status           format a120 wrap             heading "Status"

Select status_01 ||'    | '||status_02 status
  From
       (select '   Cascade '||lpad(replace(dbms_stats.get_param('cascade'),'DBMS_STATS.', ''),22) Status_01 from dual)
     , (select '   Degree   '||lpad(dbms_stats.get_param('degree'),23) Status_02 from dual)
Union
Select status_01 ||'    | '||status_02 status
  From
       (select '   Estimate % '||lpad(replace(dbms_stats.get_param('estimate_percent'),'DBMS_STATS.', ''),19) Status_01 from dual)
     , (select '   Opt. '||lpad(replace(dbms_stats.get_param('method_opt'),'DBMS_STATS.', ''),27) Status_02 from dual)
Union
Select status_01 ||'    | '||status_02 status
  From
       (select '   No Invalid.'||lpad(replace(dbms_stats.get_param('no_invalidate'),'DBMS_STATS.', ''),19) Status_01 from dual)
     , (select '   Granularity '||lpad(dbms_stats.get_param('granularity'),20) Status_02 from dual)
Union
Select status_01 ||'    | '||status_02 status
  From
       (Select '   Statistics Level  '||Lpad(value,12) status_01 from V$PARAMETER where name='statistics_level')
     , (select '   AutoStats '||lpad(dbms_stats.get_param('autostats_target'),22) Status_02 from dual)
;


Select status_01||'    | '||status_02 status
  From
       (Select '   Monitoring On '||Lpad(count(*),16) status_01 from Dba_Tables where monitoring = 'YES' and temporary = 'N'  and Table_Name not in (Select table_name From Dba_External_Tables) and owner not in ('SYS', 'SYSTEM', 'DBSNMP', 'EXFSYS', 'MDSYS', 'OLAPSYS', 'WMSYS', 'TSMSYS', 'CTXSYS', 'SYSMAN', 'ORACLE_OCM', 'MDSYS', 'ORDSYS', 'OUTLN', 'XDB'))
     , (Select '   Monitoring Off '||Lpad(count(*),17) status_02 from Dba_Tables where monitoring = 'NO' and temporary = 'N' and Table_Name not in (Select table_name From Dba_External_Tables)  and owner not in ('SYS', 'SYSTEM', 'DBSNMP', 'EXFSYS', 'MDSYS', 'OLAPSYS', 'WMSYS', 'TSMSYS', 'CTXSYS', 'SYSMAN', 'ORACLE_OCM', 'MDSYS', 'ORDSYS', 'OUTLN', 'XDB'))
Union
Select status_01 ||'    | '||status_02 status
  From
       (Select '   Last Tab. An. '||Lpad('&Var_DB_LAST_ANALYZED_TAB.',16) status_01 from dual)
     , (select '   Last Ind. An. '||lpad('&Var_DB_LAST_ANALYZED_IND.',18) Status_02 from dual)
Union
Select status_01
  From
       (Select '   Last Start Dt.'||Lpad(to_char(last_start_date, 'DD-MM-YYYY HH24:MI'), 16) status_01 from Dba_Scheduler_Jobs Where JOB_NAME = 'GATHER_STATS_JOB')
;



Set Heading  On

clear breaks
break on created on lst_ana on owner -
skip 1

column  lst_ana          heading  'Last_Analyzed'   format a20
column  owner            heading  'Owner'           format a15
column  Table_Name       heading  'Table Name'      format a35
column  Index_Name       heading  'Table Name'      format a35
column  Cluster_Name     heading  'Cluster Name'    format a15
column  Tablespace_Name  heading  'Tablespace'      format a16
column  Ini_Ext          heading  'Init.|Ext(Kb)'   format 9999999
column  Nex_Ext          heading  'Next.|Ext(Kb)'   format 9999999

Select
       To_Char(last_analyzed, 'DD-MM-YYYY HH24:MI') lst_ana
     , Owner
     , Table_Name
     , Tablespace_Name
     , Initial_Extent/1024              Ini_Ext
     , Next_Extent/1024                 Nex_Ext
 From
       Dba_Tables
Where
      last_analyzed > to_date('&Var_DB_LAST_ANALYZED_TAB.', 'DD-MM-YYYY HH24:MI') - 0.1/24/60
 Order
    By last_analyzed
     , Owner
     , Table_Name
;

Select
       To_Char(last_analyzed, 'DD-MM-YYYY HH24:MI') lst_ana
     , Owner
     , Index_Name
     , Tablespace_Name
     , Initial_Extent/1024              Ini_Ext
     , Next_Extent/1024                 Nex_Ext
 From
       Dba_Indexes
Where
      last_analyzed > to_date('&Var_DB_LAST_ANALYZED_TAB.', 'DD-MM-YYYY HH24:MI') - 0.1/24/60
 Order
    By last_analyzed
     , Owner
     , Index_Name
;





clear breaks

Set Heading  On


Prompt

prompt --   Schedule / Job / Window

prompt -- ----------------------------------------------------------------------- ---

column  o           format  a5   word_wrapped  heading  "Owner"
column  jn          format  a25  word_wrapped  heading  "Job Name|(Subname - Creator)"
column  jt          format  a17  word_wrapped  heading  "Job Type"
column  ja          format  a38                heading  "Job Action"
column  st          format  a9   word_wrapped  heading  "State"
column  lsd         format  a16  word_wrapped  heading  "Last Start Date"
column  nrd         format  a5  word_wrapped  heading  "Next|Run|Date"
column  fc          format  9999               heading  "Fail.|Ct."
column  rc          format  999999             heading  "Run|Ct."
column  en          format  a6   word_wrapped  heading  "Enab."
column  ri          format  a30  word_wrapped  heading  "Rep.|Int."
column  sosn        format  a24  word_wrapped  heading  "Sched. |Owner|Sched. Name"
column  sowc        format  a5   word_wrapped  heading  "Stop|On|Wind.|Close"
column  ad          format  a5   word_wrapped  heading  "Auto|Drop"
column  sn          format  a25  word_wrapped  heading  "Sched.|Name"
column  jc          format  a21  word_wrapped  heading  "Job|Class"
column  pn          format  a18  word_wrapped  heading  "Prog.|Name"

clear breaks
break on o -
skip 1

select
       owner                                                   o
     , job_name||'('||decode(job_subname,null,'',job_subname||' - ') ||job_creator||')'     jn
--   , job_type                                                jt
--   , replace(Substr(job_action,1,38),chr(10),' ')            ja
     , state                                                   st
     , to_char(last_start_date, 'DD-MM-YYYY HH24:MI')          lsd
     , to_char(next_run_date, 'DD-MM-YYYY HH24:MI')            nrd
--   , substr(repeat_interval,1,30)                             ri
     , failure_count                                           fc
     , run_count                                               rc
     , enabled                                                 en
--   , decode(schedule_owner,null,'',schedule_owner||' - ')||schedule_name                    sosn
     , stop_on_window_close                                    sowc
     , auto_drop                                               ad
     , SCHEDULE_NAME                                           sn
     , JOB_CLASS                                               jc
     , program_name                                            pn
  from
       Dba_Scheduler_Jobs
 Where
      JOB_NAME = 'GATHER_STATS_JOB'
 Order
    By owner
     , state
     , enabled
     , job_name
;

clear breaks

column  o           format  a5   word_wrapped  heading  "Owner"
column  pn          format  a18  word_wrapped  heading  "Prog.|Name"
column  pt          format  a18  word_wrapped  heading  "Prog.|Type"
column  pa          format  a42  word_wrapped  heading  "Prog.|Action"
column  en          format  a8   word_wrapped  heading  "Enabled"
column  de          format  a8   word_wrapped  heading  "Detached"
column  co          format  a60  word_wrapped  heading  "Comments"

select
       owner                                    o
     , program_name                             pn
     , program_type                             pt
     , program_action                           pa
     , enabled                                  en
     , detached                                 de
     , comments                                 co
  from
       dba_scheduler_programs
 where
       PROGRAM_NAME = 'GATHER_STATS_PROG'
;


column  wgn          format  a30  word_wrapped  heading  "Window Group Name"
column  wn           format  a30  word_wrapped  heading  "Window Name"

Select
       Window_Group_Name                    wgn
     , Window_Name                          wn
  From
       DBA_SCHEDULER_WINGROUP_MEMBERS
;


column  wn           format  a17  word_wrapped  heading  "Window Name"
column  ri           format  a40  word_wrapped  heading  "Repeat Interval"
column  du           format  a13  word_wrapped  heading  "Duration"
column  nsd          format  a17  word_wrapped  heading  "Next|Start Date"
column  lsd          format  a17  word_wrapped  heading  "Last|Start Date"
column  wp           format  a8   word_wrapped  heading  "Wind.|Pri."
column  en           format  a8   word_wrapped  heading  "Enabled"
column  ac           format  a8   word_wrapped  heading  "Active"
column  co           format  a30  word_wrapped  heading  "Comments"

select
       Window_Name                                       wn
     , REPEAT_INTERVAL                                   ri
--   , end_date                                          ed
     , duration                                          du
     , To_Char(next_start_date, 'DD-MM-YYYY HH24:MI')    nsd
     , To_Char(last_start_date, 'DD-MM-YYYY HH24:MI')    lsd
     , WINDOW_PRIORITY                                   wp
     , enabled                                           en
     , active                                            ac
     , comments                                          co
  From
       dba_scheduler_windows
;



Prompt

Prompt

set feedback on


