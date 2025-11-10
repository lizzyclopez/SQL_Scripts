select * from piv_reports..lkProgram order by ProgramID

--delete from piv_reports..lkProgram where ProgramID = '5147'

-- Identify current value of identity column 
DBCC CHECKIDENT(lkProgram, NORESEED)

-- Query used to reset identity column value 
DBCC CHECKIDENT(lkProgram, RESEED, 5142)

