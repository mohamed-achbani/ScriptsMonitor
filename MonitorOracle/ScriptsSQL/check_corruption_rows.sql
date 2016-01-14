/*
The ANALYZE command can be used to verify each data block in the analyzed object. 
If any corruption is detected rows are added to the INVALID_ROWS table.
@C:\ORACLE_HOME\rdbms\admin\UTLVALID.SQL
	sql: Select * from INVALID_ROWS;
*/

DECLARE
v_dynam   varchar2(500);
cursor idx_cursor is
    select owner, index_name, tablespace_name from all_indexes;
BEGIN
    for c_row in idx_cursor loop            
      v_dynam := 'ANALYZE INDEX '||c_row.owner||'."'||c_row.index_name ||'" VALIDATE STRUCTURE';
       execute immediate v_dynam;                        
    end loop;
END;
/

DECLARE
v_dynam   varchar2(500);
cursor tbl_cursor is
    select owner, table_name, tablespace_name from all_tables where  (iot_type IS NULL or  iot_type != 'IOT_OVERFLOW')
;
BEGIN
    for c_row in tbl_cursor loop        	  
      v_dynam := 'ANALYZE TABLE '||c_row.owner||'."'||c_row.table_name ||'" VALIDATE STRUCTURE CASCADE';
       execute immediate v_dynam;                        
    end loop;
END;
/