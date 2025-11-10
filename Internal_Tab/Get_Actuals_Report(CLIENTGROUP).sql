/****** Object:  StoredProcedure [dbo].[Get_Actuals_Report]    Script Date: 11/11/2013 11:49:27 ******/
drop table #TEMP_IN
drop table #TEMP_OUT
drop view [dbo].[SP_Get_AR_View]

DECLARE @SQL_statement varchar(1400)
set @SQL_statement = 'Create View dbo.SP_Get_AR_View AS select * from InternalBilling_View where 1=1 and WorkDate >= ''2016-07-01'' and WorkDate <= ''2016-07-31''  and Hours > 0'
exec (@SQL_statement)

select Client, ProjectID, ProjectTitle, TaskID, TaskName, ResourceName, WorkDate, ActualWork AS HrsToDate, ProjClientFundingPct, ProjClientFundedBy, TaskClientFundingPct, TaskClientFundedBy, ResourceOrg, Hours, Keyword, Onshore, Offshore
into #TEMP_IN from dbo.SP_Get_AR_View order by Client, ProjectID, ProjectTitle, TaskID, TaskName, ResourceName, WorkDate, ProjClientFundingPct, ProjClientFundedBy, TaskClientFundingPct, TaskClientFundedBy, ResourceOrg

ALTER TABLE #TEMP_IN ADD ID int IDENTITY(1,1) NOT NULL PRIMARY KEY 

delete T1 from #TEMP_IN T1, #TEMP_IN T2 where  T1.Client = 'Multiple' and T2.Client = 'Multiple' and T1.ProjectID = T2.ProjectID and T1.ProjectTitle = T2.ProjectTitle and T1.TaskID = T1.TaskID and T1.TaskName = T2.TaskName and        T1.ResourceName = T2.ResourceName and        T1.WorkDate = T2.WorkDate and        T1.HrsToDate = T2.HrsToDate and        T1.TaskClientFundingPct = T2.TaskClientFundingPct and        T1.TaskClientFundedBy = T2.TaskClientFundedBy and        T1.ResourceOrg = T2.ResourceOrg and        T1.Hours = T2.Hours and        T1.ID > T2.ID

-- Redefine ResourceOrg for reports
update #TEMP_IN set ResourceOrg = 'GCR - SYDNEY' where ResourceOrg like '%SYDNEY%'
update #TEMP_IN set ResourceOrg = 'GCR - MEXICO' where ResourceOrg = 'GCR - AD-MX-JUAREZ ADU'
update #TEMP_IN set ResourceOrg = 'MPHASIS' where ResourceOrg = 'BSSC INDIA'	

---CHANGED
-- Set ResourceORG field to OTHER if not one of the fixed buckets
update #TEMP_IN set ResourceOrg = 'OTHER' where ResourceOrg not in ('GCR - SYDNEY', 'GCR - MEXICO', 'HOUSTON SOLUTION CENTRE', 'HP INDIA', 'MIRAMAR SOLUTION CENTRE', 'MPHASIS', 'RDC', 'SOUTHERN CALIFORNIA SOLUTION CEN') AND (ResourceOrg not like '%MEXICO%') and ( ResourceOrg not like '%AD-MX%')

-- Adjust Hours by applying Funding Percentage. 
update #TEMP_IN set Hours = Hours * (TaskClientFundingPct/100) where TaskClientFundingPct is not NULL 

Update #TEMP_IN set TaskClientFundedBy = 'PORT' where TaskClientFundedBy = 'POR'
Update #TEMP_IN set ProjClientFundingPct = TaskClientFundingPct where TaskClientFundingPct is Not NULL
Update #TEMP_IN set Client = 'Continental Airlines' where Client = 'Multiple' and TaskClientFundedBy Like '%CO%'
Update #TEMP_IN set Client = (Select distinct Client from dbo.lkClientGroupClientRef where ClientCode = TaskClientFundedBy) where Client = 'Multiple' and TaskClientFundedBy is Not NULL and TaskClientFundedBy Not Like '%CO%' 

Create Index IDX1 on #TEMP_IN (Client, ProjectID, ResourceName, ResourceOrg)
Create Index IDX2 on #TEMP_IN (ProjectID, ResourceName, ResourceOrg)

----------------------------------------------------------------------------------
--CHANGED
--DROP TABLE #TEMP_OUT
CREATE TABLE [dbo].[#TEMP_OUT] (
	[AutoKey][int] IDENTITY (0, 1) NOT NULL,
	[RecNumber][int] NULL,				-- 0, 3, 6, 10, 20, 30, 40, 50, 55, 56, 60, 99
	[RecType] [varchar] (100) NULL,		-- Client / Project / Resource
	[RecDesc] [varchar] (100) NULL,
	[HrsToDate] [decimal](10,2) NULL,
	[FundingPct] [decimal](10,2) NULL,
	[TotalHours] [decimal](10,2) NULL,
	[SCSC_Hours] [decimal](10,2) NULL,		-- SCSC = SOUTHERN CALIFORNIA SOLUTION CEN 
	[RDC_Hours] [decimal](10,2) NULL,		-- RDC
	[MEXSC_Hours] [decimal](10,2) NULL,		-- MEXICO CITY SOLUTION CENTRE 
	[MIRSC_Hours] [decimal](10,2) NULL,		-- MIRAMAR SOLUTION CENTRE 
	[OTHER_Hours] [decimal](10,2) NULL,		-- OTHER 
	[HOUSC_Hours] [decimal](10,2) NULL,	-- HOUSTON SOLUTION CENTRE 
	[MPHASIS_Onsite_Hours] [decimal](10,2) NULL,	-- MPHASIS ONSHORE
	[MPHASIS_Offsite_Hours] [decimal](10,2) NULL,	-- MPHASIS OFFSHORE
	[HPINDIA_Hours] [decimal](10,2) NULL,	-- HP INDIA 
	[GCR_SYD_Hours] [decimal](10,2) NULL,	-- GCR SYD = BSSC SYDNEY
	[GCR_MEX_Hours] [decimal](10,2) NULL,	-- GCR MEX = MEXICO CITY SOLUTION CENTRE
	[R10_Client] [varchar] (100) NULL,
	[R30_Project] [varchar] (100) NULL
) ON [PRIMARY]

insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Grand Total'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'GrandTotal', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 7, 'GrandTotal', 'FTE Factors'

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
declare @DateFrom datetime, @DateTo datetime, @ClientGroup varchar(100)

----changed by lizzy
DECLARE @CurSolutionCentreCode varchar(50), @CurFTEFactor float, @FTE_Factor float, @FTE_Factor_SCSC float, @FTE_Factor_RDC float, @FTE_Factor_MEXSC float, @FTE_Factor_MIRSC float, @FTE_Factor_OTHER float, @FTE_Factor_HOUSC float, @FTE_Factor_INDIA float, @FTE_Factor_GCR_SYDNEY float, @FTE_Factor_GCR_MEXICO float

-- Set FTEFactors for the ClientGroup
SELECT @FTE_Factor = FTEFactor from lkClientGroup where ClientGroup = @ClientGroup

-- Set FTE Factors for ALL Solution Centres
set @FTE_Factor_OTHER = @FTE_Factor
set @FTE_Factor_GCR_SYDNEY = @FTE_Factor
set @FTE_Factor_GCR_MEXICO = @FTE_Factor
set @FTE_Factor_HOUSC = @FTE_Factor
set @FTE_Factor_INDIA = @FTE_Factor
set @FTE_Factor_MEXSC = @FTE_Factor
set @FTE_Factor_MIRSC = @FTE_Factor
set @FTE_Factor_SCSC = @FTE_Factor
set @FTE_Factor_RDC = @FTE_Factor

-- Check if there are any FTE overrides for ClientGroup/Solution Centre reset FTE Factor
DECLARE FTEOverride_cursor CURSOR FOR 
    select FTEFactor,ResourceOrg from lkClientGroupFTEOverride where ClientGroup = @ClientGroup
OPEN FTEOverride_cursor
FETCH NEXT FROM FTEOverride_cursor INTO @CurFTEFactor, @CurSolutionCentreCode
	WHILE @@FETCH_STATUS = 0
	BEGIN
	IF @CurSolutionCentreCode = 'RDC'
		set @FTE_Factor_RDC = @CurFTEFactor
	IF @CurSolutionCentreCode = 'Southern California Solution Cen'
		set @FTE_Factor_SCSC = @CurFTEFactor
    IF @CurSolutionCentreCode = 'Mexico City Solution Centre'
       	set @FTE_Factor_MEXSC = @CurFTEFactor
    IF @CurSolutionCentreCode = 'Miramar Solution Centre'
      	set @FTE_Factor_MIRSC = @CurFTEFactor
    IF @CurSolutionCentreCode = 'Houston Solution Centre'
        set @FTE_Factor_HOUSC = @CurFTEFactor
    IF @CurSolutionCentreCode in ('MPHASIS','HP INDIA')
        set @FTE_Factor_INDIA = @CurFTEFactor
    IF @CurSolutionCentreCode = 'GCR - Sydney Solution Centre'
        set @FTE_Factor_GCR_Sydney = @CurFTEFactor
    IF @CurSolutionCentreCode in ('GCR - Mexico City Solution Centre','GCR - NORTHERN MEXICO SOLUTION CENTRE')
        set @FTE_Factor_GCR_Mexico = @CurFTEFactor
FETCH NEXT FROM FTEOverride_cursor INTO @CurFTEFactor, @CurSolutionCentreCode
END    
CLOSE FTEOverride_cursor
DEALLOCATE FTEOverride_cursor

----------------------------------------------------------------------------------
--CHANGED
DECLARE @SCSC_Hours decimal(10,2), @RDC_Hours decimal(10,2), @MEXSC_Hours decimal(10,2), @MIRSC_Hours decimal(10,2), @OTHER_Hours decimal(10,2), @HOUSC_Hours decimal(10,2), @MPHASIS_Onsite_Hours decimal(10,2), @MPHASIS_Offsite_Hours decimal(10,2), @HPINDIA_Hours decimal(10,2), @GCR_SYD_Hours decimal(10,2), @GCR_MEX_Hours decimal(10,2)
DECLARE @TotalHours decimal(10,2), @CurClient varchar(50), @CurType varchar(50), @CurProjectID uniqueidentifier, @CurProjectTitle varchar(100), @CurProjPct float, @CurHrsToDate float, @CurTaskID uniqueidentifier, @CurTaskName varchar(100), @CurTaskPct float, @CurResource varchar(100),@CurTaskFundedPct decimal (5,2)
DECLARE @MaxClient int, @MaxType int, @MaxProj bigint, @MaxTask int, @MaxResource int, @ProjectActualStartDate datetime, @SAPHours decimal(10,2), @SAPHours2 float, @onshore int, @offshore int

------------------------------------------------------------------------------------
--ClientGroup_Report: ----------------------------------------------------------------
------------------------------------------------------------------------------------
insert #TEMP_OUT (RecNumber, RecType, RecDesc)
select 10, 'ClientGroup', @ClientGroup
select @MaxClient = max(AutoKey) from #TEMP_OUT

---------------------------------------------------------------------------------------------------
-- Correct Percentage Summary of Co-Funded Projects for Client Group Report. Create temp table of distinct projects, co-funded carriers, and percentages.
-- If Percentage Summary > 100, then move 999 to @CurProjPct to indicate overflow. This indicates that the Co-Funding is done at the TASK level.
-- Unable to summarize percentages when CO-Funding is at the  TASK level. 
select distinct ProjectID,  ProjClientFundingPct, ProjClientFundedBy, TaskClientFundingPct, TaskClientFundedBy ,HrsToDate into #TEMP_PCT from #TEMP_IN

---------------------------------------------------------------------------------------------------- 
DECLARE Project_cursor CURSOR FOR 
	select distinct ProjectID, ProjectTitle from #TEMP_IN where ProjectTitle is not NULL order by ProjectTitle
OPEN Project_cursor
FETCH NEXT FROM Project_cursor INTO @CurProjectID, @CurProjectTitle
WHILE @@FETCH_STATUS = 0
BEGIN
	select @ProjectActualStartDate = ProjectActualStartDate from R2_IMPORT..ALL_PROJECT where ProjectUID = @CurProjectID
	 
	if @ProjectActualStartDate > @DateFrom
		set @ProjectActualStartDate = @DateFrom						

	select @SAPHours = sum(hours) from tblResourceDetail where projectid = @CurProjectID and workdate >= CONVERT(nvarchar(10), @ProjectActualStartDate, 112) and workdate <= CONVERT(nvarchar(10), @DateTo, 112)
	select @CurProjPct = sum(isnull(ProjClientFundingPct,0)), @CurHrsToDate = @SAPHours	from #TEMP_PCT where ProjectID = @CurProjectID group by HrsToDate

	If @CurProjPct > 100
		set @CurProjPct = 999 

	insert #TEMP_OUT (RecNumber, RecType, RecDesc, FundingPct,HrsToDate, R10_Client)
    select 30, 'Project/Total', @CurProjectTitle, @CurProjPct,@CurHrsToDate, @ClientGroup
    select @MaxProj = max(AutoKey) from #TEMP_OUT

	-----------------------------------------------------------------------------------------------------------------------
    DECLARE Resource_cursor CURSOR FOR
		select distinct ResourceName, Onshore, Offshore from #TEMP_IN where ProjectID = @CurProjectID order by ResourceName
    OPEN Resource_cursor
    FETCH NEXT FROM Resource_cursor INTO @CurResource, @onshore, @offshore
    WHILE @@FETCH_STATUS = 0
    BEGIN
		--changed
		set @SCSC_Hours = 0
		set @RDC_Hours = 0
		set @MEXSC_Hours = 0
		set @MIRSC_Hours = 0
		set @OTHER_Hours = 0
		set @HOUSC_Hours = 0				
		set @MPHASIS_Onsite_Hours = 0
		set @MPHASIS_Offsite_Hours = 0                
		set @HPINDIA_Hours = 0
		set @GCR_SYD_Hours = 0
		set @GCR_MEX_Hours = 0	

        select @SCSC_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'SOUTHERN CALIFORNIA SOLUTION CEN'
            
		select @RDC_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'RDC'
             
        select @MEXSC_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and (ResourceOrg like '%MEXICO%' or ResourceOrg like '%AD-MX%' ) and ResourceOrg <> 'GCR - MEXICO'
                
        select @MIRSC_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'MIRAMAR SOLUTION CENTRE'
                
        select @OTHER_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'OTHER'
                
        select @HOUSC_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'HOUSTON SOLUTION CENTRE'

        select @MPHASIS_Onsite_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'MPHASIS' and Onshore = 1

        select @MPHASIS_Offsite_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'MPHASIS' and Offshore = 1

        select @HPINDIA_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'HP INDIA'

        select @GCR_SYD_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'GCR - SYDNEY'
                
        select @GCR_MEX_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'GCR - MEXICO'            
             
        set @TotalHours = @SCSC_Hours + @RDC_Hours + @MEXSC_Hours + @MIRSC_Hours + @OTHER_Hours + @HOUSC_Hours + @MPHASIS_Onsite_Hours + @MPHASIS_Offsite_Hours + @HPINDIA_Hours + @GCR_SYD_Hours + @GCR_MEX_Hours 
        insert #TEMP_OUT (RecNumber, RecType, RecDesc, TotalHours, SCSC_Hours, RDC_Hours, MEXSC_Hours, MIRSC_Hours, OTHER_Hours, HOUSC_Hours, MPHASIS_Onsite_Hours, MPHASIS_Offsite_Hours, HPINDIA_Hours, GCR_SYD_Hours, GCR_MEX_Hours, R10_Client, R30_Project)
        
		select 50, 'Resource', @CurResource, @TotalHours, 
		@SCSC_Hours, @RDC_Hours, @MEXSC_Hours, @MIRSC_Hours, @OTHER_Hours, @HOUSC_Hours, @MPHASIS_Onsite_Hours, @MPHASIS_Offsite_Hours, @HPINDIA_Hours, @GCR_SYD_Hours, @GCR_MEX_Hours, @ClientGroup, @CurProjectTitle

	FETCH NEXT FROM Resource_cursor INTO @CurResource, @onshore, @offshore
    END    
    CLOSE Resource_cursor
    DEALLOCATE Resource_cursor

	-----------------------------------------------------------------------------------------------------------------------
    --changed
	set @SCSC_Hours = 0
	set @RDC_Hours = 0
	set @MEXSC_Hours = 0
	set @MIRSC_Hours = 0
	set @OTHER_Hours = 0
	set @HOUSC_Hours = 0				
	set @MPHASIS_Onsite_Hours = 0
	set @MPHASIS_Offsite_Hours = 0                
	set @HPINDIA_Hours = 0
	set @GCR_SYD_Hours = 0
	set @GCR_MEX_Hours = 0	
                
    select @SCSC_Hours = sum(isnull(SCSC_Hours,0)), @RDC_Hours = sum(isnull(RDC_Hours,0)), @MEXSC_Hours = sum(isnull(MEXSC_Hours,0)), @MIRSC_Hours = sum(isnull(MIRSC_Hours,0)), @OTHER_Hours = sum(isnull(OTHER_Hours,0)), @HOUSC_Hours = sum(isnull(HOUSC_Hours,0)), @MPHASIS_Onsite_Hours = sum(isnull(MPHASIS_Onsite_Hours,0)), @MPHASIS_Offsite_Hours = sum(isnull(MPHASIS_Offsite_Hours,0)), @HPINDIA_Hours = sum(isnull(HPINDIA_Hours,0)), @GCR_SYD_Hours = sum(isnull(GCR_SYD_Hours,0)), @GCR_MEX_Hours = sum(isnull(GCR_MEX_Hours,0)), @TotalHours = sum(isnull(TotalHours,0))
    from dbo.#TEMP_OUT where AutoKey > @MaxProj and RecNumber = 50
                
    update #TEMP_OUT set SCSC_Hours = @SCSC_Hours, RDC_Hours = @RDC_Hours, MEXSC_Hours = @MEXSC_Hours, MIRSC_Hours = @MIRSC_Hours, OTHER_Hours = @OTHER_Hours, HOUSC_Hours = @HOUSC_Hours, MPHASIS_Onsite_Hours = @MPHASIS_Onsite_Hours, MPHASIS_Offsite_Hours = @MPHASIS_Offsite_Hours, HPINDIA_Hours = @HPINDIA_Hours, GCR_SYD_Hours = @GCR_SYD_Hours, GCR_MEX_Hours = @GCR_MEX_Hours, TotalHours = @TotalHours
    where AutoKey = @MaxProj    
    
FETCH NEXT FROM Project_cursor INTO @CurProjectID, @CurProjectTitle
END
CLOSE Project_cursor
DEALLOCATE Project_cursor

---------------------------------------------------------------------------------------------------
 --changed
set @SCSC_Hours = 0
set @RDC_Hours = 0
set @MEXSC_Hours = 0
set @MIRSC_Hours = 0
set @OTHER_Hours = 0
set @HOUSC_Hours = 0				
set @MPHASIS_Onsite_Hours = 0
set @MPHASIS_Offsite_Hours = 0                
set @HPINDIA_Hours = 0
set @GCR_SYD_Hours = 0
set @GCR_MEX_Hours = 0	

select @SCSC_Hours = sum(isnull(SCSC_Hours,0)), @RDC_Hours = sum(isnull(RDC_Hours,0)), @MEXSC_Hours = sum(isnull(MEXSC_Hours,0)), @MIRSC_Hours = sum(isnull(MIRSC_Hours,0)), @OTHER_Hours = sum(isnull(OTHER_Hours,0)), @HOUSC_Hours = sum(isnull(HOUSC_Hours,0)), @MPHASIS_Onsite_Hours = sum(isnull(MPHASIS_Onsite_Hours,0)), @MPHASIS_Offsite_Hours = sum(isnull(MPHASIS_Offsite_Hours,0)), @HPINDIA_Hours = sum(isnull(HPINDIA_Hours,0)), @GCR_SYD_Hours = sum(isnull(GCR_SYD_Hours,0)), @GCR_MEX_Hours = sum(isnull(GCR_MEX_Hours,0)), @TotalHours = sum(isnull(TotalHours,0))
from dbo.#TEMP_OUT where AutoKey > @MaxClient and RecNumber = 30

update #TEMP_OUT set SCSC_Hours = @SCSC_Hours, RDC_Hours = @RDC_Hours, MEXSC_Hours = @MEXSC_Hours, MIRSC_Hours = @MIRSC_Hours, OTHER_Hours = @OTHER_Hours, HOUSC_Hours = @HOUSC_Hours, MPHASIS_Onsite_Hours = @MPHASIS_Onsite_Hours, MPHASIS_Offsite_Hours = @MPHASIS_Offsite_Hours, HPINDIA_Hours = @HPINDIA_Hours, GCR_SYD_Hours = @GCR_SYD_Hours, GCR_MEX_Hours = @GCR_MEX_Hours, TotalHours = @TotalHours
where AutoKey = @MaxClient or RecNumber = 0  

update #TEMP_OUT set SCSC_Hours = @SCSC_Hours/@FTE_Factor_SCSC, RDC_Hours = @RDC_Hours/@FTE_Factor_RDC, MEXSC_Hours = @MEXSC_Hours/@FTE_Factor_MEXSC, MIRSC_Hours = @MIRSC_Hours/@FTE_Factor_MIRSC, OTHER_Hours = @OTHER_Hours/@FTE_Factor_OTHER, HOUSC_Hours = @HOUSC_Hours/@FTE_Factor_HOUSC, MPHASIS_Onsite_Hours = @MPHASIS_Onsite_Hours/@FTE_Factor_INDIA, MPHASIS_Offsite_Hours = @MPHASIS_Offsite_Hours/@FTE_Factor_INDIA, HPINDIA_Hours = @HPINDIA_Hours/@FTE_Factor_INDIA, GCR_SYD_Hours = @GCR_SYD_Hours/@FTE_Factor_GCR_SYDNEY, GCR_MEX_Hours = @GCR_MEX_Hours/@FTE_Factor_GCR_MEXICO, 
TotalHours = @SCSC_Hours/@FTE_Factor_SCSC + @RDC_Hours/@FTE_Factor_RDC + @MEXSC_Hours/@FTE_Factor_MEXSC + @MIRSC_Hours/@FTE_Factor_MIRSC + @OTHER_Hours/@FTE_Factor_OTHER + @HOUSC_Hours/@FTE_Factor_HOUSC + @MPHASIS_Onsite_Hours/@FTE_Factor_INDIA + @MPHASIS_Offsite_Hours/@FTE_Factor_INDIA + @HPINDIA_Hours/@FTE_Factor_INDIA + @GCR_SYD_Hours/@FTE_Factor_GCR_SYDNEY + @GCR_MEX_Hours/@FTE_Factor_GCR_MEXICO 
where RecNumber = 5

Update #TEMP_OUT set SCSC_Hours = @FTE_Factor_SCSC, RDC_Hours = @FTE_Factor_RDC, MEXSC_Hours = @FTE_Factor_MEXSC, MIRSC_Hours = @FTE_Factor_MIRSC, OTHER_Hours = @FTE_Factor_OTHER, HOUSC_Hours = @FTE_Factor_HOUSC, MPHASIS_Onsite_Hours = @FTE_Factor_INDIA, MPHASIS_Offsite_Hours = @FTE_Factor_INDIA, HPINDIA_Hours = @FTE_Factor_INDIA, GCR_SYD_Hours = @FTE_Factor_GCR_SYDNEY, GCR_MEX_Hours = @FTE_Factor_GCR_MEXICO
where RecNumber = 7


----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

Select RecNumber, RecType, RecDesc, HrsToDate, FundingPct, TotalHours, SCSC_Hours, RDC_Hours, MEXSC_Hours, MIRSC_Hours, OTHER_Hours, HOUSC_Hours, MPHASIS_Onsite_Hours, MPHASIS_Offsite_Hours, HPINDIA_Hours, GCR_SYD_Hours, GCR_MEX_Hours, R10_Client, R30_Project
from #TEMP_OUT order by AutoKey



