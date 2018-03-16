DECLARE @TEMP TABLE(ID INT, [VALUE] NVARCHAR(30))
INSERT INTO @TEMP VALUES(1 ,  'MAZ')
INSERT INTO @TEMP VALUES(1 ,   'HON')
INSERT INTO @TEMP VALUES(1 ,   'FOR')
INSERT INTO @TEMP VALUES(2  ,  'JEEP')
INSERT INTO @TEMP VALUES(2 ,   'CHE')
INSERT INTO @TEMP VALUES(3 ,   'NIS')
INSERT INTO @TEMP VALUES(4 ,   'GMC')
INSERT INTO @TEMP VALUES(4 ,   'ACC')
INSERT INTO @TEMP VALUES(4 ,   'LEX')


--------------------WITH STUFF FUNCTION
SELECT [id], 
       Stuff((SELECT ',' + [VALUE] 
              FROM   @TEMP 
              WHERE  [id] = a.[id] 
              FOR xml path('')), 1, 1, '') [VALUE]
FROM   @TEMP a 
GROUP  BY  [id]

---------------------WITHOUT STUFF FUNCTION
SELECT [id],RIGHT([VALUE],LEN([VALUE])-1) AS [VALUE] FROM (
	SELECT [id],(SELECT ',' + [VALUE] FROM @TEMP 
				  WHERE  [id] = a.[id] FOR xml path('')
				 ) [VALUE]
	FROM   @TEMP a 
	GROUP  BY  [id]
) X
