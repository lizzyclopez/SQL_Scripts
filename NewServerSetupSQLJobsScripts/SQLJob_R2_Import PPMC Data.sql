USE [msdb]
GO

/****** Object:  Job [04:30 R2_Import PPMC Data]    Script Date: 9/12/2018 7:02:10 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 9/12/2018 7:02:10 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'04:30 R2_Import PPMC Data', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Import PPMC Project and Task Data.
1. Extract PPMC Flat Files
2. Move PPMC Files to Download Folder
3. Check PPMC Project File
4. Check PPMC Task File
5. Insert PPMC Data into DB
6. Copy PPMC Files to Test
7. Send Failure Notificaiton', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Extract PPMC Flat Files]    Script Date: 9/12/2018 7:02:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Extract PPMC Flat Files', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'----Run .NET executable that extracts PPMC flat files from SFTP folder.
--Insert Into R2_Import..Log Values (getdate(), ''S'', ''PPMC Extract'', ''Start PPMC flat file extract at ''+ Convert(VarChar(25),GetDate(),120))
--EXEC master..xp_CMDShell ''G:\Applications\PIV_Transfer\PPMCExtract\PPMC_SFTP_Extract.exe''
--Insert Into R2_Import..Log Values (getdate(), ''S'', ''PPMC Extract'', ''Ended PPMC flat file extract at ''+ Convert(VarChar(25),GetDate(),120))', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Move PPMC Files to Download Folder]    Script Date: 9/12/2018 7:02:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Move PPMC Files to Download Folder', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'if exists ( select * from R2_Import..Log where TS > dateadd(hh, -1, getdate()) and Text like ''%Ended PPMC flat file extract%'' )
	begin	
	--declare @strSQL as varchar(1000)

	--Delete old PPMC files in Download folder.
	--set @strSQL = ''del G:\Applications\PIV_Transfer\Download\ABS_ConsumerTransport*.*''
	--exec master..xp_cmdshell @strSQL

	--Copy PPMC Project file from PPMC_Extract to Download Folder.
	--set @strSQL = ''copy G:\Applications\PIV_Transfer\PPMCExtract\Daily\ABS_ConsumerTransport_Projects.dat G:\Applications\PIV_Transfer\Download\ABS_ConsumerTransport_Projects.dat''
 	--exec xp_cmdshell @strSQL

	--Copy PPMC Task file from PPMC_Extract to Download Folder.
	--set @strSQL = ''copy G:\Applications\PIV_Transfer\PPMCExtract\Daily\ABS_ConsumerTransport_Tasks.dat G:\Applications\PIV_Transfer\Download\ABS_ConsumerTransport_Tasks.dat''
 	--exec xp_cmdshell @strSQL
	end
else
	--exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = ''R2 131C PPMC Extract Failed!'', @body = ''The SFTP_PPMC_Extract failed to extract new PPMC files. Copied old files to Download folder. Running with the previous files.''
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check PPMC Project File]    Script Date: 9/12/2018 7:02:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check PPMC Project File', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Check date of PPMC Project files and Send email notification.
declare @fileDate as datetime, @currDate as datetime, @hourvalue int, @profile_name varchar(255), @subject nvarchar(255), @body nvarchar(255)

if exists(select 1 from tempdb..sysobjects where name=''##PPMCFileDetails'')
	drop table ##PPMCFileDetails

create table ##PPMCFileDetails(mdate varchar(8000))
insert ##PPMCFileDetails
exec master.dbo.xp_cmdshell ''dir g:\Applications\PIV_Transfer\Download\ABS_ConsumerTransport_Projects.dat'' 

select * from ##PPMCFileDetails
set rowcount 5
delete from ##PPMCFileDetails

set rowcount 0
select top(1) @fileDate= substring(mdate,1,20) , @currDate=getdate() from ##PPMCFileDetails
--print @fileDate

set  @hourvalue=datediff(hh,@fileDate,@currDate)

if @hourvalue < 12
	begin
	set @subject = ''R2 131C Using New PPMC Project File''
	set @body= ''Recieved a new PPMC Project file dated: '' + convert(varchar(25), @fileDate, 120)
	--exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = @subject, @body = @body
	end
else
	begin
	set @subject = ''R2 131C Using Old PPMC Project File''
	set @body= ''Did not recieve a new PPMC Project file. Running with the previous file dated: '' + convert(varchar(25), @fileDate, 120)
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = @subject, @body = @body
	end
	
drop table ##PPMCFileDetails
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check PPMC Task File]    Script Date: 9/12/2018 7:02:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check PPMC Task File', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Check and Send email notifying of file has data or not.
declare @fileDate as datetime, @currDate as datetime, @hourvalue int, @profile_name varchar(255), @subject nvarchar(255), @body nvarchar(255)

if exists(select 1 from tempdb..sysobjects where name=''##PPMCFileDetails'')
	drop table ##PPMCFileDetails

create table ##PPMCFileDetails(mdate varchar(8000))
insert ##PPMCFileDetails
exec master.dbo.xp_cmdshell ''dir g:\Applications\PIV_Transfer\Download\ABS_ConsumerTransport_Tasks.dat'' 

select * from ##PPMCFileDetails
set rowcount 5
delete from ##PPMCFileDetails

set rowcount 0
select top(1) @fileDate= substring(mdate,1,20) , @currDate=getdate() from ##PPMCFileDetails
--print @fileDate

set  @hourvalue=datediff(hh,@fileDate,@currDate)

if @hourvalue < 12
	begin
	set @subject = ''R2 131C Using New PPMC Task File''
	set @body= ''Recieved a new PPMC Task file dated: '' + convert(varchar(25), @fileDate, 120)
	--exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = @subject, @body = @body
	end
else
	begin
	set @subject = ''R2 131C Using Old PPMC Task File''
	set @body= ''Did not recieve a new PPMC Task file. Running with the previous file dated: '' + convert(varchar(25), @fileDate, 120)
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = @subject, @body = @body
	end

drop table ##PPMCFileDetails


', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Insert PPMC Data into DB]    Script Date: 9/12/2018 7:02:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Insert PPMC Data into DB', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @retval int,  @profile_name varchar(255)

---Delete PPMC data from tables.
truncate table R2_Import..PPMC_Project
truncate table R2_Import..PPMC_Task

---Insert entry in Log table
Insert Into R2_Import..Log Values (getdate(), ''S'', ''PPMC Load'', ''Start loading PPMC data at ''+ Convert(VarChar(25),GetDate(),120))

----Run vb.net executable that inserts PPMC data into PPMC_Project and PPMC_Task tables.
EXEC @retval = master..xp_CMDShell ''G:\Applications\PIV_Transfer\PPMCExtract\PPMC_Load.exe''

if @retval = 0 -- success
	begin
	Insert Into R2_Import..Log Values (getdate(), ''S'', ''PPMC Load'', ''Ended loading PPMC data at ''+ Convert(VarChar(25),GetDate(),120))
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = ''R2 131C PPMC_Load Successful'', @body = ''The PPMC_Load.exe vbscript program ran successfully!''
	end
else
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = ''R2 131C PPMC_Load Failed!'', @body = ''The PPMC_Load.exe program failed to run! Check G:\Applications\PIV_Transfer\PPMCExtract\PPMC_Extract_Load.exe.''
', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Copy PPMC Files To Test]    Script Date: 9/12/2018 7:02:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Copy PPMC Files To Test', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=7, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @strSQL as varchar(1000)

------Delete PPMC files in Test server.
set @strSQL = ''del \\USHOSEDS132C\PIV_Transfer\Download\ABS_ConsumerTransport*.*''
exec master..xp_cmdshell @strSQL

------Copy PPMC files from Production to Test
set @strSQL = ''copy g:\Applications\PIV_Transfer\Download\ABS_ConsumerTransport_Projects.dat \\USHOSEDS132C\PIV_Transfer\Download''
exec xp_cmdshell @strSQL
set @strSQL = ''copy g:\Applications\PIV_Transfer\Download\ABS_ConsumerTransport_Tasks.dat \\USHOSEDS132C\PIV_Transfer\Download''
exec xp_cmdshell @strSQL', 
		@database_name=N'R2_Import', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Failure Notificaiton]    Script Date: 9/12/2018 7:02:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Failure Notificaiton', 
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
                @subject = ''R2 AM PPMC Load Failed'', 
             	@body = ''The job that runs the morning PPMC load failed in 131C.'', 
	@profile_name = @profile_name, 
          	@body_format = ''TEXT'';
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Run PPMC Extract', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20171121, 
		@active_end_date=99991231, 
		@active_start_time=43000, 
		@active_end_time=235959, 
		@schedule_uid=N'afde1d0b-556e-47a8-9c2f-456d3c534740'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


