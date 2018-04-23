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
