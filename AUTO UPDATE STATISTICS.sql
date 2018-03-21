DECLARE @SQL VARCHAR(1000)  
DECLARE @DB sysname  

DECLARE curDB CURSOR FORWARD_ONLY STATIC FOR  
   SELECT [name]  
   FROM master..sysdatabases 
   WHERE [name] NOT IN ('model', 'tempdb') 
   ORDER BY [name] 
     
OPEN curDB  
FETCH NEXT FROM curDB INTO @DB  
WHILE @@FETCH_STATUS = 0  
   BEGIN  
       SELECT @SQL = 'USE [' + @DB +']' + CHAR(13) + 'EXEC sp_updatestats' + CHAR(13)  
       print (@SQL)  
       FETCH NEXT FROM curDB INTO @DB  
   END  
    
CLOSE curDB  
DEALLOCATE curDB

--------------------------------------------------------

CREATE PROCEDURE SP_MAINTENANCE_OF_STATISTICS 
AS 
BEGIN 
     DECLARE @SQL VARCHAR(1000)  
     DECLARE @DB sysname  
     
     DECLARE curDB CURSOR FORWARD_ONLY STATIC FOR  
        SELECT [name]  
        FROM master..sysdatabases 
        WHERE [name] NOT IN ('model', 'tempdb') 
        ORDER BY [name] 
          
     OPEN curDB  
     FETCH NEXT FROM curDB INTO @DB  
     WHILE @@FETCH_STATUS = 0  
        BEGIN  
            SELECT @SQL = 'USE [' + @DB +']' + CHAR(13) + 'EXEC sp_updatestats' + CHAR(13)  
            EXEC (@SQL)  
            FETCH NEXT FROM curDB INTO @DB  
        END  
         
CLOSE curDB  
DEALLOCATE curDB

END


