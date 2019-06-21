WITH test
AS
(
 select '{ "ID" : "0000000000000001", "Branch" : "Nepal", "OfficeName" : "EightSquare", "DateOfJoin" : "2019-06-01T00:00:05+0800", "ReferenceID" : "5cf14f801ef63100019d6bb3"}' JD_Reference
)
SELECT 
       JD_Reference,
       CHARINDEX('"officename" :',JD_Reference) instr,
       CASE
           WHEN CHARINDEX('"officename" :', JD_Reference) = 0 THEN NULL
       ELSE SUBSTRING(JD_Reference, CHARINDEX('"', JD_Reference, CHARINDEX('"officename" :', JD_Reference)+LEN('"officename" :'))+1, CHARINDEX('"', JD_Reference, CHARINDEX('"', JD_Reference, CHARINDEX('"officename" :', JD_Reference)+LEN('"officename" :'))+1)-CHARINDEX('"', JD_Reference, CHARINDEX('"officename" :', JD_Reference)+LEN('"officename" :'))-1)
       END AS officename
FROM 
    test;
/*
JD_Reference                                                                                                                                                          instr officename
--------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----- -----------
{ "ID" : "0000000000000001", "Branch" : "Nepal", "OfficeName" : "EightSquare", "DateOfJoin" : "2019-06-01T00:00:05+0800", "ReferenceID" : "5cf14f801ef63100019d6bb3"} 50    EightSquare
*/