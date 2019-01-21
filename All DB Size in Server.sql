SELECT	
	 DB_NAME(database_id) AS DBName,
	 Name AS Logical_Name,
	 Physical_Name,
	 (size*8)/1024 SizeMB, 
	 (size*8)/(1024*1024) SizeGB
FROM sys.master_files

