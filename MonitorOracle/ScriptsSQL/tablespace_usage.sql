set line 300
select T1.TABLESPACE_NAME,
T1.BYTES / 1024 / 1024 as "bytes_used (Mb)",
T2.BYTES /1024 / 1024 as "bytes_free (Mb)",
T2.largest /1024 /1024 as "largest (Mb)",
round(((T1.BYTES-T2.BYTES)/T1.BYTES)*100,2) percent_used
from
(
select TABLESPACE_NAME,
sum(BYTES) BYTES
from dba_data_files
group by TABLESPACE_NAME
)
T1,
(
select TABLESPACE_NAME,
sum(BYTES) BYTES ,
max(BYTES) largest
from dba_free_space
group by TABLESPACE_NAME
)
T2
where T1.TABLESPACE_NAME=T2.TABLESPACE_NAME
order by ((T1.BYTES-T2.BYTES)/T1.BYTES) desc;
