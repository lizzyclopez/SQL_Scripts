USE [msdb]
GO

/****** Object:  Job [08:15 R2_Import_COMPASS_Data]    Script Date: 7/27/2018 4:48:26 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 7/27/2018 4:48:26 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'08:15 R2_Import_COMPASS_Data', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Extract Compass file from Outlook
1. Delete COMPASS File
2. Extract COMPASS File from Mailbox ---COMMENTED RUNNING FROM TEST
3. Copy CATW to Test ---COMMNETED
4. Unzip COMPASS FIle
5. Update COMPASS File
6. Load Compass File
7. Send Failure Notificaiton', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete Compass Files]    Script Date: 7/27/2018 4:48:26 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Compass Files', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @strSQL as varchar(1000), @profile_name varchar(255) 

--Insert entry in Log table.
insert into R2_Import..log (StatusCode, ProcessName, Text) values(''S'', ''COMPASS Load'',  ''COMPASS Load Process Start at ''+convert(varchar(25), getdate(),120))	

----Delete COMPASS file in daily folder.
--set @strSQL = ''del G:\Applications\PIV_Transfer\CompassExtract\Daily\ZC_GFDM0013*.*''
--exec master..xp_cmdshell @strSQL

----Delete COMPASS file in PreviousCompassFile folder.
set @strSQL = ''del G:\Applications\PIV_Transfer\CompassExtract\PreviousCompassFile\ZC_GFDM0013*.*''
exec master..xp_cmdshell @strSQL

----Copy previous COMPASS file from Download folder to PreviousCompassFile folder in case needed.
set @strSQL = ''copy G:\Applications\PIV_Transfer\Download\ZC_GFDM0013_PROJTIME_A_00000.xls G:\Applications\PIV_Transfer\CompassExtract\PreviousCompassFile''
exec xp_cmdshell @strSQL

----Delete COMPASS file in Download folder.
set @strSQL = ''del G:\Applications\PIV_Transfer\Download\ZC_GFDM0013*.*''
exec master..xp_cmdshell @strSQL
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Extract Compass Via Scheduled Task  -- COMMENTED RUNNING FROM TEST]    Script Date: 7/27/2018 4:48:27 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Extract Compass Via Scheduled Task  -- COMMENTED RUNNING FROM TEST', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Execute the windows scheduled task to run the program that extracts the file from Outlook.
EXEC master..XP_CMDShell ''SCHTASKS /RUN /TN ExtractMailAttachment'' 
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Copy CATW File to Test --COMMENTED]    Script Date: 7/27/2018 4:48:27 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Copy CATW File to Test --COMMENTED', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @strSQL as varchar(1000)

------Delete file in Test server.
--set @strSQL = ''del \\USHOSEDS132C\PIV_Transfer\CompassExtract\Daily\ZC_GFDM0013_PROJTIME_A.ZIP''
--exec master..xp_cmdshell @strSQL

------Copy file from Production to Test
--set @strSQL = ''copy g:\Applications\PIV_Transfer\CompassExtract\Daily\ZC_GFDM0013_PROJTIME_A.ZIP  \\USHOSEDS132C\PIV_Transfer\CompassExtract\Daily''
--exec xp_cmdshell @strSQL
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Unzip Compass FIle]    Script Date: 7/27/2018 4:48:27 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Unzip Compass FIle', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @FileExists INT, @strSQL as varchar(1000), @profile_name varchar(255) 

--- Unzip the extracted COMPASS file.
exec master..xp_cmdshell ''C:\"Program Files"\7-Zip\7z.exe e "G:\Applications\PIV_Transfer\CompassExtract\Daily\ZC_GFDM0013_PROJTIME_A.ZIP" "-oG:\Applications\PIV_Transfer\CompassExtract\Daily\"''

-- Check if file was unzipped and send email notification.
exec master.dbo.xp_fileexist ''G:\Applications\PIV_Transfer\CompassExtract\Daily\ZC_GFDM0013_PROJTIME_A_00000.xls'', @FileExists OUTPUT
If @FileExists = 1 
	begin
	insert into R2_Import..log (StatusCode, ProcessName, Text) values(''S'', ''COMPASS Load'',  ''COMPASS file was unzipped successfully.'')	
	--exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = ''R2 131C Compass File Unzipped Successfully'', @body = ''Compass file was unzipped successfully.''
	end
else
	begin
	insert into R2_Import..log (StatusCode, ProcessName, Text) values(''E'', ''COMPASS Load'',  ''COMPASS file was not unzipped.'')	
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = ''R2 131C Compass File Not Unzipped!'', @body = ''Did not unzip the Compass file. Check to see if the Compass file was received.''
	end', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Compass File and Move to Download]    Script Date: 7/27/2018 4:48:27 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update Compass File and Move to Download', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @strSQL as varchar(1000), @profile_name varchar(255) 

if exists (select * from R2_Import..Log where TS > dateadd(hh, -1, getdate()) and Text like ''%COMPASS file was unzipped successfully%'')
	begin

	---Execute vbscript to update the COMPASS file.
	EXEC MASTER..XP_CMDSHELL ''CScript G:\Applications\PIV_Transfer\CompassExtract\UpdateCompass.vbs''

	--Move COMPASS file from Daily folder to Download folder.
	set @strSQL = ''move G:\Applications\PIV_Transfer\CompassExtract\Daily\ZC_GFDM0013_PROJTIME_A_00000.xls G:\Applications\PIV_Transfer\Download''
	exec xp_cmdshell @strSQL

	--Insert entry in Log table.
	insert into R2_Import..log (StatusCode, ProcessName, Text) values(''S'', ''COMPASS Load'',  ''Updated the COMPASS file successfully.'')	

	end
else if exists (select * from R2_Import..Log where TS > dateadd(hh, -1, getdate()) and StatusCode = ''E'' and Text like ''%COMPASS file was not unzipped%'')
	begin
	insert into R2_Import..log (StatusCode, ProcessName, Text) values(''E'', ''COMPASS Load'', ''COMPASS file was not updated.'')	
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = ''R2 131C Compass File Not Updated!'', @body = ''Did not updated the Compass file. Check to see if the Compass file was received.''
	end', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load Compass Extract]    Script Date: 7/27/2018 4:48:27 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Compass Extract', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @profile_name varchar(255)

---Delete data from table.
truncate table R2_Import..COMPASS_ResourceDetails
Insert Into R2_Import..Log Values (getdate(), ''S'', ''COMPASS Load'', ''Truncated the COMPASS_ResourceDetails table.'')

---Insert entry in Log table
Insert Into R2_Import..Log Values (getdate(), ''S'', ''COMPASS Load'', ''Start loading COMPASS data.'')

----Run program that inserts data into table.
EXEC master..xp_CMDShell ''G:\Applications\PIV_Transfer\CompassExtract\CompassLoad.exe''

---Check if file was loaded.
if exists(select * from R2_Import..COMPASS_ResourceDetails) 
	begin
	--Insert successful entry in Log table.
	insert into R2_Import..log (StatusCode, ProcessName, Text) values(''S'', ''COMPASS Load'',  ''COMPASS Load Process Ended Successfully at ''+convert(varchar(25), getdate(),120))
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = ''R2 131C COMPASS_Load Successful'', @body = ''The Compass data was loaded successfully!''		
	end
else
	begin
	--Insert failed entry in Log table.
	Insert Into R2_Import..Log Values (getdate(), ''E'', ''COMPASS Load'', ''COMPASS load failed!'')		
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = ''R2 131C COMPASS_Load Failed!'', @body = ''The CompassLoad.exe program failed to load the data! Check G:\Applications\PIV_Transfer\CompassExtract\CompassLoad.exe.''
	end
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Failure Notification]    Script Date: 7/27/2018 4:48:27 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Failure Notification', 
		@step_id=7, 
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
                @subject = ''R2 AM COMPASS Load Failed'', 
             	@body = ''The job that runs the morning COMPASS load failed in 131C.'', 
	@profile_name = @profile_name, 
          	@body_format = ''TEXT'';
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Load Compass Data', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20171129, 
		@active_end_date=99991231, 
		@active_start_time=81500, 
		@active_end_time=235959, 
		@schedule_uid=N'b3bc3fdf-b4aa-4047-ab48-487e576c6cdf'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


