USE [msdb]
GO

/****** Object:  Job [23:00 R2_Delete and Copy DB Backups to 130C and 132C]    Script Date: 9/12/2018 7:26:30 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [R2_Daily_Job]    Script Date: 9/12/2018 7:26:30 AM ******/
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
/****** Object:  Step [Delete and Copy DB Backups to 130C and 132C]    Script Date: 9/12/2018 7:26:30 AM ******/
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


