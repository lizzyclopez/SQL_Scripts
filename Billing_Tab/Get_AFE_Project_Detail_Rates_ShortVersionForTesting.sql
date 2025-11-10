drop table #TEMP_IN
drop table #TEMP_OUT
drop view [dbo].[SP_Get_AFE_Project_Detail]
drop view [dbo].[SP_Get_AFE_Project_Detail2]

-- Create the first temp VIEW.
DECLARE @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Project_Detail AS select AFE_Summary_View.*, CO_Resource.ResourceNumber, CO_Resource.BillingRate AS FTP_BillingRate, CO_Resource.Onshore, CO_Resource.Offshore, CO_Resource.Hourly, CO_BillingCode.Billing_CodeID, CO_BillingCode.Description AS NewBillingType, CO_BillingCodeRate.BillingRateOnshore, CO_BillingCodeRate.BillingRateOffshore
from AFE_Summary_View inner join CO_Resource ON AFE_Summary_View.EDSNETID = CO_Resource.ResourceNumber inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID left outer join CO_BillingCodeRate ON CO_BillingCode.Billing_CodeID = CO_BillingCodeRate.Billing_CodeID
where WorkDate >= ''2016-07-01'' and WorkDate <= ''2016-07-31'' ' 
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
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Project_Detail2 AS select dbo.lkITSABillingCategory.Description AS ITSABillingCat, FTE_Approved_Time.* from FTE_Approved_Time LEFT OUTER JOIN dbo.tblAFEDetail ON FTE_Approved_Time.AFE_DescID = dbo.tblAFEDetail.AFE_DescID LEFT OUTER JOIN dbo.lkITSABillingCategory ON dbo.tblAFEDetail.ITSABillingCategoryID = dbolkITSABillingCategory.ITSABillingCategoryID 
where Appr_FTE_Hours > 0 and CurrentMonth = ''201607'' ' 
exec (@SQL_statement)

-- Copy the data from the second temp VIEW into #TEMP_IN.
insert dbo.#TEMP_IN ( AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, ITSABillingCat, UA_VicePresident )
select AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, ITSABillingCat, UA_VicePresident 
from dbo.SP_Get_AFE_Project_Detail2

-- Create Index
Create Index IDX1 on dbo.#TEMP_IN (Prog_GroupID, ProgramID, AFE_DescID, ProjectID, NewBillingType)

-- Adjust the Hours according to the ClientFundingPct by CO
update dbo.#TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0

--select * from #TEMP_IN
--delete from #TEMP_IN where ItSABillingCat <> 'Outsource Dev'
--------------------------------------------------------------------------------------------------
--drop table #TEMP_OUT
CREATE TABLE [dbo].[#TEMP_OUT] ( [AutoKey][int] IDENTITY (0, 1) NOT NULL, [RecNumber][int] NULL, [RecType] [varchar] (100) NULL, [RecDesc] [varchar] (100) NULL, [RecTypeID] [varchar] (100) NULL, [ITSABillingCat] [varchar] (30) NULL, [TotalHours] [decimal](10,2) NULL,[ActualFTEs] [decimal](10,2) NULL,[COApprovedFTEs] [decimal](10,2) NULL,[EDSVariance] [decimal](10,2) NULL,[JrSEOnshoreHours] [decimal](10,2) NULL,[JrSeOffshoreHours] [decimal](10,2) NULL,[MidSEOnshoreHours] [decimal](10,2) NULL,[MidSEOffshoreHours] [decimal](10,2) NULL,[AdvSEOnshoreHours] [decimal](10,2) NULL,[AdvSEOffshoreHours] [decimal](10,2) NULL,[SenSEOnshoreHours] [decimal](10,2) NULL,[SenSEOffshoreHours] [decimal](10,2) NULL,[ConsArchOnshoreHours] [decimal](10,2) NULL,[ConsArchOffshoreHours] [decimal](10,2) NULL,[ProjLeadOnshoreHours] [decimal](10,2) NULL,[ProjLeadOffshoreHours] [decimal](10,2) NULL,[ProjMgrOnshoreHours] [decimal](10,2) NULL,[ProjMgrOffshoreHours] [decimal](10,2) NULL,[ProgMgrOnshoreHours] [decimal](10,2) NULL, [ProgMgrOffshoreHours] [decimal](10,2) NULL, [JrProjMgrOffshoreHours] [decimal](10,2) NULL, [JrProgMgrOffshoreHours] [decimal](10,2) NULL	
) ON [PRIMARY]

insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 3, 'TotalPSS', 'Total PSS CO Investment'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 3, 'TotalPSSConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 3, 'TotalCostPSS', 'Total Cost'

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID varchar(100), @UPVP varchar (50), @CurProgram varchar(100), @CurProgramID  varchar(100), @CurCoBusinessLead varchar (100), @CurAFEDesc varchar (100), @CurAFE_DescID varchar (100), @CurProjectTitle varchar(100), @CurProjID varchar (100), @CurTaskName varchar(100), @CurTaskID varchar (100), @CurResourceName varchar(100), @CurEventList varchar(100), @CurEventName varchar(100), @MaxProgGroup bigint, @MaxProgram bigint, @MaxAFEDesc bigint, @MaxProj bigint, @MaxTask bigint, @MaxEvent bigint, @CurResourceNumber varchar(15), @JrSEOnshore decimal(10,2), @JrSEOffshore decimal(10,2), @MidSEOnshore decimal(10,2), @MidSEOffshore decimal(10,2), @AdvSEOnshore decimal(10,2), @AdvSEOffshore decimal(10,2), @SenSEOnshore decimal(10,2), @SenSEOffshore decimal(10,2), @ConsArchOnshore decimal(10,2), @ConsArchOffshore decimal(10,2), @ProjLeadOnshore decimal(10,2), @ProjLeadOffshore decimal(10,2), @ProjMgrOnshore decimal(10,2), @ProjMgrOffshore decimal(10,2), @ProgMgrOnshore decimal(10,2), @ProgMgrOffshore decimal(10,2), @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2), @ProgMgrOffshoreHours decimal(10,2), @TotalHours decimal(10,2), @COApprovedFTEs decimal(10,2), @FTPStaffAugOnshore decimal(10,2), @FTPStaffAugOffshore decimal(10,2), @FTPStaffAugOnshoreHours decimal(10,2), @FTPStaffAugOffshoreHours decimal(10,2), @FTPBillingRate decimal(9,2), @year int, @month int, @BillableDays int, @OnshoreFTERate decimal(9,2), @OffshoreFTERate decimal(9,2), @FTPStaffAugProjectOnshore decimal(10,2), @FTPStaffAugProjectOffshore decimal(10,2), @FTPStaffAugTotalHoursOnshore decimal(10,2), @FTPStaffAugTotalHoursOffshore decimal(10,2), @FTPStaffAugBillingRateOnshore decimal(9,2), @FTPStaffAugBillingRateOffshore decimal(9,2), @CalcHoursOnshore decimal(9,2), @CalcHoursOffshore decimal(9,2), @PrevCalcHoursOnshore decimal(9,2), @PrevCalcHoursOffshore decimal(9,2), @FTPStaffAugTotalCostOnshore decimal(9,2), @FTPStaffAugTotalCostOffshore decimal(9,2), @JrSEBillingRateOnshore decimal(10,2), @JrSEBillingRateOffshore decimal(10,2), @MidSEBillingRateOnshore decimal(10,2), @MidSEBillingRateOffshore decimal(10,2), @AdvSEBillingRateOnshore decimal(10,2), @AdvSEBillingRateOffshore decimal(10,2), @SenSEBillingRateOnshore decimal(10,2), @SenSEBillingRateOffshore decimal(10,2), @ConsArchBillingRateOnshore decimal(10,2), @ConsArchBillingRateOffshore decimal(10,2), @ProjLeadBillingRateOnshore decimal(10,2), @ProjLeadBillingRateOffshore decimal(10,2), @ProjMgrBillingRateOnshore decimal(10,2), @ProjMgrBillingRateOffshore decimal(10,2), @ProgMgrBillingRateOnshore decimal(10,2), @ProgMgrBillingRateOffshore decimal(10,2), @JrSEOnshorePct decimal(10,2), @JrSEOffshorePct decimal(10,2), @MidSEOnshorePct decimal(10,2), @MidSEOffshorePct decimal(10,2), @AdvSEOnshorePct decimal(10,2), @AdvSEOffshorePct decimal(10,2), @SenSEOnshorePct decimal(10,2), @SenSEOffshorePct decimal(10,2), @ConsArchOnshorePct decimal(10,2), @ConsArchOffshorePct decimal(10,2), @ProjLeadOnshorePct decimal(10,2), @ProjLeadOffshorePct decimal(10,2), @ProjMgrOnshorePct decimal(10,2), @ProjMgrOffshorePct decimal(10,2), @ProgMgrOnshorePct decimal(10,2), @ProgMgrOffshorePct decimal(10,2), @JrProjMgrOffshore decimal(10,2), @JrProgMgrOffshore decimal(10,2), @JrProjMgrOffshoreHours decimal(10,2), @JrProgMgrOffshoreHours decimal(10,2), @JrProjMgrOffshorePct decimal(10,2), @JrProgMgrOffshorePct decimal(10,2), @JrProjMgrBillingRateOffshore decimal(10,2), @JrProgMgrBillingRateOffshore decimal(10,2), @ITSABillingCatSelection varchar(30), @DateFrom datetime, @DateTo datetime, @ITSABillingCat varchar(30)
set @DateFrom = '2016-07-01'
set @DateTo = '2016-07-31'
select @year = datepart(year, @DateFrom) 
select @month = datepart(month, @DateFrom) 
select @BillableDays = BillableDays from piv_reports..CO_PTD_Calendar where Year = @year and Month = @month
set @OnshoreFTERate = '149'
set @OffshoreFTERate = '143.5'

---------------------------------------------------------------------------------------------------
-- ProgramGroup_cursor, populates record type 10.
DECLARE ProgramGroup_cursor CURSOR FOR 
    select distinct ProgramGroup, Prog_GroupID from dbo.#TEMP_IN where ProgramGroup is not null order by ProgramGroup	
OPEN ProgramGroup_cursor
FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID  
WHILE @@FETCH_STATUS = 0
BEGIN
	insert #TEMP_OUT (RecNumber) values (10) -- A blank line
	insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID)
   	select 10, 'ProgGroup/Total', @CurProgramGroup, @CurProg_GroupID 
    select @MaxProgGroup = max(AutoKey) from #TEMP_OUT

	---------------------------------------------------------------------------------------------------
	-- Program_cursor, populates record type 20.	
	DECLARE Program_cursor CURSOR FOR 
		select distinct Program, ProgramID from dbo.#TEMP_IN where ProgramGroup = @CurProgramGroup and Program is not null order by Program
	OPEN Program_cursor
	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
    WHILE @@FETCH_STATUS = 0
    BEGIN
		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID) 
        select 20, 'Program', @CurProgram, @CurProgramID
        select @MaxProgram = max(AutoKey) from #TEMP_OUT

		---------------------------------------------------------------------------------------------------                
		-- AFEDesc_cursor, populates record type 30.
		DECLARE AFEDesc_cursor CURSOR FOR 
			select distinct AFEDesc, AFE_DescID from dbo.#TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFEDesc is not null
		OPEN AFEDesc_cursor
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID
		WHILE @@FETCH_STATUS = 0
        BEGIN
			insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID)
           	select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID
			select @MaxAFEDesc = max(AutoKey) from #TEMP_OUT

			---------------------------------------------------------------------------------------------------
			-- ProjDesc_cursor, populates record type 40.
    		DECLARE ProjDesc_cursor CURSOR FOR 
    			select distinct ProjectID, ProjectTitle from dbo.#TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID is not null
			OPEN ProjDesc_cursor
			FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
    		WHILE @@FETCH_STATUS = 0
			BEGIN
				insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID)
               	select 40, 'ProjDesc', @CurProjectTitle, @CurProjID
                select @MaxProj = max(AutoKey) from #TEMP_OUT 

				-- Populate the ITSA Billing Category.
				select @ITSABillingCat = ITSABillingCat from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 

				-- Populate hours by new Billing Type for record type 10.      
				select @JrSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Jr SE%' and Onshore = 1
				select @JrSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Jr SE%' and Offshore = 1
				select @MidSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Mid SE%' and Onshore = 1
				select @MidSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Mid SE%' and Offshore = 1
--print 'rec50 hours='
--print @MidSEOffshore
				select @AdvSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Adv SE%' and Onshore = 1
				select @AdvSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Adv SE%' and Offshore = 1
				select @SenSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Sen SE%' and Onshore = 1
				select @SenSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Sen SE%' and Offshore = 1
				select @ConsArchOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Cons%' and Onshore = 1
				select @ConsArchOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Cons%' and Offshore = 1
				select @ProjLeadOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Project Lead%' and Onshore = 1
				select @ProjLeadOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Project Lead%' and Offshore = 1			
				select @ProjMgrOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Project Mgr%' and Onshore = 1
				select @ProjMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Project Mgr%' and Offshore = 1
				select @ProgMgrOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Program Mgr%' and Onshore = 1	
				select @ProgMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Program Mgr%' and Offshore = 1	
				select @JrProjMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Jr Project Mgr%' and Offshore = 1	
				select @JrProgMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Jr Program Mgr%' and Offshore = 1	

				-- Update total information in type 10 records, summarize hours by new Billing Type.      
				update #TEMP_OUT set JrSEOnshoreHours = isnull(@JrSEOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshore,0), MidSEOnshoreHours = isnull(@MidSEOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshore,0), AdvSEOnshoreHours = isnull(@AdvSEOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshore,0), SenSEOnshoreHours = isnull(@SenSEOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshore,0), ConsArchOnshoreHours = isnull(@ConsArchOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshore,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshore,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshore,0),	ProgMgrOnshoreHours = isnull(@ProgMgrOnshore,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshore,0), JrProjMgrOffshoreHours = isnull(@JrProjMgrOffshore,0), JrProgMgrOffshoreHours = isnull(@JrProgMgrOffshore,0) where AutoKey = @MaxProj
				
				-- Populate Total Cost record type 50.
				insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID)
               	select 50, 'TotalCost', 'Total Cost', @ITSABillingCat

				-- Populate billing rate by new Billing Type to be used for calculation for record type 50 (Total Cost).      
				select @JrSEBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Jr SE%' and Onshore = 1
				select @JrSEBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Jr SE%' and Offshore = 1
				select @MidSEBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Mid SE%' and Onshore = 1					
				select @MidSEBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Mid SE%' and Offshore = 1									
--print 'BillingRate='
--print @MidSEBillingRateOffshore				
				select @AdvSEBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Adv SE%' and Onshore = 1
				select @AdvSEBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Adv SE%' and Offshore = 1
				select @SenSEBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Sen SE%' and Onshore = 1
				select @SenSEBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Sen SE%' and Offshore = 1
				select @ConsArchBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Cons%' and Onshore = 1
				select @ConsArchBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Cons%' and Offshore = 1
				select @ProjLeadBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Project Lead%' and Onshore = 1
				select @ProjLeadBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Project Lead%' and Offshore = 1			
				select @ProjMgrBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Project Mgr%' and Onshore = 1
				select @ProjMgrBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Project Mgr%' and Offshore = 1
				select @ProgMgrBillingRateOnshore = BillingRateOnshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Program Mgr%' and Onshore = 1	
				select @ProgMgrBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Program Mgr%' and Offshore = 1	
				select @JrProjMgrBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Jr Project Mgr%' and Offshore = 1	
				select @JrProgMgrBillingRateOffshore = BillingRateOffshore from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and NewBillingType like '%Jr Program Mgr%' and Offshore = 1	

				-- Populate percentage calculate (ex: Hours / FTE Rate)
				set @JrSEOnshorePct = (isnull(@JrSEOnshore,0) / @OnshoreFTERate) 
				set @JrSEOffshorePct = (isnull(@JrSEOffshore,0) / @OffshoreFTERate) 
				set @MidSEOnshorePct = (isnull(@MidSEOnshore,0) / @OnshoreFTERate) 
				set @MidSEOffshorePct = (isnull(@MidSEOffshore,0) / @OffshoreFTERate) 
--print 'Pct='
--print @MidSEOffshorePct				
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
				set @JrProjMgrOffshorePct = (isnull(@JrProjMgrOffshore,0) / @OffshoreFTERate) 
				set @JrProgMgrOffshorePct = (isnull(@JrProgMgrOffshore,0) / @OffshoreFTERate) 

                ---------------------------------------------------------------------------------------------------
       			-- Task_cursor, populates task records for Total Cost type 50 for FTP resources.
				DECLARE Task_cursor CURSOR FOR
					select distinct TaskID from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID
				OPEN Task_cursor
				FETCH NEXT FROM Task_cursor INTO @CurTaskID
				WHILE @@FETCH_STATUS = 0
				BEGIN				
					-- Resource_cursor, populates FTP Resources under Tasks and calculates the Total Cost, record type 50.
					DECLARE Resource_cursor CURSOR FOR 
						Select distinct ResourceNumber From #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and TaskID = @CurTaskID and NewBillingType = 'FTP Staff Aug' and ResourceNumber is not NULL
					OPEN Resource_cursor
					FETCH NEXT FROM Resource_cursor INTO @CurResourceNumber
					WHILE @@FETCH_STATUS = 0
					BEGIN				

					FETCH NEXT FROM Resource_cursor INTO @CurResourceNumber	
					END
					CLOSE Resource_cursor
					DEALLOCATE Resource_cursor					
				FETCH NEXT FROM Task_cursor INTO @CurTaskID
				END    
				CLOSE Task_cursor
				DEALLOCATE Task_cursor

				-- Update Total Cost information in type 50 records, summarize hours by new Billing Type.   
				update #TEMP_OUT set JrSEOnshoreHours = isnull(@JrSEOnshorePct * @JrSEBillingRateOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshorePct * @JrSEBillingRateOffshore,0),	MidSEOnshoreHours = isnull(@MidSEOnshorePct * @MidSEBillingRateOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshorePct * @MidSEBillingRateOffshore,0), AdvSEOnshoreHours = isnull(@AdvSEOnshorePct * @AdvSEBillingRateOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshorePct * @AdvSEBillingRateOffshore,0), SenSEOnshoreHours = isnull(@SenSEOnshorePct * @SenSEBillingRateOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshorePct * @SenSEBillingRateOffshore,0), ConsArchOnshoreHours = isnull(@ConsArchOnshorePct * @ConsArchBillingRateOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshorePct * @ConsArchBillingRateOffshore,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshorePct * @ProjLeadBillingRateOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshorePct * @ProjLeadBillingRateOffshore,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshorePct * @ProjMgrBillingRateOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshorePct * @ProjMgrBillingRateOffshore,0), ProgMgrOnshoreHours = isnull(@ProgMgrOnshorePct * @ProgMgrBillingRateOnshore,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshorePct * @ProgMgrBillingRateOffshore,0), JrProjMgrOffshoreHours = isnull(@JrProjMgrOffshorePct * @JrProjMgrBillingRateOffshore,0), JrProgMgrOffshoreHours = isnull(@JrProgMgrOffshorePct * @JrProgMgrBillingRateOffshore,0) where AutoKey > @MaxProj and RecNumber = 50															
--MidSEOffshoreHours = 3860 * .21 = 810.60	
    		FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
   			END    
    		CLOSE ProjDesc_cursor
    		DEALLOCATE ProjDesc_cursor
    		
            -- GET funding category and location combo  --
            Declare @@out_location varchar (100), @@out_fundingcat varchar (100), @@out_afenumber varchar (20),@@out_programmgr varchar (50), @@Total_FTE float             
        	set @@out_location  = NULL
        	set @@out_fundingcat = NULL
        	set @@out_afenumber = NULL
			set @@out_programmgr = NULL	
        	set @@Total_FTE = NULL
            exec GET_Location_Combo @CurAFE_DescID, @DateFrom, @DateTo, @@out_location OUTPUT, @@out_fundingcat OUTPUT, @@out_afenumber OUTPUT,@@out_programmgr OUTPUT, @@Total_FTE OUTPUT
			update #TEMP_OUT set ITSABillingCat = @ITSABillingCat, COApprovedFTEs = isnull(@@Total_FTE,0) where AutoKey = @MaxAFEDesc

			-- Populate Hours and TotalHours and ActualFTEs Column (rec type 30 horizontal).
			select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @JrProjMgrOffshoreHours = sum(isnull(JrProjMgrOffshoreHours,0)), @JrProgMgrOffshoreHours = sum(isnull(JrProgMgrOffshoreHours,0)) from #TEMP_OUT 
			where AutoKey > @MaxAFEDesc and RecNumber = 40
--print 'Rec30='
--print @MidSEOffshoreHours	--481.00
			select @TotalHours = isnull(@JrSEOnshoreHours,0) + isnull(@JrSEOffshoreHours,0) + isnull(@MidSEOnshoreHours,0) + isnull(@MidSEOffshoreHours,0) + isnull(@AdvSEOnshoreHours,0) + isnull(@AdvSEOffshoreHours,0) + isnull(@SenSEOnshoreHours,0) + isnull(@SenSEOffshoreHours,0) + isnull(@ConsArchOnshoreHours,0) + isnull(@ConsArchOffshoreHours,0) + isnull(@ProjLeadOnshoreHours,0) + isnull(@ProjLeadOffshoreHours,0) + isnull(@ProjMgrOnshoreHours,0) + isnull(@ProjMgrOffshoreHours,0) + isnull(@ProgMgrOnshoreHours,0) + isnull(@ProgMgrOffshoreHours,0) + isnull(@JrProjMgrOffshore,0) + isnull(@JrProgMgrOffshore,0)
			update #TEMP_OUT set TotalHours = isnull(@TotalHours,0), JrSEOnshoreHours = isnull(@JrSEOnshoreHours,0), JrSEOffshoreHours = isnull(@JrSEOffshoreHours,0), MidSEOnshoreHours = isnull(@MidSEOnshoreHours,0), MidSEOffshoreHours = isnull(@MidSEOffshoreHours,0), AdvSEOnshoreHours = isnull(@AdvSEOnshoreHours,0), AdvSEOffshoreHours = isnull(@AdvSEOffshoreHours,0), SenSEOnshoreHours = isnull(@SenSEOnshoreHours,0), SenSEOffshoreHours = isnull(@SenSEOffshoreHours,0), ConsArchOnshoreHours = isnull(@ConsArchOnshoreHours,0), ConsArchOffshoreHours = isnull(@ConsArchOffshoreHours,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshoreHours,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshoreHours,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshoreHours,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshoreHours,0), ProgMgrOnshoreHours = isnull(@ProgMgrOnshoreHours,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshoreHours,0), JrProjMgrOffshoreHours = isnull(@JrProjMgrOffshoreHours,0), JrProgMgrOffshoreHours = isnull(@JrProgMgrOffshoreHours,0) where AutoKey = @MaxAFEDesc
			update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours + @JrProjMgrOffshoreHours + @JrProgMgrOffshoreHours) / @OffshoreFTERate) where AutoKey = @MaxAFEDesc	
			update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey = @MaxAFEDesc

			-- Populate Hours and TotalHours and ActualFTEs Column (rec type 40 horizontal).
			update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) + isnull(ProgMgrOffshoreHours,0) + isnull(JrProjMgrOffshoreHours,0) + isnull(JrProgMgrOffshoreHours,0) where AutoKey > @MaxAFEDesc and RecNumber = 40
			update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours + JrProjMgrOffshoreHours + JrProgMgrOffshoreHours) / @OffshoreFTERate) where AutoKey > @MaxAFEDesc and RecNumber = 40

  			-- Populate TotalHours Column for Record Type 50 (horizontal).		         
            update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) + isnull(ProgMgrOffshoreHours,0) + isnull(JrProjMgrOffshoreHours,0) + isnull(JrProgMgrOffshoreHours,0) where AutoKey > @MaxAFEDesc and RecNumber = 50
			
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID
		END    
		CLOSE AFEDesc_cursor
		DEALLOCATE AFEDesc_cursor

	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
	END
	CLOSE Program_cursor
	DEALLOCATE Program_cursor

	-- Update total information for record type 10.
	select @JrSEOnshore = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshore = sum(isnull(JrSeOffshoreHours,0)), @MidSEOnshore = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshore = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshore = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshore = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshore = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshore= sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshore = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshore= sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshore = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshore= sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshore = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshore= sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshore = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshore = sum(isnull(ProgMgrOffshoreHours,0)), @JrProjMgrOffshoreHours = sum(isnull(JrProjMgrOffshoreHours,0)), @JrProgMgrOffshoreHours = sum(isnull(JrProgMgrOffshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0)) from #TEMP_OUT 
	where AutoKey > @MaxProgGroup and RecNumber = 30
--print 'Rec10=' 
--print @MidSEOffshore	--481.00
	select @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)) from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30
	Update #TEMP_OUT set JrSEOnshoreHours = @JrSEOnshore, JrSeOffshoreHours = @JrSEOffshore, MidSEOnshoreHours = @MidSEOnshore, MidSEOffshoreHours = @MidSEOffshore, AdvSEOnshoreHours = @AdvSEOnshore, AdvSEOffshoreHours = @AdvSEOffshore, SenSEOnshoreHours = @SenSEOnshore, SenSEOffshoreHours = @SenSEOffshore, ConsArchOnshoreHours = @ConsArchOnshore, ConsArchOffshoreHours = @ConsArchOffshore, ProjLeadOnshoreHours = @ProjLeadOnshore, ProjLeadOffshoreHours = @ProjLeadOffshore, ProjMgrOnshoreHours = @ProjMgrOnshore, ProjMgrOffshoreHours = @ProjMgrOffshore, ProgMgrOnshoreHours = @ProgMgrOnshore, ProgMgrOffshoreHours = @ProgMgrOffshore, JrProjMgrOffshoreHours = @JrProjMgrOffshoreHours, JrProgMgrOffshoreHours = @JrProgMgrOffshoreHours, TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs where AutoKey = @MaxProgGroup
	update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours + JrProjMgrOffshoreHours + JrProgMgrOffshoreHours) / @OffshoreFTERate)  where AutoKey = @MaxProgGroup						
	update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey = @MaxProgGroup

FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID
END
CLOSE ProgramGroup_cursor
DEALLOCATE ProgramGroup_cursor

----------------------------------------------------------------------------------------------------------------------
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 3, 'TotalPSS', 'Total PSS CO Investment'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 3, 'TotalPSSConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 3, 'TotalCostPSS', 'Total Cost'

-- Calculate and Populate the 3 records (Total PSS CO Investment)
	select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @JrProjMgrOffshoreHours = sum(isnull(JrProjMgrOffshoreHours,0)), @JrProgMgrOffshoreHours = sum(isnull(JrProgMgrOffshoreHours,0))
	from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'PSS CO Investment'
print 'TotalHours-PSS='
print @AdvSEOffshoreHours	--8.00
	update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, JrProjMgrOffshoreHours = @JrProjMgrOffshoreHours, JrProgMgrOffshoreHours = @JrProgMgrOffshoreHours 
		where RecNumber = 3 and RecType = 'TotalPSS'
	update #TEMP_OUT set TotalHours = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours + @JrProjMgrOffshoreHours + @JrProgMgrOffshoreHours) / @OffshoreFTERate), JrSEOnshoreHours = @JrSEOnshoreHours/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffshoreHours/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnshoreHours/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffshoreHours/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnshoreHours/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffshoreHours/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnshoreHours/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffshoreHours/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchOnshoreHours/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchOffshoreHours/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadOnshoreHours/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrOnshoreHours/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrOnshoreHours/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/@OffshoreFTERate, JrProjMgrOffshoreHours = @JrProjMgrOffshoreHours/@OffshoreFTERate, JrProgMgrOffshoreHours = @JrProgMgrOffshoreHours/@OffshoreFTERate 
		where RecNumber = 3 and RecType = 'TotalPSSConversion'		
	update #TEMP_OUT set ActualFTEs = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours + @JrProjMgrOffshoreHours + @JrProgMgrOffshoreHours) / @OffshoreFTERate) 
		where RecNumber = 3 and RecType in ('TotalPSS', 'TotalPSSConversion', 'TotalCostPSS')	

	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @JrProjMgrOffshoreHours = sum(isnull(JrProjMgrOffshoreHours,0)), @JrProgMgrOffshoreHours = sum(isnull(JrProgMgrOffshoreHours,0)) from #TEMP_OUT
		where RecNumber = 50 and RecTypeID = 'PSS CO Investment'
print 'TotalCost-PSS-AdvSEOffshore='
print @AdvSEOffshoreHours	
	
	select @TotalHours = @JrSEOnshoreHours + @JrSEOffshoreHours + @MidSEOnshoreHours + @MidSEOffshoreHours + @AdvSEOnshoreHours + @AdvSEOffshoreHours + @SenSEOnshoreHours + @SenSEOffshoreHours + @ConsArchOnshoreHours + @ConsArchOffshoreHours + @ProjLeadOnshoreHours + @ProjLeadOffshoreHours + @ProjMgrOnshoreHours + @ProjMgrOffshoreHours + @ProgMgrOnshoreHours + @ProgMgrOffshoreHours + @JrProjMgrOffshoreHours + @JrProgMgrOffshoreHours from #TEMP_OUT 
		where RecNumber = 3 and RecType = 'TotalCostPSS'
print 'TotalCost='
print @TotalHours	
	update #TEMP_OUT set TotalHours = @TotalHours, JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours,	SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours,  ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, JrProjMgrOffshoreHours = @JrProjMgrOffshoreHours, JrProgMgrOffshoreHours = @JrProgMgrOffshoreHours
		where RecNumber = 3 and RecType = 'TotalCostPSS'

	update #TEMP_OUT set COApprovedFTEs = @COApprovedFTEs where RecNumber = 3 and RecType in ('TotalCostPSS', 'TotalPSSConversion', 'TotalCostPSS')	
	update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 3 and RecType in ('TotalCostPSS', 'TotalPSSConversion', 'TotalCostPSS')

----------------------------------------------------------------------------------------------------------------------
-- Remove any rows that have ZERO values in the TotalHours and the COApprovedFTEs
delete #TEMP_OUT where RecNumber in (10,20,30,40,50) and (TotalHours = 0 or TotalHours is NULL) and COApprovedFTEs = 0

----------------------------------------------------------------------------------------------------------------------

select * from #TEMP_OUT order by AutoKey
	