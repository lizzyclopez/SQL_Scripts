USE [msdb]
GO

/****** Object:  Job [06:00 R2_Import ALDEA Data]    Script Date: 7/27/2018 4:47:00 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 7/27/2018 4:47:00 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'06:00 R2_Import ALDEA Data', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Import Aldea Data.
', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Import Aldea Data]    Script Date: 7/27/2018 4:47:01 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Import Aldea Data', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @result int

Insert Into R2_Import..Log (Text) Values (''ALDEA_Extract - Start at ''+ Convert(VarChar(25),GetDate(),120))
exec @result = xp_cmdshell ''dtexec /f "g:\Applications\PIV_Transfer\SSISPackages\SSIS Package - Import Aldea data.dtsx"''

if @result = 0
	insert into R2_Import..Log ( StatusCode, ProcessName, Text) values( ''I'', ''Aldea Extract'', ''ALDEA_Extract - Ended At '' + convert(varchar(25), getdate(),120))
else
begin
	insert into R2_Import..Log ( StatusCode, ProcessName, Text) values( ''E'', ''Aldea Extract'', ''Aldea Extract Failed At '' + convert(varchar(25), getdate(),120))
	exec R2_Import..sp_sendnotification ''lizzy.lopez@dxc.com'', ''lizzy.lopez@hpe.com'',''R2 Load Failed!'',''Aldea Extract Failed!'' 
	--exec R2_import..sp_sendnotification ''lizzy.lopez@dxc.com'', ''8662346717@skytel.com'',''R2 Load Failed!'',''Aldea Extract Failed!''
end
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Extract A:DEA Data', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20150515, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=235959, 
		@schedule_uid=N'0bb133fa-cd8f-4c8a-96db-b462918d030e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


