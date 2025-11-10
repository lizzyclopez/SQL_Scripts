USE [msdb]
GO

/****** Object:  Job [08:20 R2_Morning Load Process]    Script Date: 7/27/2018 4:49:53 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [R2_Daily_Job]    Script Date: 7/27/2018 4:49:53 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'R2_Daily_Job' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'R2_Daily_Job'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'08:20 R2_Morning Load Process', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'R2 Load Process:
1. Move Data to ResourceDetails
2. Run Resource Cleanup
3. Move Manual Hours
4. Insert Workdate
5. PreProcess Data
6. Process Data
7. Prebuild Reports
8. Send Load Notification
9. Send Failure Notificaiton - only if job fails', 
		@category_name=N'R2_Daily_Job', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Move Data to ResourceDetails]    Script Date: 7/27/2018 4:49:53 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Move Data to ResourceDetails', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Delete all data in ResourceDetails table.
truncate table R2_Import..ResourceDetails
	
-- Move COMPASS data to ResourceDetails table.
INSERT INTO R2_Import..ResourceDetails (Name, IdNumber, WorkDate, Hours, ExtProjectTask, ProjectName, TaskName, AAType, ProjectNumber, TaskNumber, LastUpdDate)
SELECT LTRIM(RIGHT(name,CHARINDEX('' '', REVERSE(name)+'' ''))) + '','' + RTRIM( LEFT(name,LEN(name) - LEN( LTRIM(RIGHT(name,CHARINDEX('' '', REVERSE(name)+'' ''))) ))) AS NAME, IdNumber, WorkDate, Hours, ExtProjectTask, ProjectName, TaskName, AAType, NULL, NULL, getdate() 
FROM R2_Import..COMPASS_ResourceDetails Where ExtProjectTask <> ''#''
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run ResourceCleanUpData]    Script Date: 7/27/2018 4:49:53 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run ResourceCleanUpData', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Run the Cleanup Stored Procedure
Insert Into R2_Import..Log values ( getdate(), ''S'', ''Resource Cleanup'', ''Started resource cleanup data at '' + convert(varchar(25), getdate(),120) )
exec ResourceCleanUpData
Insert Into R2_Import..Log values ( getdate(), ''S'', ''Resource Cleanup'', ''Ended resource cleanup data at '' + convert(varchar(25), getdate(),120) )
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Move Manual Hours to ResourceDetails]    Script Date: 7/27/2018 4:49:53 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Move Manual Hours to ResourceDetails', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Clean table by removing records whose hours have been set to zero.
delete from R2_Import..ResourceDetails_Manual where hours = ''0.00''

--Load manual data into ResourceDetails table.
declare @BillingYYYYMM as varchar(6)
set @BillingYYYYMM = (select top 1 convert(varchar(6),workdate,112) from R2_Import..ResourceDetails)
INSERT INTO R2_Import..ResourceDetails (Name, IdNumber, WorkDate, Hours, ExtProjectTask, ProjectName, TaskName, AAType, ProjectNumber, TaskNumber, LastUpdDate)
SELECT Name, IdNumber, WorkDate, Hours, ExtProjectTask, ProjectName, TaskName, AAType, ProjectNumber, TaskNumber, getdate() FROM R2_Import..ResourceDetails_Manual where convert(varchar(6),workdate,112) = @BillingYYYYMM
Insert Into R2_Import..Log values ( getdate(), ''S'', ''Manual Hours'', ''Ended moving manual hours at '' + convert(varchar(25), getdate(),120) )

--Set the AAType to a billable code
update R2_Import..ResourceDetails set AAType = ''2000'' where AAType <> ''2000''

--Delete hours, per Kathy Anderson.
--update R2_Import..ResourceDetails set hours = ''0.00'' where ExtProjectTask = ''ES-268349-22106296''  --Delete from 62605_1 Architecture Foundation Program Support - HPE
--update R2_Import..ResourceDetails set hours = ''0.00'' where ExtProjectTask = ''ES-299215-28595317'' and IdNumber = ''82057674'' and Workdate < ''2017-11-16''
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Insert Workdate for Billing Month into ResourceWorkdate Table]    Script Date: 7/27/2018 4:49:53 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Insert Workdate for Billing Month into ResourceWorkdate Table', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @month varchar(2), @year varchar(4), @date varchar(20), @FirstDate datetime, @EndDate datetime

--Select the month and year from the SAP Resource Details table.
select @month = month(workdate), @year = year(workdate) from R2_import..ResourceDetails WHERE WorkDate is not NULL
set @date = @month + ''/1/'' + @year

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
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [PreProcess Data]    Script Date: 7/27/2018 4:49:53 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'PreProcess Data', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--- Check if previous step ended Successfully in the past hour
if exists ( select * from R2_Import..Log where TS > dateadd(hh, -1, getdate()) and Text like ''%Ended moving manual hours%'' )
	begin
	exec PreProcess_All_Tables	
	insert into R2_Import..log ( StatusCode, ProcessName, Text) values( ''S'', ''PreProcess All Tables'',  ''PreProcess_All_Tables completed successfully at ''+convert(varchar(25), getdate(),120))	

	exec PPMC_PreProcess
	insert into R2_Import..log ( StatusCode, ProcessName, Text) values( ''S'', ''PreProcess PPMC Data'',  ''PPMC_PreProcess completed successfully at ''+convert(varchar(25), getdate(),120))	
	end
else
	begin
	Insert Into R2_Import..Log values ( getdate(), ''E'', ''PreProcess All Tables'', ''PreProcess_ALL_Tables Failed at '' + convert(varchar(25), getdate(),120) )

	--Send email
	declare  @profile_name varchar(255) 
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = ''R2 131C PreProcess_All_Tables Failed!'', @body = ''The PreProcess_All_Tables process failed!''
	end
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Process Data for Reports Database]    Script Date: 7/27/2018 4:49:53 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Process Data for Reports Database', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'if exists ( select * from R2_Import..Log where TS > dateadd(hh, -1, getdate()) and Text like ''%PPMC_PreProcess completed successfully%'' )
	begin
	exec Process_Project
	insert into R2_Import..log ( StatusCode, ProcessName, Text) values( ''S'', ''Process Project'',  ''Process_Project completed successfully at ''+convert(varchar(25), getdate(),120))	

	exec Process_Task
	insert into R2_Import..log ( StatusCode, ProcessName, Text) values( ''S'', ''Process Task'',  ''Process_Task completed successfully at ''+convert(varchar(25), getdate(),120))	

	exec Process_ResourceDetails
	insert into R2_Import..log ( StatusCode, ProcessName, Text) values( ''S'', ''Process ResourceDetails'',  ''Process_ResourceDetails completed successfully at ''+convert(varchar(25), getdate(),120))

	exec Process_ResourceDetails_NPT
	insert into R2_Import..log ( StatusCode, ProcessName, Text) values( ''S'', ''Process ResourceDetails_NPT'',  ''Process_ResourceDetails_NPT completed successfully at ''+convert(varchar(25), getdate(),120))
	end
else
	begin	
	Insert Into R2_Import..Log values ( getdate(), ''E'', ''Process Data'', ''Process Data Failed at '' + convert(varchar(25), getdate(),120))

	--Send email
	declare  @profile_name varchar(255) 
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = ''R2 131C Process Data Failed!'', @body = ''The Process job failed!''	
	end
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Prebuild Reports]    Script Date: 7/27/2018 4:49:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Prebuild Reports', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'if exists ( select * from R2_Import..Log where TS > dateadd(hh, -1, getdate()) and Text like ''%Process_ResourceDetails_NPT completed successfully%'' )
	begin
	exec Pre_Build_Get_AFE_Resource_Detail
	insert into R2_Import..log ( StatusCode, ProcessName, Text) values( ''S'', ''Pre-build Reports '',  ''Pre_Build_Get_AFE_Resource_Detail completed successfully at ''+convert(varchar(25), getdate(),120))	
	
	exec Pre_Build_Solution_Centre_Data	
	insert into R2_Import..log ( StatusCode, ProcessName, Text) values( ''S'', ''Pre-build Reports '',  ''Pre_Build_Solution_Centre_Data completed successfully at ''+convert(varchar(25), getdate(),120))	
	
	exec Load_YTD_Tables	
	insert into R2_Import..log ( StatusCode, ProcessName, Text) values( ''S'', ''Pre-build Reports '',  ''Load_YTD_Tables completed successfully at ''+convert(varchar(25), getdate(),120))	
	end
else
	begin	
	Insert Into R2_Import..Log values ( getdate(), ''E'', ''Prebuild Process'', ''Prebuild Reports Process Failed at '' + convert(varchar(25), getdate(),120))

	--Send email
	declare  @profile_name varchar(255) 
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = ''R2 131C Prebuild Reports Process Failed!'', @body = ''The Pebuild Reports Process job failed!''	
	end
', 
		@database_name=N'R2_Reports', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Load Notification]    Script Date: 7/27/2018 4:49:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Load Notification', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec Send_Notification @AM_PM_Indicator = ''AM''
insert into R2_Import..log ( StatusCode, ProcessName, Text) values( ''S'', ''Send Notification'',  ''Load complete - all steps above ended successfully.'')	

-- Keep only 5 days of log
delete from R2_Import..Log where TS < dateadd(dd, -5, getdate())
', 
		@database_name=N'R2_Reports', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Failure Notification]    Script Date: 7/27/2018 4:49:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Failure Notification', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=2, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Send email notifying of Failed job.
declare  @profile_name varchar(255) 

--set @profile_name = ''SQL_DBMail''  
exec msdb.dbo.sp_send_dbmail 
             	@recipients = ''lizzy.lopez@dxc.com'', 
                @subject = ''R2 AM Load Failed'', 
             	@body = ''The job that runs the morning load failed in 131C.'', 
	@profile_name = @profile_name, 
          	@body_format = ''TEXT'';
', 
		@database_name=N'R2_Reports', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'R2 Morning Load Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20150529, 
		@active_end_date=99991231, 
		@active_start_time=82000, 
		@active_end_time=235959, 
		@schedule_uid=N'15061ed2-17f2-44c8-b2a4-1d0a5a4a39f1'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


