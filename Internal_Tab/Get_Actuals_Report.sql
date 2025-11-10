--[Get_Actuals_Report] 
--(@DateFrom datetime = NULL, @DateTo datetime = NULL, @ClientGroup varchar(100) = NULL, @ClientList varchar(500) = '-1', @SummaryLevel varchar(30) = NULL, @ProductList varchar(500) = '-1', @OutputTable varchar(30) = NULL )

drop view [dbo].[SP_Get_AR_View]
drop table #TEMP_IN
drop table #TEMP_OUT
DROP table #TEMP_PCT

DECLARE @SQL_statement varchar(1400), @row_count int, @FTE_Factor  float, @FTE_Factor_SCSC float, @FTE_Factor_MEXSC float, @FTE_Factor_MIRSC float, @FTE_Factor_ESOL float, @FTE_Factor_HOUSC float, @FTE_Factor_GCR_CHENNAI float, @FTE_Factor_GCR_SYDNEY float, @FTE_Factor_GCR_MEXICO float, @CurFTEFactor  float,  @CurSolutionCentreCode  varchar(50)

set @SQL_statement = 'Create View dbo.SP_Get_AR_View AS select * from InternalBilling_View where and WorkDate >= ''2012-03-01'' and WorkDate <= ''2012-03-31'' and Hours > 0 '
exec (@SQL_statement)

select Client, ProjectID, ProjectTitle, TaskID, TaskName, ResourceName, WorkDate, ActualWork AS HrsToDate, ProjClientFundingPct, ProjClientFundedBy, TaskClientFundingPct, TaskClientFundedBy, ResourceOrg, Hours, Keyword
into #TEMP_IN from dbo.SP_Get_AR_View order by Client, ProjectID, ProjectTitle, TaskID, TaskName, ResourceName, WorkDate, ProjClientFundingPct, ProjClientFundedBy, TaskClientFundingPct, TaskClientFundedBy, ResourceOrg

ALTER TABLE #TEMP_IN ADD ID int IDENTITY(1,1) NOT NULL PRIMARY KEY 

delete T1 from #TEMP_IN T1, #TEMP_IN T2
where  T1.Client = 'Multiple' and
       T2.Client = 'Multiple' and
       T1.ProjectID = T2.ProjectID and
       T1.ProjectTitle = T2.ProjectTitle and 
       T1.TaskID = T1.TaskID and 
       T1.TaskName = T2.TaskName and
       T1.ResourceName = T2.ResourceName and
       T1.WorkDate = T2.WorkDate and
       T1.HrsToDate = T2.HrsToDate and
       T1.TaskClientFundingPct = T2.TaskClientFundingPct and
       T1.TaskClientFundedBy = T2.TaskClientFundedBy and
       T1.ResourceOrg = T2.ResourceOrg and
       T1.Hours = T2.Hours and
       T1.ID > T2.ID

-- Business Rule: Redefine to 8 ResourceOrg for reports
update #TEMP_IN set ResourceOrg = 'GCR - SYDNEY' where ResourceOrg = 'GCR - BSSC SYDNEY'
update #TEMP_IN set ResourceOrg = 'GCR - MEXICO' where ResourceOrg = 'GCR - AD-MX-JUAREZ ADU'

-- New Other Bucket set ResourceORG field to OTHER if not one of the fixed buckets
update #TEMP_IN set ResourceOrg = 'OTHER' where ResourceOrg not in ('SOUTHERN CALIFORNIA SOLUTION CEN', 'MIRAMAR SOLUTION CENTRE', 'HOUSTON SOLUTION CENTRE', 'GCR - SYDNEY', 'GCR - MEXICO', 'BSSC INDIA') AND (ResourceOrg not like '%MEXICO%') and ( ResourceOrg not like '%AD-MX%')

-- Adjust Hours by applying Funding Percentage. Business Rule: TaskClientFundingPct or ProjClientFundingPct > 0, not both
update #TEMP_IN set Hours = Hours * (TaskClientFundingPct/100) where TaskClientFundingPct is not NULL 

-- Set FTEFactors for the ClientGroup
select @FTE_Factor = FTEFactor from lkClientGroup where ClientGroup = @ClientGroup

-- 07/12/2005 Ne way of updating the Client Field for Multiple Clients...
Update #TEMP_IN set TaskClientFundedBy = 'PORT' where TaskClientFundedBy = 'POR'
Update #TEMP_IN set ProjClientFundingPct = TaskClientFundingPct where TaskClientFundingPct is Not NULL
Update #TEMP_IN set Client = 'Continental Airlines' where Client = 'Multiple' and TaskClientFundedBy Like 'CO%'
Update #TEMP_IN set Client = (Select Client from [PIV_Reports].dbo.lkClientGroupClientRef where ClientCode = TaskClientFundedBy) where Client = 'Multiple' and TaskClientFundedBy is Not NULL and TaskClientFundedBy Not Like 'CO%'

set @FTE_Factor_SCSC = 143.5
set @FTE_Factor_MEXSC = 143.5
set @FTE_Factor_MIRSC = 143.5
set @FTE_Factor_ESOL = 143.5
set @FTE_Factor_HOUSC = 143.5
set @FTE_Factor_GCR_CHENNAI = 143.5
set @FTE_Factor_GCR_SYDNEY = 143.5
set @FTE_Factor_GCR_MEXICO = 143.5

-- Set FTE Factors for ALL Solution Centres
set @FTE_Factor_SCSC = @FTE_Factor
set @FTE_Factor_MEXSC = @FTE_Factor
set @FTE_Factor_MIRSC = @FTE_Factor
set @FTE_Factor_ESOL = @FTE_Factor
set @FTE_Factor_HOUSC = @FTE_Factor
set @FTE_Factor_GCR_CHENNAI = @FTE_Factor
set @FTE_Factor_GCR_SYDNEY = @FTE_Factor
set @FTE_Factor_GCR_MEXICO = @FTE_Factor

-- Check if there are any FTE overrides for ClientGroup/Solution Centre reset FTE Factor
DECLARE FTEOverride_cursor CURSOR FOR 
    select FTEFactor,ResourceOrg from lkClientGroupFTEOverride where ClientGroup = @ClientGroup
OPEN FTEOverride_cursor
FETCH NEXT FROM FTEOverride_cursor INTO @CurFTEFactor, @CurSolutionCentreCode
	WHILE @@FETCH_STATUS = 0
	BEGIN
	IF @CurSolutionCentreCode = 'Southern California Solution Cen'
		set @FTE_Factor_SCSC = @CurFTEFactor
    	IF @CurSolutionCentreCode = 'Mexico City Solution Centre'
    	   	set @FTE_Factor_MEXSC = @CurFTEFactor
    	IF @CurSolutionCentreCode = 'Miramar Solution Centre'
    	  	set @FTE_Factor_MIRSC = @CurFTEFactor
    	IF @CurSolutionCentreCode = 'Houston Solution Centre'
    	    set @FTE_Factor_HOUSC = @CurFTEFactor
    	IF @CurSolutionCentreCode = 'BSSC India'
    	    set @FTE_Factor_GCR_Chennai = @CurFTEFactor
    	IF @CurSolutionCentreCode = 'GCR - Sydney Solution Centre'
    	    set @FTE_Factor_GCR_Sydney = @CurFTEFactor
    	IF @CurSolutionCentreCode in ( 'GCR - Mexico City Solution Centre','GCR - NORTHERN MEXICO SOLUTION CENTRE')
    	    set @FTE_Factor_GCR_Mexico = @CurFTEFactor
FETCH NEXT FROM FTEOverride_cursor INTO @CurFTEFactor, @CurSolutionCentreCode
END    
CLOSE FTEOverride_cursor
DEALLOCATE FTEOverride_cursor

----------------------------------------------------------------------------------
Create Index IDX1 on #TEMP_IN (Client, ProjectID, ResourceName, ResourceOrg)
Create Index IDX2 on #TEMP_IN (ProjectID, ResourceName, ResourceOrg)

CREATE TABLE [dbo].[#TEMP_OUT] (
	[AutoKey][int] IDENTITY (0, 1) NOT NULL,
	[RecNumber][int] NULL,          -- 0, 3, 6, 10, 20, 30, 40, 50, 55, 56, 60, 99
	[RecType] [varchar] (100) NULL, -- Client / Project / Resource
	[RecDesc] [varchar] (100) NULL, 
	[HrsToDate] [decimal](10,2) NULL,
	[FundingPct] [decimal](10,2) NULL,
	[TotalHours] [decimal](10,2) NULL,
	[C1_Hours] [decimal](10,2) NULL,  -- 1 SOUTHERN CALIFORNIA SOLUTION CEN - Keyword GCR
	[C2_Hours] [decimal](10,2) NULL,  -- 2 MEXICO CITY SOLUTION CENTRE - Keyword GCR
	[C3_Hours] [decimal](10,2) NULL,  -- 3 MIRAMAR SOLUTION CENTRE - Keyword GCR
	[C4_Hours] [decimal](10,2) NULL,  -- 4 OTHER Bucket new as of 12/16/2005
	[C5_Hours] [decimal](10,2) NULL,  -- 5 HOUSTON SOLUTION CENTRE - Keyword GCR
	[G1_Hours] [decimal](10,2) NULL,  -- 1 GCR Group = BSSC SYDNEY + Keyword GCR
	[G2_Hours] [decimal](10,2) NULL,  -- 2 GCR Group = MEXICO CITY SOLUTION CENTRE + Keyword GCR
	[G3_Hours] [decimal](10,2) NULL,  -- 3 GCR Group = CHENNAI SOLUTION CENTRE / BSSC India
	[R10_Client] [varchar] (100) NULL,
	[R30_Project] [varchar] (100) NULL
) ON [PRIMARY]


--------------------------------------------------------------------------------------------------------------
DECLARE @C1_Hours decimal(10,2), @C2_Hours decimal(10,2), @C3_Hours decimal(10,2), @C4_Hours decimal(10,2), @C5_Hours decimal(10,2), @G1_Hours decimal(10,2), @G2_Hours decimal(10,2), @G3_Hours decimal(10,2), @TotalHours decimal(10,2)
DECLARE @CurClient varchar(50), @CurType varchar(50), @CurProjectID uniqueidentifier, @CurProjectTitle varchar(100), @CurProjPct float, @CurHrsToDate float, @CurTaskID uniqueidentifier, @CurTaskName varchar(100), @CurTaskPct float, @CurResource varchar(100),@CurTaskFundedPct decimal (5,2)
DECLARE @MaxClient int, @MaxType int, @MaxProj bigint, @MaxTask int, @MaxResource int, @ProjectActualStartDate datetime, @SAPHours decimal(10,2), @SAPHours2 float

insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Grand Total'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'GrandTotal', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 7, 'GrandTotal', 'FTE Factors'


------------------------------------------------------------------------------------
--Client_Report: 
------------------------------------------------------------------------------------
DECLARE Client_cursor CURSOR FOR 
    select distinct Client from #TEMP_IN where Client is not NULL order by Client
OPEN Client_cursor
FETCH NEXT FROM Client_cursor INTO @CurClient
	WHILE @@FETCH_STATUS = 0
	BEGIN
		insert #TEMP_OUT (RecNumber) values (10)
		insert #TEMP_OUT (RecNumber, RecType, RecDesc)
   		select 10, 'Client/Total', @CurClient
        	select @MaxClient = max(AutoKey) from #TEMP_OUT
		insert #TEMP_OUT (RecNumber, RecType, RecDesc)
   		select 15, 'Client FTE/Total', 'FTE Conversion ' 

		---------------------------------------------------------------------------------------------------
    		DECLARE Project_cursor CURSOR FOR 
    			select distinct ProjectID, ProjectTitle from #TEMP_IN where Client = @CurClient and ProjectTitle is not NULL order by ProjectTitle
		OPEN Project_cursor
		FETCH NEXT FROM Project_cursor INTO @CurProjectID, @CurProjectTitle
		WHILE @@FETCH_STATUS = 0
        	BEGIN
                  	select @ProjectActualStartDate = ProjectActualStartDate from MSPS_IMPORT..ALL_PROJECT where ProjectUID = @CurProjectID 
			if @ProjectActualStartDate > @DateFrom
				set @ProjectActualStartDate = @DateFrom
			select @SAPHours = sum(hours) from piv_reports..tblResourceDetail where projectid = @CurProjectID and workdate >= CONVERT(nvarchar(10), @ProjectActualStartDate, 112) and workdate <= CONVERT(nvarchar(10), @DateTo, 112)
			select @CurProjPct = ProjClientFundingPct, @CurHrsToDate = @SAPHours from #TEMP_IN where ProjectID = @CurProjectID and Client = @CurClient
       			insert #TEMP_OUT (RecNumber, RecType, RecDesc, HrsToDate, FundingPct, R10_Client)
       			select 30, 'Project/Total', @CurProjectTitle, @CurHrsToDate, @CurProjPct, @CurClient
           		select @MaxProj = max(AutoKey) from #TEMP_OUT

			-----------------------------------------------------------------------------------------------------------------------
        		DECLARE Resource_cursor CURSOR FOR
           			select distinct ResourceName,TaskClientFundingPct from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID order by ResourceName
        		OPEN Resource_cursor
        		FETCH NEXT FROM Resource_cursor INTO @CurResource, @CurTaskFundedPct
        		WHILE @@FETCH_STATUS = 0
            		BEGIN
				set @C1_Hours = 0
                		set @C2_Hours = 0
                		set @C3_Hours = 0
                		set @C4_Hours = 0
                		set @C5_Hours = 0
                		set @G1_Hours = 0
                		set @G2_Hours = 0
                		set @G3_Hours = 0
                
				-- sum up is done in the #TEMP_IN already
                		select @C1_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
		                and ResourceOrg = 'SOUTHERN CALIFORNIA SOLUTION CEN'
                
                		select @C2_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
                		and (ResourceOrg like '%MEXICO%' or ResourceOrg like '%AD-MX%' ) and ResourceOrg <> 'GCR - MEXICO'
                	
                		select @C3_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
                		and ResourceOrg = 'MIRAMAR SOLUTION CENTRE'
                
                		select @C4_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
                		and ResourceOrg = 'OTHER'
                
                		select @C5_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
                		and ResourceOrg = 'HOUSTON SOLUTION CENTRE'
                
                		select @G1_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
                		and ResourceOrg = 'GCR - SYDNEY'
                
                		select @G2_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
                		and ResourceOrg = 'GCR - MEXICO'
                
                		select @G3_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
                		and ResourceOrg = 'BSSC India'
                
                		set @TotalHours = @C1_Hours + @C2_Hours + @C3_Hours + @C4_Hours + @C5_Hours + @G1_Hours + @G2_Hours + @G3_Hours
                		insert #TEMP_OUT (RecNumber, RecType, RecDesc,FundingPct, TotalHours, C1_Hours, C2_Hours, C3_Hours, C4_Hours, C5_Hours, G1_Hours, G2_Hours, G3_Hours, R10_Client, R30_Project)
                		select 50, 'Resource', @CurResource, @CurTaskFundedPct,@TotalHours, @C1_Hours, @C2_Hours, @C3_Hours, @C4_Hours, @C5_Hours, @G1_Hours, @G2_Hours, @G3_Hours, @CurClient, @CurProjectTitle
	      		FETCH NEXT FROM Resource_cursor INTO @CurResource, @CurTaskFundedPct
        	 	END    
            		CLOSE Resource_cursor
            		DEALLOCATE Resource_cursor

			-----------------------------------------------------------------------------------------------------------------------
            set @C1_Hours = 0
            set @C2_Hours = 0
            set @C3_Hours = 0
            set @C4_Hours = 0
            set @C5_Hours = 0
            set @G1_Hours = 0
            set @G2_Hours = 0
            set @G3_Hours = 0
                
            select  @C1_Hours = sum(isnull(C1_Hours,0)), @C2_Hours = sum(isnull(C2_Hours,0)), @C3_Hours = sum(isnull(C3_Hours,0)), @C4_Hours = sum(isnull(C4_Hours,0)), @C5_Hours = sum(isnull(C5_Hours,0)), @G1_Hours = sum(isnull(G1_Hours,0)), @G2_Hours = sum(isnull(G2_Hours,0)), @G3_Hours = sum(isnull(G3_Hours,0)), @TotalHours = sum(isnull(TotalHours,0))
            from dbo.#TEMP_OUT where AutoKey > @MaxProj and RecNumber = 50
                
            update #TEMP_OUT set C1_Hours = @C1_Hours, C2_Hours = @C2_Hours, C3_Hours = @C3_Hours, C4_Hours = @C4_Hours, C5_Hours = @C5_Hours, G1_Hours = @G1_Hours, G2_Hours = @G2_Hours, G3_Hours = @G3_Hours, TotalHours = @TotalHours
            where AutoKey = @MaxProj
		FETCH NEXT FROM Project_cursor INTO @CurProjectID, @CurProjectTitle
        END
        CLOSE Project_cursor
        DEALLOCATE Project_cursor

	---------------------------------------------------------------------------------------------------
    set @C1_Hours = 0
    set @C2_Hours = 0
    set @C3_Hours = 0
    set @C4_Hours = 0
    set @C5_Hours = 0
    set @G1_Hours = 0
    set @G2_Hours = 0
    set @G3_Hours = 0

    select @C1_Hours = sum(isnull(C1_Hours,0)), @C2_Hours = sum(isnull(C2_Hours,0)), @C3_Hours = sum(isnull(C3_Hours,0)), @C4_Hours = sum(isnull(C4_Hours,0)), @C5_Hours = sum(isnull(C5_Hours,0)), @G1_Hours = sum(isnull(G1_Hours,0)), @G2_Hours = sum(isnull(G2_Hours,0)), @G3_Hours = sum(isnull(G3_Hours,0)), @TotalHours = sum(isnull(TotalHours,0))
    from dbo.#TEMP_OUT where AutoKey > @MaxClient and RecNumber = 30

    update #TEMP_OUT set C1_Hours = @C1_Hours, C2_Hours = @C2_Hours, C3_Hours = @C3_Hours, C4_Hours = @C4_Hours, C5_Hours = @C5_Hours, G1_Hours = @G1_Hours, G2_Hours = @G2_Hours, G3_Hours = @G3_Hours, TotalHours = @TotalHours
    where AutoKey = @MaxClient

    update #TEMP_OUT set C1_Hours = @C1_Hours/@FTE_Factor_SCSC, C2_Hours = @C2_Hours/@FTE_Factor_MEXSC, C3_Hours = @C3_Hours/@FTE_Factor_MIRSC, C4_Hours = @C4_Hours/@FTE_Factor_ESOL, C5_Hours = @C5_Hours/@FTE_Factor_HOUSC, G1_Hours = @G1_Hours/@FTE_Factor_GCR_SYDNEY, G2_Hours = @G2_Hours/@FTE_Factor_GCR_MEXICO, G3_Hours = @G3_Hours/@FTE_Factor_GCR_CHENNAI, TotalHours = @C1_Hours/@FTE_Factor_SCSC + @C2_Hours/@FTE_Factor_MEXSC + @C3_Hours/@FTE_Factor_MIRSC + @C4_Hours/@FTE_Factor_ESOL + @C5_Hours/@FTE_Factor_HOUSC + @G1_Hours/@FTE_Factor_GCR_SYDNEY + @G2_Hours/@FTE_Factor_GCR_MEXICO + @G3_Hours/@FTE_Factor_GCR_CHENNAI
    where AutoKey > @MaxClient and RecNumber = 15
FETCH NEXT FROM Client_cursor INTO @CurClient
END
CLOSE Client_cursor
DEALLOCATE Client_cursor

---------------------------------------------------------------------------------------------------
select @C1_Hours = sum(isnull(C1_Hours,0)), @C2_Hours = sum(isnull(C2_Hours,0)), @C3_Hours = sum(isnull(C3_Hours,0)), @C4_Hours = sum(isnull(C4_Hours,0)), @C5_Hours = sum(isnull(C5_Hours,0)), @G1_Hours = sum(isnull(G1_Hours,0)), @G2_Hours = sum(isnull(G2_Hours,0)), @G3_Hours = sum(isnull(G3_Hours,0)), @TotalHours = sum(isnull(TotalHours,0))
from dbo.#TEMP_OUT where RecNumber = 10

update #TEMP_OUT set C1_Hours = @C1_Hours, C2_Hours = @C2_Hours, C3_Hours = @C3_Hours, C4_Hours = @C4_Hours, C5_Hours = @C5_Hours, G1_Hours = @G1_Hours, G2_Hours = @G2_Hours, G3_Hours = @G3_Hours, TotalHours = @TotalHours
where RecNumber = 0

update #TEMP_OUT set C1_Hours = @C1_Hours/@FTE_Factor_SCSC, C2_Hours = @C2_Hours/@FTE_Factor_MEXSC, C3_Hours = @C3_Hours/@FTE_Factor_MIRSC, C4_Hours = @C4_Hours/@FTE_Factor_ESOL, C5_Hours = @C5_Hours/@FTE_Factor_HOUSC, G1_Hours = @G1_Hours/@FTE_Factor_GCR_SYDNEY, G2_Hours = @G2_Hours/@FTE_Factor_GCR_MEXICO, G3_Hours = @G3_Hours/@FTE_Factor_GCR_CHENNAI, TotalHours = @C1_Hours/@FTE_Factor_SCSC + @C2_Hours/@FTE_Factor_MEXSC + @C3_Hours/@FTE_Factor_MIRSC + @C4_Hours/@FTE_Factor_ESOL + @C5_Hours/@FTE_Factor_HOUSC + @G1_Hours/@FTE_Factor_GCR_SYDNEY + @G2_Hours/@FTE_Factor_GCR_MEXICO + @G3_Hours/@FTE_Factor_GCR_CHENNAI
where RecNumber = 5

Update #TEMP_OUT set C1_Hours = @FTE_Factor_SCSC, C2_Hours = @FTE_Factor_MEXSC, C3_Hours = @FTE_Factor_MIRSC, C4_Hours = @FTE_Factor_ESOL, C5_Hours = @FTE_Factor_HOUSC, G1_Hours = @FTE_Factor_GCR_SYDNEY, G2_Hours = @FTE_Factor_GCR_MEXICO, G3_Hours = @FTE_Factor_GCR_CHENNAI
where RecNumber = 7

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
ClientGroup_Report: 
------------------------------------------------------------------------------------

insert #TEMP_OUT (RecNumber, RecType, RecDesc)
select 10, 'ClientGroup', @ClientGroup
select @MaxClient = max(AutoKey) from #TEMP_OUT

-- Correct Percentage Summary of Co-Funded Projects for Client Group Report. If Percentage Summary > 100, then move 999 to @CurProjPct to indicate overflow. This indicates that the Co-Funding is done at the TASK level.
select distinct ProjectID,  ProjClientFundingPct, ProjClientFundedBy, TaskClientFundingPct, TaskClientFundedBy ,HrsToDate
into #TEMP_PCT from #TEMP_IN

---------------------------------------------------------------------------------------------------- 
DECLARE Project_cursor CURSOR FOR 
	select distinct ProjectID, ProjectTitle from #TEMP_IN where ProjectTitle is not NULL order by ProjectTitle
OPEN Project_cursor
FETCH NEXT FROM Project_cursor INTO @CurProjectID, @CurProjectTitle
WHILE @@FETCH_STATUS = 0
BEGIN
	select @ProjectActualStartDate = ProjectActualStartDate from MSPS_IMPORT..ALL_PROJECT where ProjectUID = @CurProjectID 
	if @ProjectActualStartDate > @DateFrom
		set @ProjectActualStartDate = @DateFrom						
	select @SAPHours = sum(hours) from piv_reports..tblResourceDetail where projectid = @CurProjectID and workdate >= CONVERT(nvarchar(10), @ProjectActualStartDate, 112) and workdate <= CONVERT(nvarchar(10), @DateTo, 112)
	select @CurProjPct = sum(isnull(ProjClientFundingPct,0)), @CurHrsToDate = @SAPHours	from #TEMP_PCT where ProjectID = @CurProjectID group by HrsToDate

	If @CurProjPct > 100
		set @CurProjPct = 999 

	insert #TEMP_OUT (RecNumber, RecType, RecDesc, FundingPct,HrsToDate, R10_Client)
    	select 30, 'Project/Total', @CurProjectTitle, @CurProjPct,@CurHrsToDate, @ClientGroup
    	select @MaxProj = max(AutoKey) from #TEMP_OUT

	-----------------------------------------------------------------------------------------------------------------------
    	DECLARE Resource_cursor CURSOR FOR
		select distinct ResourceName from #TEMP_IN where ProjectID = @CurProjectID order by ResourceName
    	OPEN Resource_cursor
    	FETCH NEXT FROM Resource_cursor INTO @CurResource
    	WHILE @@FETCH_STATUS = 0
    	BEGIN
		set @C1_Hours = 0
        	set @C2_Hours = 0
        	set @C3_Hours = 0
        	set @C4_Hours = 0
        	set @C5_Hours = 0
        	set @G1_Hours = 0
        	set @G2_Hours = 0
        	set @G3_Hours = 0
                
        -- sum up is done in the #TEMP_IN already
        select @C1_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'SOUTHERN CALIFORNIA SOLUTION CEN'
                
        select @C2_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and (ResourceOrg like '%MEXICO%' or ResourceOrg like '%AD-MX%' ) and ResourceOrg <> 'GCR - MEXICO'
                
        select @C3_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'MIRAMAR SOLUTION CENTRE'
                
        select @C4_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'OTHER'
                
        select @C5_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'HOUSTON SOLUTION CENTRE'

        select @G1_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'GCR - SYDNEY'
                
        select @G2_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'GCR - MEXICO'
                
        select @G3_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
        and ResourceOrg = 'BSSC India'
                
        set @TotalHours = @C1_Hours + @C2_Hours + @C3_Hours + @C4_Hours + @C5_Hours + @G1_Hours + @G2_Hours + @G3_Hours 
        insert #TEMP_OUT (RecNumber, RecType, RecDesc, TotalHours, C1_Hours, C2_Hours, C3_Hours, C4_Hours, C5_Hours, G1_Hours, G2_Hours, G3_Hours, R10_Client, R30_Project)
        select 50, 'Resource', @CurResource, @TotalHours, @C1_Hours, @C2_Hours, @C3_Hours, @C4_Hours, @C5_Hours, @G1_Hours, @G2_Hours, @G3_Hours, @ClientGroup, @CurProjectTitle
	FETCH NEXT FROM Resource_cursor INTO @CurResource
    END    
    CLOSE Resource_cursor
    DEALLOCATE Resource_cursor

	-----------------------------------------------------------------------------------------------------------------------
    set @C1_Hours = 0
    set @C2_Hours = 0
    set @C3_Hours = 0
    set @C4_Hours = 0
    set @C5_Hours = 0
    set @G1_Hours = 0
    set @G2_Hours = 0
    set @G3_Hours = 0
                
    select @C1_Hours = sum(isnull(C1_Hours,0)), @C2_Hours = sum(isnull(C2_Hours,0)), @C3_Hours = sum(isnull(C3_Hours,0)), @C4_Hours = sum(isnull(C4_Hours,0)), @C5_Hours = sum(isnull(C5_Hours,0)), @G1_Hours = sum(isnull(G1_Hours,0)), @G2_Hours = sum(isnull(G2_Hours,0)), @G3_Hours = sum(isnull(G3_Hours,0)), @TotalHours = sum(isnull(TotalHours,0))
    from dbo.#TEMP_OUT where AutoKey > @MaxProj and RecNumber = 50
                
    update #TEMP_OUT set C1_Hours = @C1_Hours, C2_Hours = @C2_Hours, C3_Hours = @C3_Hours, C4_Hours = @C4_Hours, C5_Hours = @C5_Hours, G1_Hours = @G1_Hours, G2_Hours = @G2_Hours, G3_Hours = @G3_Hours, TotalHours = @TotalHours
    where AutoKey = @MaxProj
FETCH NEXT FROM Project_cursor INTO @CurProjectID, @CurProjectTitle
END
CLOSE Project_cursor
DEALLOCATE Project_cursor

---------------------------------------------------------------------------------------------------
set @C1_Hours = 0
set @C2_Hours = 0
set @C3_Hours = 0
set @C4_Hours = 0
set @C5_Hours = 0
set @G1_Hours = 0
set @G2_Hours = 0
set @G3_Hours = 0

select @C1_Hours = sum(isnull(C1_Hours,0)), @C2_Hours = sum(isnull(C2_Hours,0)), @C3_Hours = sum(isnull(C3_Hours,0)), @C4_Hours = sum(isnull(C4_Hours,0)), @C5_Hours = sum(isnull(C5_Hours,0)), @G1_Hours = sum(isnull(G1_Hours,0)), @G2_Hours = sum(isnull(G2_Hours,0)), @G3_Hours = sum(isnull(G3_Hours,0)), @TotalHours = sum(isnull(TotalHours,0))
from dbo.#TEMP_OUT where AutoKey > @MaxClient and RecNumber = 30

update #TEMP_OUT set C1_Hours = @C1_Hours, C2_Hours = @C2_Hours, C3_Hours = @C3_Hours, C4_Hours = @C4_Hours, C5_Hours = @C5_Hours, G1_Hours = @G1_Hours, G2_Hours = @G2_Hours, G3_Hours = @G3_Hours, TotalHours = @TotalHours
where AutoKey = @MaxClient or RecNumber = 0  

update #TEMP_OUT set C1_Hours = @C1_Hours/@FTE_Factor_SCSC, C2_Hours = @C2_Hours/@FTE_Factor_MEXSC, C3_Hours = @C3_Hours/@FTE_Factor_MIRSC, C4_Hours = @C4_Hours/@FTE_Factor_ESOL, C5_Hours = @C5_Hours/@FTE_Factor_HOUSC, G1_Hours = @G1_Hours/@FTE_Factor_GCR_SYDNEY, G2_Hours = @G2_Hours/@FTE_Factor_GCR_MEXICO, G3_Hours = @G3_Hours/@FTE_Factor_GCR_CHENNAI, TotalHours = @C1_Hours/@FTE_Factor_SCSC + @C2_Hours/@FTE_Factor_MEXSC + @C3_Hours/@FTE_Factor_MIRSC + @C4_Hours/@FTE_Factor_ESOL + @C5_Hours/@FTE_Factor_HOUSC + @G1_Hours/@FTE_Factor_GCR_SYDNEY + @G2_Hours/@FTE_Factor_GCR_MEXICO + @G3_Hours/@FTE_Factor_GCR_CHENNAI
where RecNumber = 5

Update #TEMP_OUT set C1_Hours = @FTE_Factor_SCSC, C2_Hours = @FTE_Factor_MEXSC, C3_Hours = @FTE_Factor_MIRSC, C4_Hours = @FTE_Factor_ESOL, C5_Hours = @FTE_Factor_HOUSC, G1_Hours = @FTE_Factor_GCR_SYDNEY, G2_Hours = @FTE_Factor_GCR_MEXICO, G3_Hours = @FTE_Factor_GCR_CHENNAI
where RecNumber = 7

----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

Select RecNumber, RecType, RecDesc, HrsToDate, FundingPct, TotalHours, C1_Hours, C2_Hours, C3_Hours, C4_Hours, C5_Hours, G1_Hours, G2_Hours, G3_Hours, R10_Client, R30_Project
--SELECT *
from #TEMP_OUT order by AutoKey



