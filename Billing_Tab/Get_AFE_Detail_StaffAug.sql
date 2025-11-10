--StoredProcedure [dbo].[Get_AFE_Detail_StaffAug] 

drop view [dbo].[SP_Get_AFE_Resource_Detail_Airline_View]
drop view [dbo].[SP_Get_AFE_Resource_Detail_Airline_View2]
drop table #TEMP_IN
drop table #TEMP_OUT
	
-- Create new temp VIEW.
DECLARE @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Resource_Detail_Airline_View AS select AFE_Resource_Summary_View.*, CO_Resource.Onshore, CO_Resource.Offshore, CO_Resource.Hourly, CO_BillingCode.Billing_CodeID, CO_BillingCode.Description AS NewBillingType
from AFE_Resource_Summary_View inner join CO_Resource ON AFE_Resource_Summary_View.ResourceNumber = CO_Resource.ResourceNumber inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID
where 1=1 and hours > 0 and WorkDate >= ''2014-01-01'' and WorkDate <= ''2014-01-31'' '
exec (@SQL_statement)

-- Copy the data from the temp VIEW into #TEMP_IN working storage.
select ProgramGroup, Program, AFEDesc, ITSABillingCat, ProjectTitle, TaskName, EventList, eventname, ResourceName, billingid, Prog_GroupID, ProgramID, AFE_DescID, Client, BillingFlag, NewBillingType, Type, TaskClientFundingPct, TaskClientFundedBy, Funding_CatID, ProjectStatusID, ResourceNumber, ProjectID, TaskID, eventlistid, sum(hours) as hours, COBusinessLead, Onshore, Offshore, Hourly, UA_VicePresident
into #TEMP_IN from dbo.SP_Get_AFE_Resource_Detail_Airline_View
group by ProgramGroup, Program, AFEDesc, ITSABillingCat, ProjectTitle, TaskName, EventList, eventname, ResourceName, billingid, Prog_GroupID, ProgramID, AFE_DescID, Client, BillingFlag, NewBillingType, Type, TaskClientFundingPct, TaskClientFundedBy, Funding_CatID, ProjectStatusID, ResourceNumber, ProjectID, TaskID, eventlistid, COBusinessLead, Onshore, Offshore, Hourly, UA_VicePresident
order by ProgramGroup, Program, AFEDesc, ProjectTitle, TaskName, EventList, eventname, ResourceName

-- Drop the temp view.
drop view [dbo].[SP_Get_AFE_Resource_Detail_Airline_View]

-- Alter table definitions.
ALTER TABLE #TEMP_IN ADD Appr_FTE_Hours decimal(7,2) NULL
ALTER TABLE #TEMP_IN ADD CurrentMonth varchar(6) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN TaskID varchar(100) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ProjectID varchar(100) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ResourceNumber varchar(15) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN NewBillingType varchar(50) NULL

-- Create the second temp VIEW.
DECLARE @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Resource_Detail_Airline_View2 AS select dbo.lkITSABillingCategory.Description AS ITSABillingCat, FTE_Approved_Time.* from FTE_Approved_Time LEFT OUTER JOIN	dbo.tblAFEDetail ON FTE_Approved_Time.AFE_DescID = dbo.tblAFEDetail.AFE_DescID LEFT OUTER JOIN dbo.lkITSABillingCategory ON dbo.tblAFEDetail.ITSABillingCategoryID = dbolkITSABillingCategory.ITSABillingCategoryID 
where Appr_FTE_Hours > 0 and CurrentMonth = ''201401'' '
exec (@SQL_statement)

-- Copy the data from the second temp VIEW into #TEMP_IN.
insert #TEMP_IN (AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, ITSABillingCat, UA_VicePresident)
select AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID ,COBusinessLead, ITSABillingCat, UA_VicePresident 
from dbo.SP_Get_AFE_Resource_Detail_Airline_View2

-- Drop the second temp VIEW.
drop view [dbo].[SP_Get_AFE_Resource_Detail_Airline_View2]

-- Adjust the Hours according to the ClientFundingPct by CO
update #TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0

---------------------------------------------------------------------------------
--drop table #TEMP_OUT

-- Create the output table #TEMP_OUT.
CREATE TABLE [dbo].[#TEMP_OUT] ( 
		[AutoKey][int] IDENTITY (0, 1) NOT NULL,
		[RecNumber][int] NULL,           -- 0, 3, 6, 10, 20, 30, 40, 50, 55, 56, 60, 99
		[RecType] [varchar] (100) NULL, -- ProgramGroup / Program / AFEDesc / Project / Task / Event / Resource
		[RecDesc] [varchar] (100) NULL, -- PIV Data
		[RecTypeID] [varchar] (100) NULL, -- Prog_GroupID / ProgramID / AFE_DescID / ProjectID / TaskID 
		[ITSABillingCat] [varchar] (30) NULL,
		[FundingCat] [varchar] (30) NULL,
	    [AFENumber] [varchar] (20) NULL,
	    [UAVP] [varchar] (50) NULL,
		[COBusinessLead] [varchar] (100) NULL,
		[ProgramMgr] [varchar] (50) NULL,
		[Location] [varchar] (30) NULL,
		[TotalHours] [decimal](10,2) NULL,
		[ActualFTEs] [decimal](10,2) NULL,
		[COApprovedFTEs] [decimal](10,2) NULL,
		[EDSVariance] [decimal](10,2) NULL,
		[FTPStaffAugOnshoreHours] [decimal](10,2) NULL,
		[FTPStaffAugOffshoreHours] [decimal](10,2) NULL,
		[R10_ProgramGroup] [varchar] (100) NULL,
		[R20_Program] [varchar] (100) NULL,
		[R30_AFEDesc] [varchar] (100) NULL,
		[R40_Project] [varchar] (100) NULL,
		[R50_Task] [varchar] (100) NULL
		--[R55_EventTitle] [varchar] (100) NULL,
		--[R56_Event] [varchar] (100) NULL
) ON [PRIMARY]

-- Populate summary rows.
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Total United (UA)'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotalConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 1, 'TotalAirline', 'Total Airline'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 1, 'TotalAirlineConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 2, 'TotalADM', 'Total ADM'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 2, 'TotalADMConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 4, 'TotalAFEProd', 'Total UA Skill/NA'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 4, 'TotalAFEProdConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'TotalStaffAug', 'Total Staff Augmentation (FTE Based)'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'TotalStafAugConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 6, 'TotalUAMerger', 'Total UA Merger'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 6, 'TotalUAMergerConversion', 'FTE Conversion'

-- Data was found, build the report.	
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--***changed
-- Declare variables.
DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID varchar(100), @UPVP varchar(50), @CurProgram varchar(100), @CurProgramID varchar(100)
DECLARE @CurCOBusinessLead varchar(100), @CurAFEDesc varchar(100), @CurAFE_DescID varchar(100), @CurProjectTitle varchar(100), @CurProjID varchar(100), @CurTaskName varchar(100), @CurTaskID varchar(100), @CurResourceName varchar(100), @CurEventList varchar(100)
DECLARE	@CurEventName varchar(100), @Billing_Type varchar(150), @Hours decimal(10,2), @MaxProgGroup bigint, @MaxProg bigint, @MaxAFEDesc bigint, @MaxProj bigint, @MaxTask bigint, @MaxEvent bigint, @Onshore bit, @Offshore bit, @Hourly bit, @ITSABillingCat varchar(30)
-- Declare additional variables for calculation.        
Declare @FTPStaffAugOnshore decimal(10,2), @FTPStaffAugOffshore decimal(10,2), @TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2), @FTPStaffAugOnshoreHours decimal(10,2), @FTPStaffAugOffshoreHours decimal(10,2)

---for testing only
declare @DateFrom datetime, @DateTo datetime
set @DateFrom = '2014-01-01'
set @DateTo = '2014-01-31'

-- Get the FTE Billing hours for FTP records and set the FTE rate.
Declare @FTPBillingRate decimal(10,2), @year int, @month int, @BillableDays int
select @year = datepart(year, @DateFrom) 
select @month = datepart(month, @DateFrom) 
select @BillableDays = BillableDays from piv_reports..CO_PTD_Calendar where Year = @year and Month = @month

if @BillableDays > 0
begin
	set @FTPBillingRate = 8 * @BillableDays
end
else
begin
	set @FTPBillingRate = '143.5'
end

--------------------------------------------------------------------------------------------
--***changed
-- ProgramGroup_cursor, populates record type 10.
DECLARE ProgramGroup_cursor CURSOR FOR 
	select distinct ProgramGroup, Prog_GroupID, UA_VicePresident from #TEMP_IN where ProgramGroup is not null order by ProgramGroup 
OPEN ProgramGroup_cursor
FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID, @UPVP 
WHILE @@FETCH_STATUS = 0
BEGIN
	insert #TEMP_OUT (RecNumber) values (10) -- A blank line
	insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, UAVP)
	select 10, 'ProgGroup/Total', @CurProgramGroup, @CurProg_GroupID, @UPVP
	select @MaxProgGroup = max(AutoKey) from #TEMP_OUT

	--------------------------------------------------------------------------------------------
	-- Program_cursor, populates record type 20.
	DECLARE Program_cursor CURSOR FOR 
		select distinct Program, ProgramID from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program is not null order by Program
	OPEN Program_cursor
	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
	WHILE @@FETCH_STATUS = 0
	BEGIN
		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup)
		select 20, 'Program', @CurProgram, @CurProgramID, @CurProgramGroup
		select @MaxProg = max(AutoKey) from #TEMP_OUT

		--------------------------------------------------------------------------------------------
		-- AFEDesc_cursor, populates record type 30.
		DECLARE AFEDesc_cursor CURSOR FOR 
			select distinct AFEDesc, AFE_DescID, COBusinessLead from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFEDesc is not null order by AFEDesc
		OPEN AFEDesc_cursor
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
		WHILE @@FETCH_STATUS = 0
		BEGIN
			insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, COBusinessLead) 
			select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID, @CurProgramGroup, @CurProgram, @CurCOBusinessLead
			select @MaxAFEDesc = max(AutoKey) from #TEMP_OUT

			--------------------------------------------------------------------------------------------
			-- ProjDesc_cursor, populates record type 40.
			DECLARE ProjDesc_cursor CURSOR FOR 
				select distinct ProjectID, ProjectTitle from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID is not null order by ProjectTitle 
			OPEN ProjDesc_cursor
			FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
			WHILE @@FETCH_STATUS = 0
			BEGIN
				insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, R30_AFEDesc)
				select 40, 'ProjDesc', @CurProjectTitle, @CurProjID, @CurProgramGroup, @CurProgram, @CurAFEDesc
				select @MaxProj = max(AutoKey) from #TEMP_OUT 

				--------------------------------------------------------------------------------------------
				-- Task_cursor, populates record type 50.
				DECLARE Task_cursor CURSOR FOR
					select distinct TaskID, TaskName from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID order by TaskName
				OPEN Task_cursor
				FETCH NEXT FROM Task_cursor INTO @CurTaskID, @CurTaskName
				WHILE @@FETCH_STATUS = 0
				BEGIN
					insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project)
					select 50, 'TaskDesc', @CurTaskName, @CurTaskID, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle
					select @MaxTask = max(AutoKey) from #TEMP_OUT

					--------------------------------------------------------------------------------------------
					---Resource_cursor, populates Resources under Tasks, record type 60.
					DECLARE Resource_cursor CURSOR FOR
						select ResourceName, NewBillingType, Onshore, Offshore, Hourly, Hours from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and TaskID = @CurTaskID and EventList is NULL and EventName is NULL and ResourceName is not NULL order by ResourceName
					OPEN Resource_cursor
					FETCH NEXT FROM Resource_cursor INTO @CurResourceName, @Billing_Type, @Onshore, @Offshore, @Hourly, @hours
					WHILE @@FETCH_STATUS = 0
					BEGIN
	   					-- Determine billing type for Resource and then insert record.
						if @Billing_Type = 'FTP Staff Aug' and @Onshore = 1 
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, FTPStaffAugOnshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task) --, R55_EventTitle, R56_Event) 
							select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName -- , @CurEventList, @CurEventName
								
						if @Billing_Type = 'FTP Staff Aug' and @Offshore = 1 
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, FTPStaffAugOffshoreHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task) --, R55_EventTitle, R56_Event) 
							select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName --, @CurEventList, @CurEventName

					FETCH NEXT FROM Resource_cursor INTO @CurResourceName, @Billing_Type, @Onshore, @Offshore, @Hourly, @hours
                    END    
                    CLOSE Resource_cursor
                    DEALLOCATE Resource_cursor

				--------------------------------------------------------------------------------------------

				-- SUMMARIZE Total Hours for each event (vertical), record type 60.        
				select @FTPStaffAugOnshore = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshore= sum(isnull(FTPStaffAugOffshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0))
				from #TEMP_OUT where AutoKey > @MaxEvent and RecNumber = 60

				update #TEMP_OUT set FTPStaffAugOnshoreHours = @FTPStaffAugOnshore, FTPStaffAugOffshoreHours = @FTPStaffAugOffshore, TotalHours = @TotalHours
				where AutoKey = @MaxEvent

				-- SUMMARIZE Total Hours for each task (vertical), record type 60.
				select @FTPStaffAugOnshore = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshore= sum(isnull(FTPStaffAugOffshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0))					
				from #TEMP_OUT where AutoKey > @MaxTask and RecNumber = 60

				update #TEMP_OUT set FTPStaffAugOnshoreHours = @FTPStaffAugOnshore, FTPStaffAugOffshoreHours = @FTPStaffAugOffshore, TotalHours = @TotalHours
				where AutoKey = @MaxTask
					
				FETCH NEXT FROM Task_cursor INTO @CurTaskID, @CurTaskName
				END    
				CLOSE Task_cursor
				DEALLOCATE Task_cursor

			-----------------------------------------------------------------------------------------------------------------------
                
			-- SUMMARIZE Total Hours at Project Level on 10 fields (vertical), record type 50.
			select @FTPStaffAugOnshore = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshore= sum(isnull(FTPStaffAugOffshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0))					
			from #TEMP_OUT where AutoKey > @MaxProj and RecNumber = 50 

			update #TEMP_OUT set FTPStaffAugOnshoreHours = @FTPStaffAugOnshore, FTPStaffAugOffshoreHours = @FTPStaffAugOffshore, TotalHours = @TotalHours
			where AutoKey = @MaxProj                
		
			FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
			END    
			CLOSE ProjDesc_cursor
			DEALLOCATE ProjDesc_cursor

		-----------------------------------------------------------------------------------------------------------------------
		-- Get the ITSA Billing Category.
		select @ITSABillingCat = ITSABillingCat from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 

		-- Populate the Hours by the new Billing Type.
		select @FTPStaffAugOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
			NewBillingType = 'FTP Staff Aug' and Onshore = 1
		select @FTPStaffAugOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
			NewBillingType = 'FTP Staff Aug' and Offshore = 1				

		-- GET funding category and location combo.
		Declare @@out_location varchar (100), @@out_fundingcat varchar (100), @@out_afenumber varchar (20), @@out_programmgr varchar (50), @@Total_FTE float             
		set @@out_location  = NULL
		set @@out_fundingcat = NULL
		set @@out_afenumber = NULL
		set @@out_programmgr = NULL
		set @@Total_FTE = NULL
		exec GET_Location_Combo @CurAFE_DescID, @DateFrom, @DateTo, @@out_location OUTPUT, @@out_fundingcat OUTPUT, @@out_afenumber OUTPUT, @@out_programmgr OUTPUT, @@Total_FTE OUTPUT
                
		-- UPDATE temporary table --
		update #TEMP_OUT set ITSABillingCat = @ITSABillingCat, fundingcat = @@out_fundingcat, AFENumber = @@out_afenumber, ProgramMgr = @@out_programmgr, location = @@out_location, COApprovedFTEs = isnull(@@Total_FTE,0), FTPStaffAugOnshoreHours = isnull(@FTPStaffAugOnshore,0), FTPStaffAugOffshoreHours = isnull(@FTPStaffAugOffshore,0)
		where AutoKey = @MaxAFEDesc

		-- Populate TotalHours Column for record type 40, 50, 56, 60 (horizontal add up)
		update #TEMP_OUT set TotalHours = isnull(@FTPStaffAugOnshore,0)+isnull(@FTPStaffAugOffshore,0)
		where AutoKey > @MaxProgGroup and RecNumber in (40, 50, 60)

		-- UPDATE Summary Fields --
		update #TEMP_OUT set ActualFTEs = TotalHours/@FTPBillingRate where AutoKey > @MaxAFEDesc and RecNumber in (40, 50, 60)
		update #TEMP_OUT set TotalHours = (select isnull(sum(TotalHours),0) from #TEMP_OUT where AutoKey > @MaxAFEDesc and RecNumber = 40), ActualFTEs = (select isnull(sum(ActualFTEs),0) from #TEMP_OUT where AutoKey > @MaxAFEDesc and RecNumber = 40) where AutoKey = @MaxAFEDesc
		update #TEMP_OUT set ActualFTEs = TotalHours/@FTPBillingRate where AutoKey = @MaxAFEDesc
		update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey = @MaxAFEDesc
    
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
		END    
		CLOSE AFEDesc_cursor
		DEALLOCATE AFEDesc_cursor

	-----------------------------------------------------------------------------------------------------------------------
	-- Update Program Record (20) with summary totals, populate TotalHours and COApprovedFTEs.
	Select @FTPStaffAugOnshore = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshore= sum(isnull(FTPStaffAugOffshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0))
	from #TEMP_OUT where AutoKey > @MaxProg and RecNumber = 40

	select @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)) from #TEMP_OUT where AutoKey > @MaxProg and RecNumber = 30	

	update #TEMP_OUT set FTPStaffAugOnshoreHours = @FTPStaffAugOnshore, FTPStaffAugOffshoreHours = @FTPStaffAugOffshore, TotalHours = @TotalHours, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, EDSVariance = @TotalHours/@FTPBillingRate - @COApprovedFTEs
	where AutoKey = @MaxProg

	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
	END
	CLOSE Program_cursor
	DEALLOCATE Program_cursor

-----------------------------------------------------------------------------------------------------------------------
-- Populate TotalHours Column for record type 20 (horizontal add up).
update #TEMP_OUT set TotalHours = isnull(FTPStaffAugOnshoreHours,0) + isnull(FTPStaffAugOffshoreHours,0)
where AutoKey > @MaxProgGroup and RecNumber = 20
        
-- Populate ActualFTEs column for record type 20. 
update #TEMP_OUT set ActualFTEs = TotalHours/@FTPBillingRate where AutoKey > @MaxProgGroup and RecNumber = 20
       
-- Populate EDSVariance column for record type 20. 
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey > @MaxProgGroup and RecNumber = 20

-- Populate TotalHours Column for record type 30 (horizontal add up).
update #TEMP_OUT set TotalHours = isnull(FTPStaffAugOnshoreHours,0) + isnull(FTPStaffAugOffshoreHours,0)
where AutoKey > @MaxProgGroup and RecNumber = 30
        
-- Populate ActualFTEs column for record type 30. 
update #TEMP_OUT set ActualFTEs = TotalHours/@FTPBillingRate where AutoKey > @MaxProgGroup and RecNumber = 30
       
-- Populate EDSVariance column for record type 30. 
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey > @MaxProgGroup and RecNumber = 30

-- Populate TotalHours Column for record type 40 (horizontal add up).
update #TEMP_OUT set TotalHours = isnull(FTPStaffAugOnshoreHours,0) + isnull(FTPStaffAugOffshoreHours,0) 
where AutoKey > @MaxProgGroup and RecNumber = 40

-- Populate ActualFTEs column for record type 40 (horizontal add up). 
update #TEMP_OUT set ActualFTEs = TotalHours/@FTPBillingRate where AutoKey > @MaxProgGroup and RecNumber = 40

-- Populate TotalHours Column for record type 50 (horizontal add up).
update #TEMP_OUT set TotalHours = isnull(FTPStaffAugOnshoreHours,0) + isnull(FTPStaffAugOffshoreHours,0)
where AutoKey > @MaxProgGroup and RecNumber = 50

-- Populate ActualFTEs column for record type 50 (horizontal add up). 
update #TEMP_OUT set ActualFTEs = TotalHours/@FTPBillingRate where AutoKey > @MaxProgGroup and RecNumber = 50

-- Populate TotalHours Column for record type 60 (horizontal add up).
update #TEMP_OUT set TotalHours = isnull(FTPStaffAugOnshoreHours,0) + isnull(FTPStaffAugOffshoreHours,0)
where AutoKey > @MaxProgGroup and RecNumber = 60

-- Populate ActualFTEs column for record type 60 (horizontal add up). 
update #TEMP_OUT set ActualFTEs = TotalHours/@FTPBillingRate where AutoKey > @MaxProgGroup and RecNumber = 60

-- Update total information for 10 fields (vertical add up).
select @FTPStaffAugOnshore = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshore= sum(isnull(FTPStaffAugOffshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0))
from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 40

select @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)) from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30
Update #TEMP_OUT set FTPStaffAugOnshoreHours = @FTPStaffAugOnshore, FTPStaffAugOffshoreHours = @FTPStaffAugOffshore, TotalHours = @TotalHours, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, EDSVariance = @TotalHours/@FTPBillingRate - @COApprovedFTEs
where AutoKey = @MaxProgGroup

--***changed
FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID, @UPVP
END
CLOSE ProgramGroup_cursor
DEALLOCATE ProgramGroup_cursor

-----------------------------------------------------------------------------------------------------------------------	
-- Set all the NULL values to 0 for 60 records
update #TEMP_OUT set FTPStaffAugOnshoreHours = 0 where RecNumber = 60 and FTPStaffAugOnshoreHours is null 
update #TEMP_OUT set FTPStaffAugOffshoreHours = 0 where RecNumber = 60 and FTPStaffAugOffshoreHours is null 

-----------------------------------------------
-- Calculate and Populate the RecNumber 0 records (Grand Total Continental)
select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
from #TEMP_OUT where RecNumber = 10

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
where RecNumber = 0 and RecType = 'GrandTotal'

update #TEMP_OUT set TotalHours = @TotalHours/@FTPBillingRate, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate
where RecNumber = 0 and RecType = 'GrandTotalConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/@FTPBillingRate where RecNumber = 0 and RecType = 'GrandTotal'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 0 and RecType in ('GrandTotal', 'GrandTotalConversion')

-----------------------------------------------
-- Calculate and Populate the 1 records (Total Airline)
select  @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'Airline'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
where RecNumber = 1 and RecType = 'TotalAirline'

update #TEMP_OUT set TotalHours = @TotalHours/@FTPBillingRate, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate
where RecNumber = 1 and RecType = 'TotalAirlineConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/@FTPBillingRate where RecNumber = 1 and RecType = 'TotalAirline'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 1 and RecType in ('TotalAirline', 'TotalAirlineConversion')

-----------------------------------------------
-- Calculate and Populate the 2 records (Total ADM)
select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'ADM'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
where RecNumber = 2 and RecType = 'TotalADM'

update #TEMP_OUT set TotalHours = @TotalHours/@FTPBillingRate, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate
where RecNumber = 2 and RecType = 'TotalADMConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/@FTPBillingRate where RecNumber = 2 and RecType = 'TotalADM'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 2 and RecType in ('TotalADM', 'TotalADMConversion')

-----------------------------------------------
-- Calculate and Populate the 4 records (Total AFE_Prod)
select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'Skill/NA'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
where RecNumber = 4 and RecType = 'TotalAFEProd'

update #TEMP_OUT set TotalHours = @TotalHours/@FTPBillingRate, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate
where RecNumber = 4 and RecType = 'TotalAFEProdConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/@FTPBillingRate where RecNumber = 4 and RecType = 'TotalAFEProd'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber =4 and RecType in ('TotalAFEProd','TotalAFEProdConversion')

-----------------------------------------------
-- Calculate and Populate the 5 records (Total Staff Augmentation)
select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'Staff Aug'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
where RecNumber = 5 and RecType = 'TotalStaffAug'

update #TEMP_OUT set TotalHours = @TotalHours/@FTPBillingRate, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate
where RecNumber = 5 and RecType = 'TotalStafAugConversion'
	
update #TEMP_OUT set ActualFTEs = @TotalHours/@FTPBillingRate where RecNumber = 5 and RecType = 'TotalStaffAug'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 5 and RecType in ('TotalStaffAug','TotalStafAugConversion')

-----------------------------------------------
-- Calculate and Populate the 6 records (UA Merger)
select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'UA Merger'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
where RecNumber = 6 and RecType = 'TotalUAMerger'

update #TEMP_OUT set TotalHours = @TotalHours/@FTPBillingRate, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate
where RecNumber = 6 and RecType = 'TotalUAMergerConversion'
	
update #TEMP_OUT set ActualFTEs = @TotalHours/@FTPBillingRate where RecNumber = 6 and RecType = 'TotalUAMerger'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 6 and RecType in ('TotalUAMerger','TotalUAMergerConversion')

-----------------------------------------------
	-- Set the Factor.
declare @Factor decimal(5,2)
if ( month(@datefrom) <> month(getdate())) or ( year(@datefrom) <> year(getdate()))
	set @Factor = 1
else
	select @Factor = convert(float, day(getdate())) / convert(float, day(DATEADD(d, -DAY(DATEADD(m,1,getdate())),DATEADD(m,1,getdate()))))

-- Remove any rows that have ZERO values in the TotalHours
delete #TEMP_OUT where RecNumber in (10,20,30,40,50) and (TotalHours = 0 or TotalHours is NULL) 

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

select * from #TEMP_OUT order by AutoKey

