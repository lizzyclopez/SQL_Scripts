USE [msdb]
GO

/****** Object:  Job [21:00 R2_Update YTD Client Table - Mthly]    Script Date: 9/12/2018 7:25:15 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [R2_Daily_Job]    Script Date: 9/12/2018 7:25:15 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'R2_Daily_Job' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'R2_Daily_Job'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'21:00 R2_Update YTD Client Table - Mthly', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Monthly job to update the YTD Client Table', 
		@category_name=N'R2_Daily_Job', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run the Update_YTD_Client]    Script Date: 9/12/2018 7:25:15 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run the Update_YTD_Client', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Run stored procedure with lockin date = first date of current billing month.
declare @curyear  int
declare @curmonth int
declare @firstdayofmo varchar(10)

set @curyear = year(getdate())
set @curmonth = month(getdate())
--set @currmonth = 9
set @firstdayofmo = convert(varchar(4),@curyear)+''-''+convert(varchar(2),@curmonth)+''-01''

exec Update_YTD_Client @lockindate = @firstdayofmo, @SolutionCentreList= ''''''Southern California Solution Cen'''', ''''GCR - AD-MX-NORTHERN MEXICO SOLUTION CENTRE'''',''''GCR - SYDNEY SOLUTION CENTRE'''', ''''SYDNEY SOLUTION CENTRE'''', ''''INDIA SC'''', ''''Miramar Solution Centre''''''
', 
		@database_name=N'R2_Reports', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Update YTD Client Table', 
		@enabled=1, 
		@freq_type=16, 
		@freq_interval=15, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20150828, 
		@active_end_date=99991231, 
		@active_start_time=210000, 
		@active_end_time=235959, 
		@schedule_uid=N'4de39b14-f89d-4abb-8da0-9e013f13d24c'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


