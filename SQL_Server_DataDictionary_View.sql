-- To Find Database Size without Last Backup
SELECT
     DB_NAME(database_id) dbname,
     Name                 Logical_Name,
     Physical_Name,
     (size*8)/1024        SizeMB, 
     (size*8)/(1024*1024) SizeGB
FROM sys.master_files
WHERE DB_NAME(database_id) = (SELECT name FROM sys.sysdatabases u WHERE u.dbid = db_id());

-- To Find Database Size with Last Backup
SELECT
      d.database_id
    , t.name Logical_Name
    , t.Physical_Name
    , d.state_desc
    , d.recovery_model_desc
    , t.total_size/1024      total_size_gb
    , t.data_size/1024       data_size_gb
    , s.data_used_size/1024  data_used_size_gb
    , t.log_size/1024        log_size_gb
    , bu.full_last_date      last_date_of_backup
    , bu.full_size/1024      last_backup_full_size_gb
FROM (
    SELECT
          database_id
        , name
        , Physical_Name
        , log_size = CAST(SUM(CASE WHEN [type] = 1 THEN size END) * 8. / 1024 AS DECIMAL(18,2))
        , data_size = CAST(SUM(CASE WHEN [type] = 0 THEN size END) * 8. / 1024 AS DECIMAL(18,2))
        , total_size = CAST(SUM(size) * 8. / 1024 AS DECIMAL(18,2))
    FROM sys.master_files
    WHERE DB_NAME(database_id) = (SELECT name FROM sys.sysdatabases u WHERE u.dbid = db_id())
    GROUP BY database_id
        , name
        , Physical_Name
) t
JOIN sys.databases d ON d.database_id = t.database_id
LEFT JOIN (SELECT
          DB_ID() database_id
        , SUM(CASE WHEN [type] = 0 THEN space_used END) data_used_size
        , SUM(CASE WHEN [type] = 1 THEN space_used END) log_used_size
    FROM (
        SELECT s.[type], space_used = SUM(FILEPROPERTY(s.name, 'SpaceUsed') * 8. / 1024)
        FROM sys.database_files s
        GROUP BY s.[type]
    ) t) s ON d.database_id = s.database_id
LEFT JOIN (
    SELECT
          database_name
        , full_last_date = MAX(CASE WHEN [type] = 'D' THEN backup_finish_date END)
        , full_size = MAX(CASE WHEN [type] = 'D' THEN backup_size END)
        , log_last_date = MAX(CASE WHEN [type] = 'L' THEN backup_finish_date END)
        , log_size = MAX(CASE WHEN [type] = 'L' THEN backup_size END)
    FROM (
        SELECT
              s.database_name
            , s.[type]
            , s.backup_finish_date
            , backup_size =
                        CAST(CASE WHEN s.backup_size = s.compressed_backup_size
                                    THEN s.backup_size
                                    ELSE s.compressed_backup_size
                        END / 1048576.0 AS DECIMAL(18,2))
            , RowNum = ROW_NUMBER() OVER (PARTITION BY s.database_name, s.[type] ORDER BY s.backup_finish_date DESC)
        FROM msdb.dbo.backupset s
        WHERE s.[type] IN ('D', 'L')
    ) f
    WHERE f.RowNum = 1
    GROUP BY f.database_name
) bu ON d.name = bu.database_name
ORDER BY t.total_size DESC;

-- To Find the Table Size with Rows Count
SELECT
     u.name
    ,s.name AS schemaname
    ,t.name AS tablename
    ,p.rows AS rowcounts
    ,CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS used_mb
    ,CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2)) / 1024 AS used_gb
    ,CAST(ROUND((SUM(a.total_pages) - SUM(a.used_pages)) / 128.00, 2) AS NUMERIC(36, 2)) AS unused_mb
    ,CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS total_mb
FROM sys.tables t INNER JOIN sys.indexes i 
ON (t.object_id = i.object_id)
INNER JOIN sys.partitions p 
ON (i.object_id = p.object_id AND i.index_id = p.index_id)
INNER JOIN sys.allocation_units a 
ON (p.partition_id = a.container_id)
INNER JOIN sys.schemas s 
ON (t.schema_id = s.schema_id)
CROSS JOIN sys.sysdatabases u
WHERE u.dbid = db_id()
GROUP BY
     u.name 
    ,t.name
    ,s.name
    ,p.rows
ORDER BY 
     s.name
    ,t.name;

--To find the Object ID
SELECT OBJECT_ID('sp_updatestats');

--To Find the Object Structure
SELECT *
FROM sys.all_sql_modules
WHERE OBJECT_ID = '-838816646';

--To find the Object list
SELECT
     name,
     type_desc,
     create_date,
     modify_date 
FROM [sys].[all_objects]
WHERE schema_id =1 
AND type IN ('P','FN','V','TR','C','UQ')
ORDER BY 
    type,
    name;

--To Find the Table Privilage
EXEC sp_table_privileges @table_name ='<<table_name>>';

--To Find the User Roles
SELECT
     rp.name AS DatabaseRoleName,
     mp.name AS DatabaseUserName
FROM sys.database_role_members rm
INNER JOIN sys.database_principals rp ON rm.role_principal_id = rp.principal_id
INNER JOIN sys.database_principals mp ON rm.member_principal_id = mp.principal_id;

--To Find the Index Status
SELECT
    a.name                                                       index_name,
    COL_NAME(b.object_id,b.column_id)                            column_name,
    CASE WHEN b.is_descending_key =0 THEN 'ASC' ELSE 'DESC' END  is_descending_key,
    CASE WHEN a.is_unique=1 THEN 'YES' ELSE 'NO' END             is_unique,
    a.type_desc                                                  type_desc
FROM
    sys.indexes a  
INNER JOIN
    sys.index_columns b   
ON a.object_id = b.object_id AND a.index_id = b.index_id  
WHERE
    a.is_hypothetical = 0 AND
    a.object_id = OBJECT_ID('<<Table_Name>>');

--To find the table structure
SELECT
     t.name AS tablename
    ,c.name AS columnname
    ,c.column_id
    ,CONCAT (UPPER(cc.data_type),CASE 
                                    WHEN cc.character_maximum_length IS NOT NULL
                                        THEN CONCAT (' (', CASE
                                                              WHEN cc.character_maximum_length = -1 
                                                                 THEN 'Max'
                                                           ELSE CAST(cc.character_maximum_length AS VARCHAR) 
                                                           END ,')')
                                    WHEN cc.data_type = 'decimal'
                                        THEN CONCAT (' (',cc.numeric_precision,',',cc.numeric_scale,')')
                                 ELSE ''
                                 END
        ) AS datatype,
     cc.is_nullable,
     cc.column_default
FROM sys.tables t INNER JOIN sys.all_columns c 
ON (t.object_id = c.object_id)
INNER JOIN information_schema.columns cc 
ON (cc.column_name = c.name AND cc.table_name = t.name)
ORDER BY
    1,3;

--To Find the Current Memory Allocation
SELECT 
    physical_memory_in_use_kb/1024             sql_physical_memory_in_use_MB, 
    large_page_allocations_kb/1024             sql_large_page_allocations_MB, 
    locked_page_allocations_kb/1024            sql_locked_page_allocations_MB,
    virtual_address_space_reserved_kb/1024     sql_VirtulaAddressSpace_reserved_MB, 
    virtual_address_space_committed_kb/1024    sql_VirtulaAddressSpace_committed_MB, 
    virtual_address_space_available_kb/1024    sql_VirtulaAddressSpace_available_MB,
    page_fault_count                           sql_page_fault_count,
    memory_utilization_percentage              sql_memory_utilization_percentage, 
    process_physical_memory_low                sql_process_physical_memory_low, 
    process_virtual_memory_low                 sql_process_virtual_memory_low
FROM sys.dm_os_process_memory;

--To Find the All Orphaned SQL Server Database Users
SELECT
     DB_NAME()            [database]
    ,name                 [user_name]
    ,type_desc
    ,default_schema_name
    ,create_date
    ,modify_date
FROM sys.database_principals
WHERE type IN ('G','S','U')
AND authentication_type <> 2 -- Use this filter only if you are running on SQL Server 2012 and major versions and you have "contained databases"
AND [sid] NOT IN (SELECT 
                       [sid]
                  FROM sys.server_principals
                  WHERE type IN ('G','S','U')
                  )
AND name NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys','MS_DataCollectorInternalUser');


--To Find Backup Progress/Completion Time
SELECT
     session_id                                                spid,
     command                                                   command,
     a.text                                                    query,
     start_time                                                start_time,
     percent_complete                                          percent_complete,
     dateadd(second,estimated_completion_time/1000, getdate()) estimated_completion_time 
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a 
WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE')

--To Find the Phiysical and Logical Database Name
SELECT
     d.name DatabaseName
    ,f.name LogicalName
    ,f.physical_name AS PhysicalName
    ,f.type_desc TypeofFile
FROM sys.master_files f
INNER JOIN sys.databases d ON d.database_id = f.database_id;

--To Find the Enabled/Disabled Accounts (on the Basis of Last Password Change):
SELECT 
     name                                           [name], 
     CASE
        WHEN is_disabled =0 THEN 'Enabled' 
        WHEN is_disabled =1 THEN 'Disabled'
     ELSE
        CAST(is_disabled AS VARCHAR(20))
     END                                             [status],
     create_date                                     create_date, 
     LOGINPROPERTY([name], 'PasswordLastSetTime')    [PasswordChanged]
FROM sys.sql_logins
WHERE LOGINPROPERTY([name], 'PasswordLastSetTime') < DATEADD(dd, -30, GETDATE());
--and NOT (LEFT([name], 2) = '##' AND RIGHT([name], 2) = '##');

-- To Find Session ID/Informations - SPID
exec sp_who2
-- To get the SQL_TEXT on Basis of SPID 
dbcc inputbuffer(<<SPID>>)

-- To Find Processed or Processing User Details
SELECT
     ORIGINAL_LOGIN()                           login_as, 
     CASE 
        WHEN is_user_process=1 THEN 'Yes'
        WHEN is_user_process=0 THEN 'No'
     ELSE 
        CAST(is_user_process AS VARCHAR(10))
     END                                        is_user_process, 
     session_id                                 session_id,
     SESSION_USER                               [session_user],
     login_name                                 login_name,
     original_login_name                        original_login_name,
     host_name                                  host_name,
     program_name                               program_name,
     status                                     status,
     cpu_time                                   cpu_time,
     memory_usage                               memory_usage,
     total_elapsed_time                         total_elapsed_time,
     reads                                      reads,
     writes                                     writes,
     logical_reads                              logical_reads,
     last_request_start_time                    last_request_start_time,
     last_request_end_time                      last_request_end_time,
     last_successful_logon                      last_successful_logon,
     last_unsuccessful_logon                    last_unsuccessful_logon
     FROM sys.dm_exec_sessions a
     --WHERE a.original_login_name = ORIGINAL_LOGIN()
     ORDER BY 2 DESC;

-- To Find the Contains one row for each login account with password
SELECT
     ORIGINAL_LOGIN()                                 server_access_as,
     createdate                                       login_createdate,
     updatedate                                       login_updatedate,
     name                                             login_name,
     password                                         login_password,
     CASE 
        WHEN denylogin=0 THEN 'Allowed'
        WHEN denylogin=1 THEN 'Denied'
     ELSE
        CAST(denylogin AS VARCHAR(10))
     END                                              login_status,
     CASE 
        WHEN hasaccess=1 THEN 'Yes'
        WHEN hasaccess=0 THEN 'No'
     ELSE
        CAST(hasaccess AS VARCHAR(10))
     END                                              server_access,
     CASE 
        WHEN isntname=1 THEN 'Window User or Group'
        WHEN isntname=0 THEN 'SQL Server login'
     ELSE
        CAST(isntname AS VARCHAR(30))
     END                                              user_status,
     CASE 
        WHEN sysadmin=1 THEN 'Yes'
        WHEN sysadmin=0 THEN 'No'
     ELSE
        CAST(sysadmin AS VARCHAR(10))
     END                                              sysadmin_server_role,
     CASE 
        WHEN securityadmin=1 THEN 'Yes'
        WHEN securityadmin=0 THEN 'No'
     ELSE
        CAST(securityadmin AS VARCHAR(10))
     END                                              securityadmin_server_role,     
     CASE 
        WHEN serveradmin=1 THEN 'Yes'
        WHEN serveradmin=0 THEN 'No'
     ELSE
        CAST(serveradmin AS VARCHAR(10))
     END                                              serveradmin_server_role,
     CASE 
        WHEN setupadmin=1 THEN 'Yes'
        WHEN setupadmin=0 THEN 'No'
     ELSE
        CAST(setupadmin AS VARCHAR(10))
     END                                              setupadmin_server_role,     
     CASE 
        WHEN processadmin=1 THEN 'Yes'
        WHEN processadmin=0 THEN 'No'
     ELSE
        CAST(processadmin AS VARCHAR(10))
     END                                              processadmin_server_role,     
     CASE 
        WHEN diskadmin=1 THEN 'Yes'
        WHEN diskadmin=0 THEN 'No'
     ELSE
        CAST(diskadmin AS VARCHAR(10))
     END                                              diskadmin_server_role,    
     CASE 
        WHEN dbcreator=1 THEN 'Yes'
        WHEN dbcreator=0 THEN 'No'
     ELSE
        CAST(dbcreator AS VARCHAR(10))
     END                                              dbcreator_server_role,         
     CASE 
        WHEN bulkadmin=1 THEN 'Yes'
        WHEN bulkadmin=0 THEN 'No'
     ELSE
        CAST(bulkadmin AS VARCHAR(10))
     END                                              bulkadmin_server_role          
     FROM sys.syslogins
     ORDER BY 2;

-- To Find Index Fragmentation 
SELECT
     object_name(ind.object_id)                                   tablename
    ,ind.name                                                     indexname
    ,indexstats.index_type_desc                                   indextype
    ,cast(indexstats.avg_fragmentation_in_percent AS VARCHAR(20)) avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(db_id(), NULL, NULL, NULL, NULL) indexstats
INNER JOIN sys.indexes ind
ON (ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id)
WHERE indexstats.avg_fragmentation_in_percent > 5
ORDER BY indexstats.avg_fragmentation_in_percent DESC;

-- To Find the SQL Server Agent Jobs Details
-- Gives Job Name, Schedule AND Next run time
SELECT
     s.name AS JobName,
     ss.name AS ScheduleName,
     CASE(ss.freq_type)
          WHEN 1  THEN 'Once'
          WHEN 4  THEN 'Daily'
          WHEN 8  THEN (CASE WHEN (ss.freq_recurrence_factor > 1) THEN  'Every ' + CONVERT(VARCHAR(3),ss.freq_recurrence_factor) + ' Weeks'  else 'Weekly'  end)
          WHEN 16 THEN (CASE WHEN (ss.freq_recurrence_factor > 1) THEN  'Every ' + CONVERT(VARCHAR(3),ss.freq_recurrence_factor) + ' Months' else 'Monthly' end)
          WHEN 32 THEN 'Every ' + CONVERT(VARCHAR(3),ss.freq_recurrence_factor) + ' Months' -- RELATIVE
          WHEN 64 THEN 'SQL Startup'
          WHEN 128 THEN 'SQL Idle'
          ELSE '??'
     END AS Frequency,  
     CASE
        WHEN (freq_type = 1)                       THEN 'One time only'
        WHEN (freq_type = 4 AND freq_interval = 1) THEN 'Every Day'
        WHEN (freq_type = 4 AND freq_interval > 1) THEN 'Every ' + CONVERT(VARCHAR(10),freq_interval) + ' Days'
        WHEN (freq_type = 8) THEN (SELECT 'Weekly Schedule' = MIN(D1+D2+D3+D4+D5+D6+D7)
                                    FROM (SELECT
                                               ss.schedule_id,
                                               freq_interval, 
                                               'D1' = CASE WHEN (freq_interval & 1  <> 0) THEN 'Sun '  ELSE '' END,
                                               'D2' = CASE WHEN (freq_interval & 2  <> 0) THEN 'Mon '  ELSE '' END,
                                               'D3' = CASE WHEN (freq_interval & 4  <> 0) THEN 'Tue '  ELSE '' END,
                                               'D4' = CASE WHEN (freq_interval & 8  <> 0) THEN 'Wed '  ELSE '' END,
                                               'D5' = CASE WHEN (freq_interval & 16 <> 0) THEN 'Thu '  ELSE '' END,
                                               'D6' = CASE WHEN (freq_interval & 32 <> 0) THEN 'Fri '  ELSE '' END,
                                               'D7' = CASE WHEN (freq_interval & 64 <> 0) THEN 'Sat '  ELSE '' END
                                          FROM msdb..sysschedules ss
                                          WHERE freq_type = 8
                                        ) AS F
                                    WHERE schedule_id = SJ.schedule_id
                                )
        WHEN (freq_type = 16) THEN 'Day ' + CONVERT(VARCHAR(2),freq_interval) 
        WHEN (freq_type = 32) THEN (SELECT  freq_rel + WDAY 
                                    FROM (SELECT ss.schedule_id,
                                                       'freq_rel' = CASE(freq_relative_interval)
                                                                       WHEN 1 THEN 'First'
                                                                       WHEN 2 THEN 'Second'
                                                                       WHEN 4 THEN 'Third'
                                                                       WHEN 8 THEN 'Fourth'
                                                                       WHEN 16 THEN 'Last'
                                                                    ELSE '??'
                                                                    END,
                                                       'WDAY' = CASE (freq_interval)
                                                                   WHEN 1 THEN ' Sun'
                                                                   WHEN 2 THEN ' Mon'
                                                                   WHEN 3 THEN ' Tue'
                                                                   WHEN 4 THEN ' Wed'
                                                                   WHEN 5 THEN ' Thu'
                                                                   WHEN 6 THEN ' Fri'
                                                                   WHEN 7 THEN ' Sat'
                                                                   WHEN 8 THEN ' Day'
                                                                   WHEN 9 THEN ' Weekday'
                                                                   WHEN 10 THEN ' Weekend'
                                                                ELSE '??'
                                                                END
                                         FROM msdb..sysschedules SS
                                         WHERE ss.freq_type = 32
                                         ) AS WS 
                                    WHERE Ws.schedule_id = ss.schedule_id
                                    ) 
     END AS Interval,
     CASE (freq_subday_type)
         WHEN 1 THEN   LEFT(STUFF((STUFF((REPLICATE('0', 6 - LEN(active_start_time)))+ CONVERT(VARCHAR(6),active_start_time),3,0,':')),6,0,':'),8)
         WHEN 2 THEN 'Every ' + CONVERT(VARCHAR(10),freq_subday_interval) + ' seconds'
         WHEN 4 THEN 'Every ' + CONVERT(VARCHAR(10),freq_subday_interval) + ' minutes'
         WHEN 8 THEN 'Every ' + CONVERT(VARCHAR(10),freq_subday_interval) + ' hours'
         ELSE '??'
     END AS [Time],
     CASE SJ.next_run_date
         WHEN 0 THEN CAST('n/a' AS CHAR(10))
         ELSE CONVERT(char(10), CONVERT(datetime, CONVERT(CHAR(8),SJ.next_run_date)),120)  + ' ' + LEFT(STUFF((STUFF((REPLICATE('0', 6 - len(next_run_time)))+ CONVERT(VARCHAR(6),next_run_time),3,0,':')),6,0,':'),8)
     END AS NextRunTime
FROM msdb.dbo.sysjobs S
LEFT JOIN msdb.dbo.sysjobschedules SJ ON s.job_id = SJ.job_id  
LEFT JOIN msdb.dbo.sysschedules SS ON ss.schedule_id = SJ.schedule_id
ORDER BY s.name;
------------------------------


-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  
declare @svrName varchar(255)
declare @sql varchar(400)
--by default it will take the current server name, we can the set the server name as well
set @svrName = @@SERVERNAME
set @sql = 'powershell.exe -c "Get-WmiObject -ComputerName ' + QUOTENAME(@svrName,'''') + ' -Class Win32_Volume -Filter ''DriveType = 3'' | select name,capacity,freespace | foreach{$_.name+''|''+$_.capacity/1048576+''%''+$_.freespace/1048576+''*''}"'
--creating a temporary table
CREATE TABLE #output
(line varchar(255))
--inserting disk name, total space and free space value in to temporary table
insert #output
EXEC xp_cmdshell @sql
--script to retrieve the values in MB from PS Script output
select rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) as drivename
   ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
   (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float),0) as 'capacity(MB)'
   ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
   (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float),0) as 'freespace(MB)'
from #output
where line like '[A-Z][:]%'
order by drivename
--script to retrieve the values in GB from PS Script output
select rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) as drivename
   ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
   (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float)/1024,0) as 'capacity(GB)'
   ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
   (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float) /1024 ,0)as 'freespace(GB)'
from #output
where line like '[A-Z][:]%'
order by drivename
--script to drop the temporary table
drop table #output

                           
--Disable 
                           
-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 0;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To disable the feature.  
EXEC sp_configure 'xp_cmdshell', 0;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO                           
-------                         
                           
https://www.mssqltips.com/sql-server-dba-resources/

