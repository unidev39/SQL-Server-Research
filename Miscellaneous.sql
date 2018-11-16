--Unlock user of DB
Syntax: ALTER LOGIN [Mary5] WITH PASSWORD = '****' UNLOCK ;  

Example: ALTER LOGIN sa_db WITH PASSWORD = 'U@tdbMM/>!@#' UNLOCK ; 




Shrink Log file size of SQL SERVER 

Syntax:
DBCC SHRINKFILE(LogFile_LogicalName,size in MB to Shrink);

Eg:

DBCC SHRINKFILE(EightSquare_log,10);


---------------************ Change Column Name **********---------------------

--Syntax: EXEC sp_RENAME 'table_name.old_name', 'new_name', 'COLUMN'
EG: EXEC sp_RENAME 'RiskFactor.RiskFactorId', 'RiskFactorCategoryId', 'COLUMN'

---------------************ Change Column Name **********---------------------


-------------Find the Table Hierarchy 

EXEC sp_msdependencies @intrans = 1 ,@objtype=3



---------Check the port listening by sql server instance

USE MASTER
GO
xp_readerrorlog 0, 1, N'Server is listening on'
GO


-----------------------Procedure Execution Details----------------------------
--Execution count / Last Execution time / Cached Time / Plan Handle


SELECT 
	DB_NAME(database_id) as  DatabaseName,
	OBJECT_NAME(object_id) as ProcName,	
	cp.plan_handle,
	cached_time,
	last_execution_time,
    execution_count,
	cp.refcounts	
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st 
INNER JOIN sys.dm_exec_procedure_stats ps on ps.object_id = st.objectid
WHERE OBJECT_NAME (st.objectid) = 'BO_GetTransactions'


---------------------------------------  XML PATH

SELECT ',' + cast(AgentId as varchar(10))
              FROM Agent where ParentAgentId is not null
              FOR XML PATH ('')


----------------------------------------  STUFF 

SELECT top 1 BranchId = STUFF((
            SELECT ',' + CAST(AgentId as varchar(10))
            FROM Agent where ParentAgentId is not null
            FOR XML PATH('')
            ), 1, 1, '')
FROM Agent


