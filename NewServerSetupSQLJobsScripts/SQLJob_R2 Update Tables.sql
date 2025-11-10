USE [msdb]
GO

/****** Object:  Job [01:30 R2_Update tblStaffingPlanDetail Table]    Script Date: 7/27/2018 4:56:00 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [R2_Daily_Job]    Script Date: 7/27/2018 4:56:00 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'R2_Daily_Job' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'R2_Daily_Job'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'01:30 R2_Update tblStaffingPlanDetail Table', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Run Update_tblStaffingPlanDetail stored procedure to update FTE with 0.00 where it is NULL for months 11-18.', 
		@category_name=N'R2_Daily_Job', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run Update Script]    Script Date: 7/27/2018 4:56:00 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Update Script', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec Update_tblStaffingPlanDetail', 
		@database_name=N'R2_Reports', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Update StaffingPlanDetail Table', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20150828, 
		@active_end_date=99991231, 
		@active_start_time=13000, 
		@active_end_time=235959, 
		@schedule_uid=N'f99ddad6-14c5-4caf-8175-393808f7239a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-------------------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [09:15 R2_YEARLY Vacation Accrual - Monthly]    Script Date: 7/27/2018 4:56:52 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [R2_Daily_Job]    Script Date: 7/27/2018 4:56:52 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'R2_Daily_Job' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'R2_Daily_Job'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'09:15 R2_YEARLY Vacation Accrual - Monthly', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Update the Vacation Accrual table with each Employees vacation accrual value based on their service date.', 
		@category_name=N'R2_Daily_Job', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Vacation Accrual - Yearly]    Script Date: 7/27/2018 4:56:52 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update Vacation Accrual - Yearly', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec Setup_VacationAccrual', 
		@database_name=N'R2_Reports', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Yearly Update to Vacation Accrual Table', 
		@enabled=1, 
		@freq_type=32, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=1, 
		@freq_recurrence_factor=12, 
		@active_start_date=20150828, 
		@active_end_date=99991231, 
		@active_start_time=91500, 
		@active_end_time=235959, 
		@schedule_uid=N'faa4894e-7d60-42a5-a73a-87962cb897d2'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [21:00 R2_Update YTD Client Table - Mthly]    Script Date: 7/27/2018 4:57:22 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [R2_Daily_Job]    Script Date: 7/27/2018 4:57:22 PM ******/
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
/****** Object:  Step [Run the Update_YTD_Client]    Script Date: 7/27/2018 4:57:22 PM ******/
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

-------------------------------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [23:00 R2_Delete and Copy DB Backups to 130C and 132C]    Script Date: 7/27/2018 4:57:49 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [R2_Daily_Job]    Script Date: 7/27/2018 4:57:49 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'R2_Daily_Job' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'R2_Daily_Job'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'23:00 R2_Delete and Copy DB Backups to 130C and 132C', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Delete and copy all Database Backups to repository folder on Web Server and Test Server.', 
		@category_name=N'R2_Daily_Job', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete and Copy DB Backups to 130C and 132C]    Script Date: 7/27/2018 4:57:49 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete and Copy DB Backups to 130C and 132C', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @PreviousDate as varchar(10), @CurrentDate as varchar(10), @strSQL as varchar(1000)
set @PreviousDate = REPLACE(CONVERT(char(10), DATEADD(D,-3, GetDate()),126), ''-'', ''_'')
set @CurrentDate = REPLACE(CONVERT(char(10), GetDate(),126),''-'',''_'')

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Delete backup files greater than 3 days and copy latest database backup to WEB USHOSEDS130C
set @strSQL = ''del \\USHOSEDS130C\Applications\R2\SQLServerBackups\ALDEA_Import_backup_'' + @PreviousDate + ''*.bak''
exec master..xp_cmdshell @strSQL
set @strSQL = ''copy E:\MSSQLBackups\ALDEA_Import_backup_'' + @CurrentDate + ''*.bak \\USHOSEDS130C\Applications\R2\SQLServerBackups''
exec xp_cmdshell @strSQL

set @strSQL = ''del \\USHOSEDS130C\Applications\R2\SQLServerBackups\R2_Import_backup_'' + @PreviousDate + ''*.bak''
exec master..xp_cmdshell @strSQL
set @strSQL = ''copy E:\MSSQLBackups\R2_Import_backup_'' + @CurrentDate + ''*.bak \\USHOSEDS130C\Applications\R2\SQLServerBackups''
exec xp_cmdshell @strSQL

set @strSQL = ''del \\USHOSEDS130C\Applications\R2\SQLServerBackups\R2_Reports_backup_'' + @PreviousDate + ''*.bak''
exec master..xp_cmdshell @strSQL
set @strSQL = ''copy E:\MSSQLBackups\R2_Reports_backup_'' + @CurrentDate + ''*.bak \\USHOSEDS130C\Applications\R2\SQLServerBackups''
exec xp_cmdshell @strSQL

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Delete backup files greater than 3 days and copy the latest backup in TEST USHOSEDS132C
--set @strSQL = ''del \\USHOSEDS132C\SQLBackups\Aldea_Import_backup_'' + @PreviousDate + ''*.bak''
--exec master..xp_cmdshell @strSQL
--set @strSQL = ''copy E:\MSSQLBackups\Aldea_Import_backup_'' + @CurrentDate + ''*.bak \\USHOSEDS132C\SQLBackups''
--exec xp_cmdshell @strSQL

--set @strSQL = ''del \\USHOSEDS132C\SQLBackups\R2_Import_backup_'' + @PreviousDate + ''*.bak''
--exec master..xp_cmdshell @strSQL
--set @strSQL = ''copy E:\MSSQLBackups\R2_Import_backup_'' + @CurrentDate + ''*.bak \\USHOSEDS132C\SQLBackups''
--exec xp_cmdshell @strSQL

--set @strSQL = ''del \\USHOSEDS132C\SQLBackups\R2_Reports_backup_'' + @PreviousDate + ''*.bak''
--exec master..xp_cmdshell @strSQL
--set @strSQL = ''copy E:\MSSQLBackups\R2_Reports_backup_'' + @CurrentDate + ''*.bak \\USHOSEDS132C\SQLBackups''
--exec xp_cmdshell @strSQL

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO






