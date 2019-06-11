DECLARE
 @database_name VARCHAR(30)   =  'EightSquare',
 @user_name     VARCHAR(30)   =  'User_EightSquare',
 @user_password NVARCHAR(30)  = N'',
 @user_type     VARCHAR(10)   =  'R',  --R,RW,APP
 @user_status   VARCHAR(10)   =  'D', --C => Master, --D => Master --A => @database_name
 @sql    NVARCHAR(MAX)

BEGIN
    IF (@user_status ='C') 
        BEGIN
            IF ((SELECT name FROM master.sys.server_principals where name = @user_name) IS NULL)
              BEGIN
                  SET @sql = 'CREATE LOGIN '+@user_name+' WITH PASSWORD = N'''+@user_password+'''';
                  EXEC ('USE '+@database_name+';' +@sql)
              END;
            SET @sql = 'CREATE USER '+@user_name+' FOR LOGIN '+@user_name;
            EXEC ('USE '+@database_name+';' +@sql)
            IF (@user_type = 'R')
                BEGIN
                    SET @sql = 'ALTER USER '+@user_name+' WITH DEFAULT_SCHEMA=[dbo]';
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'ALTER ROLE [db_datareader] ADD MEMBER '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'GRANT EXECUTE TO '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                END;
                IF (@user_type = 'RW')
                    BEGIN
                        SET @sql = 'ALTER USER '+@user_name+' WITH DEFAULT_SCHEMA=[dbo]';
                        EXEC ('USE '+@database_name+';' +@sql)
                        SET @sql = 'ALTER ROLE [db_datareader] ADD MEMBER '+@user_name;
                        EXEC ('USE '+@database_name+';' +@sql)
                        SET @sql = 'ALTER ROLE [db_datawriter] ADD MEMBER '+@user_name;
                        EXEC ('USE '+@database_name+';' +@sql)
                        SET @sql = 'REVOKE ALTER FROM '+@user_name;
                        EXEC ('USE '+@database_name+';' +@sql)
                        SET @sql = 'GRANT EXECUTE TO '+@user_name;
                        EXEC ('USE '+@database_name+';' +@sql)                          
                    END;
                IF (@user_type = 'APP')
                    BEGIN
                        SET @sql = 'ALTER USER '+@user_name+' WITH DEFAULT_SCHEMA=[dbo]';
                        EXEC ('USE '+@database_name+';' +@sql)
                        SET @sql = 'ALTER ROLE [db_datareader] ADD MEMBER '+@user_name;
                        EXEC ('USE '+@database_name+';' +@sql)
                        SET @sql = 'ALTER ROLE [db_datawriter] ADD MEMBER '+@user_name;
                        EXEC ('USE '+@database_name+';' +@sql)   
                        SET @sql = 'ALTER ROLE [db_ddladmin] ADD MEMBER '+@user_name;
                        EXEC ('USE '+@database_name+';' +@sql)
                        SET @sql = 'GRANT ALTER TO '+@user_name;
                        EXEC ('USE '+@database_name+';' +@sql)
                        SET @sql = 'GRANT EXECUTE TO '+@user_name;
                        EXEC ('USE '+@database_name+';' +@sql)       
                    END;
        END;
    IF (@user_status ='A')
        BEGIN
            IF (LEN(@user_password) >=1)
            BEGIN
                SET @sql = 'ALTER LOGIN '+@user_name+' WITH PASSWORD = N'''+@user_password+'''';
                EXEC ('USE '+@database_name+';' +@sql)
            END;
            IF (@user_type = 'R')
                BEGIN
                    SET @sql = 'ALTER USER '+@user_name+' WITH DEFAULT_SCHEMA=[dbo]';
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'ALTER ROLE [db_datawriter] DROP MEMBER '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'ALTER ROLE [db_ddladmin] DROP MEMBER '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'ALTER ROLE [db_datareader] ADD MEMBER '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'REVOKE ALTER FROM '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'GRANT EXECUTE TO '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                END;
            IF (@user_type = 'RW')
                BEGIN
                    SET @sql = 'ALTER USER '+@user_name+' WITH DEFAULT_SCHEMA=[dbo]';
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'ALTER ROLE [db_ddladmin] DROP MEMBER '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'ALTER ROLE [db_datareader] ADD MEMBER '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'ALTER ROLE [db_datawriter] ADD MEMBER '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'REVOKE ALTER FROM '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'GRANT EXECUTE TO '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                END;
            IF (@user_type = 'APP')
                BEGIN
                    SET @sql = 'ALTER USER '+@user_name+' WITH DEFAULT_SCHEMA=[dbo]';
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'ALTER ROLE [db_datareader] ADD MEMBER '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'ALTER ROLE [db_datawriter] ADD MEMBER '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                    SET @sql = 'ALTER ROLE [db_ddladmin] ADD MEMBER '+@user_name;
                    EXEC ('USE '+@database_name+';' +@sql)
                END;
        END;
    IF (@user_status ='D' and @user_name = (SELECT name FROM master.sys.server_principals where name = @user_name))
        BEGIN
            USE master
            BEGIN
                DECLARE @sqlverno INT;
                SET @sqlverno = cast(substring(CAST(Serverproperty('ProductVersion') AS VARCHAR(50)) ,0,charindex('.',CAST(Serverproperty('ProductVersion') AS VARCHAR(50)) ,0)) as int);
                
                IF @sqlverno >= 9 
                    IF OBJECT_ID('tempdb..#user_list') IS NOT NULL
                       DROP TABLE #user_list
                ELSE
                IF @sqlverno = 8
                BEGIN
                    IF OBJECT_ID('tempdb..#user_list') IS NOT NULL
                       DROP TABLE #user_list
                END
                
                CREATE TABLE #user_list (
                    dbname        SYSNAME,
                    username      SYSNAME
                )
                IF @sqlverno = 8
                BEGIN
                    INSERT INTO #user_list
                    EXEC sp_MSForEachdb
                    'SELECT
                          ''?''  AS dbname,
                          u.name AS username
                     FROM [?].dbo.sysUsers u LEFT JOIN ([?].dbo.sysMembers m JOIN [?].dbo.sysUsers r ON m.groupuid = r.uid)
                     ON m.memberuid = u.uid
                     LEFT JOIN dbo.sysLogins l
                     ON u.sid = l.sid
                     WHERE u.islogin = 1 OR u.isntname = 1 OR u.isntgroup = 1
                     ORDER BY u.name'
                END
                
                ELSE 
                IF @sqlverno >= 9
                BEGIN
                    INSERT INTO #user_list
                    EXEC sp_MSForEachdb
                    'SELECT
                          ''?''  AS dbname,
                          u.name AS username
                     FROM [?].sys.database_principals u LEFT JOIN ([?].sys.database_role_members m JOIN [?].sys.database_principals r ON m.role_principal_id = r.principal_id)
                     ON m.member_principal_id = u.principal_id
                     LEFT JOIN [?].sys.server_principals l
                     ON u.sid = l.sid
                     WHERE u.TYPE <> ''R''
                     ORDER BY u.name'
                END
            END
            BEGIN
                DECLARE db_userlist  CURSOR READ_ONLY
                                     FOR
                                     SELECT
                                          a.username,
                                          a.dbname  
                                     FROM #user_list a
                                     WHERE a.username = @user_name
                                     ORDER BY 2;
                DECLARE @username VARCHAR(30), @dbname VARCHAR(30);
                OPEN db_userlist
                FETCH NEXT FROM db_userlist INTO @username,@dbname
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    --To Kill the Sessions of User
                    IF OBJECT_ID('tempdb..#sp_who2') IS NOT NULL
                       DROP TABLE #sp_who2
                    CREATE TABLE #sp_who2
                    (
                     spid        INT,
                     status      VARCHAR(255),
                     login       VARCHAR(255),
                     hostname    VARCHAR(255),
                     blkby       VARCHAR(255),
                     dbname      VARCHAR(255),
                     command     VARCHAR(255),
                     cputime     INT,
                     diskio      INT,
                     lastbatch   VARCHAR(255),
                     programname VARCHAR(255),
                     spid2       INT,
                     requestid   INT
                    );
                    INSERT INTO #sp_who2 EXEC sp_who2
                    
                    DECLARE db_spid  CURSOR READ_ONLY
                                     FOR
                                     SELECT 'KILL '+CAST(spid AS VARCHAR(10)) spid
                                     FROM #sp_who2 
                                     WHERE [Login] = @username;
                    DECLARE @spid NVARCHAR(10)
                    BEGIN
                        OPEN db_spid
                        FETCH NEXT FROM db_spid INTO @spid
                        WHILE @@FETCH_STATUS = 0
                        BEGIN
                            EXEC (@spid)
                            FETCH NEXT FROM db_spid INTO @spid
                        END;   
                        CLOSE db_spid
                        DEALLOCATE db_spid
                    END;
                    SET @sql = 'DROP LOGIN '+@username
                    EXEC ('USE master;' + @sql)
                    SET @sql = 'DROP USER '+@username
                    EXEC ('USE '+@dbname+';' + @sql)
                    FETCH NEXT FROM db_userlist INTO @username,@dbname
                END;
                CLOSE db_userlist
                DEALLOCATE db_userlist
                DROP TABLE #user_list
            END;
        END;
    SET @sql = 'SELECT
                     rp.name AS DatabaseRoleName,
                     mp.name AS DatabaseUserName
                FROM sys.database_role_members rm
                INNER JOIN sys.database_principals rp ON rm.role_principal_id = rp.principal_id
                INNER JOIN sys.database_principals mp ON rm.member_principal_id = mp.principal_id
                WHERE mp.name = '''+@user_name+''''
    
    EXEC ('USE '+@database_name+' '+@sql);
END;