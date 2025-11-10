---------------------------------STEP 1------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_Get_AFE_Summary_View_Airline]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[SP_Get_AFE_Summary_View_Airline]

DECLARE @SQL_statement varchar(1000) 
SET @SQL_statement = 'Create View dbo.SP_Get_AFE_Summary_View_Airline AS select AFE_Summary_View.*, CO_Resource.Onshore, CO_Resource.Offshore, CO_BillingCode.Billing_CodeID, CO_BillingCode.Description AS NewBillingType
from AFE_Summary_View inner join CO_Resource ON AFE_Summary_View.EDSNETID = CO_Resource.ResourceNumber
inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID
where WorkDate >= ''04/01/2008'' and WorkDate <= ''04/30/2008'' '

EXEC (@SQL_statement)

---------------------------------STEP 2-------------
--Only use this if you need to drop #TEMP_IN in order to insert the next line
--IF OBJECT_ID('tempdb..#TEMP_IN') IS NOT NULL DROP TABLE #TEMP_IN
select * into #TEMP_IN from dbo.SP_Get_AFE_Summary_View_Airline

---------------------------------STEP 3----------------------
exec('Drop View dbo.SP_Get_AFE_Summary_View_Airline')

---------------------------------STEP 4----------------------
ALTER TABLE #TEMP_IN ADD Appr_FTE_Hours decimal(7,2) NULL
ALTER TABLE #TEMP_IN ADD CurrentMonth varchar(6) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN TaskID int NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ProjectID bigint NULL
ALTER TABLE #TEMP_IN ALTER COLUMN WorkDate datetime NULL
ALTER TABLE #TEMP_IN ALTER COLUMN EDSNETID varchar(15) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN Billing_CodeID int NULL
ALTER TABLE #TEMP_IN ALTER COLUMN NewBillingType varchar(50) NULL

---------------------------------STEP 5-------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_Get_AFE_Summary_Airline_View2]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[SP_Get_AFE_Summary_Airline_View2]

DECLARE @SQL_statement varchar(1000) 
SET @SQL_statement = 'Create View dbo.SP_Get_AFE_Summary_Airline_View2 AS select * from FTE_Approved_Time where Appr_FTE_Hours > 0 '

EXEC (@SQL_statement)

---------------------------------STEP 6-------------
insert #TEMP_IN (AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead )
select AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead from dbo.SP_Get_AFE_Summary_Airline_View2

---------------------------------STEP 7---------------------------------
exec('Drop View dbo.SP_Get_AFE_Summary_Airline_View2')

---------------------------------STEP 8-----------------------------
Create Index IDX1 on #TEMP_IN (Prog_GroupID, ProgramID, AFE_DescID, BillingType)

---------------------------------STEP 9-----------------------------
update #TEMP_IN set Hours = isnull(ClientFundingPct,100)/100*Hours where isnull( ClientFundingPct,0) > 0
update #TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0

---------------------------------STEP 10-----------------------------
--DECLARE @Factor decimal(5,2), @row_count int
--if (month('04/1/2008') <> month(getdate())) or ( year('04/1/2008') <> year(getdate()))
--    set @Factor = 1
--else
--    select @Factor = convert(float, day(getdate())) / convert(float, day(DATEADD(d, -DAY(DATEADD(m,1,getdate())),DATEADD(m,1,getdate()))))

---------------------------------STEP 11--------------------------------
--IF OBJECT_ID('tempdb..#TEMP_OUT') IS NOT NULL DROP TABLE #TEMP_OUT

CREATE TABLE [dbo].[#TEMP_OUT] ( 
	[AutoKey][int] IDENTITY (0, 1) NOT NULL,
	[RecNumber][int] NULL,
	[RecType] [varchar] (100) NULL, -- ProgramGroup Totals / Program / AFEDesc / Total / FTE Conversion
	[RecDesc] [varchar] (100) NULL,
	[RecTypeID] [bigint] NULL,
	[ITSABillingCat] [varchar] (30) NULL,
	[FundingCat] [varchar] (30) NULL,
    [AFENumber] [varchar] (20) NULL,
	[COBusinessLead] [varchar] (100) NULL,
	[ProgramMgr] [varchar] (50) NULL,
	[Location] [varchar] (30) NULL,
	[TotalHours] [decimal](10,2) NULL,
	[ActualFTEs] [decimal](10,2) NULL,
	[COApprovedFTEs] [decimal](10,2) NULL,
	[EDSVariance] [decimal](10,2) NULL,
	[JrSEOnshoreHours] [decimal](10,2) NULL,
	[JrSeOffshoreHours] [decimal](10,2) NULL,
	[MidSEOnshoreHours] [decimal](10,2) NULL,
	[MidSEOffshoreHours] [decimal](10,2) NULL,
	[AdvSEOnshoreHours] [decimal](10,2) NULL,
	[AdvSEOffshoreHours] [decimal](10,2) NULL,
	[SenSEOnshoreHours] [decimal](10,2) NULL,
	[SenSEOffshoreHours] [decimal](10,2) NULL,
	[ConsArchOnshoreHours] [decimal](10,2) NULL,
	[ConsArchOffshoreHours] [decimal](10,2) NULL,
	[ProjLeadOnshoreHours] [decimal](10,2) NULL,
	[ProjLeadOffshoreHours] [decimal](10,2) NULL,
	[ProjMgrOnshoreHours] [decimal](10,2) NULL,
	[ProjMgrOffshoreHours] [decimal](10,2) NULL,
	[ProgMgrOnshoreHours] [decimal](10,2) NULL,
    --[ExpectedMTDFTE] [decimal](10,2) NULL,
    --[VarianceMTDFTE] [decimal](10,2) NULL,
	[R10_ProgramGroup] [varchar] (100) NULL,
	[R20_Program] [varchar] (100) NULL
) ON [PRIMARY]

---------------------------------STEP 14-----------------------------
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Total Continental (CO)'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotalConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 1, 'TotalAirline', 'Total Airline'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 1, 'TotalAirlineConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 2, 'TotalADM', 'Total ADM'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 2, 'TotalADMConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 4, 'TotalAFEProd', 'Total AFE Prod'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 4, 'TotalAFEProdConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'TotalStaffAug', 'Total Staff Augmentation (FTE Based)'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'TotalStafAugConversion', 'FTE Conversion'

---------------------------------STEP 15-----------------------------
DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID int, @CurProgram varchar(100), 
@CurProgramID int, @CurCOBusinessLead varchar(100), @CurAFEDesc varchar(100), 
@CurAFE_DescID int, @MaxProgGroup int, @MaxProgram int, @MaxAFEDesc int, @MaxProj bigint

--Delete these variables after testing.
,@DateFrom datetime, @DateTo datetime, @ITSABillingCat varchar(30)
set @DateFrom = '04-01-2008'
set @DateTo = '04-30-2008'
--Delete the above after testing.

---ProgramGroup_cursor---
DECLARE ProgramGroup_cursor CURSOR FOR 
    select distinct ProgramGroup, Prog_GroupID from #TEMP_IN where ProgramGroup is not null order by ProgramGroup
OPEN ProgramGroup_cursor
FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID
WHILE @@FETCH_STATUS = 0
BEGIN
	insert #TEMP_OUT (RecNumber) values (10) -- A blank line
	insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID) select 10, 'ProgGroup/Total', @CurProgramGroup, @CurProg_GroupID
    select @MaxProgGroup = max(AutoKey) from #TEMP_OUT 

	--------------------Program_cursor--------------------
	DECLARE Program_cursor CURSOR FOR 
		select distinct Program, ProgramID, COBusinessLead from #TEMP_IN
		where ProgramGroup = @CurProgramGroup and Program is not null order by Program				
	OPEN Program_cursor
	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID, @CurCOBusinessLead
	WHILE @@FETCH_STATUS = 0
    BEGIN
		--insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, COBusinessLead) select 20, 'Program', @CurProgram, @CurProgramID, @CurCOBusinessLead
		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, COBusinessLead) select 20, 'Program', @CurProgram, @CurProgramID, @CurProgramGroup, @CurCOBusinessLead              
        select @MaxProgram = max(AutoKey) from #TEMP_OUT 

		-------------------AFEDesc_cursor------------------
		DECLARE AFEDesc_cursor CURSOR FOR 
			select distinct AFEDesc, AFE_DescID from #TEMP_IN 
			where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFEDesc is not null order by AFEDesc
		OPEN AFEDesc_cursor
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID
		WHILE @@FETCH_STATUS = 0
		BEGIN
			--insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID) select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID
        	insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program) select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID, @CurProgramGroup, @CurProgram
			select @MaxAFEDesc = max(AutoKey) from #TEMP_OUT

--@CurProgramGroup=CO-Airport Services
--@CurProg_GroupID=6000
--@CurProgram=CO-ETA
--@CurProgramID=5072							
--@CurAFEDesc=ETA Production Support
--@CurAFE_DescID=1627
							
			-- Get the ITSA Billing Category.
			select @ITSABillingCat = ITSABillingCat from #TEMP_IN
			where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 

            -- Declare variables for Hours calculation.        
            declare @JrSEOnshore decimal(10,2), @JrSEOffshore decimal(10,2), 
					@MidSEOnshore decimal(10,2), @MidSEOffshore decimal(10,2),
					@AdvSEOnshore decimal(10,2), @AdvSEOffshore decimal(10,2),
					@SenSEOnshore decimal(10,2), @SenSEOffshore decimal(10,2),
					@ConsArchOnshore decimal(10,2), @ConsArchOffshore decimal(10,2), 
					@ProjLeadOnshore decimal(10,2), @ProjLeadOffshore decimal(10,2), 
					@ProjMgrOnshore decimal(10,2), @ProjMgrOffshore decimal(10,2), @ProgMgrOnshore decimal(10,2)
--Sum Hrs: 96 ITSABillingCat: Staff Aug
--select sum(isnull(Hours,0)) select * from #TEMP_IN
--where Prog_GroupID = '6000' and ProgramID = '5072' and AFE_DescID = '1627' and NewBillingType = 'Adv SE' and Onshore = 1

--Sum Hrs: 104 ITSABillingCat: Staff Aug
--select sum(isnull(Hours,0)) from #TEMP_IN
--where Prog_GroupID = '6000' and ProgramID = '5072' and AFE_DescID = '1627' and NewBillingType = 'Sen SE' and Onshore = 1
  
			-- SUMMARIZE Hours by New Billing Type.        
			select @JrSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Jr SE' and Onshore = 1
			select @JrSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Jr SE' and Offshore = 1

			select @MidSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Mid SE' and Onshore = 1
			select @MidSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Mid SE' and Offshore = 1
 
			select @AdvSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Adv SE' and Onshore = 1
			select @AdvSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Adv SE' and Offshore = 1

			select @SenSEOnshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Sen SE' and Onshore = 1
			select @SenSEOffshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Sen SE' and Offshore = 1

			select @ConsArchOnshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Cons Arch' and Onshore = 1
			select @ConsArchOffshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Cons Arch' and Offshore = 1

			select @ProjLeadOnshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Project Lead' and Onshore = 1
			select @ProjLeadOffshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Project Lead' and Offshore = 1
		
			select @ProjMgrOnshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Project Mgr' and Onshore = 1
			select @ProjMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Project Mgr' and Offshore = 1				

			select @ProgMgrOnshore = sum(isnull(Hours,0)) from #TEMP_IN
            where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'Program Mgr' and Onshore = 1	
 			
            --GET funding category and location combo  --		
            Declare @@out_location varchar (100), @@out_fundingcat varchar (100), @@out_afenumber varchar (20), @@out_programmgr varchar (50), @@Total_FTE float
    		set @@out_fundingcat = NULL
       		set @@out_afenumber = NULL
			set @@out_programmgr = NULL
			set @@out_location = NULL
       		set @@Total_FTE = NULL
            exec GET_Location_Combo @CurAFE_DescID, @DateFrom, @DateTo, @@out_location OUTPUT, @@out_fundingcat OUTPUT, @@out_afenumber OUTPUT,@@out_programmgr OUTPUT, @@Total_FTE OUTPUT
        
            -- UPDATE temporary table --        
            update #TEMP_OUT 
			set ITSABillingCat = @ITSABillingCat,
					fundingcat = @@out_fundingcat,
                    AFENumber = @@out_afenumber,
					ProgramMgr = @@out_programmgr,	
					location = @@out_location,
                    COApprovedFTEs = isnull(@@Total_FTE,0),
					JrSEOnshoreHours = isnull(@JrSEOnshore,0),
					JrSEOffshoreHours = isnull(@JrSEOffshore,0),				
 					MidSEOnshoreHours = isnull(@MidSEOnshore,0),
					MidSEOffshoreHours = isnull(@MidSEOffshore,0),
					AdvSEOnshoreHours = isnull(@AdvSEOnshore,0),
					AdvSEOffshoreHours = isnull(@AdvSEOffshore,0),					
 					SenSEOnshoreHours = isnull(@SenSEOnshore,0),
					SenSEOffshoreHours = isnull(@SenSEOffshore,0),
					ConsArchOnshoreHours = isnull(@ConsArchOnshore,0),
					ConsArchOffshoreHours = isnull(@ConsArchOffshore,0),
 					ProjLeadOnshoreHours = isnull(@ProjLeadOnshore,0),
					ProjLeadOffshoreHours = isnull(@ProjLeadOffshore,0),
					ProjMgrOnshoreHours = isnull(@ProjMgrOnshore,0),
					ProjMgrOffshoreHours = isnull(@ProjMgrOffshore,0),	
					ProgMgrOnshoreHours = isnull(@ProgMgrOnshore,0)
            where AutoKey = @MaxAFEDesc				

		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID
		END    
		CLOSE AFEDesc_cursor
		DEALLOCATE AFEDesc_cursor

	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID, @CurCOBusinessLead
	END
	CLOSE Program_cursor
	DEALLOCATE Program_cursor

    -- Populate TotalHours Column (horizontal add up).
    update #TEMP_OUT set TotalHours = 
			isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + 
			isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + 
			isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) +
			isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + 
			isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + 
			isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + 
			isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + 
			isnull(ProgMgrOnshoreHours,0) 
    where AutoKey > @MaxProgGroup and RecNumber = 30

    update #TEMP_OUT set ActualFTEs = TotalHours/143.5 where AutoKey > @MaxProgGroup and RecNumber = 30
    update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey > @MaxProgGroup and RecNumber = 30
   
    -- Update totals for 10 fields (vertical add up).
    declare @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), 
				@MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2),  
				@AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2),
				@SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), 
				@ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), 
				@SCEAOnshoreHours decimal(10,2), @SCEAOffshoreHours decimal(10,2), 
				@ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), 
				@ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), 
				@ProgMgrOnshoreHours decimal(10,2), @TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2)
       
	select  @TotalHours = sum(isnull(TotalHours,0)), @ActualFTEs = sum(isnull(ActualFTEs,0)),
                @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @EDSVariance = sum(isnull(EDSVariance,0)),
				@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), 
				@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)),
				@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)),
				@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)),
				@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)),
				@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
				@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), 
				@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0))
    from #TEMP_OUT where AutoKey > @MaxProgGroup

    update #TEMP_OUT
    set TotalHours = @TotalHours, ActualFTEs = @ActualFTEs, COApprovedFTEs = @COApprovedFTEs, EDSVariance = @EDSVariance,
			JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours,
			MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
			AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
			SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
			ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, 
			ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours,
			ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
			ProgMgrOnshoreHours = @ProgMgrOnshoreHours
    where AutoKey = @MaxProgGroup		

FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID
END
CLOSE ProgramGroup_cursor
DEALLOCATE ProgramGroup_cursor

---------------------------------STEP 16-----------------------------
-- Declare variables for Hours calculation.        
declare @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @SCEAOnshoreHours decimal(10,2), @SCEAOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2), 
@TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2)

-- Calculate and Populate the 0 RecNumber Grand Total.
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
--update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber in (0,1)
--update #TEMP_OUT set ExpectedMTDFTE = COApprovedFTEs * @Factor where COApprovedFTEs is not NULL
--update #TEMP_OUT set VarianceMTDFTE = ActualFTEs - ExpectedMTDFTE where COApprovedFTEs is not NULL

---------------------------------STEP 17-----------------------------
select * from #TEMP_OUT

-- Declare variables for Hours calculation.        
declare @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @SCEAOnshoreHours decimal(10,2), @SCEAOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2), 
@TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2)

-- Calculate and Populate the RecNumber 1 (Total Airline) records.
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

---------------------------------STEP 18-----------------------------
select * from #TEMP_OUT

-- Declare variables for Hours calculation.        
declare @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @SCEAOnshoreHours decimal(10,2), @SCEAOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2), 
@TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2)

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

---------------------------------STEP 19-----------------------------
select * from #TEMP_OUT

-- Declare variables for Hours calculation.        
declare @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @SCEAOnshoreHours decimal(10,2), @SCEAOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2), 
@TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2)

-- Calculate and Populate the 6 and 7 records
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

---------------------------------STEP 19-----------------------------
select * from #TEMP_OUT

-- Declare variables for Hours calculation.        
declare @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), @MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2), @AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2), @SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), @ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), @SCEAOnshoreHours decimal(10,2), @SCEAOffshoreHours decimal(10,2), @ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), @ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), @ProgMgrOnshoreHours decimal(10,2), 
@TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2)

-- Calculate and Populate the 5 records (Staff Aug).
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


---------------------------------STEP 16-----------------------------
select * from #TEMP_OUT order by AutoKey


--Select RecNumber, RecType, RecDesc, RecTypeID, ITSABillingCat, FundingCat, AFENumber, COBusinessLead, Programmgr, Location, TotalHours, ActualFTEs, COApprovedFTEs, EDSVariance,
--JrSEOnshoreHours, JrSEOffshoreHours, MidSEOnshoreHours, MidSEOffshoreHours, 
--AdvSEOnshoreHours, AdvSEOffshoreHours, SenSEOnshoreHours, SenSEOffshoreHours, 
--ConsArchOnshoreHours, ConsArchOffshoreHours, ProjLeadOnshoreHours, ProjLeadOffshoreHours,  
--ProjMgrOnshoreHours, ProjMgrOffshoreHours, ProgMgrOnshoreHours
--from #TEMP_OUT order by AutoKey
