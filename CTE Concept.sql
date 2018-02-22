--A CTE must be followed by a single SELECT, INSERT, UPDATE, or DELETE statement that references some or all the CTE columns


-- For Double select from one CTE(Common Table Expression) is not possile
--for which we can using following methods.

--select * into TableName from (
--select 1 as RollNo, 'A' as Name union all
--select 2 as RollNo, 'B' as Name union all
--select 3 as RollNo, 'C' as Name ) l

-----------------***********----------------
-- Using two CTE 
-----------------***********----------------



BEGIN 
DECLARE @RecordCount int;

WITH CTE AS
(
   SELECT *
   FROM TableName
   
)
    Select @RecordCount = Count(*) from CTE

select @RecordCount as RecCount;

WITH CTE2 AS
(
   SELECT *
   FROM TableName   
)
select * from CTE2;
end;


--OR


-----------------***********----------------
--Using Temp Table
-----------------***********----------------


BEGIN 
DECLARE @RecordCount int;

drop table #Temp;

WITH CTE AS
(
   SELECT *
   FROM TableName
)
select * INTO #Temp from CTE;
select count(*) as RecCount from #Temp;
SELECT * FROM #Temp;
end;



BEGIN 

WITH CTE AS
(
   SELECT *
   FROM TableName   
)
select RollNo,Name from CTE
union all 
select COUNT(*) as RecCount, 'Total' as Total    from CTE;

END;