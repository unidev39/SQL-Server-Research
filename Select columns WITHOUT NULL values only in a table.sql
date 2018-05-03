

DECLARE @tableName sysname;
DECLARE @sql nvarchar(max);
SET @sql = N'';
SET @tableName = N'Reports_table';

SELECT @sql += 'SELECT CASE WHEN EXISTS (SELECT 1 FROM ' + @tableName + ' WHERE '+ COLUMN_NAME + ' IS NULL) THEN NULL ELSE ''' + COLUMN_NAME +
''' END AS ColumnsWithNoNulls UNION ALL '
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tableName
SELECT @sql = SUBSTRING(@sql, 0, LEN(@sql) - 10);
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;
CREATE TABLE #Results (ColumnsWithNoNulls sysname NULL);
INSERT INTO #Results EXEC(@sql);
SELECT * FROM #Results WHERE ColumnsWithNoNulls IS NOT NULL
