USE [msdb]
GO

/****** Object:  Job [04:00 EMIPS_Process Daily File]    Script Date: 9/12/2018 7:03:52 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [EMIPS Daily Job]    Script Date: 9/12/2018 7:03:52 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'EMIPS Daily Job' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'EMIPS Daily Job'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'04:00 EMIPS_Process Daily File', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'1. Get EMIPS daily file.
2. Move data to EMIPS_Data table and delete data from FTP_Import1 and FTP_Import2 table.
3. Inserts data from EMIPS file to FTP_Import1 table.
4. Move data from FTP_Import1 to FTP_Import2 table.
5. Update Empty Cells.
6. Create Excel daily file in EMIPS\DailyFile folder.
7. Create Master Report and send mail notification.
8. Copy Report to HIstory Folder.
9. Send failure mail  notification only if any one of the above step fail.', 
		@category_name=N'EMIPS Daily Job', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Get EMIPS Daily File]    Script Date: 9/12/2018 7:03:52 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Get EMIPS Daily File', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @strSQL as varchar(1000)

--Delete the previous daily file.
set @strSQL = ''del G:\Applications\EMIPS\DailyFile\*.xls''
exec xp_cmdshell @strSQL
set @strSQL = ''del G:\Applications\EMIPS\DailyFile\*.emips''
exec xp_cmdshell @strSQL

--If it is second of the month, delete the previous report.
IF DAY(getdate()) = 2
	begin
	print ''It is the second day of the month, delete the previous month report.''
	set @strSQL = ''del G:\Applications\EMIPS\*TPFPlatformMinXMindata.xls''
	exec xp_cmdshell @strSQL
	end

--Get the EMIPS daily file.
EXEC MASTER..XP_CMDSHELL ''G:\Applications\EMIPS\get_previous_day_file.bat''
', 
		@database_name=N'EMIPS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Move Data to EMIPS_Data Table and Delete Data from FTP_Import1 and FTP_Import2 Table]    Script Date: 9/12/2018 7:03:52 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Move Data to EMIPS_Data Table and Delete Data from FTP_Import1 and FTP_Import2 Table', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--2. Delete all existing data from FTP tables and delete data in EMIP_Data which are more than 2 years back from todays date.
Insert into EMIPS_Data select * from FTP_Import2
Delete from FTP_Import1 
Delete from FTP_Import2
Delete from EMIPS_Data where LastUpdDate < dateadd(yyyy, -2, getdate()-1)
', 
		@database_name=N'EMIPS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Insert Data into FTP_Import1 from EMIPS File]    Script Date: 9/12/2018 7:03:52 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Insert Data into FTP_Import1 from EMIPS File', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--3. Insert data from EMIPS file to FTP_Import1 table.
BULK INSERT FTP_Import1 FROM ''G:\Applications\EMIPS\DailyFile\EMIPS.csv''
delete  from FTP_Import1 where LPARS in (select LPARS from FTP_IMport1 where LPARS like ''Sun%'' or  LPARS like ''Mon%'' or  LPARS like ''Tue%'' or  LPARS like ''Wed%'' or  LPARS like ''Thu%'' or  LPARS like ''Fri%'' or  LPARS like ''Sat%'')

--Check for missing data.
if (select count(*) from FTP_Import1) = 1440
	print ''success''
else 
	begin
	print ''Missing Data''
	declare  @profile_name varchar(255) 
	--exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com; doug.blum@hpe.com; glenn.frick@hpe.com'', @subject = ''EMIPS 131C Minute by Minute Missing Data'', @body = ''The EMIPS file received does not have 1440 records. Check file for missing data.''	
	end
', 
		@database_name=N'EMIPS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Move Data from FTP_Import1 to FTP_Import2 Tables]    Script Date: 9/12/2018 7:03:52 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Move Data from FTP_Import1 to FTP_Import2 Tables', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--4. Execute stored procedure to move data from FTP_Import1 to FTP_Import2 table.
exec sp_ftpImportbulkinsert
', 
		@database_name=N'EMIPS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Empty Cells]    Script Date: 9/12/2018 7:03:52 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update Empty Cells', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--5. Update Empty Cells

-- Execute Stored procedure to update the empty cells to 0 and arrange all the LPARS in the correct column.
exec sp_bulkupdateEMIPSdaily

-- Update as 10 engine 
update ftp_import2 set NbrPhysicalEngine=''10'' where NbrPhysicalEngine=''11''
', 
		@database_name=N'EMIPS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Create Excel Daily File]    Script Date: 9/12/2018 7:03:52 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Create Excel Daily File', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--6. Create excel daily file in the EMIPS\DailyFile folder.
declare @filename varchar(100), @profile_name varchar(255) 

--Create the filename.
set @filename = (SELECT  CASE DATEPART(WEEKDAY,GETDATE()-1) 
          WHEN 1 THEN CONVERT(VARCHAR(15), GETDATE()-1,12)+''Su''  
          WHEN 2 THEN  CONVERT(VARCHAR(15), GETDATE()-1,12)+''Mo''  
          WHEN 3 THEN  CONVERT(VARCHAR(15), GETDATE()-1,12)+''Tu''  
          WHEN 4 THEN  CONVERT(VARCHAR(15), GETDATE()-1,12)+''We''   
          WHEN 5 THEN  CONVERT(VARCHAR(15), GETDATE()-1,12)+''Th''     
          WHEN 6 THEN  CONVERT(VARCHAR(15), GETDATE()-1,12)+''Fr''    
          WHEN 7 THEN  CONVERT(VARCHAR(15), GETDATE()-1,12)+''Sa''  
          END ) 

--Filename will be changed from .emips to YYMMDDDA.xls format.
select @filename = ''G:\Applications\EMIPS\DailyFile\''+@filename+''.xls''  

--Execute stored procedure to create daily xls file in the EMIPS\DailyFile folder.
EXEC Generate_Excel_from_FTPImport2 ''EMIPS'', ''FTP_Import2'', @filename 
', 
		@database_name=N'EMIPS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Create Master Report]    Script Date: 9/12/2018 7:03:52 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Create Master Report', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @strSQL as varchar(1000), @profile_name varchar(255) 

--Create the master report.
EXEC MASTER..XP_CMDSHELL ''CScript G:\Applications\EMIPS\MasterReport.vbs -S USHOSEDS131C\PROD'' 

--Send email notification.
--exec msdb.dbo.sp_send_dbmail 
--	@profile_name = ''SQL_DBMail'', 
--	@recipients = ''lizzy.lopez@dxc.com'', 
--	@subject = ''EMIPS 131C Minute by Minute Report Successful'', 
--	@body = ''The EMIPS process that creates the Minute by Minute Master Report ran Successfully in 131C.''
--	@copy_recipients = ''lizzy.lopez@hpe.com'', 
--             	@body_format = ''TEXT'';', 
		@database_name=N'EMIPS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Copy Report to HIstory Folder]    Script Date: 9/12/2018 7:03:52 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Copy Report to HIstory Folder', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=9, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @strSQL as varchar(1000), @CurrentMonth as varchar(2), @PreviousMonth as varchar(2), @YesterdaytDate as varchar(10)

--Set current or previous month to be used as part of report name (01-January-TPFPlatformMinXMindata.xls). 
--set @CurrentMonth = RIGHT(''0'' + RTRIM(MONTH(getdate())), 2)
--set @PreviousMonth =RIGHT(''0'' + RTRIM(MONTH(DATEADD(MONTH, -1, GETDATE()))), 2)

--Get yesterday date and remove the slahes. Move yesterdays files to MinuteByMinute\History folder in 130C.
--set @YesterdaytDate = replace(CONVERT(varchar(8),getdate()-2,11) , ''/'', '''')
---set @strSQL = ''move G:\Applications\EMIPS\DailyFile\'' + @YesterdaytDate + ''*.xls \\USHOSEDS130c\E$\Applications\Compute_Services\MinuteByMinute\History''
--exec xp_cmdshell @strSQL
--set @strSQL = ''move G:\Applications\EMIPS\DailyFile\'' + @YesterdaytDate + ''*.emips \\USHOSEDS130c\E$\Applications\Compute_Services\MinuteByMinute\History''
--exec xp_cmdshell @strSQL

--Copy the daily input files and mater report to History folder in 130C.
set @strSQL = ''copy G:\Applications\EMIPS\DailyFile\*.xls \\USHOSEDS130c\E$\Applications\Compute_Services\MinuteByMinute\History''
exec xp_cmdshell @strSQL
set @strSQL = ''copy G:\Applications\EMIPS\DailyFile\*.emips \\USHOSEDS130c\E$\Applications\Compute_Services\MinuteByMinute\History''
exec xp_cmdshell @strSQL
set @strSQL = ''copy G:\Applications\EMIPS\*TPFPlatformMinXMindata.xls \\USHOSEDS130c\E$\Applications\Compute_Services\MinuteByMinute\History''
exec xp_cmdshell @strSQL
', 
		@database_name=N'EMIPS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Failure Mail]    Script Date: 9/12/2018 7:03:52 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Failure Mail', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=2, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--8. Send email to developer notifying of Failed job.
declare  @profile_name varchar(255) 

set @profile_name = ''SQL_DBMail''  
exec msdb.dbo.sp_send_dbmail 
             	@recipients = ''lizzy.lopez@dxc.com'', 
                @subject = ''EMIPS 131C Job Failed'', 
             	@body = ''The EMIPS job that creates the Minute by Minute Report failed in 131C prod.'', 
           	@profile_name = @profile_name, 
          	@body_format = ''TEXT'';
', 
		@database_name=N'EMIPS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'EMIPS Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20150520, 
		@active_end_date=99991231, 
		@active_start_time=40000, 
		@active_end_time=235959, 
		@schedule_uid=N'176bdf74-535d-4672-9660-142bbd9617a5'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


