DECLARE @dbname sysname
SET @dbname = NULL --set this to be whatever dbname you want
SELECT 
  bup.user_name AS [User],
  bup.database_name AS [Database],
  bup.server_name AS [Server],
  bup.backup_start_date AS [Backup Started],
  bup.backup_finish_date AS [Backup Finished]
  ,CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))/3600 AS varchar) + ' hours, ' 
  + CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))/60 AS varchar)+ ' minutes, '
  + CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))%60 AS varchar)+ ' seconds'
  AS [Total Time]
FROM msdb.dbo.backupset bup
/* COMMENT THE NEXT LINE IF YOU WANT ALL BACKUP HISTORY */
WHERE bup.database_name IN (SELECT name FROM master.dbo.sysdatabases)
ORDER BY bup.backup_start_date desc
