--Make sure the DB is set to SIMPLE before running these.

USE ComputeServices;
GO
DBCC SHRINKFILE (ComputeServices_Log, 1);
GO


USE R2_Import;
GO
DBCC SHRINKFILE (R2_Import_Log, 1);
GO




DBCC SHRINKDATABASE(tempdb, 10) 
