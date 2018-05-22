-- This procedure will fetch the table and column different between two similar databases (says UAT database and Development Database)

CREATE PROC spTableAndColumnDiff
(
 @NewDatabase VARCHAR(50),
 @OldDatabase VARCHAR(50)
)
AS
BEGIN 
--EXEC spTableAndColumnDiff @NewDatabase = 'Eremitv3', @OldDatabase = 'EremitUAT_March';
      BEGIN 
	      DECLARE @TablesDiff  VARCHAR(500);

	      IF OBJECT_ID('tempdb..#TableDiff') IS NOT NULL 
			DROP TABLE #TableDiff;

	      SET @TablesDiff =  N'';
	      SELECT @TablesDiff += 'SELECT 
		                               TABLE_NAME 
								  FROM 
								      '+@NewDatabase+'.INFORMATION_SCHEMA.TABLES 
								 WHERE 
								      TABLE_NAME COLLATE DATABASE_DEFAULT NOT IN (SELECT TABLE_NAME FROM '+@OldDatabase+'.INFORMATION_SCHEMA.TABLES)'
		  
		  CREATE TABLE #TableDiff(TableDifferent VARCHAR(MAX))
		  INSERT INTO #TableDiff 
		  EXEC (@TablesDiff);

		  SELECT * FROM #TableDiff;		 
	  END;

	  BEGIN 	      
		   DECLARE @ColumnDiff VARCHAR(1000);

		   IF OBJECT_ID('tempdb..#ColumnDiff') IS NOT NULL 
				DROP TABLE #ColumnDiff;

		   SET @ColumnDiff =  N'';
		   SELECT @ColumnDiff += 'SELECT 
		                               TABLE_NAME,
									   COLUMN_NAME 
							     FROM 
								      '+@NewDatabase+'.INFORMATION_SCHEMA.COLUMNS 
		                         WHERE 
								      TABLE_NAME NOT IN (SELECT TableDifferent FROM #TableDiff)
								      AND COLUMN_NAME COLLATE DATABASE_DEFAULT NOT IN 
                                      (SELECT COLUMN_NAME FROM '+@OldDatabase+'.INFORMATION_SCHEMA.COLUMNS)                                
                                 ORDER BY 
								       TABLE_NAME,ORDINAL_POSITION'
		
		   CREATE TABLE #ColumnDiff(TableName VARCHAR(130),AddedColumn VARCHAR(130))
		   INSERT INTO #ColumnDiff 
		   EXEC (@ColumnDiff);

		   SELECT * FROM #ColumnDiff
	  END;

	  DROP TABLE #TableDiff;
	  DROP TABLE #ColumnDiff;  
END;
