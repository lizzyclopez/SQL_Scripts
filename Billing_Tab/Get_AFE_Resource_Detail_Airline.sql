---------------------------------STEP 1------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_Get_AFE_Resource_Detail_Airline_View]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[SP_Get_AFE_Resource_Detail_Airline_View]

DECLARE @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Resource_Detail_Airline_View AS select AFE_Resource_Summary_View.*, CO_Resource.Onshore, CO_Resource.Offshore, CO_Resource.Hourly, CO_BillingCode.Billing_CodeID, CO_BillingCode.Description AS NewBillingType
from AFE_Resource_Summary_View inner join CO_Resource ON AFE_Resource_Summary_View.ResourceNumber = CO_Resource.ResourceNumber
inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID
where WorkDate >= ''06/01/2008'' and WorkDate <= ''06/30/2008'' and ITSABillingCat in (''AFE_Prod'') '
exec (@SQL_statement)

--select * from SP_Get_AFE_Resource_Detail_Airline_View order by ResourceName

---------------------------------STEP 2------------------------------------------
--Only use this if you need to drop #TEMP_IN in order to insert the next line
--IF OBJECT_ID('tempdb..#TEMP_IN') IS NOT NULL DROP TABLE #TEMP_IN

-- Insert data into #TEMP_IN from temp view.
select ProgramGroup, Program, AFEDesc, ITSABillingCat, ProjectTitle, TaskName, EventList, eventname, 
	ResourceName, billingid, Prog_GroupID, ProgramID, AFE_DescID, Client, BillingFlag, ClientFundingPct, 
	ClientFundedBy, NewBillingType, Type, TaskClientFundingPct, TaskClientFundedBy, Funding_CatID, 
	ProjectStatusID, ResourceNumber, ProjectID, TaskID, eventlistid, sum(hours) as hours, COBusinessLead, Onshore, Offshore, Hourly
into #TEMP_IN from dbo.SP_Get_AFE_Resource_Detail_Airline_View
group by ProgramGroup, Program, AFEDesc, ITSABillingCat, ProjectTitle, TaskName, EventList, eventname, 
	ResourceName, billingid, Prog_GroupID, ProgramID, AFE_DescID, Client, BillingFlag, ClientFundingPct, 
	ClientFundedBy, NewBillingType, Type, TaskClientFundingPct, TaskClientFundedBy, Funding_CatID, 
	ProjectStatusID, ResourceNumber, ProjectID, TaskID, eventlistid, COBusinessLead, Onshore, Offshore, Hourly
order by ProgramGroup, Program, AFEDesc, ProjectTitle, TaskName, EventList, eventname, ResourceName

---------------------------------STEP 3------------------------------------------
-- Drop temp view.
exec('Drop View dbo.SP_Get_AFE_Resource_Detail_Airline_View')

---------------------------------STEP 4------------------------------------------
-- Alter table definitions.
ALTER TABLE #TEMP_IN ADD Appr_FTE_Hours decimal(7,2) NULL
ALTER TABLE #TEMP_IN ADD CurrentMonth varchar(6) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN TaskID int NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ProjectID bigint NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ResourceNumber varchar(15) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN NewBillingType varchar(50) NULL

---------------------------------STEP 5------------------------------------------
-- Drop the second temp VIEW if it exists.
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_Get_AFE_Resource_Detail_Airline_View2]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[SP_Get_AFE_Resource_Detail_Airline_View2]

---------------------------------STEP 6------------------------------------------
declare @ITSABillingCat varchar(30), @SQL_statement varchar(1000)
set @ITSABillingCat = 'AFE_Prod'
set @SQL_statement = ''
	if ( @ITSABillingCat <> '-1' )
	   select @SQL_statement = @SQL_statement+' and lkITSABillingCategory.Description in ('+@ITSABillingCat+')'
print @SQL_statement


-- Create the second temp VIEW.
DECLARE @SQL_statement varchar(1000) 
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Resource_Detail_Airline_View2 AS select dbo.lkITSABillingCategory.Description AS ITSABillingCat, FTE_Approved_Time.* from FTE_Approved_Time 
	LEFT OUTER JOIN dbo.tblAFEDetail ON FTE_Approved_Time.AFE_DescID = dbo.tblAFEDetail.AFE_DescID 
	LEFT OUTER JOIN dbo.lkITSABillingCategory ON dbo.tblAFEDetail.ITSABillingCategoryID = dbolkITSABillingCategory.ITSABillingCategoryID 
	where Appr_FTE_Hours > 0 and lkITSABillingCategory.Description = ''AFE_Prod''  ' 
exec (@SQL_statement)

select * from SP_Get_AFE_Resource_Detail_Airline_View2

---------------------------------STEP 7------------------------------------------
-- Copy the data from the second temp VIEW into #TEMP_IN.
insert #TEMP_IN (AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead)
select AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID ,COBusinessLead from dbo.SP_Get_AFE_Resource_Detail_Airline_View2

---------------------------------STEP 8------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_Get_AFE_Resource_Detail_Airline_View2]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[SP_Get_AFE_Resource_Detail_Airline_View2]

---------------------------------STEP 9------------------------------------------
-- Adjust the Hours according to the ClientFundingPct by CO
update #TEMP_IN set Hours = isnull(ClientFundingPct,100)/100*Hours where isnull(ClientFundingPct,0) > 0
update #TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0

select * from #TEMP_IN

---------------------------------STEP 10------------------------------------------
IF OBJECT_ID('tempdb..#TEMP_OUT') IS NOT NULL DROP TABLE #TEMP_OUT

-- Create the output table #TEMP_OUT.
CREATE TABLE [dbo].[#TEMP_OUT] ( 
	[AutoKey][int] IDENTITY (0, 1) NOT NULL, 
	[RecNumber][int] NULL, [RecType] [varchar] (100) NULL,  [RecDesc] [varchar] (100) NULL,  [RecTypeID] [bigint] NULL,          
	[ITSABillingCat] [varchar] (30) NULL, [FundingCat] [varchar] (30) NULL, [AFENumber] [varchar] (20) NULL,
	[COBusinessLead] [varchar] (100) NULL, [ProgramMgr] [varchar] (50) NULL, [Location] [varchar] (30) NULL,
	[TotalHours] [decimal](10,2) NULL, [ActualFTEs] [decimal](10,2) NULL, [COApprovedFTEs] [decimal](10,2) NULL, [EDSVariance] [decimal](10,2) NULL,
	[JrSEOnshoreHours] [decimal](10,2) NULL, [JrSeOffshoreHours] [decimal](10,2) NULL, 
	[MidSEOnshoreHours] [decimal](10,2) NULL, [MidSEOffshoreHours] [decimal](10,2) NULL,
	[AdvSEOnshoreHours] [decimal](10,2) NULL, [AdvSEOffshoreHours] [decimal](10,2) NULL,
	[SenSEOnshoreHours] [decimal](10,2) NULL, [SenSEOffshoreHours] [decimal](10,2) NULL,
	[ConsArchOnshoreHours] [decimal](10,2) NULL, [ConsArchOffshoreHours] [decimal](10,2) NULL,
	[ProjLeadOnshoreHours] [decimal](10,2) NULL, [ProjLeadOffshoreHours] [decimal](10,2) NULL,
	[ProjMgrOnshoreHours] [decimal](10,2) NULL, [ProjMgrOffshoreHours] [decimal](10,2) NULL,
	[ProgMgrOnshoreHours] [decimal](10,2) NULL, [R10_ProgramGroup] [varchar] (100) NULL,
	[R20_Program] [varchar] (100) NULL, [R30_AFEDesc] [varchar] (100) NULL, [R40_Project] [varchar] (100) NULL,
	[R50_Task] [varchar] (100) NULL, [R55_EventTitle] [varchar] (100) NULL, [R56_Event] [varchar] (100) NULL
) ON [PRIMARY]

---------------------------------STEP 11------------------------------------------
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Total Continental (CO)'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotalConversion', 'FTE Conversion'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 1, 'TotalAirline', 'Total Airline'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 1, 'TotalAirlineConversion', 'FTE Conversion'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 2, 'TotalADM', 'Total ADM'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 2, 'TotalADMConversion', 'FTE Conversion'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 4, 'TotalAFEProd', 'Total AFE Prod'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 4, 'TotalAFEProdConversion', 'FTE Conversion'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'TotalStaffAug', 'Total Staff Augmentation (FTE Based)'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'TotalStafAugConversion', 'FTE Conversion'

------------------------------------STEP 12-------------------------------------------------------------
-- Declare variables.
DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID int, @CurProgram varchar(100), @CurProgramID int, @CurCOBusinessLead varchar(100), @CurAFEDesc varchar(100), @CurAFE_DescID int, @CurProjectTitle varchar(100), @CurProjID bigint, @CurTaskName varchar(100), @CurTaskID int, @CurResourceName varchar(100), @CurEventList varchar(100), @CurEventName varchar(100), @Billing_Type varchar(150), @Hours decimal(10,2), @MaxProgGroup int, @MaxProg int, @MaxAFEDesc int, @MaxProj bigint, @MaxTask int, @MaxEvent int, @Onshore bit, @Offshore bit, @Hourly bit
Declare @JrSEOnshore decimal(10,2), @JrSEOffshore decimal(10,2), @MidSEOnshore decimal(10,2), @MidSEOffshore decimal(10,2), @AdvSEOnshore decimal(10,2), @AdvSEOffshore decimal(10,2), @SenSEOnshore decimal(10,2), @SenSEOffshore decimal(10,2), @ConsArchOnshore decimal(10,2), @ConsArchOffshore decimal(10,2), @ProjLeadOnshore decimal(10,2), @ProjLeadOffshore decimal(10,2), @ProjMgrOnshore decimal(10,2), @ProjMgrOffshore decimal(10,2), @ProgMgrOnshore decimal(10,2), @TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2)
Declare @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2)  

-------ProgramGroup_cursor, populates record type 10.---------
DECLARE ProgramGroup_cursor CURSOR FOR 
	select distinct ProgramGroup, Prog_GroupID from #TEMP_IN where ProgramGroup is not null order by ProgramGroup 
OPEN ProgramGroup_cursor
FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID 
WHILE @@FETCH_STATUS = 0
BEGIN
	insert #TEMP_OUT (RecNumber) values (10) -- A blank line
	insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID) select 10, 'ProgGroup/Total', @CurProgramGroup, @CurProg_GroupID
	select @MaxProgGroup = max(AutoKey) from #TEMP_OUT

	--------Program_cursor, populates record type 20.--------
	DECLARE Program_cursor CURSOR FOR 
		select distinct Program, ProgramID, COBusinessLead from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program is not null order by Program
	OPEN Program_cursor
	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID, @CurCOBusinessLead
	WHILE @@FETCH_STATUS = 0
	BEGIN
		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, COBusinessLead) select 20, 'Program', @CurProgram, @CurProgramID, @CurProgramGroup, @CurCOBusinessLead
		select @MaxProg = max(AutoKey) from #TEMP_OUT

		--------AFEDesc_cursor, populates record type 30.--------
		DECLARE AFEDesc_cursor CURSOR FOR 
			select distinct AFEDesc, AFE_DescID from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFEDesc is not null order by AFEDesc
		OPEN AFEDesc_cursor
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID
		WHILE @@FETCH_STATUS = 0
		BEGIN
			insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program) select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID, @CurProgramGroup, @CurProgram
			select @MaxAFEDesc = max(AutoKey) from #TEMP_OUT

			--------ProjDesc_cursor, populates record type 40.--------
			DECLARE ProjDesc_cursor CURSOR FOR 
				select distinct ProjectID, ProjectTitle from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID is not null order by ProjectTitle 
			OPEN ProjDesc_cursor
			FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
			WHILE @@FETCH_STATUS = 0
			BEGIN
				insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, R30_AFEDesc) select 40, 'ProjDesc', @CurProjectTitle, @CurProjID, @CurProgramGroup, @CurProgram, @CurAFEDesc
				select @MaxProj = max(AutoKey) from #TEMP_OUT 

				--------Task_cursor, populates record type 50.--------
				DECLARE Task_cursor CURSOR FOR
					select distinct TaskID, TaskName from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID order by TaskName
				OPEN Task_cursor
				FETCH NEXT FROM Task_cursor INTO @CurTaskID, @CurTaskName
				WHILE @@FETCH_STATUS = 0
				BEGIN
					insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project) select 50, 'TaskDesc', @CurTaskName, @CurTaskID, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle
					select @MaxTask = max(AutoKey) from #TEMP_OUT

					--------Resource_cursor, populates Resources under Tasks, record type 60.--------
					DECLARE Resource_cursor CURSOR FOR
						select ResourceName, NewBillingType, Onshore, Offshore, Hourly, Hours from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and TaskID = @CurTaskID and EventList is NULL and EventName is NULL and ResourceName is not NULL order by ResourceName
					OPEN Resource_cursor
					FETCH NEXT FROM Resource_cursor INTO @CurResourceName, @Billing_Type, @Onshore, @Offshore, @Hourly, @hours
					WHILE @@FETCH_STATUS = 0
					BEGIN
	   					-- Determine billing type for Resource and then insert record
						if @Billing_Type = 'Jr SE' and @Onshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, JrSEOnshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Jr SE' and @Offshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, JrSeOffshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Mid SE' and @Onshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, MidSEOnshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Mid SE' and @Offshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, MidSEOffshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Adv SE' and @Onshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, AdvSEOnshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Adv SE' and @Offshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, AdvSEOffshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Sen SE' and @Onshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, SenSEOnshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Sen SE' and @Offshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, SenSEOffshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Cons Arch' and @Onshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, ConsArchOnshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Cons Arch' and @Offshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, ConsArchOffshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Project Lead' and @Onshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, ProjLeadOnshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Project Lead' and @Offshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, ProjLeadOffshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Project Mgr' and @Onshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, ProjMgrOnshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Project Mgr' and @Offshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, ProjMgrOffshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Program Mgr' and @Onshore = 1 insert #TEMP_OUT (RecNumber, RecType, RecDesc, ProgMgrOnshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event) select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName                                            
					FETCH NEXT FROM Resource_cursor INTO @CurResourceName, @Billing_Type, @Onshore, @Offshore, @Hourly, @hours
                    END    
                    CLOSE Resource_cursor
                    DEALLOCATE Resource_cursor

				-----------------------------------------------------------------------------------------------------------------------
				-- SUMMARIZE total hours for each task (vertical), record type 60.    
				select @JrSEOnshore = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshore = sum(isnull(JrSeOffshoreHours,0)), @MidSEOnshore = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshore = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshore = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshore = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshore = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshore= sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshore = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshore= sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshore = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshore= sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshore = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshore= sum(isnull(ProjMgrOffshoreHours,0)), 
						@ProgMgrOnshore = sum(isnull(ProgMgrOnshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0))					
				from #TEMP_OUT where AutoKey > @MaxTask and RecNumber = 60

				update #TEMP_OUT
				set JrSEOnshoreHours = @JrSEOnshore, JrSeOffshoreHours = @JrSEOffshore, MidSEOnshoreHours = @MidSEOnshore, MidSEOffshoreHours = @MidSEOffshore, AdvSEOnshoreHours = @AdvSEOnshore, AdvSEOffshoreHours = @AdvSEOffshore, SenSEOnshoreHours = @SenSEOnshore, SenSEOffshoreHours = @SenSEOffshore, ConsArchOnshoreHours = @ConsArchOnshore, ConsArchOffshoreHours = @ConsArchOffshore, ProjLeadOnshoreHours = @ProjLeadOnshore, ProjLeadOffshoreHours = @ProjLeadOffshore, ProjMgrOnshoreHours = @ProjMgrOnshore, ProjMgrOffshoreHours = @ProjMgrOffshore, 
					ProgMgrOnshoreHours = @ProgMgrOnshore, TotalHours = @TotalHours
				where AutoKey = @MaxTask
			FETCH NEXT FROM Task_cursor INTO @CurTaskID, @CurTaskName
            END    
            CLOSE Task_cursor
            DEALLOCATE Task_cursor

		-----------------------------------------------------------------------------------------------------------------------
       
		-- SUMMARIZE at Project Level on 10 fields (vertical), record type 50.
		select @JrSEOnshore = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshore = sum(isnull(JrSeOffshoreHours,0)), @MidSEOnshore = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshore = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshore = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshore = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshore = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshore= sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshore = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshore= sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshore = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshore= sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshore = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshore= sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshore = sum(isnull(ProgMgrOnshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0))					
		from #TEMP_OUT where AutoKey > @MaxProj and RecNumber = 50 

		update #TEMP_OUT
		set JrSEOnshoreHours = @JrSEOnshore, JrSeOffshoreHours = @JrSEOffshore, MidSEOnshoreHours = @MidSEOnshore, MidSEOffshoreHours = @MidSEOffshore, AdvSEOnshoreHours = @AdvSEOnshore, AdvSEOffshoreHours = @AdvSEOffshore, SenSEOnshoreHours = @SenSEOnshore, SenSEOffshoreHours = @SenSEOffshore, ConsArchOnshoreHours = @ConsArchOnshore, ConsArchOffshoreHours = @ConsArchOffshore, ProjLeadOnshoreHours = @ProjLeadOnshore, ProjLeadOffshoreHours = @ProjLeadOffshore, ProjMgrOnshoreHours = @ProjMgrOnshore, ProjMgrOffshoreHours = @ProjMgrOffshore, 
    		ProgMgrOnshoreHours = @ProgMgrOnshore, TotalHours = @TotalHours
		where AutoKey = @MaxProj    

	FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
    END    
    CLOSE ProjDesc_cursor
    DEALLOCATE ProjDesc_cursor

	--Delete these variables after testing.
	declare @DateFrom datetime, @DateTo datetime
	set @DateFrom = '06-01-2008'
	set @DateTo = '06-30-2008'
                
	-- Populate the ITSA Billing Category.
	declare @ITSABillingCat varchar(30)
	select @ITSABillingCat = ITSABillingCat from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 

	select @JrSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Jr SE' and Onshore = 1
	select @JrSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Jr SE' and Offshore = 1
	select @MidSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Mid SE' and Onshore = 1
	select @MidSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Mid SE' and Offshore = 1
	select @AdvSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Adv SE' and Onshore = 1
	select @AdvSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Adv SE' and Offshore = 1
	select @SenSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Sen SE' and Onshore = 1
	select @SenSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Sen SE' and Offshore = 1
	select @ConsArchOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Cons Arch' and Onshore = 1
	select @ConsArchOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Cons Arch' and Offshore = 1
	select @ProjLeadOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Project Lead' and Onshore = 1
	select @ProjLeadOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Project Lead' and Offshore = 1
	select @ProjMgrOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Project Mgr' and Onshore = 1
	select @ProjMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Project Mgr' and Offshore = 1				
	select @ProgMgrOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
		NewBillingType = 'Program Mgr' and Onshore = 1	

	-- GET funding category and location combo.
	Declare @@out_location varchar (100), @@out_fundingcat varchar (100), @@out_afenumber varchar (20), @@out_programmgr varchar (50), @@Total_FTE float             
	set @@out_location  = NULL	
	set @@out_fundingcat = NULL
	set @@out_afenumber = NULL
	set @@Total_FTE = NULL
	exec GET_Location_Combo @CurAFE_DescID, @DateFrom, @DateTo, @@out_location OUTPUT, @@out_fundingcat OUTPUT, @@out_afenumber OUTPUT, @@out_programmgr OUTPUT, @@Total_FTE OUTPUT

	-- UPDATE temporary table --
	update #TEMP_OUT set ITSABillingCat = @ITSABillingCat, location = @@out_location, fundingcat = @@out_fundingcat, AFENumber = @@out_afenumber, COApprovedFTEs = isnull(@@Total_FTE,0),
	JrSEOnshoreHours = isnull(@JrSEOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshore,0), MidSEOnshoreHours = isnull(@MidSEOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshore,0), AdvSEOnshoreHours = isnull(@AdvSEOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshore,0),	SenSEOnshoreHours = isnull(@SenSEOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshore,0), ConsArchOnshoreHours = isnull(@ConsArchOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshore,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshore,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshore,0),	
	ProgMgrOnshoreHours = isnull(@ProgMgrOnshore,0)
	where AutoKey = @MaxAFEDesc

	-- Populate TotalHours Column for record type 30, 40, 50, 56, 60 (horizontal add up).
	update #TEMP_OUT set TotalHours = isnull(@JrSEOnshore,0) + isnull(@JrSEOffshore,0) + isnull(@MidSEOnshore,0) + isnull(@MidSEOffshore,0) + isnull(@AdvSEOnshore,0) + isnull(@AdvSEOffshore,0) + isnull(@SenSEOnshore,0) + isnull(@SenSEOffshore,0) + isnull(@ConsArchOnshore,0) + isnull(@ConsArchOffshore,0) + isnull(@ProjLeadOnshore,0) + isnull(@ProjLeadOffshore,0) + isnull(@ProjMgrOnshore,0) + isnull(@ProjMgrOffshore,0) + isnull(@ProgMgrOnshore,0)
	where AutoKey > @MaxProgGroup and RecNumber in (30, 40, 50, 56, 60)

	--update #TEMP_OUT set TotalHours = isnull(@JrSEOnshore,0)+isnull(@JrSEOffshore,0)+ isnull(@MidSEOnshore,0)+isnull(@MidSEOffshore,0)+ isnull(@AdvSEOnshore,0)+isnull(@AdvSEOffshore,0)+ isnull(@SenSEOnshore,0)+isnull(@SenSEOffshore,0)+ isnull(@ConsArchOnshore,0)+isnull(@ConsArchOffshore,0)+ isnull(@ProjLeadOnshore,0)+isnull(@ProjLeadOffshore,0)+ isnull(@ProjMgrOnshore,0)+isnull(@ProjMgrOffshore,0)+ isnull(@ProgMgrOnshore,0)
	--where AutoKey > @MaxProgGroup and RecNumber = 40

	--update #TEMP_OUT set TotalHours = isnull(@JrSEOnshore,0)+isnull(@JrSEOffshore,0)+ isnull(@MidSEOnshore,0)+isnull(@MidSEOffshore,0)+isnull(@AdvSEOnshore,0)+isnull(@AdvSEOffshore,0)+ isnull(@SenSEOnshore,0)+isnull(@SenSEOffshore,0)+	isnull(@ConsArchOnshore,0)+isnull(@ConsArchOffshore,0)+ isnull(@ProjLeadOnshore,0)+isnull(@ProjLeadOffshore,0)+	isnull(@ProjMgrOnshore,0)+isnull(@ProjMgrOffshore,0)+ isnull(@ProgMgrOnshore,0)
	--where AutoKey > @MaxProgGroup and RecNumber = 60

	-- UPDATE Summary Fields --
	update #TEMP_OUT set ActualFTEs = TotalHours/143.5 where AutoKey > @MaxAFEDesc and RecNumber in (30, 40, 50, 56, 60)
	--update #TEMP_OUT set TotalHours = (select isnull(sum(TotalHours),0) from #TEMP_OUT where AutoKey > @MaxAFEDesc and RecNumber = 40), 
	--					 ActualFTEs = (select isnull(sum(ActualFTEs),0) from #TEMP_OUT where AutoKey > @MaxAFEDesc and RecNumber = 40) where AutoKey = @MaxAFEDesc
	--update #TEMP_OUT set ActualFTEs = TotalHours/143.5 where AutoKey = @MaxAFEDesc
select @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)) from #TEMP_OUT where AutoKey > @MaxProg and RecNumber = 40
print @COApprovedFTEs

	update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey = @MaxAFEDesc

	FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID
	END    
	CLOSE AFEDesc_cursor
	DEALLOCATE AFEDesc_cursor

-----------------------------------------------------------------------------------------------------------------------
--Declare @JrSEOnshore decimal(10,2), @JrSEOffshore decimal(10,2), @MidSEOnshore decimal(10,2), @MidSEOffshore decimal(10,2), @AdvSEOnshore decimal(10,2), @AdvSEOffshore decimal(10,2), @SenSEOnshore decimal(10,2), @SenSEOffshore decimal(10,2), @ConsArchOnshore decimal(10,2), @ConsArchOffshore decimal(10,2), @ProjLeadOnshore decimal(10,2), @ProjLeadOffshore decimal(10,2), @ProjMgrOnshore decimal(10,2), @ProjMgrOffshore decimal(10,2), @ProgMgrOnshore decimal(10,2), @TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2), @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2)  

	Select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSeOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), 	@MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), 	@AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), 	@SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), 
	@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0))
	-----------@TotalHours = sum(isnull(TotalHours,0))
	----------@TotalHours = isnull(@JrSEOnshoreHours,0)+isnull(@JrSEOffshoreHours,0)+ isnull(@MidSEOnshoreHours,0)+isnull(@MidSEOffshoreHours,0)+ isnull(@AdvSEOnshoreHours,0)+isnull(@AdvSEOffshoreHours,0)+ isnull(@SenSEOnshoreHours,0)+isnull(@SenSEOffshoreHours,0)+ isnull(@ConsArchOnshoreHours,0)+isnull(@ConsArchOffshoreHours,0)+ isnull(@ProjLeadOnshoreHours,0)+isnull(@ProjLeadOffshoreHours,0)+ isnull(@ProjMgrOnshoreHours,0)+isnull(@ProjMgrOffshoreHours,0)+ isnull(@ProgMgrOnshoreHours,0)	
	from #TEMP_OUT where AutoKey > @MaxProg and RecNumber = 30

select @TotalHours = isnull(@JrSEOnshoreHours,0)+isnull(@JrSEOffshoreHours,0)+ isnull(@MidSEOnshoreHours,0)+isnull(@MidSEOffshoreHours,0)+ isnull(@AdvSEOnshoreHours,0)+isnull(@AdvSEOffshoreHours,0)+ isnull(@SenSEOnshoreHours,0)+isnull(@SenSEOffshoreHours,0)+ isnull(@ConsArchOnshoreHours,0)+isnull(@ConsArchOffshoreHours,0)+ isnull(@ProjLeadOnshoreHours,0)+isnull(@ProjLeadOffshoreHours,0)+ isnull(@ProjMgrOnshoreHours,0)+isnull(@ProjMgrOffshoreHours,0)+ isnull(@ProgMgrOnshoreHours,0)	
from #TEMP_OUT where AutoKey > @MaxProg and RecNumber = 30
--from #TEMP_OUT where AutoKey > @MaxProgGroup

----------Select @JrSEOnshore = sum(isnull(JrSEOnshoreHours,0)),	@JrSEOffshore = sum(isnull(JrSeOffshoreHours,0)), 	@MidSEOnshore = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshore = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshore = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshore = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshore = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshore= sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshore = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshore= sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshore = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshore= sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshore = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshore= sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshore = sum(isnull(ProgMgrOnshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0))
----------from #TEMP_OUT where AutoKey > @MaxProg and RecNumber = 30
----------select @TotalHours =  isnull(@JrSEOnshore,0)+isnull(@JrSEOffshore,0)+ isnull(@MidSEOnshore,0)+isnull(@MidSEOffshore,0)+ isnull(@AdvSEOnshore,0)+isnull(@AdvSEOffshore,0)+ isnull(@SenSEOnshore,0)+isnull(@SenSEOffshore,0)+ isnull(@ConsArchOnshore,0)+isnull(@ConsArchOffshore,0)+ isnull(@ProjLeadOnshore,0)+isnull(@ProjLeadOffshore,0)+ isnull(@ProjMgrOnshore,0)+isnull(@ProjMgrOffshore,0)+ isnull(@ProgMgrOnshore,0)	
----------from #TEMP_OUT where AutoKey > @MaxProg and RecNumber = 30

		-- Populate ActualFTEs column for record type 30. 
		--update #TEMP_OUT set ActualFTEs = TotalHours/143.5 where AutoKey > @MaxProgGroup and RecNumber = 30
        
		-- Populate EDSVariance column for record type 30. 
		update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey > @MaxProgGroup and RecNumber = 30


--select @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)) from #TEMP_OUT where AutoKey > @MaxProg and RecNumber = 30	

update #TEMP_OUT set JrSEOnshoreHours = @JrSEOnshoreHours, JrSeOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
	ProgMgrOnshoreHours = @ProgMgrOnshoreHours, TotalHours = @TotalHours, 
	ActualFTEs = @TotalHours/143.5, 
	COApprovedFTEs = @COApprovedFTEs
	--EDSVariance = @TotalHours/143.5 - @COApprovedFTEs
where AutoKey = @MaxProg

FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID, @CurCOBusinessLead
END
CLOSE Program_cursor
DEALLOCATE Program_cursor

FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID
END
CLOSE ProgramGroup_cursor
DEALLOCATE ProgramGroup_cursor


SELECT * from #TEMP_OUT order by AutoKey


------------------------------------STEP 13-------------------------------------------------------------









-----------------------------------------------------------------------------------------------------------------------
--Declare @JrSEOnshore decimal(10,2), @JrSEOffshore decimal(10,2), @MidSEOnshore decimal(10,2), @MidSEOffshore decimal(10,2), @AdvSEOnshore decimal(10,2), @AdvSEOffshore decimal(10,2), @SenSEOnshore decimal(10,2), @SenSEOffshore decimal(10,2), @ConsArchOnshore decimal(10,2), @ConsArchOffshore decimal(10,2), @ProjLeadOnshore decimal(10,2), @ProjLeadOffshore decimal(10,2), @ProjMgrOnshore decimal(10,2), @ProjMgrOffshore decimal(10,2), @ProgMgrOnshore decimal(10,2), @TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2)
--Declare @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2)  

-- Update vertical sum hours for record type 10 (vertical add up).
select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSeOffshoreHours,0)), 
	@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
	@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
	@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
	@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
	@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
	@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), 
	@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0)) 
from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30
--from #TEMP_OUT where AutoKey > 21 and RecNumber = 40

Select @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)) from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30

Update #TEMP_OUT set JrSEOnshoreHours = @JrSEOnshore, JrSeOffshoreHours = @JrSEOffshore, 
	MidSEOnshoreHours = @MidSEOnshore, MidSEOffshoreHours = @MidSEOffshore, 
	AdvSEOnshoreHours = @AdvSEOnshore, AdvSEOffshoreHours = @AdvSEOffshore, 
	SenSEOnshoreHours = @SenSEOnshore, SenSEOffshoreHours = @SenSEOffshore, 
	ConsArchOnshoreHours = @ConsArchOnshore, ConsArchOffshoreHours = @ConsArchOffshore, 
	ProjLeadOnshoreHours = @ProjLeadOnshore, ProjLeadOffshoreHours = @ProjLeadOffshore, 
	ProjMgrOnshoreHours = @ProjMgrOnshore, ProjMgrOffshoreHours = @ProjMgrOffshore, 
	ProgMgrOnshoreHours = @ProgMgrOnshore, TotalHours = @TotalHours, 
	ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs, EDSVariance = @TotalHours/143.5 - @COApprovedFTEs
where AutoKey = @MaxProgGroup


/*    
-- Populate TotalHours Column for record type 20 (horizontal add up).
update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) 
where AutoKey > @MaxProgGroup and RecNumber = 20
--where AutoKey > @MaxProgGroup and RecNumber = 20	--21
-- Populate TotalHours Column for record type 30 (horizontal add up).
update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) 
where AutoKey > @MaxProgGroup and RecNumber = 30
-- Populate TotalHours Column for record type 40 (horizontal add up).
update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) 
where AutoKey > @MaxProgGroup and RecNumber = 40
-- Populate TotalHours Column for record type 50 (horizontal add up).
update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) 
where AutoKey > @MaxProgGroup and RecNumber = 50

-- Populate ActualFTEs column for record type 20. 
update #TEMP_OUT set ActualFTEs = TotalHours/143.5 where AutoKey > @MaxProgGroup and RecNumber = 20
-- Populate ActualFTEs column for record type 30 (horizontal add up). 
update #TEMP_OUT set ActualFTEs = TotalHours/143.5 where AutoKey > @MaxProgGroup and RecNumber = 30
-- Populate ActualFTEs column for record type 40 (horizontal add up). 
update #TEMP_OUT set ActualFTEs = TotalHours/143.5 where AutoKey > @MaxProgGroup and RecNumber = 40

-- Populate EDSVariance column for record type 20. 
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey > @MaxProgGroup and RecNumber = 20
-- Populate EDSVariance column for record type 30 (horizontal add up).
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey > @MaxProgGroup and RecNumber = 30
-- Populate ActualFTEs column for record type 50 (horizontal add up). 
update #TEMP_OUT set ActualFTEs = TotalHours/143.5 where AutoKey > @MaxProgGroup and RecNumber = 50
*/

FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID
END
CLOSE ProgramGroup_cursor
DEALLOCATE ProgramGroup_cursor


SELECT * from #TEMP_OUT order by AutoKey

-----------------------------------------------------------------------------------------------------------------------





























-- Set all the NULL values to 0 for 60 records
update #TEMP_OUT set JrSEOnshoreHours = 0 where RecNumber = 60 and JrSEOnshoreHours is null 
update #TEMP_OUT set JrSeOffshoreHours = 0 where RecNumber = 60 and JrSeOffshoreHours is null 
update #TEMP_OUT set MidSEOnshoreHours = 0 where RecNumber = 60 and MidSEOnshoreHours is null 
update #TEMP_OUT set MidSEOffshoreHours = 0 where RecNumber = 60 and MidSEOffshoreHours is null 
update #TEMP_OUT set AdvSEOnshoreHours = 0 where RecNumber = 60 and AdvSEOnshoreHours is null 
update #TEMP_OUT set AdvSEOffshoreHours = 0 where RecNumber = 60 and AdvSEOffshoreHours is null 
update #TEMP_OUT set SenSEOnshoreHours = 0 where RecNumber = 60 and SenSEOnshoreHours is null 
update #TEMP_OUT set SenSEOffshoreHours = 0 where RecNumber = 60 and SenSEOffshoreHours is null 
update #TEMP_OUT set ConsArchOnshoreHours = 0 where RecNumber = 60 and ConsArchOnshoreHours is null 
update #TEMP_OUT set ConsArchOffshoreHours = 0 where RecNumber = 60 and ConsArchOffshoreHours is null 
update #TEMP_OUT set ProjLeadOnshoreHours = 0 where RecNumber = 60 and ProjLeadOnshoreHours is null 
update #TEMP_OUT set ProjLeadOffshoreHours = 0 where RecNumber = 60 and ProjLeadOffshoreHours is null 
update #TEMP_OUT set ProjMgrOnshoreHours = 0 where RecNumber = 60 and ProjMgrOnshoreHours is null 
update #TEMP_OUT set ProjMgrOffshoreHours = 0 where RecNumber = 60 and ProjMgrOffshoreHours is null 
update #TEMP_OUT set ProgMgrOnshoreHours = 0 where RecNumber = 60 and ProgMgrOnshoreHours is null 

	----------------------------------------------------------------------------------------------------------------------
-- Declare variables additional variables for Hours calculation.        
--Declare @JrSEOnshore decimal(10,2), @JrSEOffshore decimal(10,2), @MidSEOnshore decimal(10,2), @MidSEOffshore decimal(10,2), @AdvSEOnshore decimal(10,2), @AdvSEOffshore decimal(10,2), @SenSEOnshore decimal(10,2), @SenSEOffshore decimal(10,2), @ConsArchOnshore decimal(10,2), @ConsArchOffshore decimal(10,2), @ProjLeadOnshore decimal(10,2), @ProjLeadOffshore decimal(10,2), @ProjMgrOnshore decimal(10,2), @ProjMgrOffshore decimal(10,2), @ProgMgrOnshore decimal(10,2), @TotalHours decimal(10,2), @COApprovedFTEs decimal(10,2)
--Declare @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2)

-- Calculate and Populate the RecNumber 0 records (Grand Total Continental)
select  @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0))
from #TEMP_OUT where RecNumber = 10

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours
where RecNumber = 0 and RecType = 'GrandTotal'

update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5
where RecNumber = 0 and RecType = 'GrandTotalConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 0 and RecType = 'GrandTotal'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 0 and RecType in ('GrandTotal', 'GrandTotalConversion')

-- Calculate and Populate the 1 records (Total Airline)
select  @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'Airline'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours
where RecNumber = 1 and RecType = 'TotalAirline'

update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5
where RecNumber = 1 and RecType = 'TotalAirlineConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 1 and RecType = 'TotalAirline'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 1 and RecType in ('TotalAirline', 'TotalAirlineConversion')

-- Calculate and Populate the 2 records (Total ADM)
select  @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'ADM'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours
where RecNumber = 2 and RecType = 'TotalADM'

update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5
where RecNumber = 2 and RecType = 'TotalADMConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 2 and RecType = 'TotalADM'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 2 and RecType in ('TotalADM', 'TotalADMConversion')

-- Calculate and Populate the 4 records (Total AFE_Prod)
select  @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'AFE_Prod'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours
where RecNumber = 4 and RecType = 'TotalAFEProd'

update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5
where RecNumber = 4 and RecType = 'TotalAFEProdConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 4 and RecType = 'TotalAFEProd'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber =4 and RecType in ('TotalAFEProd','TotalAFEProdConversion')

-- Calculate and Populate the 5 records (Total Staff Augmentation)
select  @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'Staff Aug'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours
where RecNumber = 5 and RecType = 'TotalStaffAug'

update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, 
		COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5
where RecNumber = 5 and RecType = 'TotalStafAugConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 5 and RecType = 'TotalStaffAug'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 5 and RecType in ('TotalStaffAug','TotalStafAugConversion')

-- Set the Factor.
declare @Factor decimal(5,2)
if ( month(@datefrom) <> month(getdate())) or ( year(@datefrom) <> year(getdate()))
	set @Factor = 1
else
	select @Factor = convert(float, day(getdate())) / convert(float, day(DATEADD(d, -DAY(DATEADD(m,1,getdate())),DATEADD(m,1,getdate()))))



---------------------------------STEP 7------------------------------------------
--update #TEMP_OUT set ExpectedMTDFTE = COApprovedFTEs * @Factor where COApprovedFTEs is not NULL
--update #TEMP_OUT set VarianceMTDFTE = ActualFTEs - ExpectedMTDFTE where COApprovedFTEs is not NULL

-- Remove any rows that have ZERO values in the TotalHours and the COApprovedFTEs
delete #TEMP_OUT where RecNumber in (10,20,30) and (TotalHours = 0 or TotalHours is NULL) and COApprovedFTEs = 0

---------------------------------STEP 8------------------------------------------
SELECT * from #TEMP_OUT order by AutoKey

select * from #TEMP_OUT where RecDesc like '%Flight Operations%'

--------------------------------------------------
--Execute the stored procedure
exec Get_AFE_Detail_Airline
	@DateFrom = '05/01/2008', @DateTo = '05/31/2008',  @CurrentMonth = 200805, 
	@ProgGroupID = '-1', @FundCatIDList = '-1',
	@SolutionCentreList = '-1', @ITSABillingCat = '-1',
	@StatusID = -1, 
	@AFEID = -1, 
	@ProjectID = -1  , 
	@BillingShoreWhere varchar(20) = Null,







