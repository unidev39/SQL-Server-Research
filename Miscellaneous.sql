Shrink Log file size of SQL SERVER 

Syntax:
DBCC SHRINKFILE(LogFile_LogicalName,size in MB to Shrink);

Eg:

DBCC SHRINKFILE(EightSquare_log,10);
