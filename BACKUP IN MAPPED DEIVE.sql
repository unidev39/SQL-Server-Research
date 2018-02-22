
--BACKUP IN MAPPED DRIVE

EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell',1
GO
RECONFIGURE
GO

--configure map drive as backup location
exec xp_cmdshell
'net use Z: \\192.168.19.1\VirtualBox\TLogBackUp /user:"Eight Square" 8Square@'

"Eight Square"  ==> Username
8Square ==> Password

BEGIN 
declare @filename varchar(255)
set @filename = 'Z:\eForexDB_' +  REPLACE(CONVERT(VARCHAR(200),GETDATE(),121),':','-') + '.bak'
backup database eForexDB 
to disk = @filename 
END


CREATE PROC spDatabaseBackup
AS
BEGIN 
declare @filename varchar(255)
set @filename = 'Z:\eForexDB_' +  REPLACE(CONVERT(VARCHAR(200),GETDATE(),121),':','-') + '.bak'
backup database eForexDB 
to disk = @filename 
END

exec spDatabaseBackup


CREATE PROCEDURE spDeleteOldBackup
AS 
BEGIN
     DECLARE @DELETE_DATE      NVARCHAR(50),
	         @DELETE_DATE_TIME DATETIME;
			 
	 SET @DELETE_DATE_TIME = DATEADD(DAY, -10, GETDATE())
	 SET @DELETE_DATE = (SELECT ( REPLACE( CONVERT( NVARCHAR, @DELETE_DATE_TIME, 111), '/', '-') + 'T' + CONVERT( NVARCHAR, @DELETE_DATE_TIME, 108)))
	 EXECUTE xp_delete_file 0,N'Z:\',N'BAK',@DELETE_DATE,1
END;

EXEC spDeleteOldBackup;

