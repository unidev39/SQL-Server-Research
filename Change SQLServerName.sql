-- Check the ServerName.

SELECT  HOST_NAME() AS 'host_name()',
@@servername AS 'ServerName\InstanceName',
SERVERPROPERTY('servername') AS 'ServerName',
SERVERPROPERTY('machinename') AS 'Windows_Name',
SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS 'NetBIOS_Name',
SERVERPROPERTY('instanceName') AS 'InstanceName',
SERVERPROPERTY('IsClustered') AS 'IsClustered'



--Syntax:
EXEC sp_DROPSERVER 'oldservername'
EXEC sp_ADDSERVER 'newservername', 'local'


--Example:

EXEC sp_DROPSERVER 'WIN-KOB3V8MHTBK\VMSQLSERVER';
EXEC sp_ADDSERVER 'WIN-KOB3V8MHTBK', 'local';

--Always Restart the SqlServer Services after the changes.
