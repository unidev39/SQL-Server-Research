SELECT
     t.name AS TableName
    ,c.name AS ColumnName
    ,c.column_id
    ,CONCAT (UPPER(cc.data_type)
        ,CASE 
            WHEN cc.CHARACTER_MAXIMUM_LENGTH IS NOT NULL
                THEN CONCAT (' (', case when cc.CHARACTER_MAXIMUM_LENGTH = -1 then 'Max' else  cast(cc.CHARACTER_MAXIMUM_LENGTH AS VARCHAR) end ,')')
            WHEN cc.DATA_TYPE = 'decimal'
                THEN CONCAT (' (',cc.NUMERIC_PRECISION,',',cc.NUMERIC_SCALE,')')
            ELSE ''
            END
        ) AS DataType
FROM sys.tables t INNER JOIN sys.all_columns c 
ON (t.object_id = c.object_id)
INNER JOIN INFORMATION_SCHEMA.COLUMNS cc 
ON (cc.COLUMN_NAME = c.name AND cc.TABLE_NAME = t.name)
ORDER BY
    1,3
