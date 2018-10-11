CREATE PROCEDURE [dbo].[DropIndexesStatistics] 
  @SchemaName NVARCHAR(255) = 'dbo', @TableName NVARCHAR(255) = NULL AS
BEGIN
SET NOCOUNT ON

CREATE TABLE #commands (ID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, Command NVARCHAR(2000));
DECLARE @CurrentCommand NVARCHAR(2000);

INSERT INTO #commands (Command)
SELECT 'DROP INDEX [' + i.name + '] ON [' + s.name + '].[' + t.name + ']'
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.type = 2
AND s.name = COALESCE(@SchemaName, s.name)
AND t.name = COALESCE(@TableName, t.name);

INSERT INTO #commands (Command)
SELECT 'DROP STATISTICS ' + SCHEMA_NAME(t.schema_id) + '.['  + OBJECT_NAME(s.object_id) + '].' + s.name
FROM sys.stats AS s
JOIN sys.tables AS t
ON s.object_id = t.object_id
WHERE NOT EXISTS (SELECT * FROM sys.indexes AS i WHERE i.name = s.name) 
AND OBJECT_NAME(s.object_id) NOT LIKE 'sys%';

DECLARE result_cursor CURSOR FOR
SELECT Command FROM #commands

OPEN result_cursor
FETCH NEXT FROM result_cursor into @CurrentCommand
WHILE @@FETCH_STATUS = 0
BEGIN 
        
        PRINT @CurrentCommand;
	--EXEC(@CurrentCommand);

FETCH NEXT FROM result_cursor into @CurrentCommand
END
--end loop

--clean up
CLOSE result_cursor
DEALLOCATE result_cursor
END
GO
