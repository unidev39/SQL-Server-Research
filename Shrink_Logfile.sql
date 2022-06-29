-- Step 1

USE [master]
GO
backup database <<database_name>> to disk ='location/<<database_name_date>>.bak'
GO

-- Step 2
USE [master]
GO
ALTER DATABASE <<database_name>> SET RECOVERY SIMPLE WITH NO_WAIT
GO

-- Step 3
select name from sys.database_files where type_desc = 'LOG'
GO

-- Step 4
USE [<<database_name>>]
GO
DBCC SHRINKFILE (N'<<LogFileName>>' , 0, TRUNCATEONLY)
GO

-- Step 5
USE [master]
GO
ALTER DATABASE <<database_name>> SET RECOVERY FULL WITH NO_WAIT
GO

