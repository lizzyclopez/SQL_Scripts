USE [msdb]
GO

/****** Object:  Job [08:15 TPF_SHARES_Data_Load]    Script Date: 9/12/2018 7:13:06 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 9/12/2018 7:13:06 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'08:15 TPF_SHARES_Data_Load', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'1. Extract FQA XML file.------------NOT WORKING RUNNING VIA SCHEDULE TASK
2. Extract FQB XML file. ------------NOT WORKING RUNNING VIA SCHEDULE TASK
3. Copy the fqa and fqb daily SHARES XML files to 132C Test server.
4. Create temporary tables.
5. Load FQA XML File.
6. Load FQB XML File.
7. Drop temporary tables.
8. Load Monthly Counts.
9. Move XML Files from Archive to Back', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Get FQA XML File ------------NOT WORKING RUNNING VIA SCHEDULE TASK]    Script Date: 9/12/2018 7:13:06 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Get FQA XML File ------------NOT WORKING RUNNING VIA SCHEDULE TASK', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Run the script to retrieve the fqa16mmdd.xml file.
--EXEC master..xp_CMDShell ''CSCRIPT G:\Applications\Shares\SCSCAirlineApp\SharesStats\GetSharesFQA.vbs''
', 
		@database_name=N'TPF_SHARES_Generic_Stats', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Get FQB XML File ------------NOT WORKING RUNNING VIA SCHEDULE TASK]    Script Date: 9/12/2018 7:13:06 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Get FQB XML File ------------NOT WORKING RUNNING VIA SCHEDULE TASK', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Run the script to retrieve the fqb16mmdd.xml file.
--EXEC master..xp_CMDShell ''CSCRIPT G:\Applications\Shares\SCSCAirlineApp\SharesStats\GetSharesFQB.vbs''
', 
		@database_name=N'TPF_SHARES_Generic_Stats', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Copy SHA SHB XML to 132C]    Script Date: 9/12/2018 7:13:06 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Copy SHA SHB XML to 132C', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @strSQL as varchar(1000)

----Copy files from Production to 132C Test
set @strSQL = ''copy g:\Applications\Shares\SCSCAirlineApp\SharesStats\WSPNActivityCounts\fq*.xml \\USHOSEDS132C\WSPNActivityCounts''
exec xp_cmdshell @strSQL
', 
		@database_name=N'TPF_SHARES_Generic_Stats', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Create Temporary Tables]    Script Date: 9/12/2018 7:13:06 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Create Temporary Tables', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[FK_Key_Dummy_Key_Dummy2]'') and OBJECTPROPERTY(id, N''IsForeignKey'') = 1)
ALTER TABLE [dbo].[Key_Dummy] DROP CONSTRAINT FK_Key_Dummy_Key_Dummy2
GO

if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[Key_Dummy]'') and OBJECTPROPERTY(id, N''IsUserTable'') = 1)
drop table [dbo].[Key_Dummy]
GO

if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[Key_Dummy2]'') and OBJECTPROPERTY(id, N''IsUserTable'') = 1)
drop table [dbo].[Key_Dummy2]
GO

if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[Report_Date]'') and OBJECTPROPERTY(id, N''IsUserTable'') = 1)
drop table [dbo].[Report_Date]
GO

CREATE TABLE [dbo].[Report_Date] (
	[App_Code] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Stat_Date] [datetime] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Key_Dummy2] (
	[Stat_Date] [datetime] NOT NULL ,
	[Stat_System] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Stat_Name] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Key_Dummy] (
	[Stat_Date] [datetime] NOT NULL ,
	[Stat_System] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Stat_Name] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Airline_Code] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Key1_Name] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Key2_Name] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Key3_Name] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Key_Dummy2] WITH NOCHECK ADD 
	CONSTRAINT [IX_Key_Dummy2] UNIQUE  NONCLUSTERED 
	(	[Stat_Date],
		[Stat_System],
		[Stat_Name]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Key_Dummy] WITH NOCHECK ADD 
	CONSTRAINT [IX_Key_Dummy_1] UNIQUE  NONCLUSTERED 
	(	[Stat_Date],
		[Stat_System],
		[Stat_Name],
		[Airline_Code]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Key_Dummy] WITH NOCHECK ADD 
	CONSTRAINT [FK_Key_Dummy_Key_Dummy2] FOREIGN KEY 
	(	[Stat_Date],
		[Stat_System],
		[Stat_Name]
	) REFERENCES [dbo].[Key_Dummy2] (
		[Stat_Date],
		[Stat_System],
		[Stat_Name]
	)
GO
', 
		@database_name=N'TPF_SHARES_Generic_Stats', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load FQA XML File]    Script Date: 9/12/2018 7:13:06 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load FQA XML File', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @count int, @profile_name varchar(255), @subject nvarchar(255), @body nvarchar(255)

---Load the FQA XML File
EXEC MASTER..XP_CMDSHELL ''CScript G:\Applications\Shares\SCSCAirlineApp\SharesStats\WSPNActivityCounts\STAT_TRAN_CNT.VBS SHA''

---Check if file was loaded in the table.
select @count = count(*) from TPF_SHARES_Generic_Stats..Daily_Counts where Stat_Date = CONVERT(char(10), DATEADD(D,-1, GetDate()),126) and Stat_System = ''SHA''
if @count > 1
	begin
	print ''Data loaded in table''
	set @subject = ''TPF_SHARES 131C FQA XML Load Successful''
	set @body= ''Recieved a new FQA XML file on: '' + convert(varchar(25), getdate(), 120) + '' The FQA data was loaded successfully!''
	--exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = @subject, @body = @body
	end
else
	begin
	--print ''Data was not loaded in table''
	set @subject = ''TPF_SHARES 131C FQA XML Load Failedl''
	set @body= ''Recieved a new FQA XML file on: '' + convert(varchar(25), getdate(), 120) + '' But the FQA data failed to load!''
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = @subject, @body = @body
	end
', 
		@database_name=N'TPF_SHARES_Generic_Stats', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load FQB XML File]    Script Date: 9/12/2018 7:13:06 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load FQB XML File', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @count int, @profile_name varchar(255), @subject nvarchar(255), @body nvarchar(255)

---Load FQB XML File
EXEC MASTER..XP_CMDSHELL ''CScript G:\Applications\Shares\SCSCAirlineApp\SharesStats\WSPNActivityCounts\STAT_TRAN_CNT.VBS SHB''

---Check if file was loaded in the table.
select @count = count(*) from TPF_SHARES_Generic_Stats..Daily_Counts where Stat_Date = CONVERT(char(10), DATEADD(D,-1, GetDate()),126) and Stat_System = ''SHB''
if @count > 1
	begin
	print ''Data loaded in table''
	set @subject = ''TPF_SHARES 131C FQB XML Load Successful''
	set @body= ''Recieved a new FQB XML file on: '' + convert(varchar(25), getdate(), 120) + '' The FQB data was loaded successfully!''
	--exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = @subject, @body = @body
	end
else
	begin
	--print ''Data was not loaded in table''
	set @subject = ''TPF_SHARES 131C FQB XML Load Failedl''
	set @body= ''Recieved a new FQB XML file on: '' + convert(varchar(25), getdate(), 120) + '' But the FQB data failed to load!''
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = @subject, @body = @body
	end
', 
		@database_name=N'TPF_SHARES_Generic_Stats', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Drop Temporary Tables]    Script Date: 9/12/2018 7:13:06 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Drop Temporary Tables', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[FK_Key_Dummy_Key_Dummy2]'') and OBJECTPROPERTY(id, N''IsForeignKey'') = 1)
ALTER TABLE [dbo].[Key_Dummy] DROP CONSTRAINT FK_Key_Dummy_Key_Dummy2
GO

if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[Key_Dummy]'') and OBJECTPROPERTY(id, N''IsUserTable'') = 1)
drop table [dbo].[Key_Dummy]
GO

if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[Key_Dummy2]'') and OBJECTPROPERTY(id, N''IsUserTable'') = 1)
drop table [dbo].[Key_Dummy2]
GO

if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[Report_Date]'') and OBJECTPROPERTY(id, N''IsUserTable'') = 1)
drop table [dbo].[Report_Date]
GO', 
		@database_name=N'TPF_SHARES_Generic_Stats', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load Monthly Counts]    Script Date: 9/12/2018 7:13:06 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Monthly Counts', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @count int, @strMonth as nvarchar(2), @strYear as nvarchar(4), @profile_name varchar(255), @subject nvarchar(255), @body nvarchar(255)

--Execute stored procedure to load the Monthly counts.
EXEC TPF_SHARES_Generic_Stats..MonthlyCounts

--Set the month and year for the query.
select @strMonth = FORMAT(getdate()-1,''MM'')
select @strYear = datepart (yy,getdate()-1)

---Check if data was loaded in the table.
select @count = sum(Transaction_Counts) from Monthly_Counts where Stat_Year = @strYear and Stat_Month = @strMonth
if @count > 1
	begin
	print ''Data loaded in table''
	set @subject = ''TPF_SHARES 131C MonthlyCounts Load Successful''
	set @body= ''Stored procedure MonthlyCounts successfully loaded the Monthly counts data and the FQA and FQB data was loaded successfully! ''
	--exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = @subject, @body = @body
	end
else
	begin
	--print ''Data was not loaded in table''
	set @subject = ''TPF_SHARES 131C MonthlyCounts Load Failedl''
	set @body= ''Stored procedure MonthlyCounts failed to load the Monthly counts data!''
	exec msdb.dbo.sp_send_dbmail @profile_name = ''SQL_DBMail'', @recipients = ''lizzy.lopez@dxc.com'', @subject = @subject, @body = @body
	end
', 
		@database_name=N'TPF_SHARES_Generic_Stats', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Move Files from Archive to Backup]    Script Date: 9/12/2018 7:13:06 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Move Files from Archive to Backup', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @PrevDate as varchar(6), @PrevYear as varchar(4), @strSQL as varchar(1000)

--Get date of 10 days ago.
select @PrevDate = SUBSTRING(CONVERT(nvarchar(8),getdate()-10, 112),3,6)
select @PrevYear = SUBSTRING(CONVERT(nvarchar(8),getdate()-10, 112),1,4)

--Move the XML files to Backup folder.
set @strSQL = ''move G:\Applications\Shares\SCSCAirlineApp\SharesStats\WSPNActivityCounts\Archive\*'' + @PrevDate + ''.xml G:\Applications\Shares\SCSCAirlineApp\SharesStats\WSPNActivityCounts\Backup\'' + @PrevYear
exec xp_cmdshell @strSQL', 
		@database_name=N'TPF_SHARES_Generic_Stats', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Run TPF_SHARES Load', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20150902, 
		@active_end_date=99991231, 
		@active_start_time=81500, 
		@active_end_time=235959, 
		@schedule_uid=N'b581e269-d069-44bf-ad8e-dcd82501eff1'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


