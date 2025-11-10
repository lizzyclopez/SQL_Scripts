select * from msps_Import..log where ts >= convert(char(8),getdate(),112) and text like '%Ended%' order by ts
--select * from msps_Import..log where ts >= '2010-04-05 17:00' and text like '%Ended%' --and ts <= '2010-04-0506:00' order by ts

------------------- RUN CLEANUP JOB -----------------
--exec MSPSCleanUpDataCO
--exec MSPSCleanUpDataTAIU

select t.ProjectUID, t.TaskUID, t.Projectname, t.TaskName, t.TaskIndex, t.TaskOutlineNumber, tt.TaskText11 
from msps_Import..CO_Task t join msps_Import..CO_Task_Text tt on t.taskuid = tt.taskuid
where t.ProjectUID = 'AD43A7A2-52D5-4F45-B9E3-0A43A9116FB5'
--and t.TaskOutlineNumber = '0' 
--and tt.tasktext11 is not null 
--and (tt.tasktext12 is null or rtrim(tt.tasktext12) = '')

-----------------------------------------------------------------------------------------------------------------------

---------------------LOAD MANUAL TIME (DISCONTINUED) ------------------------
--exec xp_cmdshell 'dtexec /f "g:\Applications\PIV_Transfer\SSISPackages\SSIS Package - Import Manual Data.dtsx"'
---------------------LOAD SAP FILE (DISCONTINUED) ---------------------
--exec xp_cmdshell 'dtexec /f "g:\Applications\PIV_Transfer\SSISPackages\SSIS Package - Import SAP data.dtsx"'
----------------- LOAD FOT & FLIGHT PLANNING FILE (DISCONTINUED) ------------------------
--exec xp_cmdshell 'dtexec /f "g:\Applications\PIV_Transfer\SSISPackages\SSIS Package - Import SAP-FOT Data.dtsx"'
----------------- LOAD SHARES FILE (DISCONTINUED) ------------------------
--exec xp_cmdshell 'dtexec /f "g:\Applications\PIV_Transfer\SSISPackages\SSIS Package - Import SAP-SHARES Data.dtsx"'
----------------- 1. LOAD COMPASS CATW FILE ------------------------
exec xp_cmdshell 'dtexec /f "g:\Applications\PIV_Transfer\SSISPackages\SSIS Package - Import COMPASS Data.dtsx"'

----------------- 2. MOVE DATA TO R2_Import..ResourceDetails TABLE ------------------------
-- Delete all data in ResourceDetails table.
truncate table R2_Import..ResourceDetails	
-- Move COMPASS data to ResourceDetails table.
INSERT INTO R2_Import..ResourceDetails (Name, IdNumber, WorkDate, Hours, ExtProjectTask, ProjectName, TaskName, AAType, ProjectNumber, TaskNumber, LastUpdDate)
SELECT LTRIM(RIGHT(name,CHARINDEX(' ', REVERSE(name)+' '))) + ',' + RTRIM( LEFT(name,LEN(name) - LEN( LTRIM(RIGHT(name,CHARINDEX(' ', REVERSE(name)+' '))) ))) AS NAME, IdNumber, WorkDate, Hours, ExtProjectTask, ProjectName, TaskName, AAType, NULL, NULL, getdate() 
FROM R2_Import..COMPASS_ResourceDetails Where ExtProjectTask <> '#'

----------------- 3. RUN RESOURCE CLEANUP STORED PROCEDURE THAT CLEANS R2_Import..ResourceDetails TABLE ------------------------ 
--Run the Cleanup Stored Procedure
Insert Into R2_Import..Log values ( getdate(), 'S', 'Resource Cleanup', 'Started resource cleanup data at ' + convert(varchar(25), getdate(),120) )
exec ResourceCleanUpData
Insert Into R2_Import..Log values ( getdate(), 'S', 'Resource Cleanup', 'Ended resource cleanup data at ' + convert(varchar(25), getdate(),120) )

----------------- 4. MOVE MANUAL HOURS ------------------------ 
--Clean table by removing records whose hours have been set to zero.
delete from R2_Import..ResourceDetails_Manual where hours = '0.00'
--select * from R2_Import..ResourceDetails_Manual order by name

--Load manual data into R2_Import..ResourceDetails table.
declare @BillingYYYYMM as varchar(6)
set @BillingYYYYMM = (select top 1 convert(varchar(6),workdate,112) from R2_Import..ResourceDetails)
INSERT INTO R2_Import..ResourceDetails (Name, IdNumber, WorkDate, Hours, ExtProjectTask, ProjectName, TaskName, AAType, ProjectNumber, TaskNumber, LastUpdDate)
SELECT Name, IdNumber, WorkDate, Hours, ExtProjectTask, ProjectName, TaskName, AAType, ProjectNumber, TaskNumber, getdate() FROM R2_Import..ResourceDetails_Manual where convert(varchar(6),workdate,112) = @BillingYYYYMM
Insert Into R2_Import..Log values ( getdate(), 'S', 'Manual Hours', 'Ended moving manual hours at ' + convert(varchar(25), getdate(),120) )

--Set the AAType to a billable code.
update R2_Import..ResourceDetails set AAType = '2000' where AAType <> '2000'

--Update or delete hours, per Kathy Anderson.
--update R2_Import..ResourceDetails set hours = '0.00' where ExtProjectTask = 'ES-268349-22106296'  --Delete all hours from PSS-I Program Support -
--update R2_Import..ResourceDetails set hours = '0.00' where ExtProjectTask = 'ES-294458-21409321' and IdNumber = '81066939' --Delete all 56673 Delivery Oversite for DOUGLAS, IRENE

----------------- 5. INSERT WORKDATE ------------------------ 
Declare @month varchar(2), @year varchar(4), @date varchar(20), @FirstDate datetime, @EndDate datetime

--Select the month and year from the SAP Resource Details table.
select @month = month(workdate), @year = year(workdate) from R2_import..ResourceDetails WHERE WorkDate is not NULL
set @date = @month + '/1/' + @year
--Set the First day of the month.
select @FirstDate = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@date)-1),@date),101) 
--Set the Last day of the month.
select @EndDate = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,@date))),DATEADD(mm,1,@date)),101) 

--Delete all dates from the Workdate table.
Delete from R2_import..ResourceWorkdate

--Insert the workdate into table for current billing month.
While @FirstDate <= @EndDate
  	Begin
	Insert Into R2_import..ResourceWorkdate Values(@FirstDate)
	Set @FirstDate = DateAdd(d,1,@FirstDate)
	End 

--select * from R2_Import..ResourceWorkdate

-------------- 6. PRE-PROCESS DATA (run in R2_Import) --------------------
exec PreProcess_All_Tables	
insert into R2_Import..log ( StatusCode, ProcessName, Text) values( 'S', 'PreProcess All Tables',  'PreProcess_All_Tables completed successfully at '+convert(varchar(25), getdate(),120))	
exec PPMC_PreProcess
insert into R2_Import..log ( StatusCode, ProcessName, Text) values( 'S', 'PreProcess PPMC Data',  'PPMC_PreProcess completed successfully at '+convert(varchar(25), getdate(),120))	

-------------- 7. PROCESS LOAD DATA FOR REPORTS DATABASE (run in R2_Import) --------------------
exec Process_Project
insert into R2_Import..log ( StatusCode, ProcessName, Text) values( 'S', 'Process Project',  'Process_Project completed successfully at '+convert(varchar(25), getdate(),120))	

exec Process_Task
insert into R2_Import..log ( StatusCode, ProcessName, Text) values( 'S', 'Process Task',  'Process_Task completed successfully at '+convert(varchar(25), getdate(),120))	

exec Process_ResourceDetails
insert into R2_Import..log ( StatusCode, ProcessName, Text) values( 'S', 'Process ResourceDetails',  'Process_ResourceDetails completed successfully at '+convert(varchar(25), getdate(),120))

exec Process_ResourceDetails_NPT
insert into R2_Import..log ( StatusCode, ProcessName, Text) values( 'S', 'Process ResourceDetails_NPT',  'Process_ResourceDetails_NPT completed successfully at '+convert(varchar(25), getdate(),120))

-------------- 8. PRE-BUILD REPORTS (run in R2_Reports) --------------------
exec Pre_Build_Get_AFE_Resource_Detail
insert into R2_Import..log ( StatusCode, ProcessName, Text) values( 'S', 'Pre-build Reports ',  'Pre_Build_Get_AFE_Resource_Detail completed successfully at '+convert(varchar(25), getdate(),120))	
	
exec Pre_Build_Solution_Centre_Data	
insert into R2_Import..log ( StatusCode, ProcessName, Text) values( 'S', 'Pre-build Reports ',  'Pre_Build_Solution_Centre_Data completed successfully at '+convert(varchar(25), getdate(),120))	
	
exec Load_YTD_Tables	
insert into R2_Import..log ( StatusCode, ProcessName, Text) values( 'S', 'Pre-build Reports ',  'Load_YTD_Tables completed successfully at '+convert(varchar(25), getdate(),120))	

-------------- 9. SEND LOAD NOTIFICATION --------------------
exec Send_Notification @AM_PM_Indicator = 'AM'

-- Keep only 5 days of log
delete from R2_Import..Log where TS < dateadd(dd, -5, getdate())

insert into R2_Import..log ( StatusCode, ProcessName, Text) values( 'S', 'Send Notification',  'Load complete - all steps above ended successfully.')	
	