--CREATE PROCEDURE [dbo].[Get_NonBillable_Detail] 
drop table #TEMP_IN
drop table #TEMP_OUT
drop view [dbo].[SP_Get_NonBillable_Resource_Detail_View]

-- Declare variables.
DECLARE  @SQL_statement varchar(1000), @CurProjectTitle varchar(100), @CurProjID varchar(100), @CurTaskName varchar(100), @CurTaskID varchar(100), @CurResourceName varchar(100),
@ResourceNumber varchar(30), @ResourceType varchar(30), @ResourceRole varchar(30), @Billing_CodeID varchar(30), @Billing_CodeDesc varchar(50), @WorkDate varchar(10), 
@Hours decimal(10,2), @Onshore bit, @Offshore bit, @Hourly bit, @MaxProj bigint, @MaxTask int, @ProgrammeProjectManager varchar(50), @ProjectNumber varchar(30), 
@SummaryTaskName varchar(30), @BillingRate decimal(10,2), @BillingRateOnshore decimal(10,2), @BillingRateOffshore decimal(10,2), @ResourceHourlyRate decimal(10,2),
@DateFrom datetime, @DateTo datetime, @DatePeriod varchar(25), @ResultsFile varchar(255), @BodyText varchar(255), @Result int

select top 1 @DateFrom = CurrentDate from R2_Import..ResourceWorkdate order by CurrentDate asc
select top 1 @DateTo = CurrentDate from R2_Import..ResourceWorkdate order by CurrentDate desc
--set @DateFrom = '2018-03-01'
--set @DateTo = '2018-03-31'
--print @DateFrom   print @DateTo

-- Set the date period for the report using the from and to dates.
select @DatePeriod = convert(varchar(11), @DateFrom, 100)
set @DatePeriod = @DatePeriod + ' - '
select @DatePeriod = @DatePeriod + convert(varchar(11), @DateTo, 100)

-- Create new temp VIEW.
DECLARE @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_NonBillable_Resource_Detail_View AS select NonBillable_Resource_Summary_View.*, 
CO_Resource.Onshore, CO_Resource.Offshore, CO_Resource.Hourly, CO_Resource.BillingRate, CO_BillingCodeRate.BillingRateOnshore, CO_BillingCodeRate.BillingRateOffshore
from NonBillable_Resource_Summary_View 
inner join CO_Resource ON NonBillable_Resource_Summary_View.ResourceNumber = CO_Resource.ResourceNumber 
inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID 
left outer join CO_BillingCodeRate ON CO_BillingCodeRate.Billing_CodeID = CO_Resource.Billing_CodeID 
where WorkDate >= ''2018-03-01'' and WorkDate <= ''2018-03-31'' '
exec (@SQL_statement)
--select * from SP_Get_NonBillable_Resource_Detail_View
		
-- Copy the data from the temp VIEW into #TEMP_IN working storage. (Not using: ResourceOrg, ServiceCategory 
select ResourceNumber, ResourceName, WorkDate, sum(hours) as hours, ProjectUID, ProjectTitle, TaskUID, TaskName, Billing_CodeID, Billing_CodeDesc, TaskClientFundingPct, TaskClientFundedBy, Onshore, Offshore, Hourly, BillingRate, BillingRateOnshore, BillingRateOffshore
into #TEMP_IN from dbo.SP_Get_NonBillable_Resource_Detail_View 
group by ProjectTitle, ProjectUID, TaskName, TaskUID, ResourceName, ResourceNumber, Billing_CodeID, Billing_CodeDesc, TaskClientFundingPct, TaskClientFundedBy, WorkDate, Onshore, Offshore, Hourly, BillingRate, BillingRateOnshore, BillingRateOffshore
order by ProjectTitle, TaskName, ResourceName

-- Alter table definitions.
ALTER TABLE #TEMP_IN ALTER COLUMN ResourceNumber varchar(15) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN Billing_CodeDesc varchar(50) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN TaskUID varchar(100) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ProjectUID varchar(100) NULL

-- Adjust the Hours according to the ClientFundingPct by CO
update #TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0
	
--select * from #TEMP_IN 
---------------------------------------------------------------------------------------------------
-- Create the output table #TEMP_OUT.	
CREATE TABLE [dbo].[#TEMP_OUT] ( 
	[AutoKey][int] IDENTITY (0, 1) NOT NULL, 
	[ProjectNumber] [varchar] (30) NULL, 
	[ProjectName] [varchar] (100) NULL, 
	[ResourceNumber] [varchar] (30) NULL, 
	[ResourceName] [varchar] (50) NULL,
	[TaskName] [varchar] (100) NULL, 
	[SummaryTaskName] [varchar] (30) NULL, 
	[WorkDate] [varchar] (10) NULL, 
	[Hours] [decimal](10,2) NULL, 
	[ResourceRole] [varchar] (30) NULL, 
	[ResourceType] [varchar] (30) NULL, 
	[BillingCode] [varchar] (30) NULL,
	[BillingCodeID] [varchar] (30) NULL,
	[BillingRate] [decimal](10,2),
	[ResourceHourlyRate] [decimal](10,2),
	[BillingRateOnshore] [decimal](10,2),
	[BillingRateOffshore] [decimal](10,2),
	[ProgrammeProjectManager] [varchar] (50) NULL
) ON [PRIMARY]

--------------------------------------------------------------------------------------------------------
-- ProjDesc_cursor, populates record type 40.
DECLARE ProjDesc_cursor CURSOR FOR 
	select distinct ProjectUID, ProjectTitle from #TEMP_IN where ProjectUID is not null order by ProjectTitle 	
OPEN ProjDesc_cursor
FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
WHILE @@FETCH_STATUS = 0
BEGIN
	--Get the Programme Project Manager name for each project.
	select @ProgrammeProjectManager = ProgrammeProjectManager from R2_Import..Exception_Project where ProjectUid = @CurProjID
		
	--------------------------------------------------------------------------------------------
	-- Task_cursor, populates record type 50.
	DECLARE Task_cursor CURSOR FOR
		select distinct TaskUID, TaskName from #TEMP_IN where ProjectUID = @CurProjID order by TaskName	
	OPEN Task_cursor
	FETCH NEXT FROM Task_cursor INTO @CurTaskID, @CurTaskName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		select @ProjectNumber = TaskText21 from R2_Import..all_Task where TaskuId = @CurTaskID
		select @SummaryTaskName = TaskText24 from R2_Import..all_Task where TaskuId = @CurTaskID

		--------------------------------------------------------------------------------------------
		---Resource_cursor, populates Resources under Tasks, record type 60.
		DECLARE Resource_cursor CURSOR FOR
			select ResourceNumber, ResourceName, Billing_CodeID, Billing_CodeDesc, Onshore, Offshore, Hourly, BillingRate, BillingRateOnshore, BillingRateOffshore, sum(Hours), convert(varchar(10), Workdate, 101) 
			from #TEMP_IN where ProjectUID = @CurProjID and TaskUID = @CurTaskID and ResourceName is not NULL group by ResourceName, ResourceNumber, Billing_CodeDesc, Billing_CodeID, Onshore, Offshore, Hourly, BillingRate, BillingRateOnshore, BillingRateOffshore, Workdate order by ResourceName
		OPEN Resource_cursor
		FETCH NEXT FROM Resource_cursor INTO @ResourceNumber, @CurResourceName, @Billing_CodeID, @Billing_CodeDesc, @Onshore, @Offshore, @hourly, @BillingRate, @BillingRateOnshore, @BillingRateOffshore, @hours, @WorkDate
		WHILE @@FETCH_STATUS = 0
		BEGIN
		--print 'ResName= ' + @CurResourceName			print 'BillingCode= ' + @Billing_CodeID
		
		--Set ResourceHourlyRate		
   		If @Billing_CodeID >= '3000' or @Billing_CodeID <= '3007' or @Billing_CodeID >= '3020'
   			begin
	   		If @Onshore = 1 
	   			begin
  				set @ResourceHourlyRate = @BillingRateOnshore / 149
   				end
   			If @Offshore = 1 
   				begin
   				set @ResourceHourlyRate = @BillingRateOffshore / 143.5
   				end
   			end
   		Else
   			set @ResourceHourlyRate = 0.00
			   			
		--print 'onshore= ' + convert(nvarchar(5),@Onshore)		print 'BillingRateOnshore= ' print @BillingRateOnshore		print 'offshore= ' + convert(nvarchar(5), @Offshore)	print 'BillingRateOffshore= ' print @BillingRateOffshore
			
		--Set ResourceType
   		If @Onshore = 1 
   			set @ResourceType = 'Contractor-On'
   		If @Offshore = 1 
   			set @ResourceType = 'Contractor-Off'
   		
		--Set ResourceRole
		If @Billing_CodeDesc like '%SE%'
			set @ResourceRole = 'Developer'
		If @Billing_CodeDesc like '%Cons Arch%'
			set @ResourceRole = 'Architect'
		If @Billing_CodeDesc like '%Project%'
			set @ResourceRole = 'Project Manager'
		If @Billing_CodeDesc like '%Program Mgr%'
			set @ResourceRole = 'Project Manager'
		
		--Set SummaryTaskName
		If @SummaryTaskName = 'DEF'
			set @SummaryTaskName = 'Feasibility'
		If @SummaryTaskName = 'IMPL'
			set @SummaryTaskName = 'Deploy'
		If @SummaryTaskName = 'POST'
			set @SummaryTaskName = 'Closeout'
		If @SummaryTaskName = 'PM'
			set @SummaryTaskName = 'Analysis'
		
		insert #TEMP_OUT (ProjectNumber, ProjectName, ResourceNumber, ResourceName, TaskName, SummaryTaskName, WorkDate, Hours, ResourceRole, ResourceType, 
			BillingCode, BillingCodeID, BillingRate, ResourceHourlyRate, BillingRateOnshore, BillingRateOffshore, ProgrammeProjectManager) 
		select @ProjectNumber, @CurProjectTitle, @ResourceNumber, @CurResourceName, @CurTaskName, @SummaryTaskName, @WorkDate, @hours, @ResourceRole, @ResourceType,
			@Billing_CodeDesc, @Billing_CodeID, @BillingRate, @ResourceHourlyRate, @BillingRateOnshore, @BillingRateOffshore, @ProgrammeProjectManager
											
		--Reset flags
		set @Onshore = 0
		set @Offshore = 0
		set @ResourceType = null
		set @ResourceHourlyRate = 0		
			
		FETCH NEXT FROM Resource_cursor INTO @ResourceNumber, @CurResourceName, @Billing_CodeID, @Billing_CodeDesc, @Onshore, @Offshore, @hourly, @BillingRate, @BillingRateOnshore, @BillingRateOffshore, @hours, @WorkDate
		END    
		CLOSE Resource_cursor
		DEALLOCATE Resource_cursor
					
	FETCH NEXT FROM Task_cursor INTO @CurTaskID, @CurTaskName
	END    
	CLOSE Task_cursor
	DEALLOCATE Task_cursor
		
FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
END    
CLOSE ProjDesc_cursor
DEALLOCATE ProjDesc_cursor

delete #TEMP_OUT where Hours = 0 or Hours is NULL

----------------------------------------------------------------------------------------------------------------------
select * from #TEMP_OUT order by AutoKey


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-- Clean up temporary table from yesterday's run.
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[TEMP_FIXED_PRICE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[TEMP_FIXED_PRICE]

CREATE TABLE [dbo].[TEMP_FIXED_PRICE] (
	[ProjectNumber] 		varchar(30)	NULL,
	[ProjectName]			varchar(100) NULL,
	[ResourceNumber] 		varchar(30) NULL,
	[ResourceName] 			varchar(50) NULL,
	[TaskName]				varchar(100) NULL,
	[SummaryTaskName]		varchar(30)	NULL,   
	[WorkDate]				varchar(10) NULL,           
	[Hours]					varchar(30) NULL,
	[ResourceRole]			varchar(30) NULL,
	[ResourceType]			varchar(30) NULL,
	[BillingCode]			varchar(30) NULL,	
	[ResourceHourlyRate]	varchar(30) NULL,	
	[ProgrammeProjectManager]	varchar(50) NULL
) ON [PRIMARY]

-- Insert Column Headings into output table.
insert into TEMP_FIXED_PRICE (ProjectNumber, ProjectName, ResourceNumber, ResourceName, TaskName, SummaryTaskName, WorkDate, Hours, ResourceRole, ResourceType, BillingCode, ResourceHourlyRate, ProgrammeProjectManager) 
values ('ProjectNumber', 'ProjectName', 'ResourceNumber', 'ResourceName', 'TaskName', 'SummaryTaskName', 'WorkDate', 'Hours', 'ResourceRole', 'ResourceType', 'BillingCode', 'ResourceHourlyRate', 'ProgrammeProjectManager')

-- Insert data rows from #TEMP_OUT into output table.
insert into TEMP_FIXED_PRICE (ProjectNumber, ProjectName, ResourceNumber, ResourceName, TaskName, SummaryTaskName, WorkDate, Hours, ResourceRole, ResourceType, BillingCode, ResourceHourlyRate, ProgrammeProjectManager)
select ProjectNumber, ProjectName, ResourceNumber, ResourceName, TaskName, SummaryTaskName, WorkDate, Hours, ResourceRole, ResourceType, BillingCode, ResourceHourlyRate, ProgrammeProjectManager
from #TEMP_OUT order by ProjectNumber, ProjectName, ResourceName, WorkDate

-- Drop the view from yesterday's output report.
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[VIEW_FIXED_output]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[VIEW_FIXED_output]

-- Generate data for final output report.
SET @SQL_statement = 'Create View dbo.VIEW_FIXED_output AS select ProjectNumber, ProjectName, ResourceNumber, ResourceName, TaskName, SummaryTaskName, WorkDate, Hours, ResourceRole, ResourceType, BillingCode, ResourceHourlyRate, ProgrammeProjectManager 
FROM TEMP_FIXED_PRICE'
EXEC (@SQL_statement)

-- Delete previously created file.
set @SQL_statement = ' del G:\Applications\PIV_Transfer\Download\Fixed_DXC_Funded_Projects_Report.xls'
exec master..xp_cmdshell @SQL_statement

-- BCP the Data to a File
EXEC master.dbo.xp_cmdshell 'bcp R2_Reports..VIEW_FIXED_output out "G:\Applications\PIV_Transfer\Download\Fixed_DXC_Funded_Projects_Report.xls" -c -t\t -T -SUSHOSEDS131C\PROD'

-- Email the Results as an Attachment
set @ResultsFile = 'G:\Applications\PIV_Transfer\Download\Fixed_DXC_Funded_Projects_Report.xls'
set @BodyText = 'The attached file contains the Fixed DXC Funded Projects Report generated on the R2 Production Server for ' + @DatePeriod + '.'
EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'SQL_DBMail',
      @recipients = 'lizzy.lopez@dxc.com;fatima.pappas@hpe.com;kathy.anderson3@hpe.com',
      --@recipients = 'lizzy.lopez@dxc.com;fatima.pappas@hpe.com;lori.malone@hpe.com;lee.preston@hpe.com;cindys@hpe.com;kathy.anderson3@hpe.com;linda.pridgeon@hpe.com;SHARES-SHA-Support-pf@hpe.com',
      @body = @BodyText,
      @subject = 'Fixed DXC Funded Projects Report',
      @file_attachments  = @ResultsFile
