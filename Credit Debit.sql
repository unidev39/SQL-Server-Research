drop table TestTable

create table TestTable
(
Id int, 
Debit int, 
Credit int
)

insert into TestTable
select 1 ,0,0 union all
select 2 , 200,0 union all 
select 3, 50,0 union all 
select 4, 0,5 union all 
select 5, 0,50 

select * from TestTable

declare @OpeningBal int = 1000

;WITH tempDebitCredit AS (
	SELECT a.id, a.debit, a.credit,   case when a.id = 1 then @OpeningBal else  a.Debit - a.Credit end 'diff'
	FROM TestTable a
	where a.id >0
)
SELECT a.id, a.Debit, a.Credit,    SUM(b.diff) 'Balance'
FROM   tempDebitCredit a,
       tempDebitCredit b
WHERE b.id <= a.id
GROUP BY a.id,a.Debit, a.Credit
