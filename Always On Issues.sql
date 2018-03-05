
--Checking for compatibility of the database file locations on the server instance that hosts secondary replica WIN-KOB3V8MHTBK\VMSQLSERVER (Microsoft.SqlServer.Management.HadrModel)

--Wizard looks ta the exact same folder path. Here is the query to find the exact path

SELECT DB_NAME(database_id), physical_name FROM SYS.MASTER_FILES
