

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



Example:

--This procedure will only displays the columns which has value different after the comparison between each columns of Customer and CustomerHIstory table.
--Database Used Eremitv3 (EightSquare)


CREATE PROC [dbo].[spCustomerHistory]
(
  @UserId UNIQUEIDENTIFIER 
)
AS 
BEGIN 
SET NOCOUNT ON 
--EXEC spCustomerHistory  @UserId= '44D143EA-ABC3-4335-A5C4-0001336C7D3E';

IF OBJECT_ID('Tempdb..#Result', 'U') IS NOT NULL
DROP TABLE #Result;

SELECT  COLUMN_NAME
INTO  #Result
FROM  INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'CustomerHistory' AND COLUMN_NAME NOT IN ( 'Id','UserId','RefCategoryId','RefSubCategoryId','ModifiedById')

ALTER TABLE #Result ADD OldValue VARCHAR(MAX), NewValue VARCHAR(MAX) 

DECLARE @ColumnName VARCHAR(255),
        @SQLSelect VARCHAR(MAX),
        @SQLCreate VARCHAR(MAX),
        @SQLInsert VARCHAR(MAX),
        @SQLUpdate VARCHAR(MAX);
DECLARE dbCursor CURSOR FOR SELECT COLUMN_NAME FROM #Result; 

OPEN dbCursor;
FETCH NEXT FROM dbCursor INTO @ColumnName;
WHILE @@FETCH_STATUS = 0  
BEGIN  
----------------------------------------------------------
BEGIN 
     IF OBJECT_ID('Tempdb..#TempResult', 'U') IS NOT NULL
     DROP TABLE #TempResult;

     SET @SQLSelect = N'';     
     SELECT @SQLSelect += ('SELECT TOP 1 '''+ @ColumnName + ''' AS colname,
                                  ch.'+ @ColumnName + ' AS Old'+@ColumnName+', 
                               c.' + @ColumnName + ' AS New'+@ColumnName + '
                            FROM Customer c 
                            JOIN CustomerHistory ch on c.UserId = ch.UserId 
                            WHERE c.UserId = ''' + CAST(@UserId AS NVARCHAR(36)) +'''ORDER BY ch.Id desc');
              
     CREATE TABLE #TempResult (ColumnsName varchar(max) NULL,NewValue varchar(max), OldValue varchar(max));
     INSERT INTO #TempResult EXEC (@SQLSelect);
     
      UPDATE R
     SET  R.COLUMN_NAME = CASE WHEN ISNULL(TR.NewValue,'') = ISNULL(TR.OldValue,'') THEN NULL 
						       WHEN RIGHT(@ColumnName,2) = 'Id' THEN SUBSTRING(@ColumnName,1,(len(@ColumnName)-2))						   
	                      ELSE R.COLUMN_NAME END,
     	  R.NewValue = CASE WHEN @ColumnName = 'CustomerStatus'      THEN (SELECT Status FROM CustomerStatus WHERE Id = TR.NewValue)
     						WHEN @ColumnName = 'OccupationId'        THEN (SELECT CodeDescription FROM Occupation WHERE Id = TR.NewValue)
     						WHEN @ColumnName = 'ResidentialStatusId' THEN CASE WHEN TR.NewValue = 1 THEN 'Non-Malaysian' ELSE 'Malaysian' END
							WHEN @ColumnName = 'OfficeStateMalId'    THEN (SELECT MalState FROM StateMalaysia WHERE Id = TR.NewValue )
							WHEN @ColumnName = 'SourceOfWealthId'    THEN (SELECT SourceDescription FROM SourceOfWealth WHERE Id = TR.NewValue )
							WHEN @ColumnName = 'StateId'             THEN (SELECT StateName FROM State WHERE Id = TR.NewValue)
							WHEN @ColumnName = 'KYCType'             THEN CASE WHEN TR.NewValue = 0 THEN 'NONKYC' WHEN TR.NewValue = 1 THEN 'KYC' ELSE 'EKYC' END
							WHEN @ColumnName IN ( 'NationalityId', 'CountryOfBirthId', 'PaymentCountryId') THEN (SELECT CountryName FROM Country WHERE Id = TR.NewValue )
     	               ELSE  TR.NewValue END, 
					       
     	  R.OldValue = CASE WHEN @ColumnName = 'CustomerStatus'      THEN (SELECT Status FROM CustomerStatus WHERE Id = TR.OldValue )
     						WHEN @ColumnName = 'OccupationId'        THEN (SELECT CodeDescription FROM Occupation WHERE Id = TR.OldValue )
     						WHEN @ColumnName = 'ResidentialStatusId' THEN CASE WHEN TR.OldValue = 1 THEN 'Non-Malaysian' ELSE 'Malaysian' END 							
							WHEN @ColumnName = 'OfficeStateMalId'    THEN (SELECT MalState FROM StateMalaysia WHERE Id = TR.OldValue )
							WHEN @ColumnName = 'SourceOfWealthId'    THEN (SELECT SourceDescription FROM SourceOfWealth WHERE Id = TR.OldValue )
							WHEN @ColumnName = 'StateId'             THEN (SELECT StateName FROM State WHERE Id = TR.OldValue)
							WHEN @ColumnName = 'KYCType'             THEN CASE WHEN TR.OldValue = 0 THEN 'NONKYC' WHEN TR.OldValue = 1 THEN 'KYC' ELSE 'EKYC' END
							WHEN @ColumnName IN ( 'NationalityId', 'CountryOfBirthId', 'PaymentCountryId') THEN (SELECT CountryName FROM Country WHERE Id = TR.OldValue )
     				   ELSE TR.OldValue END
     FROM 
          #Result R
     JOIN #TempResult TR ON R.COLUMN_NAME = TR.ColumnsName;

END;               
       FETCH NEXT FROM dbCursor INTO @ColumnName;	   
END;
CLOSE dbCursor;
DEALLOCATE dbCursor;
SELECT  
     COLUMN_NAME AS ColumnName, 
	 CASE WHEN OldValue = '' THEN 'N/A' ELSE ISNULL(OldValue, 'N/A') END AS [From],
	 CASE WHEN NewValue = '' THEN 'N/A' ELSE ISNULL(NewValue,'N/A') END AS [To]
FROM #Result WHERE COLUMN_NAME is not null;
DROP TABLE #Result;
DROP TABLE #TempResult;
END;
