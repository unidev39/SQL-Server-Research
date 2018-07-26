SELECT OBJECT_NAME(ind.OBJECT_ID) AS TableName,
ind.name AS IndexName, indexstats.index_type_desc AS IndexType,
indexstats.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
INNER JOIN sys.indexes ind 
ON ind.object_id = indexstats.object_id
AND ind.index_id = indexstats.index_id
WHERE indexstats.avg_fragmentation_in_percent > 5--You can specify the percent as you want
ORDER BY indexstats.avg_fragmentation_in_percent DESC
----------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE SP_MAINTENANCE_OF_INDEX
AS 
BEGIN 
 SELECT 
	        OBJECT_NAME(ind.OBJECT_ID) AS TableName,
            ind.name AS IndexName, 
	        indexstats.index_type_desc AS IndexType,
            CAST(indexstats.avg_fragmentation_in_percent AS varchar(20)) AS avg_fragmentation_in_percent
       INTO #INDEX
       FROM 
	        sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
	   INNER JOIN 
	        sys.indexes ind ON ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id
       WHERE 
	        indexstats.avg_fragmentation_in_percent > 5--You can specify the percent as you want
       ORDER BY 
	        indexstats.avg_fragmentation_in_percent DESC
       
 
      BEGIN 
           DECLARE @INDEX_TABLE VARCHAR(200), @INDEX_NAME  VARCHAR(200), @FRAGMENT_PERCENT VARCHAR(200),
		           @TSQL  VARCHAR(2000) ;

	       DECLARE INDEX_FRAGMENTATION CURSOR FOR 
		   SELECT TableName, IndexName, avg_fragmentation_in_percent FROM #INDEX

		   OPEN INDEX_FRAGMENTATION; 

		   FETCH NEXT FROM INDEX_FRAGMENTATION INTO @INDEX_TABLE, @INDEX_NAME, @FRAGMENT_PERCENT
		   WHILE (@@FETCH_STATUS = 0) 
		   
		   BEGIN 
		        IF (@FRAGMENT_PERCENT <= '30' ) 
				   BEGIN 
		               SET @TSQL = ('ALTER INDEX  ['+@INDEX_NAME+'] ON dbo.['+@INDEX_TABLE+']'+CHAR(13)+' REORGANIZE')
				       --PRINT (@TSQL);
				       EXEC (@TSQL);
				   END;
                ELSE 
				    SET @TSQL = ('ALTER INDEX  ['+@INDEX_NAME+']  ON dbo.['+@INDEX_TABLE+']'+CHAR(13)+' REBUILD');
					--PRINT (@TSQL);
					EXEC (@TSQL);
           
           FETCH NEXT FROM INDEX_FRAGMENTATION INTO @INDEX_TABLE, @INDEX_NAME, @FRAGMENT_PERCENT;
		   END;
		   
		   CLOSE INDEX_FRAGMENTATION;
		   DEALLOCATE INDEX_FRAGMENTATION;
      END;	  	 
	  DROP TABLE #INDEX
END;


