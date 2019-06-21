-- Gives Job Name, Schedule AND Next run time

SELECT
     s.name AS JobName,
     ss.name AS ScheduleName,
     CASE(ss.freq_type)
          WHEN 1  THEN 'Once'
          WHEN 4  THEN 'Daily'
          WHEN 8  THEN (CASE WHEN (ss.freq_recurrence_factor > 1) THEN  'Every ' + CONVERT(VARCHAR(3),ss.freq_recurrence_factor) + ' Weeks'  else 'Weekly'  end)
          WHEN 16 THEN (CASE WHEN (ss.freq_recurrence_factor > 1) THEN  'Every ' + CONVERT(VARCHAR(3),ss.freq_recurrence_factor) + ' Months' else 'Monthly' end)
          WHEN 32 THEN 'Every ' + CONVERT(VARCHAR(3),ss.freq_recurrence_factor) + ' Months' -- RELATIVE
          WHEN 64 THEN 'SQL Startup'
          WHEN 128 THEN 'SQL Idle'
          ELSE '??'
     END AS Frequency,  
     CASE
        WHEN (freq_type = 1)                       THEN 'One time only'
        WHEN (freq_type = 4 AND freq_interval = 1) THEN 'Every Day'
        WHEN (freq_type = 4 AND freq_interval > 1) THEN 'Every ' + CONVERT(VARCHAR(10),freq_interval) + ' Days'
        WHEN (freq_type = 8) THEN (SELECT 'Weekly Schedule' = MIN(D1+D2+D3+D4+D5+D6+D7)
                                    FROM (SELECT
                                               ss.schedule_id,
                                               freq_interval, 
                                               'D1' = CASE WHEN (freq_interval & 1  <> 0) THEN 'Sun '  ELSE '' END,
                                               'D2' = CASE WHEN (freq_interval & 2  <> 0) THEN 'Mon '  ELSE '' END,
                                               'D3' = CASE WHEN (freq_interval & 4  <> 0) THEN 'Tue '  ELSE '' END,
                                               'D4' = CASE WHEN (freq_interval & 8  <> 0) THEN 'Wed '  ELSE '' END,
                                               'D5' = CASE WHEN (freq_interval & 16 <> 0) THEN 'Thu '  ELSE '' END,
                                               'D6' = CASE WHEN (freq_interval & 32 <> 0) THEN 'Fri '  ELSE '' END,
                                               'D7' = CASE WHEN (freq_interval & 64 <> 0) THEN 'Sat '  ELSE '' END
                                          FROM msdb..sysschedules ss
                                          WHERE freq_type = 8
                                        ) AS F
                                    WHERE schedule_id = SJ.schedule_id
                                )
        WHEN (freq_type = 16) THEN 'Day ' + CONVERT(VARCHAR(2),freq_interval) 
        WHEN (freq_type = 32) THEN (SELECT  freq_rel + WDAY 
                                    FROM (SELECT ss.schedule_id,
                                                       'freq_rel' = CASE(freq_relative_interval)
                                                                       WHEN 1 THEN 'First'
                                                                       WHEN 2 THEN 'Second'
                                                                       WHEN 4 THEN 'Third'
                                                                       WHEN 8 THEN 'Fourth'
                                                                       WHEN 16 THEN 'Last'
                                                                    ELSE '??'
                                                                    END,
                                                       'WDAY' = CASE (freq_interval)
                                                                   WHEN 1 THEN ' Sun'
                                                                   WHEN 2 THEN ' Mon'
                                                                   WHEN 3 THEN ' Tue'
                                                                   WHEN 4 THEN ' Wed'
                                                                   WHEN 5 THEN ' Thu'
                                                                   WHEN 6 THEN ' Fri'
                                                                   WHEN 7 THEN ' Sat'
                                                                   WHEN 8 THEN ' Day'
                                                                   WHEN 9 THEN ' Weekday'
                                                                   WHEN 10 THEN ' Weekend'
                                                                ELSE '??'
                                                                END
                                         FROM msdb..sysschedules SS
                                         WHERE ss.freq_type = 32
                                         ) AS WS 
                                    WHERE Ws.schedule_id = ss.schedule_id
                                    ) 
     END AS Interval,
     CASE (freq_subday_type)
         WHEN 1 THEN   LEFT(STUFF((STUFF((REPLICATE('0', 6 - LEN(active_start_time)))+ CONVERT(VARCHAR(6),active_start_time),3,0,':')),6,0,':'),8)
         WHEN 2 THEN 'Every ' + CONVERT(VARCHAR(10),freq_subday_interval) + ' seconds'
         WHEN 4 THEN 'Every ' + CONVERT(VARCHAR(10),freq_subday_interval) + ' minutes'
         WHEN 8 THEN 'Every ' + CONVERT(VARCHAR(10),freq_subday_interval) + ' hours'
         ELSE '??'
     END AS [Time],
     CASE SJ.next_run_date
         WHEN 0 THEN CAST('n/a' AS CHAR(10))
         ELSE CONVERT(char(10), CONVERT(datetime, CONVERT(CHAR(8),SJ.next_run_date)),120)  + ' ' + LEFT(STUFF((STUFF((REPLICATE('0', 6 - len(next_run_time)))+ CONVERT(VARCHAR(6),next_run_time),3,0,':')),6,0,':'),8)
     END AS NextRunTime
FROM msdb.dbo.sysjobs S
LEFT JOIN msdb.dbo.sysjobschedules SJ ON s.job_id = SJ.job_id  
LEFT JOIN msdb.dbo.sysschedules SS ON ss.schedule_id = SJ.schedule_id
ORDER BY s.name;