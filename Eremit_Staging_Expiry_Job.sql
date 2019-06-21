USE msdb
GO

-- To Create a Procedure to Scheduled New job
DROP PROCEDURE [dbo].[sp_add_job_test];

CREATE PROCEDURE [dbo].[sp_add_job_test]
(
  @job        nvarchar(128),
  @mycommand  nvarchar(max), 
  @servername nvarchar(28),
  @startdate  nvarchar(8),
  @starttime  nvarchar(8)
)
AS
BEGIN
     --Add a job
     EXEC [msdb].[dbo].[sp_add_job] 
     @job_name = @job;

     --Add a job step named process step. This step runs the stored procedure
     EXEC [msdb].[dbo].[sp_add_jobstep]
     @job_name = @job,
     @step_name = N'process step',
     @subsystem = N'TSQL',
     @command = @mycommand

     --Schedule the job at a specified date and time
     EXEC [msdb].[dbo].[sp_add_jobschedule] @job_name = @job,
     @name = 'MySchedule',
     @freq_type=1,
     @active_start_date = @startdate,
     @active_start_time = @starttime

     -- Add the job to the SQL Server Server
     EXEC [msdb].[dbo].sp_add_jobserver
     @job_name =  @job,
     @server_name = @servername
END;
GO

USE [EightSquare]
GO

-- To Create a Table to test the triggring event(pass/fail)
DROP TABLE [EightSquare].[dbo].[tbl_scheduler_job_process];

CREATE TABLE [EightSquare].[dbo].[tbl_scheduler_job_process]
(
 c1 int
);

-- To Create a Procedure to Populated the data into Table
DROP PROCEDURE [sp_process];

CREATE PROCEDURE [sp_process]
AS  
BEGIN
    INSERT INTO [EightSquare].[dbo].[tbl_scheduler_job_process]
    VALUES(1);
END;
GO

-- To Create table that holds the Record
DROP TABLE [EightSquare].[dbo].[tbl_scheduler_job];

CREATE TABLE [EightSquare].[dbo].[tbl_scheduler_job]
(
 c1 NVARCHAR(100),
 c2 DATETIME
); 

-- To Create a Trigger When Insert or Update event occured to scheduled a new job and drop raned jobs
DROP TRIGGER [dbo].tr_scheduler_job_test;

CREATE TRIGGER tr_scheduler_job_test
ON [EightSquare].[dbo].[tbl_scheduler_job]
FOR INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    DECLARE
          @job_name     VARCHAR(30),
          @startdate    VARCHAR(8),
          @starttime    VARCHAR(8)
    BEGIN 
        SELECT 
             @job_name  = CONCAT('schjob_',d.c1),
             @startdate = CONVERT(VARCHAR(8), d.c2, 112),
             @starttime = REPLACE(CONVERT(VARCHAR(8), d.c2, 108),':','')
        FROM [EightSquare].[dbo].[tbl_scheduler_job] d JOIN inserted i ON i.C1 = d.C1 
        BEGIN
           BEGIN TRY
                 EXEC [msdb].[dbo].[sp_delete_job] @job_name = @job_name; 
           END TRY
           BEGIN CATCH
               BEGIN TRANSACTION tran_1
               COMMIT TRANSACTION tran_1;
               --select null
           END CATCH 
           BEGIN
               EXEC [msdb].[dbo].[sp_add_job_test]
               @job = @job_name,
               @mycommand = '[EightSquare].[dbo].[sp_process]',
               @servername=@@Servername,
               @startdate = @startdate,
               @starttime = @starttime
           END
        END;
    BEGIN
        SET @job_name = LEFT(@job_name,7);
        DECLARE cursordb CURSOR FORWARD_ONLY STATIC
                         FOR  
                         SELECT DISTINCT sj.name
                         FROM msdb.dbo.sysjobs sj
                         JOIN msdb.dbo.sysjobhistory sh
                         ON sj.job_id = sh.job_id
                         WHERE sj.name like @job_name+'%' and sh.run_status =1;
        DECLARE @name VARCHAR(100) 
        BEGIN
            OPEN cursordb  
            FETCH NEXT FROM cursordb INTO @name
            WHILE @@FETCH_STATUS = 0  
               BEGIN 
                  EXEC [msdb].[dbo].[sp_delete_job] @job_name = @name; 
                  FETCH NEXT FROM cursordb INTO @name
               END;
        CLOSE cursordb;
        DEALLOCATE cursordb; 
        END;
    END;
    END;
END;
GO

-- Verification Script --
INSERT INTO [EightSquare].[dbo].[tbl_scheduler_job]
VALUES(3,GETDATE());

TRUNCATE TABLE [EightSquare].[dbo].[tbl_scheduler_job]

SELECT 
     CONCAT('schjob_',c1)                         job_name,
     CONVERT(VARCHAR(8), c2, 112)                 startdate,
     REPLACE(CONVERT(VARCHAR(8), c2, 108),':','') starttime
FROM [EightSquare].[dbo].[tbl_scheduler_job]
ORDER BY 1 DESC;

UPDATE [EightSquare].[dbo].[tbl_scheduler_job]
SET c1 = 4
WHERE c1 = 0;

