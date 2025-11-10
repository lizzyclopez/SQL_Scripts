drop table #TEMP_IN
drop table #TEMP_OUT
drop view [dbo].[SP_Get_AFE_Project_Detail]
drop view [dbo].[SP_Get_AFE_Project_Detail2]

-- Create the first temp VIEW.
DECLARE @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Project_Detail AS select AFE_Summary_View.*, CO_Resource.ResourceNumber, CO_Resource.BillingRate AS FTP_BillingRate, CO_Resource.Onshore, CO_Resource.Offshore, CO_Resource.Hourly, CO_BillingCode.Billing_CodeID, CO_BillingCode.Description AS NewBillingType, CO_BillingCodeRate.BillingRateOnshore, CO_BillingCodeRate.BillingRateOffshore from AFE_Summary_View inner join CO_Resource ON AFE_Summary_View.EDSNETID = CO_Resource.ResourceNumber  inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID left outer join CO_BillingCodeRate ON CO_BillingCode.Billing_CodeID = CO_BillingCodeRate.Billing_CodeID
where 1=1 and WorkDate >= ''2013-07-01'' and workdate <= ''2013-07-31'' ' 
exec (@SQL_statement)

-- Copy the data from the temp VIEW into #TEMP_IN working storage.
select * into dbo.#TEMP_IN from dbo.SP_Get_AFE_Project_Detail

-- Add two column  and alter columns in the #TEMP_IN temp table.
ALTER TABLE dbo.#TEMP_IN ADD Appr_FTE_Hours decimal(7,2) NULL
ALTER TABLE dbo.#TEMP_IN ADD CurrentMonth varchar(6) NULL
ALTER TABLE dbo.#TEMP_IN ALTER COLUMN TaskID varchar(100) NULL
ALTER TABLE dbo.#TEMP_IN ALTER COLUMN ProjectID varchar(100) NULL
ALTER TABLE dbo.#TEMP_IN ALTER COLUMN WorkDate datetime NULL
ALTER TABLE dbo.#TEMP_IN ALTER COLUMN EDSNETID varchar(15) NULL
ALTER TABLE dbo.#TEMP_IN ALTER COLUMN Billing_CodeID int NULL	
ALTER TABLE dbo.#TEMP_IN ALTER COLUMN NewBillingType varchar(50) NULL
ALTER TABLE dbo.#TEMP_IN ALTER COLUMN ResourceNumber varchar(15) NULL

-- Create the second temp VIEW.
DECLARE @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Project_Detail2 AS select dbo.lkITSABillingCategory.Description AS ITSABillingCat, FTE_Approved_Time.* from FTE_Approved_Time 	LEFT OUTER JOIN dbo.tblAFEDetail ON FTE_Approved_Time.AFE_DescID = dbo.tblAFEDetail.AFE_DescID  LEFT OUTER JOIN dbo.lkITSABillingCategory ON dbo.tblAFEDetail.ITSABillingCategoryID = dbolkITSABillingCategory.ITSABillingCategoryID 
where Appr_FTE_Hours > 0 and CurrentMonth = ''201307'' ' 
exec (@SQL_statement)

-- Copy the data from the second temp VIEW into #TEMP_IN.
insert dbo.#TEMP_IN ( AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, ITSABillingCat, UA_VicePresident )
select AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, ITSABillingCat, UA_VicePresident 
from dbo.SP_Get_AFE_Project_Detail2

-- Create Index
Create Index IDX1 on dbo.#TEMP_IN (Prog_GroupID, ProgramID, AFE_DescID, ProjectID, NewBillingType)

-- Adjust the Hours according to the ClientFundingPct by CO
update dbo.#TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0

-- Create the output table #TEMP_OUT.
--drop table #TEMP_OUT
CREATE TABLE [dbo].[#TEMP_OUT] ( 
	[AutoKey][int] IDENTITY (0, 1) NOT NULL,
	[RecNumber][int] NULL,             -- 0, 3, 6, 10, 20, 30, 40, 50, 55, 56, 60, 99
	[RecType] [varchar] (100) NULL,    -- ProgramGroup / Program / AFEDesc / Project / Task / Event / Resource
	[RecDesc] [varchar] (100) NULL,    -- PIV Data
    [RecTypeID] [varchar] (100) NULL,  -- Prog_GroupID / ProgramID / AFE_DescID / ProjectID / TaskID 
	[ITSABillingCat] [varchar] (30) NULL,[FundingCat] [varchar] (30) NULL,[AFENumber] [varchar] (20) NULL,[UAVP] [varchar] (50) NULL, [COBusinessLead] [varchar] (100) NULL ,[ProgramMgr] [varchar] (50) NULL,[Location] [varchar] (30) NULL,[TotalHours] [decimal](10,2) NULL,[ActualFTEs] [decimal](10,2) NULL,[COApprovedFTEs] [decimal](10,2) NULL,[EDSVariance] [decimal](10,2) NULL,
	[JrSEOnshoreHours] [decimal](10,2) NULL,[JrSeOffshoreHours] [decimal](10,2) NULL,[MidSEOnshoreHours] [decimal](10,2) NULL,[MidSEOffshoreHours] [decimal](10,2) NULL,[AdvSEOnshoreHours] [decimal](10,2) NULL,[AdvSEOffshoreHours] [decimal](10,2) NULL,[SenSEOnshoreHours] [decimal](10,2) NULL,[SenSEOffshoreHours] [decimal](10,2) NULL,[ConsArchOnshoreHours] [decimal](10,2) NULL,[ConsArchOffshoreHours] [decimal](10,2) NULL,[ProjLeadOnshoreHours] [decimal](10,2) NULL,[ProjLeadOffshoreHours] [decimal](10,2) NULL,[ProjMgrOnshoreHours] [decimal](10,2) NULL,[ProjMgrOffshoreHours] [decimal](10,2) NULL,[ProgMgrOnshoreHours] [decimal](10,2) NULL,[ProgMgrOffshoreHours] [decimal](10,2) NULL
) ON [PRIMARY]

-- Add FTP Staff Aug columns if ITSA Billing Category selection is ALL.
ALTER TABLE #TEMP_OUT ADD FTPStaffAugOnshoreHours decimal(10,2) NULL
ALTER TABLE #TEMP_OUT ADD FTPStaffAugOffshoreHours decimal(10,2) NULL
ALTER TABLE #TEMP_OUT ADD R10_ProgramGroup varchar(100) NULL
ALTER TABLE #TEMP_OUT ADD R20_Program varchar(100) NULL
ALTER TABLE #TEMP_OUT ADD R30_AFEDesc varchar(100) NULL
ALTER TABLE #TEMP_OUT ADD R40_Project varchar(100) NULL

-- Populate summary rows.
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Total United (UA)'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotalConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 1, 'TotalAirline', 'Total Airline'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 1, 'TotalAirlineConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 1, 'TotalCostAirline', 'Total Cost'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 2, 'TotalADM', 'Total ADM'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 2, 'TotalADMConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 2, 'TotalCostADM', 'Total Cost'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 4, 'TotalAFEProd', 'Total AFE Prod'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 4, 'TotalAFEProdConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 4, 'TotalCostAFEProd', 'Total Cost'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'TotalStaffAug', 'Total Staff Augmentation (FTE Based)'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'TotalStafAugConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'TotalCostStaffAug', 'Total Cost'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 6, 'TotalUAMerger', 'Total UA Merger'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 6, 'TotalUAMergerConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 6, 'TotalCostUAMerger', 'Total Cost'

---------------------------------------------------------------------------------------------------
-- Declare variables.
DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID varchar(100), @UPVP varchar (50), @CurProgram varchar(100), @CurProgramID  varchar(100), @CurCoBusinessLead varchar (100), @CurAFEDesc varchar (100), @CurAFE_DescID varchar (100), @CurProjectTitle varchar(100), @CurProjID varchar (100), @CurTaskName varchar(100), @CurTaskID varchar (100), @CurResourceName varchar(100), @CurEventList varchar(100), @CurEventName varchar(100), @MaxProgGroup bigint, @MaxProgram bigint, @MaxAFEDesc bigint, @MaxProj bigint, @MaxTask bigint, @MaxEvent bigint, @CurResourceNumber varchar(15)
DECLARE @JrSEOnshore decimal(10,2), @JrSEOffshore decimal(10,2), @MidSEOnshore decimal(10,2), @MidSEOffshore decimal(10,2), @AdvSEOnshore decimal(10,2), @AdvSEOffshore decimal(10,2), @SenSEOnshore decimal(10,2), @SenSEOffshore decimal(10,2), @ConsArchOnshore decimal(10,2), @ConsArchOffshore decimal(10,2), @ProjLeadOnshore decimal(10,2), @ProjLeadOffshore decimal(10,2), @ProjMgrOnshore decimal(10,2), @ProjMgrOffshore decimal(10,2), @ProgMgrOnshore decimal(10,2), @ProgMgrOffshore decimal(10,2), @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2), @ProgMgrOffshoreHours decimal(10,2), @TotalHours decimal(10,2), @COApprovedFTEs decimal(10,2)
Declare @FTPStaffAugOnshore decimal(10,2), @FTPStaffAugOffshore decimal(10,2), @FTPStaffAugOnshoreHours decimal(10,2), @FTPStaffAugOffshoreHours decimal(10,2), @FTPBillingRate decimal(9,2), @year int, @month int, @BillableDays int, @OnshoreFTERate decimal(9,2), @OffshoreFTERate decimal(9,2)
DECLARE @JrSEBillingRateOnshore decimal(10,2), @JrSEBillingRateOffshore decimal(10,2), @MidSEBillingRateOnshore decimal(10,2), @MidSEBillingRateOffshore decimal(10,2), @AdvSEBillingRateOnshore decimal(10,2), @AdvSEBillingRateOffshore decimal(10,2), @SenSEBillingRateOnshore decimal(10,2), @SenSEBillingRateOffshore decimal(10,2), @ConsArchBillingRateOnshore decimal(10,2), @ConsArchBillingRateOffshore decimal(10,2), @ProjLeadBillingRateOnshore decimal(10,2), @ProjLeadBillingRateOffshore decimal(10,2), @ProjMgrBillingRateOnshore decimal(10,2), @ProjMgrBillingRateOffshore decimal(10,2), @ProgMgrBillingRateOnshore decimal(10,2), @ProgMgrBillingRateOffshore decimal(10,2)
DECLARE @FTPStaffAugProjectOnshore decimal(10,2), @FTPStaffAugProjectOffshore decimal(10,2), @FTPStaffAugTotalHoursOnshore decimal(10,2), @FTPStaffAugTotalHoursOffshore decimal(10,2), @FTPStaffAugBillingRateOnshore decimal(9,2), @FTPStaffAugBillingRateOffshore decimal(9,2), @CalcHoursOnshore decimal(9,2), @CalcHoursOffshore decimal(9,2), @PrevCalcHoursOnshore decimal(9,2), @PrevCalcHoursOffshore decimal(9,2), @FTPStaffAugTotalCostOnshore decimal(9,2), @FTPStaffAugTotalCostOffshore decimal(9,2)
DECLARE @JrSEOnshorePct decimal(10,2), @JrSEOffshorePct decimal(10,2), @MidSEOnshorePct decimal(10,2), @MidSEOffshorePct decimal(10,2), @AdvSEOnshorePct decimal(10,2), @AdvSEOffshorePct decimal(10,2), @SenSEOnshorePct decimal(10,2), @SenSEOffshorePct decimal(10,2), @ConsArchOnshorePct decimal(10,2), @ConsArchOffshorePct decimal(10,2), @ProjLeadOnshorePct decimal(10,2), @ProjLeadOffshorePct decimal(10,2), @ProjMgrOnshorePct decimal(10,2), @ProjMgrOffshorePct decimal(10,2), @ProgMgrOnshorePct decimal(10,2), @ProgMgrOffshorePct decimal(10,2)
--DECLARE @FTPStaffAugOnshorePct decimal(9,2), @FTPStaffAugOffshorePct decimal(9,2)

declare @DateFrom datetime, @DateTo datetime, @ITSABillingCat varchar(30)
set @DateFrom = '2013-07-01'
set @DateTo = '2013-07-31'

-- Get the FTE Billing hours for FTP records and set the FTE rate.
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

--Set the FTE rate for onshore and offshore (non FTP).
set @OnshoreFTERate = '149'
set @OffshoreFTERate = '143.5'

---------------------------------------------------------------------------------------------------
-- ProgramGroup_cursor, populates record type 10.
DECLARE ProgramGroup_cursor CURSOR FOR 
    select distinct ProgramGroup, Prog_GroupID, UA_VicePresident from dbo.#TEMP_IN where ProgramGroup is not null order by ProgramGroup	
OPEN ProgramGroup_cursor
FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID, @UPVP  
WHILE @@FETCH_STATUS = 0
BEGIN
	insert #TEMP_OUT (RecNumber) values (10) -- A blank line
	insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, UAVP)
   	select 10, 'ProgGroup/Total', @CurProgramGroup, @CurProg_GroupID, @UPVP 
    select @MaxProgGroup = max(AutoKey) from #TEMP_OUT

	---------------------------------------------------------------------------------------------------
	-- Program_cursor, populates record type 20.	
	DECLARE Program_cursor CURSOR FOR 
		select distinct Program, ProgramID from dbo.#TEMP_IN where ProgramGroup = @CurProgramGroup and Program is not null order by Program
	OPEN Program_cursor
	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
    WHILE @@FETCH_STATUS = 0
    BEGIN
		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup) --, COBusinessLead)
        select 20, 'Program', @CurProgram, @CurProgramID, @CurProgramGroup --, @CurCOBusinessLead
        select @MaxProgram = max(AutoKey) from #TEMP_OUT

		---------------------------------------------------------------------------------------------------                
		-- AFEDesc_cursor, populates record type 30.
		DECLARE AFEDesc_cursor CURSOR FOR 
			select distinct AFEDesc, AFE_DescID, COBusinessLead from dbo.#TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFEDesc is not null
		OPEN AFEDesc_cursor
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
		WHILE @@FETCH_STATUS = 0
        BEGIN
			insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, COBusinessLead)
           	select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID, @CurProgramGroup, @CurProgram, @CurCOBusinessLead
			select @MaxAFEDesc = max(AutoKey) from #TEMP_OUT

			---------------------------------------------------------------------------------------------------
			-- ProjDesc_cursor, populates record type 40.
    		DECLARE ProjDesc_cursor CURSOR FOR 
    			select distinct ProjectID, ProjectTitle from dbo.#TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID is not null
			OPEN ProjDesc_cursor
			FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
    		WHILE @@FETCH_STATUS = 0
			BEGIN
				insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, R30_AFEDesc)
               	select 40, 'ProjDesc', @CurProjectTitle, @CurProjID, @CurProgramGroup, @CurProgram, @CurAFEDesc
                select @MaxProj = max(AutoKey) from #TEMP_OUT 
                
print 'RecDesc=' + @CurProjectTitle

				-- Populate the ITSA Billing Category.
				select @ITSABillingCat = ITSABillingCat from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 

				-- Populate hours by new Billing Type for record type 10.      
				select @JrSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Jr SE' and Onshore = 1
				select @JrSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Jr SE' and Offshore = 1
				select @MidSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Mid SE' and Onshore = 1
				select @MidSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Mid SE' and Offshore = 1
				select @AdvSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Adv SE' and Onshore = 1
				select @AdvSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Adv SE' and Offshore = 1
				select @SenSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Sen SE' and Onshore = 1
				select @SenSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Sen SE' and Offshore = 1
				select @ConsArchOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Cons Arch' and Onshore = 1
				select @ConsArchOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Cons Arch' and Offshore = 1
				select @ProjLeadOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Project Lead' and Onshore = 1
				select @ProjLeadOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Project Lead' and Offshore = 1			
				select @ProjMgrOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Project Mgr' and Onshore = 1
				select @ProjMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Project Mgr' and Offshore = 1
				select @ProgMgrOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Program Mgr' and Onshore = 1	
				select @ProgMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Program Mgr' and Offshore = 1	

print 'MidSEOnshore=' 
print @MidSEOnshore
print 'AdvSEOnshore=' 
print @AdvSEOnshore

				-- Populate FTP Staff Aug hours by new Billing Type for type 10 records.      
				  select @FTPStaffAugOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'FTP Staff Aug' and Onshore = 1
				  select @FTPStaffAugOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'FTP Staff Aug' and Offshore = 1

				-- Update total information in type 10 records, summarize hours by new Billing Type.      
				update #TEMP_OUT set JrSEOnshoreHours = isnull(@JrSEOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshore,0),				
 						MidSEOnshoreHours = isnull(@MidSEOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshore,0),
						AdvSEOnshoreHours = isnull(@AdvSEOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshore,0),					
 						SenSEOnshoreHours = isnull(@SenSEOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshore,0),
						ConsArchOnshoreHours = isnull(@ConsArchOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshore,0),
 						ProjLeadOnshoreHours = isnull(@ProjLeadOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshore,0),
						ProjMgrOnshoreHours = isnull(@ProjMgrOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshore,0),	
						ProgMgrOnshoreHours = isnull(@ProgMgrOnshore,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshore,0),
						FTPStaffAugOnshoreHours = isnull(@FTPStaffAugOnshore,0), FTPStaffAugOffshoreHours = isnull(@FTPStaffAugOffshore,0)
					where AutoKey = @MaxProj
				
				-- Populate Total Cost record type 50.
				insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, R30_AFEDesc)
               	select 50, 'TotalCost', 'Total Cost', @ITSABillingCat, @CurProgramGroup, @CurProgram, @CurAFEDesc

				-- Populate billing rate by new Billing Type to be used for calculation for record type 50 (Total Cost).      
				select @JrSEBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Jr SE' and Onshore = 1
				select @JrSEBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Jr SE' and Offshore = 1
				select @MidSEBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Mid SE' and Onshore = 1					
				select @MidSEBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Mid SE' and Offshore = 1									
				select @AdvSEBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Adv SE' and Onshore = 1
				select @AdvSEBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Adv SE' and Offshore = 1
				select @SenSEBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Sen SE' and Onshore = 1
				select @SenSEBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Sen SE' and Offshore = 1
				select @ConsArchBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Cons Arch' and Onshore = 1
				select @ConsArchBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Cons Arch' and Offshore = 1
				select @ProjLeadBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Project Lead' and Onshore = 1
				select @ProjLeadBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Project Lead' and Offshore = 1			
				select @ProjMgrBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Project Mgr' and Onshore = 1
				select @ProjMgrBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Project Mgr' and Offshore = 1
				select @ProgMgrBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Program Mgr' and Onshore = 1	
				select @ProgMgrBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Program Mgr' and Offshore = 1	

print ' MidSEBillingRateOnshore='
print @MidSEBillingRateOnshore
print ' AdvSEBillingRateOnshore='
print @AdvSEBillingRateOnshore				
	
				-- Populate percentage calculate (ex: Hours / FTE Rate)
				set @JrSEOnshorePct = (isnull(@JrSEOnshore,0) / @OnshoreFTERate) 
				set @JrSEOffshorePct = (isnull(@JrSEOffshore,0) / @OffshoreFTERate) 
				set @MidSEOnshorePct = (isnull(@MidSEOnshore,0) / @OnshoreFTERate)
				--set @MidSEOnshorePct = (isnull(@MidSEOnshore,0) / @OnshoreFTERate) * (isnull(@MidSEBillingRateOnshore,0) )
				set @MidSEOffshorePct = (isnull(@MidSEOffshore,0) / @OffshoreFTERate) 
				set @AdvSEOnshorePct = (isnull(@AdvSEOnshore,0) / @OnshoreFTERate) 
				set @AdvSEOffshorePct = (isnull(@AdvSEOffshore,0) / @OffshoreFTERate) 
				set @SenSEOnshorePct = (isnull(@SenSEOnshore,0) / @OnshoreFTERate) 
				set @SenSEOffshorePct = (isnull(@SenSEOffshore,0) / @OffshoreFTERate) 
				set @ConsArchOnshorePct = (isnull(@ConsArchOnshore,0) / @OnshoreFTERate) 
				set @ConsArchOffshorePct = (isnull(@ConsArchOffshore,0) / @OffshoreFTERate) 
				set @ProjLeadOnshorePct = (isnull(@ProjLeadOnshore,0) / @OnshoreFTERate) 
				set @ProjLeadOffshorePct = (isnull(@ProjLeadOffshore,0) / @OffshoreFTERate) 
				set @ProjMgrOnshorePct = (isnull(@ProjMgrOnshore,0) / @OnshoreFTERate) 
				set @ProjMgrOffshorePct = (isnull(@ProjMgrOffshore,0) / @OffshoreFTERate) 
				set @ProgMgrOnshorePct = (isnull(@ProgMgrOnshore,0) / @OnshoreFTERate) 
				set @ProgMgrOffshorePct = (isnull(@ProgMgrOffshore,0) / @OffshoreFTERate) 

print ' MidSEOnshorePct='
print @MidSEOnshorePct
print ' AdvSEOnshorePct='
print @AdvSEOnshorePct



                ---------------------------------------------------------------------------------------------------
       			-- Task_cursor, populates task records for Total Cost type 50 for FTP resources.
				DECLARE Task_cursor CURSOR FOR
					select distinct TaskID from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID
				OPEN Task_cursor
				FETCH NEXT FROM Task_cursor INTO @CurTaskID
				WHILE @@FETCH_STATUS = 0
				BEGIN				
					---------------------------------------------------------------------------------------------------
					-- Resource_cursor, populates FTP Resources under Tasks and calculates the Total Cost, record type 50.
					DECLARE Resource_cursor CURSOR FOR 
						Select distinct ResourceNumber From #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and TaskID = @CurTaskID and NewBillingType = 'FTP Staff Aug' and ResourceNumber is not NULL
					OPEN Resource_cursor
					FETCH NEXT FROM Resource_cursor INTO @CurResourceNumber
					WHILE @@FETCH_STATUS = 0
					BEGIN				
						-- Populate project hours for FTP Staff Aug resources to be used for records type 50 and in Total Cost calculation.
						select @FTPStaffAugProjectOnshore = sum(isnull(Hours,0)) from #TEMP_IN where ResourceNumber = @CurResourceNumber and ProjectID = @CurProjID and TaskID = @CurTaskID and Onshore = 1
						select @FTPStaffAugProjectOffshore = sum(isnull(Hours,0)) from #TEMP_IN where ResourceNumber = @CurResourceNumber and ProjectID = @CurProjID and TaskID = @CurTaskID and Offshore = 1

						-- Populate FTP Staff Aug Total Hours per Resource for the month for all projects.
						set @FTPStaffAugTotalHoursOnshore = NULL
						set @FTPStaffAugTotalHoursOffshore = NULL
						select @FTPStaffAugTotalHoursOnshore = sum(Hours) from piv_reports..tblResourceDetail where ResourceNumber = @CurResourceNumber and WorkDate >= @DateFrom and WorkDate <= @DateTo 
						select @FTPStaffAugTotalHoursOffshore = sum(Hours) from piv_reports..tblResourceDetail where ResourceNumber = @CurResourceNumber and WorkDate >= @DateFrom and WorkDate <= @DateTo

						-- Populate Billing Rate for FTP Staff Aug resources to be for Total cost calculation.      
						set @FTPStaffAugBillingRateOnshore = NULL
						set @FTPStaffAugBillingRateOffshore = NULL		
						select @FTPStaffAugBillingRateOnshore = FTP_BillingRate from #TEMP_IN where ResourceNumber = @CurResourceNumber and Onshore = 1
						select @FTPStaffAugBillingRateOffshore = FTP_BillingRate from #TEMP_IN where ResourceNumber = @CurResourceNumber and Offshore = 1

						-- Perform FTP Staff Aug Total Cost calculation (Cost = Percentage * Billing Rate)
						set @CalcHoursOnshore = NULL
						set @CalcHoursOffshore = NULL
						set @CalcHoursOnshore = ( (@FTPStaffAugProjectOnshore / @FTPStaffAugTotalHoursOnshore) * @FTPStaffAugBillingRateOnshore )
						set @CalcHoursOffshore = ( (@FTPStaffAugProjectOffshore / @FTPStaffAugTotalHoursOffshore) * @FTPStaffAugBillingRateOffshore )

						-- Populate FTP Staff Aug Total Cost by adding total from Total Cost calculation.
						set @FTPStaffAugTotalCostOnshore = isnull(@FTPStaffAugTotalCostOnshore,0) + isnull(@CalcHoursOnshore,0) 
						set @FTPStaffAugTotalCostOffshore = isnull(@FTPStaffAugTotalCostOffshore,0) + isnull(@CalcHoursOffshore,0) 

						FETCH NEXT FROM Resource_cursor INTO @CurResourceNumber	
					END
					CLOSE Resource_cursor
					DEALLOCATE Resource_cursor					
					FETCH NEXT FROM Task_cursor INTO @CurTaskID
				END    
				CLOSE Task_cursor
				DEALLOCATE Task_cursor

				-- Update Total Cost information in type 50 records, summarize hours by new Billing Type.   
				update #TEMP_OUT set 
						JrSEOnshoreHours = isnull(@JrSEOnshorePct * @JrSEBillingRateOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshorePct * @JrSEBillingRateOffshore,0),				
						MidSEOnshoreHours = isnull(@MidSEOnshorePct * @MidSEBillingRateOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshorePct * @MidSEBillingRateOffshore,0),						
						AdvSEOnshoreHours = isnull(@AdvSEOnshorePct * @AdvSEBillingRateOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshorePct * @AdvSEBillingRateOffshore,0),	
						SenSEOnshoreHours = isnull(@SenSEOnshorePct * @SenSEBillingRateOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshorePct * @SenSEBillingRateOffshore,0),	
						ConsArchOnshoreHours = isnull(@ConsArchOnshorePct * @ConsArchBillingRateOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshorePct * @ConsArchBillingRateOffshore,0),
						ProjLeadOnshoreHours = isnull(@ProjLeadOnshorePct * @ProjLeadBillingRateOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshorePct * @ProjLeadBillingRateOffshore,0),
						ProjMgrOnshoreHours = isnull(@ProjMgrOnshorePct * @ProjMgrBillingRateOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshorePct * @ProjMgrBillingRateOffshore,0),
						ProgMgrOnshoreHours = isnull(@ProgMgrOnshorePct * @ProgMgrBillingRateOnshore,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshorePct * @ProgMgrBillingRateOffshore,0),
						FTPStaffAugOnshoreHours = isnull(@FTPStaffAugTotalCostOnshore,0), FTPStaffAugOffshoreHours = isnull(@FTPStaffAugTotalCostOffshore,0)
				where AutoKey > @MaxProj and RecNumber = 50				

				--New changes to fix the rounding issue, John does not feel it should be implemented - 6/25/13.
				--update #TEMP_OUT set 
				--		JrSEOnshoreHours = (isnull(@JrSEOnshore,0) / @OnshoreFTERate) * (isnull(@JrSEBillingRateOnshore,0)), 
				--		JrSEOffshoreHours = (isnull(@JrSEOffshore,0) / @OffshoreFTERate) * (isnull(@JrSEBillingRateOffshore,0)),				
				--		MidSEOnshoreHours = (isnull(@MidSEOnshore,0) / @OnshoreFTERate) * (isnull(@MidSEBillingRateOnshore,0)), 
				--		MidSEOffshoreHours = (isnull(@MidSEOffshore,0) / @OffshoreFTERate) * (isnull(@MidSEBillingRateOffshore,0)),						
				--		AdvSEOnshoreHours = (isnull(@AdvSEOnshore,0) / @OnshoreFTERate) * (isnull(@AdvSEBillingRateOnshore,0)), 
				--		AdvSEOffshoreHours = (isnull(@AdvSEOffshore,0) / @OffshoreFTERate) * (isnull(@AdvSEBillingRateOffshore,0)),	
				--		SenSEOnshoreHours = (isnull(@SenSEOnshore,0) / @OnshoreFTERate) * (isnull(@SenSEBillingRateOnshore,0)), 
				--		SenSEOffshoreHours = (isnull(@SenSEOffshore,0) / @OffshoreFTERate) * (isnull(@SenSEBillingRateOffshore,0)),	
				--		ConsArchOnshoreHours = (isnull(@ConsArchOnshore,0) / @OnshoreFTERate) * (isnull(@ConsArchBillingRateOnshore,0)), 
				--		ConsArchOffshoreHours = (isnull(@ConsArchOffshore,0) / @OffshoreFTERate) * (isnull(@ConsArchBillingRateOffshore,0)),
				--		ProjLeadOnshoreHours = (isnull(@ProjLeadOnshore,0) / @OnshoreFTERate) * (isnull(@ProjLeadBillingRateOnshore,0)), 
				--		ProjLeadOffshoreHours = (isnull(@ProjLeadOffshore,0) / @OffshoreFTERate) * (isnull(@ProjLeadBillingRateOffshore,0)),
				--		ProjMgrOnshoreHours = (isnull(@ProjMgrOnshore,0) / @OnshoreFTERate) * (isnull(@ProjMgrBillingRateOnshore,0)), 
				--		ProjMgrOffshoreHours = (isnull(@ProjMgrOffshore,0) / @OffshoreFTERate) * (isnull(@ProjMgrBillingRateOffshore,0)),
				--		ProgMgrOnshoreHours = (isnull(@ProgMgrOnshore,0) / @OnshoreFTERate) * (isnull(@ProgMgrBillingRateOnshore,0)), 
				--		ProgMgrOffshoreHours = (isnull(@ProgMgrOffshore,0) / @OffshoreFTERate) * (isnull(@ProgMgrBillingRateOffshore,0)),
				--		FTPStaffAugOnshoreHours = isnull(@FTPStaffAugTotalCostOnshore,0), 
				--		FTPStaffAugOffshoreHours = isnull(@FTPStaffAugTotalCostOffshore,0)
				--where AutoKey > @MaxProj and RecNumber = 50		
				
declare @test1 decimal(10,2), @test2 decimal(10,2)
select @test1 = MidSEOnshoreHours from  #TEMP_OUT where AutoKey > @MaxProj and RecNumber = 50	
select @test2 = AdvSEOnshoreHours from  #TEMP_OUT where AutoKey > @MaxProj and RecNumber = 50	
print ' test1='
print @test1
print ' test2='
print @test2
				
			--Reset values in Total Cost for type 50 records
    		set @FTPStaffAugTotalCostOnshore = NULL
			set @FTPStaffAugTotalCostOffshore = NULL
				
    		FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
   			END    
    		CLOSE ProjDesc_cursor
    		DEALLOCATE ProjDesc_cursor
    		
			---------------------------------------------------------------------------------------------------
                
            -- GET funding category and location combo  --
            Declare @@out_location varchar (100), @@out_fundingcat varchar (100), @@out_afenumber varchar (20),@@out_programmgr varchar (50), @@Total_FTE float             
        	set @@out_location  = NULL
        	set @@out_fundingcat = NULL
        	set @@out_afenumber = NULL
			set @@out_programmgr = NULL	
        	set @@Total_FTE = NULL
            exec GET_Location_Combo @CurAFE_DescID, @DateFrom, @DateTo, @@out_location OUTPUT, @@out_fundingcat OUTPUT, @@out_afenumber OUTPUT,@@out_programmgr OUTPUT, @@Total_FTE OUTPUT
                
			--Update temporary output table #TEMP_OUT.    
			update #TEMP_OUT set ITSABillingCat = @ITSABillingCat, ProgramMgr = @@out_programmgr, location = @@out_location, fundingcat = @@out_fundingcat, AFENumber = @@out_afenumber, COApprovedFTEs = isnull(@@Total_FTE,0)
			where AutoKey = @MaxAFEDesc

			-- Populate Hours and TotalHours and ActualFTEs Column (rec type 30 horizontal).
			select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) from #TEMP_OUT where AutoKey > @MaxAFEDesc and RecNumber = 40
				select @TotalHours = isnull(@JrSEOnshoreHours,0) + isnull(@JrSEOffshoreHours,0) + isnull(@MidSEOnshoreHours,0) + isnull(@MidSEOffshoreHours,0) + isnull(@AdvSEOnshoreHours,0) + isnull(@AdvSEOffshoreHours,0) + isnull(@SenSEOnshoreHours,0) + isnull(@SenSEOffshoreHours,0) + isnull(@ConsArchOnshoreHours,0) + isnull(@ConsArchOffshoreHours,0) + isnull(@ProjLeadOnshoreHours,0) + isnull(@ProjLeadOffshoreHours,0) + isnull(@ProjMgrOnshoreHours,0) + isnull(@ProjMgrOffshoreHours,0) + isnull(@ProgMgrOnshoreHours,0) + isnull(@ProgMgrOffshoreHours,0) + isnull(@FTPStaffAugOnshoreHours,0) + isnull(@FTPStaffAugOffshoreHours,0)
				update #TEMP_OUT set TotalHours = isnull(@TotalHours,0), JrSEOnshoreHours = isnull(@JrSEOnshoreHours,0), JrSEOffshoreHours = isnull(@JrSEOffshoreHours,0), MidSEOnshoreHours = isnull(@MidSEOnshoreHours,0), MidSEOffshoreHours = isnull(@MidSEOffshoreHours,0), AdvSEOnshoreHours = isnull(@AdvSEOnshoreHours,0), AdvSEOffshoreHours = isnull(@AdvSEOffshoreHours,0), SenSEOnshoreHours = isnull(@SenSEOnshoreHours,0), SenSEOffshoreHours = isnull(@SenSEOffshoreHours,0), ConsArchOnshoreHours = isnull(@ConsArchOnshoreHours,0), ConsArchOffshoreHours = isnull(@ConsArchOffshoreHours,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshoreHours,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshoreHours,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshoreHours,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshoreHours,0), ProgMgrOnshoreHours = isnull(@ProgMgrOnshoreHours,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshoreHours,0), FTPStaffAugOnshoreHours = isnull(@FTPStaffAugOnshoreHours,0), FTPStaffAugOffshoreHours = isnull(@FTPStaffAugOffshoreHours,0) where AutoKey = @MaxAFEDesc
				
				update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) 
					+ ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours) / @OffshoreFTERate) 
					+ ( (FTPStaffAugOnshoreHours + FTPStaffAugOffshoreHours) / @FTPBillingRate ) 
				where AutoKey = @MaxAFEDesc	

			-- Populate EDSVariance Column (rec type 30 horizontal).
			update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey = @MaxAFEDesc

			-- Populate Hours and TotalHours and ActualFTEs Column (rec type 40 horizontal).
			update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) + isnull(ProgMgrOffshoreHours,0) + isnull(FTPStaffAugOnshoreHours,0) + isnull(FTPStaffAugOffshoreHours,0)
				where AutoKey > @MaxAFEDesc and RecNumber = 40

				update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) 
					+ ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours) / @OffshoreFTERate) 
					+ ( (FTPStaffAugOnshoreHours + FTPStaffAugOffshoreHours) / @FTPBillingRate )
				where AutoKey > @MaxAFEDesc and RecNumber = 40
 
  			-- Populate TotalHours Column for Record Type 50 (horizontal).		         
			update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) + isnull(ProgMgrOffshoreHours,0)
					+ isnull(FTPStaffAugOnshoreHours,0) + isnull(FTPStaffAugOffshoreHours,0) 
				where AutoKey > @MaxAFEDesc and RecNumber = 50				
			
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
		END    
		CLOSE AFEDesc_cursor
		DEALLOCATE AFEDesc_cursor

		---------------------------------------------------------------------------------------------------
		FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
		END
		CLOSE Program_cursor
		DEALLOCATE Program_cursor

	---------------------------------------------------------------------------------------------------  
    
    -- Update total information for record type 10.
	select @JrSEOnshore = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshore = sum(isnull(JrSeOffshoreHours,0)), @MidSEOnshore = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshore = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshore = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshore = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshore = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshore= sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshore = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshore= sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshore = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshore= sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshore = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshore= sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshore = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshore = sum(isnull(ProgMgrOffshoreHours,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0)) from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30
		select @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)) from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30
		Update #TEMP_OUT set JrSEOnshoreHours = @JrSEOnshore, JrSeOffshoreHours = @JrSEOffshore, MidSEOnshoreHours = @MidSEOnshore, MidSEOffshoreHours = @MidSEOffshore, AdvSEOnshoreHours = @AdvSEOnshore, AdvSEOffshoreHours = @AdvSEOffshore, SenSEOnshoreHours = @SenSEOnshore, SenSEOffshoreHours = @SenSEOffshore, ConsArchOnshoreHours = @ConsArchOnshore, ConsArchOffshoreHours = @ConsArchOffshore, ProjLeadOnshoreHours = @ProjLeadOnshore, ProjLeadOffshoreHours = @ProjLeadOffshore, ProjMgrOnshoreHours = @ProjMgrOnshore, ProjMgrOffshoreHours = @ProjMgrOffshore, ProgMgrOnshoreHours = @ProgMgrOnshore, ProgMgrOffshoreHours = @ProgMgrOffshore, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours, TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs where AutoKey = @MaxProgGroup
		update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) 
			+ ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours) / @OffshoreFTERate) 
			+ ( (FTPStaffAugOnshoreHours + FTPStaffAugOffshoreHours) / @FTPBillingRate ) 
		where AutoKey = @MaxProgGroup	
		
	-- Populate ActualFTEs column
	update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey = @MaxProgGroup

	FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID, @UPVP
	END
	CLOSE ProgramGroup_cursor
	DEALLOCATE ProgramGroup_cursor

---------------------------------------------------------------------------------------------------
-- Calculate and Populate the RecNumber 0 records (Grand Total Continental)
	select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) 
		from #TEMP_OUT where RecNumber = 10
	update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours 
		where RecNumber = 0 and RecType = 'GrandTotal'
	update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours) / @OffshoreFTERate) + ( (FTPStaffAugOnshoreHours + FTPStaffAugOffshoreHours) / @FTPBillingRate ) 
		where RecNumber = 0 and RecType = 'GrandTotal'
	update #TEMP_OUT set TotalHours = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + ( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate ),		
		ActualFTEs = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + ( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate ), 		
		COApprovedFTEs = @COApprovedFTEs, JrSEOnshoreHours = @JrSEOnshoreHours/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffshoreHours/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnshoreHours/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffshoreHours/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnshoreHours/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffshoreHours/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnshoreHours/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffshoreHours/@OffshoreFTERate, 	ConsArchOnshoreHours = @ConsArchOnshoreHours/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchOffshoreHours/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadOnshoreHours/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrOnshoreHours/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrOnshoreHours/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/@OffshoreFTERate, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate 
		where RecNumber = 0 and RecType = 'GrandTotalConversion'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 0 and RecType in ('GrandTotal', 'GrandTotalConversion')

-- Calculate and Populate the 1 records (Total Airline)
select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) from #TEMP_OUT 
		where RecNumber = 30 and ITSABillingCat = 'Airline'
	update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours 
		where RecNumber = 1 and RecType = 'TotalAirline'
	update #TEMP_OUT set TotalHours = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + ( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate ),		
		JrSEOnshoreHours = @JrSEOnshoreHours/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffshoreHours/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnshoreHours/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffshoreHours/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnshoreHours/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffshoreHours/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnshoreHours/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffshoreHours/@OffshoreFTERate, 	ConsArchOnshoreHours = @ConsArchOnshoreHours/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchOffshoreHours/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadOnshoreHours/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrOnshoreHours/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrOnshoreHours/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/@OffshoreFTERate, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate 
		where RecNumber = 1 and RecType = 'TotalAirlineConversion'
	update #TEMP_OUT set ActualFTEs = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + 
		( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate )
		where RecNumber = 1 and RecType in ('TotalAirline', 'TotalAirlineConversion', 'TotalCostAirline')	
		
	select @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) from #TEMP_OUT 
		where RecNumber = 50 and RecTypeID = 'Airline'
	update #TEMP_OUT set --TotalHours = @TotalHours, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours 
		where RecNumber = 1 and RecType = 'TotalCostAirline'
		
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), 	@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 1 and RecType = 'TotalAirlineConversion'
	update #TEMP_OUT set JrSEOnshoreHours = isnull(@JrSEOnshoreHours * @JrSEBillingRateOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshoreHours * @JrSEBillingRateOffshore,0), MidSEOnshoreHours = isnull(@MidSEOnshoreHours * @MidSEBillingRateOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshoreHours * @MidSEBillingRateOffshore,0), AdvSEOnshoreHours = isnull(@AdvSEOnshoreHours * @AdvSEBillingRateOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshoreHours * @AdvSEBillingRateOffshore,0),	SenSEOnshoreHours = isnull(@SenSEOnshoreHours * @SenSEBillingRateOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshoreHours * @SenSEBillingRateOffshore,0), ConsArchOnshoreHours = isnull(@ConsArchOnshoreHours * @ConsArchBillingRateOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshoreHours * @ConsArchBillingRateOffshore,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshoreHours * @ProjLeadBillingRateOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshoreHours * @ProjLeadBillingRateOffshore,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshoreHours * @ProjMgrBillingRateOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshoreHours * @ProjMgrBillingRateOffshore,0), ProgMgrOnshoreHours = isnull(@ProgMgrOnshoreHours * @ProgMgrBillingRateOnshore,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshoreHours * @ProgMgrBillingRateOffshore,0)
		where RecNumber = 1 and RecType = 'TotalCostAirline'
		
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		, @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) 
		from #TEMP_OUT where RecNumber = 1 and RecType = 'TotalCostAirline'
	update #TEMP_OUT set TotalHours = (@JrSEOnshoreHours + @JrSEOffshoreHours + @MidSEOnshoreHours + @MidSEOffshoreHours + @AdvSEOnshoreHours + AdvSEOffshoreHours + @SenSEOnshoreHours + @SenSEOffshoreHours + @ConsArchOnshoreHours + @ConsArchOffshoreHours + @ProjLeadOnshoreHours + @ProjLeadOffshoreHours + @ProjMgrOnshoreHours + @ProjMgrOffshoreHours + @ProgMgrOnshoreHours + @ProgMgrOffshoreHours) 
		+ (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) 
		where RecNumber = 1 and RecType = 'TotalCostAirline'	
update #TEMP_OUT set COApprovedFTEs = @COApprovedFTEs where RecNumber = 1 and RecType in ('TotalAirline', 'TotalAirlineConversion', 'TotalCostAirline')	
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 1 and RecType in ('TotalAirline', 'TotalAirlineConversion', 'TotalCostAirline')

-- Calculate and Populate the 2 records (Total ADM)
select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) 
		from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'ADM'
	update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours 
		where RecNumber = 2 and RecType = 'TotalADM'
	update #TEMP_OUT set TotalHours = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + ( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate ),		
		JrSEOnshoreHours = @JrSEOnshoreHours/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffshoreHours/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnshoreHours/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffshoreHours/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnshoreHours/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffshoreHours/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnshoreHours/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffshoreHours/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchOnshoreHours/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchOffshoreHours/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadOnshoreHours/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrOnshoreHours/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrOnshoreHours/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/@OffshoreFTERate, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate 
		where RecNumber = 2 and RecType = 'TotalADMConversion'
	update #TEMP_OUT set ActualFTEs = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + 
		( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate )
		where RecNumber = 2 and RecType in ('TotalADM', 'TotalADMConversion', 'TotalCostADM')	
		
	select --@TotalHours = sum(isnull(TotalHours,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), 
		@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) from #TEMP_OUT 
		where RecNumber = 50 and RecTypeID = 'ADM'
	update #TEMP_OUT set --TotalHours = @TotalHours, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours 
		where RecNumber = 2 and RecType = 'TotalCostADM'
		
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), 	@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 2 and RecType = 'TotalADMConversion'
	update #TEMP_OUT set JrSEOnshoreHours = isnull(@JrSEOnshoreHours * @JrSEBillingRateOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshoreHours * @JrSEBillingRateOffshore,0), MidSEOnshoreHours = isnull(@MidSEOnshoreHours * @MidSEBillingRateOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshoreHours * @MidSEBillingRateOffshore,0), AdvSEOnshoreHours = isnull(@AdvSEOnshoreHours * @AdvSEBillingRateOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshoreHours * @AdvSEBillingRateOffshore,0),	SenSEOnshoreHours = isnull(@SenSEOnshoreHours * @SenSEBillingRateOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshoreHours * @SenSEBillingRateOffshore,0), ConsArchOnshoreHours = isnull(@ConsArchOnshoreHours * @ConsArchBillingRateOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshoreHours * @ConsArchBillingRateOffshore,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshoreHours * @ProjLeadBillingRateOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshoreHours * @ProjLeadBillingRateOffshore,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshoreHours * @ProjMgrBillingRateOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshoreHours * @ProjMgrBillingRateOffshore,0), ProgMgrOnshoreHours = isnull(@ProgMgrOnshoreHours * @ProgMgrBillingRateOnshore,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshoreHours * @ProgMgrBillingRateOffshore,0)
		where RecNumber = 2 and RecType = 'TotalCostADM'
		
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		, @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) 
		from #TEMP_OUT where RecNumber = 2 and RecType = 'TotalCostADM'
	update #TEMP_OUT set TotalHours = (@JrSEOnshoreHours + @JrSEOffshoreHours + @MidSEOnshoreHours + @MidSEOffshoreHours + @AdvSEOnshoreHours + AdvSEOffshoreHours + @SenSEOnshoreHours + @SenSEOffshoreHours + @ConsArchOnshoreHours + @ConsArchOffshoreHours + @ProjLeadOnshoreHours + @ProjLeadOffshoreHours + @ProjMgrOnshoreHours + @ProjMgrOffshoreHours + @ProgMgrOnshoreHours + @ProgMgrOffshoreHours) 
		+ (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) 
		where RecNumber = 2 and RecType = 'TotalCostADM'		
update #TEMP_OUT set COApprovedFTEs = @COApprovedFTEs where RecNumber = 2 and RecType in ('TotalADM', 'TotalADMConversion', 'TotalCostADM')	
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 2 and RecType in ('TotalADM', 'TotalADMConversion', 'TotalCostADM')


-- Calculate and Populate the 4 records (Total AFE_Prod)
select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) from #TEMP_OUT 
		where RecNumber = 30 and ITSABillingCat = 'AFE_Prod'
	update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours 
		where RecNumber = 4 and RecType = 'TotalAFEProd'
	update #TEMP_OUT set TotalHours = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + ( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate ),		
		JrSEOnshoreHours = @JrSEOnshoreHours/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffshoreHours/@OffshoreFTERate, 			MidSEOnshoreHours = @MidSEOnshoreHours/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffshoreHours/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnshoreHours/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffshoreHours/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnshoreHours/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffshoreHours/@OffshoreFTERate, 	ConsArchOnshoreHours = @ConsArchOnshoreHours/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchOffshoreHours/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadOnshoreHours/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrOnshoreHours/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrOnshoreHours/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/@OffshoreFTERate, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate 
		where RecNumber = 4 and RecType = 'TotalAFEProdConversion'
	update #TEMP_OUT set ActualFTEs = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + 
		( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate )
		where RecNumber = 4 and RecType in ('TotalAFEProd', 'TotalAFEProdConversion', 'TotalCostAFEProd')	

	select --@TotalHours = sum(isnull(TotalHours,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), 
		@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) from #TEMP_OUT 
		where RecNumber = 50 and RecTypeID = 'AFE_Prod'
	update #TEMP_OUT set --TotalHours = @TotalHours, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours 
		where RecNumber = 4 and RecType = 'TotalCostAFEProd'
		
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), 	@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 4 and RecType = 'TotalAFEProdConversion'
	update #TEMP_OUT set JrSEOnshoreHours = isnull(@JrSEOnshoreHours * @JrSEBillingRateOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshoreHours * @JrSEBillingRateOffshore,0), MidSEOnshoreHours = isnull(@MidSEOnshoreHours * @MidSEBillingRateOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshoreHours * @MidSEBillingRateOffshore,0), AdvSEOnshoreHours = isnull(@AdvSEOnshoreHours * @AdvSEBillingRateOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshoreHours * @AdvSEBillingRateOffshore,0),	SenSEOnshoreHours = isnull(@SenSEOnshoreHours * @SenSEBillingRateOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshoreHours * @SenSEBillingRateOffshore,0), ConsArchOnshoreHours = isnull(@ConsArchOnshoreHours * @ConsArchBillingRateOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshoreHours * @ConsArchBillingRateOffshore,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshoreHours * @ProjLeadBillingRateOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshoreHours * @ProjLeadBillingRateOffshore,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshoreHours * @ProjMgrBillingRateOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshoreHours * @ProjMgrBillingRateOffshore,0), ProgMgrOnshoreHours = isnull(@ProgMgrOnshoreHours * @ProgMgrBillingRateOnshore,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshoreHours * @ProgMgrBillingRateOffshore,0)
		where RecNumber = 4 and RecType = 'TotalCostAFEProd'
		
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		, @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) 
		from #TEMP_OUT where RecNumber = 4 and RecType = 'TotalCostAFEProd'
	update #TEMP_OUT set TotalHours = (@JrSEOnshoreHours + @JrSEOffshoreHours + @MidSEOnshoreHours + @MidSEOffshoreHours + @AdvSEOnshoreHours + AdvSEOffshoreHours + @SenSEOnshoreHours + @SenSEOffshoreHours + @ConsArchOnshoreHours + @ConsArchOffshoreHours + @ProjLeadOnshoreHours + @ProjLeadOffshoreHours + @ProjMgrOnshoreHours + @ProjMgrOffshoreHours + @ProgMgrOnshoreHours + @ProgMgrOffshoreHours) 
		+ (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) 
		where RecNumber = 4 and RecType = 'TotalCostAFEProd'		
update #TEMP_OUT set COApprovedFTEs = @COApprovedFTEs where RecNumber = 4 and RecType in ('TotalAFEProd', 'TotalAFEProdConversion', 'TotalCostAFEProd')	
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 4 and RecType in ('TotalAFEProd', 'TotalAFEProdConversion', 'TotalCostAFEProd')

-- Calculate and Populate the 5 records (Total Staff Augmentation)
select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) from #TEMP_OUT 
		where RecNumber = 30 and ITSABillingCat = 'Staff Aug'		
	update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours 
		where RecNumber = 5 and RecType = 'TotalStaffAug'
	update #TEMP_OUT set TotalHours = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + ( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate ),		
		JrSEOnshoreHours = @JrSEOnshoreHours/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffshoreHours/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnshoreHours/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffshoreHours/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnshoreHours/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffshoreHours/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnshoreHours/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffshoreHours/@OffshoreFTERate, 	ConsArchOnshoreHours = @ConsArchOnshoreHours/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchOffshoreHours/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadOnshoreHours/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrOnshoreHours/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrOnshoreHours/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/@OffshoreFTERate, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate 
		where RecNumber = 5 and RecType = 'TotalStafAugConversion'
	update #TEMP_OUT set ActualFTEs = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + 
		( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate )
		where RecNumber = 5 and RecType in ('TotalStaffAug', 'TotalStafAugConversion', 'TotalCostStaffAug')	

	select --@TotalHours = sum(isnull(TotalHours,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), 
		@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) from #TEMP_OUT 
		where RecNumber = 50 and RecTypeID = 'Staff Aug'
	update #TEMP_OUT set --TotalHours = @TotalHours, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours 
		where RecNumber = 5 and RecType = 'TotalCostStaffAug'
		
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), 	@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 5 and RecType = 'TotalStafAugConversion'
	update #TEMP_OUT set JrSEOnshoreHours = isnull(@JrSEOnshoreHours * @JrSEBillingRateOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshoreHours * @JrSEBillingRateOffshore,0), MidSEOnshoreHours = isnull(@MidSEOnshoreHours * @MidSEBillingRateOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshoreHours * @MidSEBillingRateOffshore,0), AdvSEOnshoreHours = isnull(@AdvSEOnshoreHours * @AdvSEBillingRateOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshoreHours * @AdvSEBillingRateOffshore,0),	SenSEOnshoreHours = isnull(@SenSEOnshoreHours * @SenSEBillingRateOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshoreHours * @SenSEBillingRateOffshore,0), ConsArchOnshoreHours = isnull(@ConsArchOnshoreHours * @ConsArchBillingRateOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshoreHours * @ConsArchBillingRateOffshore,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshoreHours * @ProjLeadBillingRateOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshoreHours * @ProjLeadBillingRateOffshore,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshoreHours * @ProjMgrBillingRateOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshoreHours * @ProjMgrBillingRateOffshore,0), ProgMgrOnshoreHours = isnull(@ProgMgrOnshoreHours * @ProgMgrBillingRateOnshore,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshoreHours * @ProgMgrBillingRateOffshore,0)
		where RecNumber = 5 and RecType = 'TotalCostStaffAug'
		
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		, @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) 
		from #TEMP_OUT where RecNumber = 5 and RecType = 'TotalCostStaffAug'
	update #TEMP_OUT set TotalHours = (@JrSEOnshoreHours + @JrSEOffshoreHours + @MidSEOnshoreHours + @MidSEOffshoreHours + @AdvSEOnshoreHours + AdvSEOffshoreHours + @SenSEOnshoreHours + @SenSEOffshoreHours + @ConsArchOnshoreHours + @ConsArchOffshoreHours + @ProjLeadOnshoreHours + @ProjLeadOffshoreHours + @ProjMgrOnshoreHours + @ProjMgrOffshoreHours + @ProgMgrOnshoreHours + @ProgMgrOffshoreHours) 
		+ (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) 
		where RecNumber = 5 and RecType = 'TotalCostStaffAug'		
update #TEMP_OUT set COApprovedFTEs = @COApprovedFTEs where RecNumber = 5 and RecType in ('TotalStaffAug', 'TotalStafAugConversion', 'TotalCostStaffAug')	
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 5 and RecType in ('TotalStaffAug', 'TotalStafAugConversion', 'TotalCostStaffAug')

-- Calculate and Populate the 6 records (Total UA Merger)
select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) from #TEMP_OUT 
		where RecNumber = 30 and ITSABillingCat = 'UA Merger'				
	update #TEMP_OUT set TotalHours = @TotalHours, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours 
		where RecNumber = 6 and RecType = 'TotalUAMerger'
	update #TEMP_OUT set TotalHours = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + ( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate ),		
		JrSEOnshoreHours = @JrSEOnshoreHours/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffshoreHours/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnshoreHours/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffshoreHours/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnshoreHours/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffshoreHours/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnshoreHours/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffshoreHours/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchOnshoreHours/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchOffshoreHours/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadOnshoreHours/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrOnshoreHours/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrOnshoreHours/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/@OffshoreFTERate, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate 
		where RecNumber = 6 and RecType = 'TotalUAMergerConversion'
	update #TEMP_OUT set ActualFTEs = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours) / @OffshoreFTERate) + 
		( (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) / @FTPBillingRate )
		where RecNumber = 6 and RecType in ('TotalUAMerger', 'TotalUAMergerConversion', 'TotalCostUAMerger')	

	select --@TotalHours = sum(isnull(TotalHours,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), 
		@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) from #TEMP_OUT 
		where RecNumber = 50 and RecTypeID = 'UA Merger'
	update #TEMP_OUT set --TotalHours = @TotalHours, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, 
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours 
		where RecNumber = 6 and RecType = 'TotalCostUAMerger'
		
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), 	@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 6 and RecType = 'TotalUAMergerConversion'
	update #TEMP_OUT set JrSEOnshoreHours = isnull(@JrSEOnshoreHours * @JrSEBillingRateOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshoreHours * @JrSEBillingRateOffshore,0), MidSEOnshoreHours = isnull(@MidSEOnshoreHours * @MidSEBillingRateOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshoreHours * @MidSEBillingRateOffshore,0), AdvSEOnshoreHours = isnull(@AdvSEOnshoreHours * @AdvSEBillingRateOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshoreHours * @AdvSEBillingRateOffshore,0),	SenSEOnshoreHours = isnull(@SenSEOnshoreHours * @SenSEBillingRateOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshoreHours * @SenSEBillingRateOffshore,0), ConsArchOnshoreHours = isnull(@ConsArchOnshoreHours * @ConsArchBillingRateOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshoreHours * @ConsArchBillingRateOffshore,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshoreHours * @ProjLeadBillingRateOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshoreHours * @ProjLeadBillingRateOffshore,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshoreHours * @ProjMgrBillingRateOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshoreHours * @ProjMgrBillingRateOffshore,0), ProgMgrOnshoreHours = isnull(@ProgMgrOnshoreHours * @ProgMgrBillingRateOnshore,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshoreHours * @ProgMgrBillingRateOffshore,0)
		where RecNumber = 6 and RecType = 'TotalCostUAMerger'
		
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		, @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) 
		from #TEMP_OUT where RecNumber = 6 and RecType = 'TotalCostUAMerger'
	update #TEMP_OUT set TotalHours = (@JrSEOnshoreHours + @JrSEOffshoreHours + @MidSEOnshoreHours + @MidSEOffshoreHours + @AdvSEOnshoreHours + AdvSEOffshoreHours + @SenSEOnshoreHours + @SenSEOffshoreHours + @ConsArchOnshoreHours + @ConsArchOffshoreHours + @ProjLeadOnshoreHours + @ProjLeadOffshoreHours + @ProjMgrOnshoreHours + @ProjMgrOffshoreHours + @ProgMgrOnshoreHours + @ProgMgrOffshoreHours) 
		+ (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) 
		where RecNumber = 6 and RecType = 'TotalCostUAMerger'		
update #TEMP_OUT set COApprovedFTEs = @COApprovedFTEs where RecNumber = 6 and RecType in ('TotalUAMerger','TotalUAMergerConversion','TotalCostUAMerger')
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 6 and RecType in ('TotalUAMerger','TotalUAMergerConversion','TotalCostUAMerger')

-- Remove any rows that have ZERO values in the TotalHours and the COApprovedFTEs
delete #TEMP_OUT where RecNumber in (10,20,30,40,50) and (TotalHours = 0 or TotalHours is NULL) and COApprovedFTEs = 0

----------------------------------------------------------------------------------------------------------------------
select * from #TEMP_OUT order by AutoKey

