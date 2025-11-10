--StoredProcedure [dbo].[Get_AFE_Summary] 

drop view [dbo].[SP_Get_AFE_Summary_View]
drop view [dbo].[SP_Get_AFE_Summary_View2]
drop table #TEMP_IN
drop table #TEMP_OUT

--Create the 1st view
DECLARE @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Summary_View AS select * from AFE_Summary_View 
where 1=1 and WorkDate >= ''2012-06-01'' and WorkDate <= ''2012-06-30''  '
exec (@SQL_statement)

select * into #TEMP_IN from dbo.SP_Get_AFE_Summary_View

exec('Drop View dbo.SP_Get_AFE_Summary_View')

-- Add two column to include from view FTE_Approved_Time
ALTER TABLE #TEMP_IN ADD Appr_FTE_Hours decimal(7,2) NULL
ALTER TABLE #TEMP_IN ADD CurrentMonth varchar(6) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN TaskID varchar(100) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ProjectID varchar(100) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN WorkDate datetime NULL
ALTER TABLE #TEMP_IN ALTER COLUMN EDSNETID varchar(15) NULL

-- Create the 2nd view
DECLARE @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Summary_View2 AS select * from FTE_Approved_Time 
where Appr_FTE_Hours > 0 and CurrentMonth = ''201206'' '
exec (@SQL_statement)

--***changed
insert #TEMP_IN (AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, UA_VicePresident)
select AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, UA_VicePresident
from dbo.SP_Get_AFE_Summary_View2

exec('Drop View dbo.SP_Get_AFE_Summary_View2')

-- create view on temp_in table
Create Index IDX1 on #TEMP_IN (Prog_GroupID, ProgramID, AFE_DescID, BillingType)

-- Adjust the Hours according to the ClientFundingPct by CO
update #TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--drop table #TEMP_OUT

--***changed
CREATE TABLE [dbo].[#TEMP_OUT] ( 
	[AutoKey][int] IDENTITY (0, 1) NOT NULL,
	[RecNumber][int] NULL, [RecType] [varchar] (100) NULL, -- ProgramGroup Totals / Program / AFEDesc / Total / FTE Conversion
	[RecDesc] [varchar] (100) NULL, [RecTypeID] [varchar] (100) NULL, [FundingCat] [varchar] (30) NULL,
    [AFENumber] [varchar] (20) NULL,
    [UAVP] [varchar] (50) NULL, 
	[COBusinessLead] [varchar] (100) NULL,[ProgramMgr] [varchar] (50) NULL, [Location] [varchar] (30) NULL,
	[TotalHours] [decimal](10,2) NULL, [ActualFTEs] [decimal](10,2) NULL, [COApprovedFTEs] [decimal](10,2) NULL, [EDSVariance] [decimal](10,2) NULL,
	[JuniorSEHours] [decimal](10,2) NULL, [SEHours] [decimal](10,2) NULL, [ADVSEHours] [decimal](10,2) NULL,
	[SeniorSEHours] [decimal](10,2) NULL, [PLHours] [decimal](10,2) NULL, [JuniorTPFHours] [decimal](10,2) NULL,
	[SETPFHours] [decimal](10,2) NULL, [ADVTPFHours] [decimal](10,2) NULL, [SeniorTPFHours] [decimal](10,2) NULL, [PLTPFHours] [decimal](10,2) NULL,
    [ExpectedMTDFTE] [decimal](10,2) NULL, [VarianceMTDFTE] [decimal](10,2) NULL, [R10_ProgramGroup] [varchar] (100) NULL, [R20_Program] [varchar] (100) NULL
) ON [PRIMARY]

insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Total United (UA)'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 3, 'Conversion', 'FTE Conversion'

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID varchar(100), @CurProgram varchar(100), @CurProgramID  varchar(100), @CurCOBusinessLead varchar (100), @CurAFEDesc varchar (100), @CurAFE_DescID varchar(100), @MaxProgGroup int, @MaxProgram int, @MaxAFEDesc int, @MaxProj int, @Factor decimal(5,2), @UPVP varchar(50)
declare @JRSE decimal(10,2), @SE decimal(10,2), @ADVSE decimal(10,2), @SENSE decimal(10,2), @PL decimal(10,2), @JRTPF decimal(10,2), @SETPF decimal(10,2), @ADVTPF decimal(10,2), @SENTPF decimal(10,2), @PLTPF decimal(10,2)
declare @JuniorSEHours decimal(10,2), @SEHours decimal(10,2), @ADVSEHours decimal(10,2), @SeniorSEHours decimal(10,2), @PLHours decimal(10,2), @JuniorTPFHours decimal(10,2), @SETPFHours decimal(10,2), @ADVTPFHours decimal(10,2), @SeniorTPFHours decimal(10,2), @PLTPFHours decimal(10,2), @TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2)

---for testing only
declare @DateFrom datetime, @DateTo datetime
set @DateFrom = '2012-06-01'
set @DateTo = '2012-06-30'

if (month(@datefrom) <> month(getdate())) or ( year(@datefrom) <> year(getdate()))
    set @Factor = 1
else
    select @Factor = convert(float, day(getdate())) / convert(float, day(DATEADD(d, -DAY(DATEADD(m,1,getdate())),DATEADD(m,1,getdate()))))

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
		---------------------------------------------------------------------------------------------------
		DECLARE Program_cursor CURSOR FOR 
			select distinct Program, ProgramID from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program is not null 	order by Program
		OPEN Program_cursor
		FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
        	WHILE @@FETCH_STATUS = 0
            BEGIN
        		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup)
                select 20, 'Program', @CurProgram, @CurProgramID, @CurProgramGroup
                select @MaxProgram = max(AutoKey) from #TEMP_OUT
				---------------------------------------------------------------------------------------------------                
				DECLARE AFEDesc_cursor CURSOR FOR 
					select distinct AFEDesc, AFE_DescID, COBusinessLead from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFEDesc is not null order by 	AFEDesc
				OPEN AFEDesc_cursor
				FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
					WHILE @@FETCH_STATUS = 0
        			BEGIN
        				insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, COBusinessLead)
           		   		select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID, @CurProgramGroup, @CurProgram, @CurCOBusinessLead
                        select @MaxAFEDesc = max(AutoKey) from #TEMP_OUT
             		   		               
						-- Update total information in type 10 heading records. SUMMARIZE hours by BILLING TYPE.
		                select @JRSE = sum(isnull(hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID
                			and BillingType = 'Junior SE'
						select @SE = sum(isnull(hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID
                			and BillingType = 'SE'                
						select @ADVSE = sum(isnull(hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID
                			and BillingType = 'Advanced SE'                
						select @SENSE = sum(isnull(hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID
                			and BillingType = 'Senior SE'                
						select @PL = sum(isnull(hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID
                			and BillingType = 'Project Leader'                
						select @JRTPF = sum(isnull(hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID
		                	and BillingType = 'Junior SE TPF'
                        select @SETPF = sum(isnull(hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID
		                	and BillingType = 'SE TPF'
                        select @ADVTPF = sum(isnull(hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID
                			and BillingType = 'Advanced SE TPF'
                        select @SENTPF = sum(isnull(hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID
                			and BillingType = 'Senior SE TPF'
                        select @PLTPF = sum(isnull(hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID
                			and BillingType = 'Project Leader TPF'
                
						-- GET funding category and location combo  --		
						Declare @@out_location varchar (100), @@out_fundingcat varchar (100), @@out_afenumber varchar (20),@@out_programmgr varchar (50), @@Total_FTE float             
        				set @@out_location  = NULL
        				set @@out_fundingcat = NULL
        				set @@out_afenumber = NULL
						set @@out_programmgr = NULL
        				set @@Total_FTE = NULL
						exec GET_Location_Combo @CurAFE_DescID, @DateFrom, @DateTo, @@out_location OUTPUT, @@out_fundingcat OUTPUT, @@out_afenumber OUTPUT,@@out_programmgr OUTPUT, @@Total_FTE OUTPUT
                
						-- UPDATE temporary table --        
						update #TEMP_OUT set JuniorSEHours = isnull(@JRSE,0), SEHours = isnull(@SE,0), ADVSEHours = isnull(@ADVSE,0), SeniorSEHours = isnull(@SENSE,0), PLHours = isnull(@PL,0), JuniorTPFHours = isnull(@JRTPF,0), SETPFHours = isnull(@SETPF,0), ADVTPFHours = isnull(@ADVTPF,0), SeniorTPFHours = isnull(@SENTPF,0), PLTPFHours = isnull(@PLTPF,0), location = @@out_location, fundingcat = @@out_fundingcat, AFENumber = @@out_afenumber, ProgramMgr = @@out_programmgr,	COApprovedFTEs = isnull(@@Total_FTE,0)
						where AutoKey = @MaxAFEDesc
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
        -- Populate TotalHours Column (horizontal add up)
        update #TEMP_OUT set TotalHours = isnull(JuniorSEHours,0)+isnull(SEHours,0)+isnull(ADVSEHours,0)+ isnull(SeniorSEHours,0)+isnull(PLHours,0)+isnull(JuniorTPFHours,0)+isnull(SETPFHours,0)+ isnull(ADVTPFHours,0)+isnull(SeniorTPFHours,0)+isnull(PLTPFHours,0)
        where AutoKey > @MaxProgGroup and RecNumber = 30

        update #TEMP_OUT set ActualFTEs = TotalHours/143.5 
        where AutoKey > @MaxProgGroup and RecNumber = 30

        update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs 
        where AutoKey > @MaxProgGroup and RecNumber = 30
        
        -- Update total information for 10 fields (vertical add up)
        select @JuniorSEHours = sum(isnull(JuniorSEHours,0)), @SEHours = sum(isnull(SEHours,0)), @ADVSEHours = sum(isnull(ADVSEHours,0)), @SeniorSEHours = sum(isnull(SeniorSEHours,0)), @PLHours = sum(isnull(PLHours,0)), @JuniorTPFHours = sum(isnull(JuniorTPFHours,0)), @SETPFHours = sum(isnull(SETPFHours,0)), @ADVTPFHours = sum(isnull(ADVTPFHours,0)), @SeniorTPFHours = sum(isnull(SeniorTPFHours,0)), @PLTPFHours = sum(isnull(PLTPFHours,0)), @TotalHours = sum(isnull(TotalHours,0)), @ActualFTEs = sum(isnull(ActualFTEs,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @EDSVariance = sum(isnull(EDSVariance,0))
        from #TEMP_OUT where AutoKey > @MaxProgGroup

        update #TEMP_OUT set JuniorSEHours = @JuniorSEHours, SEHours = @SEHours, ADVSEHours = @ADVSEHours, SeniorSEHours = @SeniorSEHours, PLHours = @PLHours, JuniorTPFHours = @JuniorTPFHours, SETPFHours = @SETPFHours, ADVTPFHours = @ADVTPFHours, SeniorTPFHours = @SeniorTPFHours, PLTPFHours = @PLTPFHours, TotalHours = @TotalHours, ActualFTEs = @ActualFTEs, COApprovedFTEs = @COApprovedFTEs, EDSVariance = @EDSVariance
        where AutoKey = @MaxProgGroup

	FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID, @UPVP
	END
CLOSE ProgramGroup_cursor
DEALLOCATE ProgramGroup_cursor

---------------------------------------------------------------------------------------------------
-- Calculate and Populate the 0 and 3 records
select @JuniorSEHours = sum(isnull(JuniorSEHours,0)), @SEHours = sum(isnull(SEHours,0)), @ADVSEHours = sum(isnull(ADVSEHours,0)), @SeniorSEHours = sum(isnull(SeniorSEHours,0)), @PLHours = sum(isnull(PLHours,0)), @JuniorTPFHours = sum(isnull(JuniorTPFHours,0)), @SETPFHours = sum(isnull(SETPFHours,0)), @ADVTPFHours = sum(isnull(ADVTPFHours,0)), @SeniorTPFHours = sum(isnull(SeniorTPFHours,0)), @PLTPFHours = sum(isnull(PLTPFHours,0)), @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0))
from #TEMP_OUT where RecNumber = 10

update #TEMP_OUT set JuniorSEHours = @JuniorSEHours, SEHours = @SEHours, ADVSEHours = @ADVSEHours, SeniorSEHours = @SeniorSEHours, PLHours = @PLHours, JuniorTPFHours = @JuniorTPFHours, SETPFHours = @SETPFHours, ADVTPFHours = @ADVTPFHours, SeniorTPFHours = @SeniorTPFHours, PLTPFHours = @PLTPFHours, 
    TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs 
where RecNumber = 0

update #TEMP_OUT set JuniorSEHours = @JuniorSEHours/143.5, SEHours = @SEHours/143.5, ADVSEHours = @ADVSEHours/143.5, SeniorSEHours = @SeniorSEHours/143.5, PLHours = @PLHours/143.5, JuniorTPFHours = @JuniorTPFHours/143.5, SETPFHours = @SETPFHours/143.5, ADVTPFHours = @ADVTPFHours/143.5, SeniorTPFHours = @SeniorTPFHours/143.5, PLTPFHours = @PLTPFHours/143.5,
    TotalHours = @TotalHours/143.5, -- value 1
    ActualFTEs = @TotalHours/143.5, -- value 1
    COApprovedFTEs = @COApprovedFTEs
where RecNumber = 3

update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 0
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber in (0,3)
update #TEMP_OUT set ExpectedMTDFTE = COApprovedFTEs * @Factor where COApprovedFTEs is not NULL
update #TEMP_OUT set VarianceMTDFTE = ActualFTEs - ExpectedMTDFTE where COApprovedFTEs is not NULL

----------------------------------------------------------------------------------------------------------------------

select * from #TEMP_OUT order by AutoKey
