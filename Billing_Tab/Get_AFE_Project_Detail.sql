--PROCEDURE [dbo].[Get_AFE_Project_Detail] 
drop view [dbo].[SP_Get_AFE_Project_Detail]
drop view [dbo].[SP_Get_AFE_Project_Detail2]
drop table #TEMP_IN
drop table #TEMP_OUT

-- Declare common variables.
DECLARE @SQL_statement varchar(1000), @ITSABillingCatSelection varchar(30), @ITSABillingCat varchar(30), @DateFrom datetime,  @DateTo datetime, @ProgGroupID varchar(100), @FundCatID int, @FundCatIDList varchar(100), @StatusID int, @AFEID int, @SolutionCentreList varchar(500), @CurrentMonth varchar(6), @BillingShoreWhere varchar(20), @OutputTable varchar(30)
set @DateFrom = '2015-01-01'
set @DateTo = '2015-01-31'
set @ITSABillingCat = 'ADM'
set @ProgGroupID = '-1'
set @FundCatID = '-1'
set @FundCatIDList = '-1'
set @StatusID = '-1'
set @AFEID = '-1'
set @SolutionCentreList = '-1'
set @CurrentMonth = '201501'
set @BillingShoreWhere = ''

-- Create the first temp VIEW.
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Project_Detail AS select AFE_Summary_View.*, CO_Resource.Onshore, CO_Resource.Offshore, CO_Resource.Hourly, CO_BillingCode.Billing_CodeID, CO_BillingCode.Description AS NewBillingType from AFE_Summary_View inner join CO_Resource ON AFE_Summary_View.EDSNETID = CO_Resource.ResourceNumber inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID
	where WorkDate >= ''2015-01-01'' and WorkDate <= ''2015-01-31'' '
exec (@SQL_statement)

--select AFE_Summary_View.*, CO_Resource.Onshore, CO_Resource.Offshore, CO_Resource.Hourly, CO_BillingCode.Billing_CodeID, CO_BillingCode.Description AS NewBillingType from AFE_Summary_View inner join CO_Resource ON AFE_Summary_View.EDSNETID = CO_Resource.ResourceNumber inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID where WorkDate >= '2015-01-01' and WorkDate <= '2015-01-31' and AFEDesc like '%Journey%'
	
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

--DECLARE @SQL_statement varchar(1000)
-- Create the second temp VIEW.
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Project_Detail2 AS select dbo.lkITSABillingCategory.Description AS ITSABillingCat, FTE_Approved_Time.* 
from FTE_Approved_Time LEFT OUTER JOIN dbo.tblAFEDetail ON FTE_Approved_Time.AFE_DescID = dbo.tblAFEDetail.AFE_DescID LEFT OUTER JOIN dbo.lkITSABillingCategory ON dbo.tblAFEDetail.ITSABillingCategoryID = dbolkITSABillingCategory.ITSABillingCategoryID 
where Appr_FTE_Hours > 0 and CurrentMonth =''201501'' '
exec (@SQL_statement)

-- Copy the data from the second temp VIEW into #TEMP_IN.
insert dbo.#TEMP_IN ( AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, ITSABillingCat, UA_VicePresident)
select AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, ITSABillingCat, UA_VicePresident 
from dbo.SP_Get_AFE_Project_Detail2

-- Create Index
Create Index IDX1 on dbo.#TEMP_IN (Prog_GroupID, ProgramID, AFE_DescID, ProjectID, NewBillingType)

-- Adjust the Hours according to the ClientFundingPct by CO
update dbo.#TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0

---------------------------------------------------------------------------------------------------
--drop table #TEMP_OUT
-- Create the output table #TEMP_OUT.
CREATE TABLE [dbo].[#TEMP_OUT] ( 
	[AutoKey][int] IDENTITY (0, 1) NOT NULL, [RecNumber][int] NULL, [RecType] [varchar] (100) NULL, [RecDesc] [varchar] (100) NULL,   [RecTypeID] [varchar] (100) NULL, [ITSABillingCat] [varchar] (30) NULL,[FundingCat] [varchar] (30) NULL,[AFENumber] [varchar] (20) NULL,[UAVP] [varchar] (50) NULL, [COBusinessLead] [varchar] (100) NULL,[ProgramMgr] [varchar] (50) NULL,[Location] [varchar] (30) NULL,[TotalHours] [decimal](10,2) NULL,[ActualFTEs] [decimal](10,2) NULL,[COApprovedFTEs] [decimal](10,2) NULL,[EDSVariance] [decimal](10,2) NULL,[JrSEOnshoreHours] [decimal](10,2) NULL,[JrSeOffshoreHours] [decimal](10,2) NULL,[MidSEOnshoreHours] [decimal](10,2) NULL,[MidSEOffshoreHours] [decimal](10,2) NULL,[AdvSEOnshoreHours] [decimal](10,2) NULL,[AdvSEOffshoreHours] [decimal](10,2) NULL,[SenSEOnshoreHours] [decimal](10,2) NULL,[SenSEOffshoreHours] [decimal](10,2) NULL,[ConsArchOnshoreHours] [decimal](10,2) NULL,[ConsArchOffshoreHours] [decimal](10,2) NULL,[ProjLeadOnshoreHours] [decimal](10,2) NULL,[ProjLeadOffshoreHours] [decimal](10,2) NULL,[ProjMgrOnshoreHours] [decimal](10,2) NULL,[ProjMgrOffshoreHours] [decimal](10,2) NULL,[ProgMgrOnshoreHours] [decimal](10,2) NULL,[ProgMgrOffshoreHours] [decimal](10,2) NULL,
	[JrProjMgrOffshoreHours] [decimal](10,2) NULL, [JrProgMgrOffshoreHours] [decimal](10,2) NULL,
	[SrProjMgrOffshoreHours] [decimal](10,2) NULL, [SrProgMgrOffshoreHours] [decimal](10,2) NULL		
) ON [PRIMARY]

ALTER TABLE #TEMP_OUT ADD FTPStaffAugOnshoreHours decimal(10,2) NULL
ALTER TABLE #TEMP_OUT ADD FTPStaffAugOffshoreHours decimal(10,2) NULL
ALTER TABLE #TEMP_OUT ADD R10_ProgramGroup varchar(100) NULL
ALTER TABLE #TEMP_OUT ADD R20_Program varchar(100) NULL
ALTER TABLE #TEMP_OUT ADD R30_AFEDesc varchar(100) NULL
ALTER TABLE #TEMP_OUT ADD R40_Project varchar(100) NULL

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Declare variables.
DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID varchar(100), @CurProgram varchar(100), @CurProgramID  varchar(100), @CurCoBusinessLead varchar (100), @CurAFEDesc varchar (100), @CurAFE_DescID varchar (100), @CurProjectTitle varchar(100), @CurProjID varchar (100), @CurTaskName varchar(100), @CurTaskID varchar (100), @CurResourceName varchar(100), @CurEventList varchar(100), @CurEventName varchar(100), @MaxProgGroup bigint, @MaxProgram bigint, @MaxAFEDesc bigint, @MaxProj bigint, @MaxTask bigint, @MaxEvent bigint, @UPVP varchar(50)
DECLARE @JrSEOnshore decimal(10,2), @JrSEOffshore decimal(10,2), @MidSEOnshore decimal(10,2), @MidSEOffshore decimal(10,2), @AdvSEOnshore decimal(10,2), @AdvSEOffshore decimal(10,2), @SenSEOnshore decimal(10,2), @SenSEOffshore decimal(10,2), @ConsArchOnshore decimal(10,2), @ConsArchOffshore decimal(10,2), @ProjLeadOnshore decimal(10,2), @ProjLeadOffshore decimal(10,2), @ProjMgrOnshore decimal(10,2), @ProjMgrOffshore decimal(10,2), @ProgMgrOnshore decimal(10,2), @ProgMgrOffshore decimal(10,2), @JrProjMgrOffshore decimal(10,2), @JrProgMgrOffshore decimal(10,2), @SrProjMgrOffshore decimal(10,2), @SrProgMgrOffshore decimal(10,2)
DECLARE @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2), @ProgMgrOffshoreHours decimal(10,2), @JrProjMgrOffshoreHours decimal(10,2), @JrProgMgrOffshoreHours decimal(10,2), @SrProjMgrOffshoreHours decimal(10,2), @SrProgMgrOffshoreHours decimal(10,2)
Declare @TotalHours decimal(10,2), @COApprovedFTEs decimal(10,2), @FTPStaffAugOnshore decimal(10,2), @FTPStaffAugOffshore decimal(10,2), @FTPStaffAugOnshoreHours decimal(10,2), @FTPStaffAugOffshoreHours decimal(10,2), @FTPBillingRate decimal(10,2), @year int, @month int, @BillableDays int, @OnshoreFTERate decimal(10,2), @OffshoreFTERate decimal(10,2), @ITSABillingCatSelection varchar(30), @ITSABillingCat varchar(30)

set @ITSABillingCatSelection = '-1'
Declare @DateFrom datetime,  @DateTo datetime 
set @DateFrom = '2015-01-01'
set @DateTo = '2015-01-31'

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

-- Populate summary rows.
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Total United (UA)'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 3, 'Conversion', 'FTE Conversion'

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
		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup) 
        select 20, 'Program', @CurProgram, @CurProgramID, @CurProgramGroup 
        select @MaxProgram = max(AutoKey) from #TEMP_OUT

		---------------------------------------------------------------------------------------------------                
		-- AFEDesc_cursor, populates record type 30.
		DECLARE AFEDesc_cursor CURSOR FOR 
			select distinct AFEDesc, AFE_DescID, COBusinessLead from dbo.#TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFEDesc is not null
		OPEN AFEDesc_cursor
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
		WHILE @@FETCH_STATUS = 0
        BEGIN
  --print 'AFE='
  --print @CurAFEDesc
  --print 'AFEID='
  --print @CurAFE_DescID
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

				-- Populate the ITSA Billing Category.
				--select @ITSABillingCat = ITSABillingCat from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 

				-- Populate hours by new Billing Type for record type 10.      
				select @JrSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Jr SE%' and Onshore = 1
				select @JrSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Jr SE%' and Offshore = 1
				select @MidSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Mid SE%' and Onshore = 1
				select @MidSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Mid SE%' and Offshore = 1
				select @AdvSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Adv SE%' and Onshore = 1
				select @AdvSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Adv SE%' and Offshore = 1
				select @SenSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Sen SE%' and Onshore = 1
				select @SenSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Sen SE%' and Offshore = 1
				select @ConsArchOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Cons%' and Onshore = 1
				select @ConsArchOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Cons%' and Offshore = 1
				select @ProjLeadOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Project Lead%' and Onshore = 1
				select @ProjLeadOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Project Lead%' and Offshore = 1			

				select @ProjMgrOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType in ('Project Mgr','Common Project Mgr','Premium Project Mgr','Niche Project Mgr','Off SHR Project Mgr','Legacy Project Mgr','Program Project Mgr') and Onshore = 1
				select @ProjMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType in ('Project Mgr','Common Project Mgr','Premium Project Mgr','Niche Project Mgr','Off SHR Project Mgr','Legacy Project Mgr','Program Project Mgr') and Offshore = 1

				select @ProjMgrOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Project Mgr%' and Onshore = 1
				select @ProjMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Project Mgr%' and Offshore = 1
				select @ProgMgrOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Program Mgr%' and Onshore = 1	
				select @ProgMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType like '%Program Mgr%' and Offshore = 1	
				
				select @JrProjMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Common Jr Project Mgr' and Offshore = 1	
				select @JrProgMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Common Jr Program Mgr' and Offshore = 1	

				select @SrProjMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Common Sr Project Mgr' and Offshore = 1	
				select @SrProgMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'Common Sr Program Mgr' and Offshore = 1	

				if ( @ITSABillingCatSelection = '-1' )
				begin
				  select @FTPStaffAugOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'FTP Staff Aug' and Onshore = 1
				  select @FTPStaffAugOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and
					NewBillingType = 'FTP Staff Aug' and Offshore = 1
				end

				-- Update total information in type 10 records, summarize hours by new Billing Type.  					    
				if ( @ITSABillingCatSelection = '-1' )
				begin
					update #TEMP_OUT set JrSEOnshoreHours = isnull(@JrSEOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshore,0), MidSEOnshoreHours = isnull(@MidSEOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshore,0), AdvSEOnshoreHours = isnull(@AdvSEOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshore,0),	SenSEOnshoreHours = isnull(@SenSEOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshore,0), ConsArchOnshoreHours = isnull(@ConsArchOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshore,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshore,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshore,0),	ProgMgrOnshoreHours = isnull(@ProgMgrOnshore,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshore,0), JrProjMgrOffshoreHours = isnull(@JrProjMgrOffshore,0), JrProgMgrOffshoreHours = isnull(@JrProgMgrOffshore,0),
						SrProjMgrOffshoreHours = isnull(@SrProjMgrOffshore,0), SrProgMgrOffshoreHours = isnull(@SrProgMgrOffshore,0),
						FTPStaffAugOnshoreHours = isnull(@FTPStaffAugOnshore,0), FTPStaffAugOffshoreHours = isnull(@FTPStaffAugOffshore,0)
					where AutoKey = @MaxProj
				end
				else
				begin
					update #TEMP_OUT set JrSEOnshoreHours = isnull(@JrSEOnshore,0), JrSEOffshoreHours = isnull(@JrSEOffshore,0), MidSEOnshoreHours = isnull(@MidSEOnshore,0), MidSEOffshoreHours = isnull(@MidSEOffshore,0), AdvSEOnshoreHours = isnull(@AdvSEOnshore,0), AdvSEOffshoreHours = isnull(@AdvSEOffshore,0), SenSEOnshoreHours = isnull(@SenSEOnshore,0), SenSEOffshoreHours = isnull(@SenSEOffshore,0), ConsArchOnshoreHours = isnull(@ConsArchOnshore,0), ConsArchOffshoreHours = isnull(@ConsArchOffshore,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshore,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshore,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshore,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshore,0), ProgMgrOnshoreHours = isnull(@ProgMgrOnshore,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshore,0), JrProjMgrOffshoreHours = isnull(@JrProjMgrOffshore,0), JrProgMgrOffshoreHours = isnull(@JrProgMgrOffshore,0),
						SrProjMgrOffshoreHours = isnull(@SrProjMgrOffshore,0), SrProgMgrOffshoreHours = isnull(@SrProgMgrOffshore,0)				
					where AutoKey = @MaxProj
				end

    		FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
   			END    
    		CLOSE ProjDesc_cursor
    		DEALLOCATE ProjDesc_cursor

			---------------------------------------------------------------------------------------------------
			-- Populate the ITSA Billing Category.
			select @ITSABillingCat = ITSABillingCat from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
                
            -- GET funding category and location combo  --
            Declare @@out_location varchar (100), @@out_fundingcat varchar (100), @@out_afenumber varchar (20),@@out_programmgr varchar (50), @@Total_FTE float             
        	set @@out_location  = NULL
        	set @@out_fundingcat = NULL
        	set @@out_afenumber = NULL
			set @@out_programmgr = NULL	
        	set @@Total_FTE = NULL
            exec GET_Location_Combo @CurAFE_DescID, @DateFrom, @DateTo, @@out_location OUTPUT, @@out_fundingcat OUTPUT, @@out_afenumber OUTPUT,@@out_programmgr OUTPUT, @@Total_FTE OUTPUT
print 'ITSA='
print @ITSABillingCat 
			--Update temporary output table #TEMP_OUT.    
			update #TEMP_OUT set ITSABillingCat = @ITSABillingCat, ProgramMgr = @@out_programmgr, location = @@out_location, fundingcat = @@out_fundingcat, AFENumber = @@out_afenumber, COApprovedFTEs = isnull(@@Total_FTE,0)
			where AutoKey = @MaxAFEDesc

			-- Populate Hours and TotalHours and ActualFTEs Column (rec type 30 horizontal).			
			if ( @ITSABillingCatSelection = '-1' )
			begin
				select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @JrProjMgrOffshore = sum(isnull(JrProjMgrOffshoreHours,0)), @JrProgMgrOffshore = sum(isnull(JrProgMgrOffshoreHours,0)),
					@SrProjMgrOffshore = sum(isnull(SrProjMgrOffshoreHours,0)), @SrProgMgrOffshore = sum(isnull(SrProgMgrOffshoreHours,0)),					 		
					@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)) 
					from #TEMP_OUT where AutoKey > @MaxAFEDesc and RecNumber = 40
				select @TotalHours = isnull(@JrSEOnshoreHours,0) + isnull(@JrSEOffshoreHours,0) + isnull(@MidSEOnshoreHours,0) + isnull(@MidSEOffshoreHours,0) + isnull(@AdvSEOnshoreHours,0) + isnull(@AdvSEOffshoreHours,0) + isnull(@SenSEOnshoreHours,0) + isnull(@SenSEOffshoreHours,0) + isnull(@ConsArchOnshoreHours,0) + isnull(@ConsArchOffshoreHours,0) + isnull(@ProjLeadOnshoreHours,0) + isnull(@ProjLeadOffshoreHours,0) + isnull(@ProjMgrOnshoreHours,0) + isnull(@ProjMgrOffshoreHours,0) + isnull(@ProgMgrOnshoreHours,0) + isnull(@ProgMgrOffshoreHours,0) + isnull(@JrProjMgrOffshore,0) + isnull(@JrProgMgrOffshore,0) +
					isnull(@SrProjMgrOffshore,0) + isnull(@SrProgMgrOffshore,0) + isnull(@FTPStaffAugOnshoreHours,0) + isnull(@FTPStaffAugOffshoreHours,0)
				update #TEMP_OUT set TotalHours = isnull(@TotalHours,0), JrSEOnshoreHours = isnull(@JrSEOnshoreHours,0), JrSEOffshoreHours = isnull(@JrSEOffshoreHours,0), MidSEOnshoreHours = isnull(@MidSEOnshoreHours,0), MidSEOffshoreHours = isnull(@MidSEOffshoreHours,0), AdvSEOnshoreHours = isnull(@AdvSEOnshoreHours,0), AdvSEOffshoreHours = isnull(@AdvSEOffshoreHours,0), SenSEOnshoreHours = isnull(@SenSEOnshoreHours,0), SenSEOffshoreHours = isnull(@SenSEOffshoreHours,0), ConsArchOnshoreHours = isnull(@ConsArchOnshoreHours,0), ConsArchOffshoreHours = isnull(@ConsArchOffshoreHours,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshoreHours,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshoreHours,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshoreHours,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshoreHours,0), ProgMgrOnshoreHours = isnull(@ProgMgrOnshoreHours,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshoreHours,0), JrProjMgrOffshoreHours = isnull(@JrProjMgrOffshore,0), JrProgMgrOffshoreHours = isnull(@JrProgMgrOffshore,0),
					SrProjMgrOffshoreHours = isnull(@SrProjMgrOffshore,0), SrProgMgrOffshoreHours = isnull(@SrProgMgrOffshore,0),					
					FTPStaffAugOnshoreHours = isnull(@FTPStaffAugOnshoreHours,0), FTPStaffAugOffshoreHours = isnull(@FTPStaffAugOffshoreHours,0) 
					where AutoKey = @MaxAFEDesc
				update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) 
					+ ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours + JrProjMgrOffshoreHours + JrProgMgrOffshoreHours +
						SrProjMgrOffshoreHours + SrProgMgrOffshoreHours) / @OffshoreFTERate) 
					+ ( (FTPStaffAugOnshoreHours + FTPStaffAugOffshoreHours) / @FTPBillingRate ) 
					where AutoKey = @MaxAFEDesc	
			end
			else
			begin
				select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)),@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @JrProjMgrOffshore = sum(isnull(JrProjMgrOffshoreHours,0)), @JrProgMgrOffshore = sum(isnull(JrProgMgrOffshoreHours,0)),
					@SrProjMgrOffshore = sum(isnull(SrProjMgrOffshoreHours,0)), @SrProgMgrOffshore = sum(isnull(SrProgMgrOffshoreHours,0)) from #TEMP_OUT 
					where AutoKey > @MaxAFEDesc and RecNumber = 40
				select @TotalHours = isnull(@JrSEOnshoreHours,0) + isnull(@JrSEOffshoreHours,0) + isnull(@MidSEOnshoreHours,0) + isnull(@MidSEOffshoreHours,0) + isnull(@AdvSEOnshoreHours,0) + isnull(@AdvSEOffshoreHours,0) + isnull(@SenSEOnshoreHours,0) + isnull(@SenSEOffshoreHours,0) + isnull(@ConsArchOnshoreHours,0) + isnull(@ConsArchOffshoreHours,0) + isnull(@ProjLeadOnshoreHours,0) + isnull(@ProjLeadOffshoreHours,0) + isnull(@ProjMgrOnshoreHours,0) + isnull(@ProjMgrOffshoreHours,0) + isnull(@ProgMgrOnshoreHours,0) + isnull(@ProgMgrOffshoreHours,0) + isnull(@JrProjMgrOffshore,0) + isnull(@JrProgMgrOffshore,0) +
					isnull(@SrProjMgrOffshore,0) + isnull(@SrProgMgrOffshore,0) 					
				update #TEMP_OUT set TotalHours = isnull(@TotalHours,0), JrSEOnshoreHours = isnull(@JrSEOnshoreHours,0), JrSEOffshoreHours = isnull(@JrSEOffshoreHours,0), MidSEOnshoreHours = isnull(@MidSEOnshoreHours,0), MidSEOffshoreHours = isnull(@MidSEOffshoreHours,0), AdvSEOnshoreHours = isnull(@AdvSEOnshoreHours,0), AdvSEOffshoreHours = isnull(@AdvSEOffshoreHours,0), SenSEOnshoreHours = isnull(@SenSEOnshoreHours,0), SenSEOffshoreHours = isnull(@SenSEOffshoreHours,0), ConsArchOnshoreHours = isnull(@ConsArchOnshoreHours,0), ConsArchOffshoreHours = isnull(@ConsArchOffshoreHours,0), ProjLeadOnshoreHours = isnull(@ProjLeadOnshoreHours,0), ProjLeadOffshoreHours = isnull(@ProjLeadOffshoreHours,0), ProjMgrOnshoreHours = isnull(@ProjMgrOnshoreHours,0), ProjMgrOffshoreHours = isnull(@ProjMgrOffshoreHours,0), ProgMgrOnshoreHours = isnull(@ProgMgrOnshoreHours,0), ProgMgrOffshoreHours = isnull(@ProgMgrOffshoreHours,0), JrProjMgrOffshoreHours = isnull(@JrProjMgrOffshore,0), JrProgMgrOffshoreHours = isnull(@JrProgMgrOffshore,0),
					SrProjMgrOffshoreHours = isnull(@SrProjMgrOffshore,0), SrProgMgrOffshoreHours = isnull(@SrProgMgrOffshore,0)
					where AutoKey = @MaxAFEDesc
				update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) 
					+ ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours + JrProjMgrOffshoreHours + JrProgMgrOffshoreHours +
						SrProjMgrOffshoreHours + SrProgMgrOffshoreHours) / @OffshoreFTERate) 
					where AutoKey = @MaxAFEDesc	
			end

			-- Populate EDSVariance Column (rec type 30 horizontal).
			update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey = @MaxAFEDesc

			-- Populate Hours and TotalHours and ActualFTEs Column (rec type 40 horizontal).
			if ( @ITSABillingCatSelection = '-1' )
			begin
				update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) + isnull(ProgMgrOffshoreHours,0) + isnull(JrProjMgrOffshoreHours,0) + isnull(JrProgMgrOffshoreHours,0) 
					+ isnull(SrProjMgrOffshoreHours,0) + isnull(SrProgMgrOffshoreHours,0) + isnull(FTPStaffAugOnshoreHours,0) + isnull(FTPStaffAugOffshoreHours,0)
					where AutoKey > @MaxAFEDesc and RecNumber = 40
				update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) 
					+ ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours + JrProjMgrOffshoreHours + JrProgMgrOffshoreHours
						+ SrProjMgrOffshoreHours + SrProgMgrOffshoreHours) / @OffshoreFTERate) 
					+ ( (FTPStaffAugOnshoreHours + FTPStaffAugOffshoreHours) / @FTPBillingRate )
					where AutoKey > @MaxAFEDesc and RecNumber = 40
			end
			else
			begin
				update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) + isnull(ProgMgrOffshoreHours,0) + isnull(JrProjMgrOffshoreHours,0) + isnull(JrProgMgrOffshoreHours,0)
					+ isnull(SrProjMgrOffshoreHours,0) + isnull(SrProgMgrOffshoreHours,0)
					where AutoKey > @MaxAFEDesc and RecNumber = 40			
				update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) 
					+ ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours + JrProjMgrOffshoreHours + JrProgMgrOffshoreHours
						+ SrProjMgrOffshoreHours + SrProgMgrOffshoreHours) / @OffshoreFTERate) 
					where AutoKey > @MaxAFEDesc and RecNumber = 40
			end
            			
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
	if ( @ITSABillingCatSelection = '-1' )
	begin
		select @JrSEOnshore = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshore = sum(isnull(JrSeOffshoreHours,0)), @MidSEOnshore = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshore = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshore = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshore = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshore = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshore= sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshore = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshore= sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshore = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshore= sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshore = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshore= sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshore = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshore = sum(isnull(ProgMgrOffshoreHours,0)), @JrProjMgrOffshore = sum(isnull(JrProjMgrOffshoreHours,0)), @JrProgMgrOffshore = sum(isnull(JrProgMgrOffshoreHours,0)), 
			@SrProjMgrOffshore = sum(isnull(SrProjMgrOffshoreHours,0)), @SrProgMgrOffshore = sum(isnull(SrProgMgrOffshoreHours,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0)) from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30
		select @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)) from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30
		update #TEMP_OUT set JrSEOnshoreHours = @JrSEOnshore, JrSeOffshoreHours = @JrSEOffshore, MidSEOnshoreHours = @MidSEOnshore, MidSEOffshoreHours = @MidSEOffshore, AdvSEOnshoreHours = @AdvSEOnshore, AdvSEOffshoreHours = @AdvSEOffshore, SenSEOnshoreHours = @SenSEOnshore, SenSEOffshoreHours = @SenSEOffshore, ConsArchOnshoreHours = @ConsArchOnshore, ConsArchOffshoreHours = @ConsArchOffshore, ProjLeadOnshoreHours = @ProjLeadOnshore, ProjLeadOffshoreHours = @ProjLeadOffshore, ProjMgrOnshoreHours = @ProjMgrOnshore, ProjMgrOffshoreHours = @ProjMgrOffshore, ProgMgrOnshoreHours = @ProgMgrOnshore, ProgMgrOffshoreHours = @ProgMgrOffshore, JrProjMgrOffshoreHours = @JrProjMgrOffshore, JrProgMgrOffshoreHours = @JrProgMgrOffshore, 
			SrProjMgrOffshoreHours = @SrProjMgrOffshore, SrProgMgrOffshoreHours = @SrProgMgrOffshore, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours, TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs where AutoKey = @MaxProgGroup
		update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) 
			+ ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours + JrProjMgrOffshoreHours + JrProgMgrOffshoreHours
				+ SrProjMgrOffshoreHours + SrProgMgrOffshoreHours) / @OffshoreFTERate)
			+ ( (FTPStaffAugOnshoreHours + FTPStaffAugOffshoreHours) / @FTPBillingRate ) 
			where AutoKey = @MaxProgGroup						
	end
	else
	begin
		select @JrSEOnshore = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshore = sum(isnull(JrSeOffshoreHours,0)), @MidSEOnshore = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshore = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshore = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshore = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshore = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshore= sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshore = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshore= sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshore = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshore= sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshore = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshore= sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshore = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshore = sum(isnull(ProgMgrOffshoreHours,0)), @JrProjMgrOffshore = sum(isnull(JrProjMgrOffshoreHours,0)), @JrProgMgrOffshore = sum(isnull(JrProgMgrOffshoreHours,0)),
			@SrProjMgrOffshore = sum(isnull(SrProjMgrOffshoreHours,0)), @SrProgMgrOffshore = sum(isnull(SrProgMgrOffshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0)) from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30
		select @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)) from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30
		update #TEMP_OUT set JrSEOnshoreHours = @JrSEOnshore, JrSeOffshoreHours = @JrSEOffshore, MidSEOnshoreHours = @MidSEOnshore, MidSEOffshoreHours = @MidSEOffshore, AdvSEOnshoreHours = @AdvSEOnshore, AdvSEOffshoreHours = @AdvSEOffshore, SenSEOnshoreHours = @SenSEOnshore, SenSEOffshoreHours = @SenSEOffshore, ConsArchOnshoreHours = @ConsArchOnshore, ConsArchOffshoreHours = @ConsArchOffshore, ProjLeadOnshoreHours = @ProjLeadOnshore, ProjLeadOffshoreHours = @ProjLeadOffshore, ProjMgrOnshoreHours = @ProjMgrOnshore, ProjMgrOffshoreHours = @ProjMgrOffshore, ProgMgrOnshoreHours = @ProgMgrOnshore, ProgMgrOffshoreHours = @ProgMgrOffshore, JrProjMgrOffshoreHours = @JrProjMgrOffshore, JrProgMgrOffshoreHours = @JrProgMgrOffshore, 
			SrProjMgrOffshoreHours = @SrProjMgrOffshore, SrProgMgrOffshoreHours = @SrProgMgrOffshore, TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs where AutoKey = @MaxProgGroup
		update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) 
			+ ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours + JrProjMgrOffshoreHours + JrProgMgrOffshoreHours
			+ SrProjMgrOffshoreHours + SrProgMgrOffshoreHours) / @OffshoreFTERate)
			where AutoKey = @MaxProgGroup						
	end
	
	-- Populate ActualFTEs column
	update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey = @MaxProgGroup

FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID, @UPVP
END
CLOSE ProgramGroup_cursor
DEALLOCATE ProgramGroup_cursor

---------------------------------------------------------------------------------------------------
-- Get totals from 10 records for calcuation of summary totals the 0 and 3 records.
if ( @ITSABillingCatSelection = '-1' )
begin
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @JrProjMgrOffshore = sum(isnull(JrProjMgrOffshoreHours,0)), @JrProgMgrOffshore = sum(isnull(JrProgMgrOffshoreHours,0)),
	@SrProjMgrOffshore = sum(isnull(SrProjMgrOffshoreHours,0)), @SrProgMgrOffshore = sum(isnull(SrProgMgrOffshoreHours,0)),	@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0)), @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0))
	from #TEMP_OUT where RecNumber = 10
end
else
begin
	select @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)), @JrProjMgrOffshore = sum(isnull(JrProjMgrOffshoreHours,0)), @JrProgMgrOffshore = sum(isnull(JrProgMgrOffshoreHours,0)), 
	@SrProjMgrOffshore = sum(isnull(SrProjMgrOffshoreHours,0)), @SrProgMgrOffshore = sum(isnull(SrProgMgrOffshoreHours,0)),	@TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0))
	from #TEMP_OUT where RecNumber = 10
end

-- Populate the RecNumber 0 records (Total Continental)
if ( @ITSABillingCatSelection = '-1' )
begin
	update #TEMP_OUT set JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, JrProjMgrOffshoreHours = @JrProjMgrOffshore, JrProgMgrOffshoreHours = @JrProgMgrOffshore, 
		SrProjMgrOffshoreHours = @SrProjMgrOffshore, SrProgMgrOffshoreHours = @SrProgMgrOffshore, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours, TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs
		where RecNumber = 0	
	update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) 
		+ ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours + JrProjMgrOffshoreHours + JrProgMgrOffshoreHours
		+ SrProjMgrOffshoreHours + SrProgMgrOffshoreHours) / @OffshoreFTERate ) 
		+ ( (FTPStaffAugOnshoreHours + FTPStaffAugOffshoreHours) / @FTPBillingRate )
		where RecNumber = 0
end
else
begin
	update #TEMP_OUT set JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours, JrProjMgrOffshoreHours = @JrProjMgrOffshore, JrProgMgrOffshoreHours = @JrProgMgrOffshore, 
		SrProjMgrOffshoreHours = @SrProjMgrOffshore, SrProgMgrOffshoreHours = @SrProgMgrOffshore, TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs
		where RecNumber = 0	
	update #TEMP_OUT set ActualFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) 
		+ ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours + JrProjMgrOffshoreHours + JrProgMgrOffshoreHours
			+ SrProjMgrOffshoreHours + SrProgMgrOffshoreHours) / @OffshoreFTERate ) 
		where RecNumber = 0
end

-- Populate the RecNumber 3 records (FTE Conversion)
if ( @ITSABillingCatSelection = '-1' )
begin
	update #TEMP_OUT set JrSEOnshoreHours = @JrSEOnshoreHours/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffshoreHours/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnshoreHours/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffshoreHours/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnshoreHours/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffshoreHours/@OffshoreFTERate,		SenSEOnshoreHours = @SenSEOnshoreHours/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffshoreHours/@OffshoreFTERate,		ConsArchOnshoreHours = @ConsArchOnshoreHours/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchOffshoreHours/@OffshoreFTERate,		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/@OffshoreFTERate,		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrOnshoreHours/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/@OffshoreFTERate, JrProjMgrOffshoreHours = @JrProjMgrOffshore/@OffshoreFTERate, JrProgMgrOffshoreHours = @JrProgMgrOffshore/@OffshoreFTERate,
		SrProjMgrOffshoreHours = @SrProjMgrOffshore/@OffshoreFTERate, SrProgMgrOffshoreHours = @SrProgMgrOffshore/@OffshoreFTERate,	FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate,
		COApprovedFTEs = @COApprovedFTEs where RecNumber = 3
	update #TEMP_OUT set TotalHours = (( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) 
		+ ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours	+ @JrProjMgrOffshore + @JrProgMgrOffshore
		+ @SrProjMgrOffshore + @SrProgMgrOffshore) / @OffshoreFTERate) 
		+ (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) /@FTPBillingRate)
		where RecNumber = 3
	update #TEMP_OUT set ActualFTEs = (( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) 
		+ ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours + @JrProjMgrOffshore + @JrProgMgrOffshore
		+ @SrProjMgrOffshore + @SrProgMgrOffshore) / @OffshoreFTERate) 
		+ (@FTPStaffAugOnshoreHours + @FTPStaffAugOffshoreHours) /@FTPBillingRate)
		where RecNumber = 3	
end
else
begin
	update #TEMP_OUT set JrSEOnshoreHours = @JrSEOnshoreHours/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffshoreHours/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnshoreHours/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffshoreHours/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnshoreHours/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffshoreHours/@OffshoreFTERate,		SenSEOnshoreHours = @SenSEOnshoreHours/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffshoreHours/@OffshoreFTERate,		ConsArchOnshoreHours = @ConsArchOnshoreHours/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchOffshoreHours/@OffshoreFTERate,	ProjLeadOnshoreHours = @ProjLeadOnshoreHours/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/@OffshoreFTERate,	ProjMgrOnshoreHours = @ProjMgrOnshoreHours/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrOnshoreHours/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/@OffshoreFTERate, JrProjMgrOffshoreHours = @JrProjMgrOffshore/@OffshoreFTERate, JrProgMgrOffshoreHours = @JrProgMgrOffshore/@OffshoreFTERate,
		SrProjMgrOffshoreHours = @SrProjMgrOffshore/@OffshoreFTERate, SrProgMgrOffshoreHours = @SrProgMgrOffshore/@OffshoreFTERate,	
		COApprovedFTEs = @COApprovedFTEs where RecNumber = 3		
	update #TEMP_OUT set TotalHours = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) 
		+ ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours + @JrProjMgrOffshore + @JrProgMgrOffshore
		+ @SrProjMgrOffshore + @SrProgMgrOffshore) / @OffshoreFTERate) 
		where RecNumber = 3		
	update #TEMP_OUT set ActualFTEs = ( (@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours) / @OnshoreFTERate) 
		+ ( (@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours + @JrProjMgrOffshore + @JrProgMgrOffshore
		+ @SrProjMgrOffshore + @SrProgMgrOffshore) / @OffshoreFTERate) 
		where RecNumber = 3	
end

-- Populate the EDSVariance for 0 and 3 records.
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber in (0,3)

-- Remove any rows that have ZERO values in the TotalHours and the COApprovedFTEs
delete #TEMP_OUT where RecNumber in (10,20,30,40) and (TotalHours = 0 or TotalHours is NULL) and COApprovedFTEs = 0

----------------------------------------------------------------------------------------------------------------------

select * from #TEMP_OUT order by AutoKey

