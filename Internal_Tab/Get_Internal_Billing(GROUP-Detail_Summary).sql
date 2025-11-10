---PROCEDURE [dbo].[Get_Internal_Billing] (@DateFrom datetime = NULL, @DateTo datetime = NULL, @ClientGroup varchar(100) = NULL, @ClientList varchar(500) = '-1', @ProjectType varchar(100) = '-1', @SummaryLevel varchar(30) = NULL, @ProductList varchar(500) = '-1', @OutputTable varchar(30) = NULL )
--GROUP REPORT (Detail and Summary)

drop view [dbo].[SP_Get_CB_View]
drop table #TEMP_IN
drop table #TEMP_OUT

DECLARE @SQL_statement varchar(1400)
set @SQL_statement = 'Create View dbo.SP_Get_CB_View AS select * from InternalBilling_View 
where WorkDate >= ''2013-10-01'' and WorkDate <= ''2013-10-31'' and Hours > 0'
exec (@SQL_statement)

select Client, Type, ProjectID, ProjectTitle, TaskID, TaskName, ResourceName, WorkDate, ProjClientFundingPct, ProjClientFundedBy, TaskClientFundingPct, TaskClientFundedBy, ResourceOrg, ResourceOrg AS ResourceOrgRate, JobCode, Hours AS BillingRate, Hours, Keyword, Onshore, Offshore
into #TEMP_IN from dbo.SP_Get_CB_View order by Client, Type, ProjectID, ProjectTitle, TaskID, TaskName, ResourceName, WorkDate, ProjClientFundingPct, ProjClientFundedBy, TaskClientFundingPct, TaskClientFundedBy, ResourceOrg

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
       T1.TaskClientFundingPct = T2.TaskClientFundingPct and
       T1.TaskClientFundedBy = T2.TaskClientFundedBy and
       T1.ResourceOrg = T2.ResourceOrg and
       T1.Hours = T2.Hours and
       T1.ID > T2.ID

-- Business Rule: Redefine to 8 ResourceOrg for reports
update #TEMP_IN set ResourceOrg = 'GCR - SYDNEY' where ResourceOrg like '%SYDNEY%'
update #TEMP_IN set ResourceOrg = 'GCR - MEXICO' where ResourceOrg = 'GCR - AD-MX-JUAREZ ADU'
update #TEMP_IN set ResourceOrg = 'MPHASIS' where ResourceOrg = 'BSSC INDIA'	

-- update resource org for Mexico solution center 
update #TEMP_IN set ResourceOrg = 'MEXICO CITY SOLUTION CENTRE' where (ResourceOrg like '%MEXICO%' or ResourceOrg like '%AD-MX%' ) and ResourceOrg <> 'GCR - MEXICO'

-- New Other Bucket set ResourceORG field to OTHER if not one of the fixed buckets  12/20/2005
update #TEMP_IN set ResourceOrg = 'OTHER'
where ResourceOrg not in ('SOUTHERN CALIFORNIA SOLUTION CEN', 'MIRAMAR SOLUTION CENTRE', 'HOUSTON SOLUTION CENTRE', 'GCR - SYDNEY', 'GCR - MEXICO', 'MPHASIS', 'HP INDIA') AND ResourceOrg not like '%MEXICO%'

-- Reset the values
update #TEMP_IN set BillingRate = 0  

-- Adjust Hours by applying Funding Percentage, Business Rule: TaskClientFundingPct or ProjClientFundingPct > 0, not both
update #TEMP_IN set Hours = Hours * (TaskClientFundingPct/100) where TaskClientFundingPct is not NULL 

-- New way of updating the Client Field for Multiple Clients...
Update #TEMP_IN set TaskClientFundedBy = 'PORT' where TaskClientFundedBy = 'POR'
Update #TEMP_IN set ProjClientFundingPct = TaskClientFundingPct where ProjClientFundingPct = NULL and TaskClientFundingPct is Not NULL
Update #TEMP_IN set Client = 'Continental Airlines' where Client = 'Multiple' and TaskClientFundedBy Like 'CO%'
Update #TEMP_IN set Client = (Select Client from [PIV_Reports].dbo.lkClientGroupClientRef where ClientCode = TaskClientFundedBy) where Client = 'Multiple' and TaskClientFundedBy is Not NULL and TaskClientFundedBy Not Like 'CO%'

------------------------------------------------------------------------------------------------
Create Index IDX1 on #TEMP_IN (Client, Type, ProjectID, TaskID, ResourceName, ResourceOrg)
Create Index IDX2 on #TEMP_IN (Type, ProjectID, TaskID, ResourceName, ResourceOrg)

CREATE TABLE [dbo].[#TEMP_OUT] (
	[AutoKey][int] IDENTITY (0, 1) NOT NULL,
	[RecNumber][int] NULL,          -- 0, 3, 6, 10, 20, 30, 40, 50, 55, 56, 60, 99
	[RecType] [varchar] (100) NULL, -- Client / Type / Project / Task / Resource
	[RecDesc] [varchar] (100) NULL, -- PIV Data
	[FundingPct] [decimal](10,2) NULL,
	[TotalHours] [decimal](10,2) NULL,
	[C1_Hours] [decimal](10,2) NULL,  -- 1 SOUTHERN CALIFORNIA SOLUTION CEN - Keyword GCR
	[C2_Hours] [decimal](10,2) NULL,  -- 2 MEXICO CITY SOLUTION CENTRE - Keyword GCR
	[C3_Hours] [decimal](10,2) NULL,  -- 3 MIRAMAR SOLUTION CENTRE - Keyword GCR
	[C4_Hours] [decimal](10,2) NULL,  -- 4 OTHER Bucket
	[C5_Hours] [decimal](10,2) NULL,  -- 5 HOUSTON SOLUTION CENTRE - Keyword GCR
	[C6_Onsite_Hours] [decimal](10,2) NULL,  -- 6 MPHASIS 
	[C6_Offsite_Hours] [decimal](10,2) NULL,  -- 6 MPHASIS
	[C7_Hours] [decimal](10,2) NULL,  -- 7 HP INDIA - Keyword GCR
	[G1_Hours] [decimal](10,2) NULL,  -- 1 GCR Group = SYDNEY SOLUTION CENTRE + Keyword GCR
	[G2_Hours] [decimal](10,2) NULL,  -- 2 GCR Group = MEXICO CITY SOLUTION CENTRE + Keyword GCR
    [Billed] [decimal](10,2) NULL, 
	[R10_Client] [varchar] (100) NULL,
	[R20_Type] [varchar] (100) NULL,
	[R30_Project] [varchar] (100) NULL,
	[R40_Task] [varchar] (100) NULL
) ON [PRIMARY]

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
declare @ClientGroup varchar(100), @ProjectType varchar(100)
SET @ProjectType = '-1' --DETAIL REPORT
--SET @ProjectType = '0' --SUMMARY REPORT

-- Set FTEFactor for this report
declare @FTE_Factor float, @FTE_Factor_SCSC float, @FTE_Factor_MEXSC float, @FTE_Factor_MIRSC float, @FTE_Factor_ESOL float, @FTE_Factor_HOUSC float, @FTE_Factor_GCR_SYDNEY float, @FTE_Factor_GCR_MEXICO float, @FTE_Factor_INDIA float, @CurFTEFactor  float, @CurSolutionCentreCode  varchar(50)
set @FTE_Factor = 143.5
set @FTE_Factor_SCSC = 143.5
set @FTE_Factor_MEXSC = 143.5
set @FTE_Factor_MIRSC = 143.5
set @FTE_Factor_ESOL = 143.5
set @FTE_Factor_HOUSC = 143.5
set @FTE_Factor_INDIA = 143.5   
set @FTE_Factor_GCR_SYDNEY = 143.5
set @FTE_Factor_GCR_MEXICO = 143.5
select @FTE_Factor = FTEFactor from lkClientGroup where ClientGroup = @ClientGroup

-- Set FTE Factors for ALL Solution Centres
set @FTE_Factor_SCSC = @FTE_Factor
set @FTE_Factor_MEXSC = @FTE_Factor
set @FTE_Factor_MIRSC = @FTE_Factor
set @FTE_Factor_ESOL = @FTE_Factor
set @FTE_Factor_HOUSC = @FTE_Factor
set @FTE_Factor_INDIA = @FTE_Factor
set @FTE_Factor_GCR_SYDNEY = @FTE_Factor
set @FTE_Factor_GCR_MEXICO = @FTE_Factor

-- Check if there are any FTE overrides for ClientGroup/Solution Centre reset FTE Factor
DECLARE FTEOverride_cursor CURSOR FOR 
    select FTEFactor,ResourceOrg from lkClientGroupFTEOverride where ClientGroup = @ClientGroup
OPEN FTEOverride_cursor
FETCH NEXT FROM FTEOverride_cursor INTO @CurFTEFactor, @CurSolutionCentreCode
	WHILE @@FETCH_STATUS = 0
	BEGIN
	IF @CurSolutionCentreCode = 'SOUTHERN CALIFORNIA SOLUTION CEN'
		set @FTE_Factor_SCSC = @CurFTEFactor
    IF @CurSolutionCentreCode = 'MEXICO CITY SOLUTION CENTRE'
		set @FTE_Factor_MEXSC = @CurFTEFactor
    IF @CurSolutionCentreCode = 'MIRAMAR SOLUTION CENTRE'
        set @FTE_Factor_MIRSC = @CurFTEFactor
    IF @CurSolutionCentreCode = 'HOUSTON SOLUTION CENTRE'
        set @FTE_Factor_HOUSC = @CurFTEFactor
    IF @CurSolutionCentreCode = 'BSSC SYDNEY'
		set @FTE_Factor_GCR_Sydney = @CurFTEFactor
    IF @CurSolutionCentreCode in ( 'GCR - Mexico City Solution Centre','GCR - NORTHERN MEXICO SOLUTION CENTRE')
        set @FTE_Factor_GCR_Mexico = @CurFTEFactor
    IF @CurSolutionCentreCode in ('MPHASIS', 'HP INDIA')
        set @FTE_Factor_INDIA = @CurFTEFactor
FETCH NEXT FROM FTEOverride_cursor INTO @CurFTEFactor, @CurSolutionCentreCode
END    
CLOSE FTEOverride_cursor
DEALLOCATE FTEOverride_cursor

-- Update routine for individual FTE factors 
update a set a.BillingRate = b.BillingRate/@FTE_Factor_SCSC from #TEMP_IN a, lkBillingRateJobCode b
where a.ResourceOrgRate =  b.ResourceOrg and a.JobCode = b.EDSJobCode and a.ResourceOrg = 'SOUTHERN CALIFORNIA SOLUTION CEN'

update a set a.BillingRate = b.BillingRate/@FTE_Factor_MEXSC from #TEMP_IN a, lkBillingRateJobCode b
where a.ResourceOrgRate =  b.ResourceOrg and a.JobCode = b.EDSJobCode and a.ResourceOrg = 'MEXICO CITY SOLUTION CENTRE' 

update a set a.BillingRate = b.BillingRate/@FTE_Factor_MIRSC from #TEMP_IN a, lkBillingRateJobCode b
where a.ResourceOrgRate =  b.ResourceOrg and a.JobCode = b.EDSJobCode and a.ResourceOrg = 'MIRAMAR SOLUTION CENTRE'

update a set a.BillingRate = b.BillingRate/@FTE_Factor_ESOL from #TEMP_IN a, lkBillingRateJobCode b
where a.ResourceOrgRate =  b.ResourceOrg and a.JobCode = b.EDSJobCode and a.ResourceOrg = 'OTHER'

update a set a.BillingRate = b.BillingRate/@FTE_Factor_HOUSC from #TEMP_IN a, lkBillingRateJobCode b
where a.ResourceOrgRate =  b.ResourceOrg and a.JobCode = b.EDSJobCode and a.ResourceOrg = 'HOUSTON SOLUTION CENTRE'

update a set a.BillingRate = b.BillingRate/@FTE_Factor_GCR_SYDNEY from #TEMP_IN a, lkBillingRateJobCode b
where a.ResourceOrgRate =  b.ResourceOrg and a.JobCode = b.EDSJobCode and a.ResourceOrg = 'GCR - SYDNEY'

update a set a.BillingRate = b.BillingRate/@FTE_Factor_GCR_MEXICO from #TEMP_IN a, lkBillingRateJobCode b
where a.ResourceOrgRate =  b.ResourceOrg and a.JobCode = b.EDSJobCode and a.ResourceOrg = 'GCR - MEXICO'

update a set a.BillingRate = b.BillingRate/@FTE_Factor_INDIA from #TEMP_IN a, lkBillingRateJobCode b
where a.ResourceOrgRate =  b.ResourceOrg and a.JobCode = b.EDSJobCode and a.ResourceOrg = 'MPHASIS'

update a set a.BillingRate = b.BillingRate/@FTE_Factor_INDIA from #TEMP_IN a, lkBillingRateJobCode b
where a.ResourceOrgRate =  b.ResourceOrg and a.JobCode = b.EDSJobCode and a.ResourceOrg = 'HP INDIA'

------------------------------------------------------------------------------------
----ClientGroup_Report: (DETAIL and SUMMARY)
------------------------------------------------------------------------------------
DECLARE @C1_Hours decimal(10,2), @C2_Hours decimal(10,2), @C3_Hours decimal(10,2), @C4_Hours decimal(10,2), @C5_Hours decimal(10,2), @C6_Onsite_Hours decimal(10,2), @C6_Offsite_Hours decimal(10,2), @C7_Hours decimal(10,2), @G1_Hours decimal(10,2), @G2_Hours decimal(10,2), @TotalHours decimal(10,2), @Billed decimal(10,2)
DECLARE @CurClient varchar(50), @CurType varchar(50), @CurProjectID uniqueidentifier, @CurProjectTitle varchar(100), @CurProjPct float, @CurTaskID uniqueidentifier, @CurTaskName varchar(100), @CurTaskPct float, @CurResource varchar(100), @CurRate float
DECLARE @MaxClient int, @MaxType int, @MaxProj bigint, @MaxTask int, @MaxResource int, @onshore int, @offshore int

insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Grand Total'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'GrandTotal', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 7, 'GrandTotal', 'FTE Factors'

insert #TEMP_OUT (RecNumber, RecType, RecDesc)
select 10, 'ClientGroup', @ClientGroup
select @MaxClient = max(AutoKey) from #TEMP_OUT

---------------------------------------------------------------------------------------------------
-- 8/10/2005 Correct Percentage Summary of Co-Funded Projects for Client Group Report
-- Create temp table of distinct projects, co-funded carriers, and percentages
-- If Percentage Summary > 100, then move 999 to @CurProjPct to indicate overflow. This indicates that the Co-Funding is done at the TASK level.
-- Unable to summarize percentages when CO-Funding is at the  TASK level. 
select distinct ProjectID,  ProjClientFundingPct, ProjClientFundedBy, TaskClientFundingPct, TaskClientFundedBy , Type
into #TEMP_PCT from #TEMP_IN

DECLARE Project_cursor CURSOR FOR 
	select distinct ProjectID, ProjectTitle from #TEMP_IN where ProjectTitle is not NULL order by ProjectTitle
OPEN Project_cursor
FETCH NEXT FROM Project_cursor INTO @CurProjectID, @CurProjectTitle
WHILE @@FETCH_STATUS = 0
BEGIN
	select @CurProjPct = sum(isnull(ProjClientFundingPct,0)+isnull(TaskClientFundingPct,0)) from #TEMP_PCT where ProjectID = @CurProjectID

	If @CurProjPct > 100
		set @CurProjPct = 999 

	insert #TEMP_OUT (RecNumber, RecType, RecDesc, FundingPct, R10_Client)
    select 30, 'Project/Total', @CurProjectTitle, @CurProjPct, @ClientGroup
    select @MaxProj = max(AutoKey) from #TEMP_OUT

	----------------------------------------------------------------------------------------------------------------------
    -- Resources directly under Project (SUMMARY REPORT)
    IF (@ProjectType <> '-1')
		BEGIN
			DECLARE Resource_cursor CURSOR FOR
           		select distinct ResourceName, BillingRate, Onshore, Offshore from #TEMP_IN where ProjectID = @CurProjectID order by ResourceName
        	OPEN Resource_cursor
        	FETCH NEXT FROM Resource_cursor INTO @CurResource, @CurRate, @onshore, @offshore
        	WHILE @@FETCH_STATUS = 0
            BEGIN
				set @C1_Hours = 0
                set @C2_Hours = 0
                set @C3_Hours = 0
                set @C4_Hours = 0
                set @C5_Hours = 0
                set @C6_Onsite_Hours = 0
                set @C6_Offsite_Hours = 0                
	            set @C7_Hours = 0
                set @G1_Hours = 0
                set @G2_Hours = 0
                
				-- sum up is done in the #TEMP_IN already
                select @C1_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
                and ResourceOrg = 'SOUTHERN CALIFORNIA SOLUTION CEN'
                
                select @C2_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
                and ResourceOrg = 'MEXICO CITY SOLUTION CENTRE'
                
                select @C3_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
                and ResourceOrg = 'MIRAMAR SOLUTION CENTRE'
                
                select @C4_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
                and ResourceOrg = 'OTHER'
                
                select @C5_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
                and ResourceOrg = 'HOUSTON SOLUTION CENTRE'

                select @C6_Onsite_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
                and ResourceOrg = 'MPHASIS' and Onshore = 1

                select @C6_Offsite_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
                and ResourceOrg = 'MPHASIS' and Offshore = 1

                select @C7_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
                and ResourceOrg = 'HP INDIA'
                
                select @G1_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
                and ResourceOrg = 'GCR - SYDNEY'

                select @G2_Hours = isnull(sum(Hours),0) from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource
                and ResourceOrg = 'GCR - MEXICO'
               
                set @TotalHours = @C1_Hours + @C2_Hours + @C3_Hours + @C4_Hours + @C5_Hours + @C6_Onsite_Hours + @C6_Offsite_Hours + @C7_Hours + @G1_Hours + @G2_Hours 
                set @Billed = @TotalHours * @CurRate
            	insert #TEMP_OUT (RecNumber, RecType, RecDesc, TotalHours, C1_Hours, C2_Hours, C3_Hours, C4_Hours, C5_Hours, C6_Onsite_Hours, C6_Offsite_Hours, C7_Hours, G1_Hours, G2_Hours, Billed, R10_Client, R30_Project)
             	select 50, 'Resource', @CurResource, @TotalHours, @C1_Hours, @C2_Hours, @C3_Hours, @C4_Hours, @C5_Hours, @C6_Onsite_Hours, @C6_Offsite_Hours, @C7_Hours, @G1_Hours, @G2_Hours, @Billed, @ClientGroup, @CurProjectTitle
             	
            FETCH NEXT FROM Resource_cursor INTO @CurResource, @CurRate, @onshore, @offshore
            END    
            CLOSE Resource_cursor
            DEALLOCATE Resource_cursor
		END -- IF (@ProjectType <> '-1')

		----------------------------------------------------------------------------------------------------------------------
        -- Resources under Tasks of Projects (DETAIL REPORT)
		IF (@ProjectType = '-1')
        BEGIN
			DECLARE Task_cursor CURSOR FOR
        		select distinct TaskID, TaskName, TaskClientFundingPct from #TEMP_IN where ProjectID = @CurProjectID and TaskName is not NULL order by TaskName
			OPEN Task_cursor
			FETCH NEXT FROM Task_cursor INTO @CurTaskID, @CurTaskName, @CurTaskPct
			WHILE @@FETCH_STATUS = 0
   			BEGIN
				insert #TEMP_OUT (RecNumber, RecType, RecDesc, FundingPct, R10_Client, R30_Project)
                select 40, 'Task/Total', @CurTaskName, @CurTaskPct, @ClientGroup, @CurProjectTitle
                select @MaxTask = max(AutoKey) from #TEMP_OUT

				-----------------------------------------------------------------------------------------------------------------------
                DECLARE Resource_cursor CURSOR FOR
                	select distinct ResourceName, BillingRate, Onshore, Offshore from #TEMP_IN where ProjectID = @CurProjectID and TaskID = @CurTaskID order by ResourceName
   				OPEN Resource_cursor
   				FETCH NEXT FROM Resource_cursor INTO @CurResource, @CurRate, @onshore, @offshore
                WHILE @@FETCH_STATUS = 0
                BEGIN
					set @C1_Hours = 0
                    set @C2_Hours = 0
                    set @C3_Hours = 0
                    set @C4_Hours = 0
                    set @C5_Hours = 0
					set @C6_Onsite_Hours = 0
					set @C6_Offsite_Hours = 0                
				    set @C7_Hours = 0
                    set @G1_Hours = 0
                    set @G2_Hours = 0
                                
                    -- sum up is done in the #TEMP_IN already
                    select @C1_Hours = isnull(sum(Hours),0) from #TEMP_IN
                    where ProjectID = @CurProjectID and TaskID = @CurTaskID and ResourceName = @CurResource and ResourceOrg = 'SOUTHERN CALIFORNIA SOLUTION CEN'
                                
                    select @C2_Hours = isnull(sum(Hours),0) from #TEMP_IN
                    where ProjectID = @CurProjectID and TaskID = @CurTaskID and ResourceName = @CurResource and ResourceOrg = 'MEXICO CITY SOLUTION CENTRE'

                    select @C3_Hours = isnull(sum(Hours),0) from #TEMP_IN
                    where ProjectID = @CurProjectID and TaskID = @CurTaskID and ResourceName = @CurResource and ResourceOrg = 'MIRAMAR SOLUTION CENTRE'
                                
                    select @C4_Hours = isnull(sum(Hours),0) from #TEMP_IN
                    where ProjectID = @CurProjectID and TaskID = @CurTaskID and ResourceName = @CurResource and ResourceOrg = 'OTHER'
                                
                    select @C5_Hours = isnull(sum(Hours),0) from #TEMP_IN
                    where ProjectID = @CurProjectID and TaskID = @CurTaskID and ResourceName = @CurResource and ResourceOrg = 'HOUSTON SOLUTION CENTRE'

                    select @C6_Onsite_Hours = isnull(sum(Hours),0) from #TEMP_IN 
                    where ProjectID = @CurProjectID and TaskID = @CurTaskID and ResourceName = @CurResource and ResourceOrg = 'MPHASIS' and Onshore = 1

                    select @C6_Offsite_Hours = isnull(sum(Hours),0) from #TEMP_IN 
                    where ProjectID = @CurProjectID and TaskID = @CurTaskID and ResourceName = @CurResource and ResourceOrg = 'MPHASIS' and Offshore = 1

                    select @C7_Hours = isnull(sum(Hours),0) from #TEMP_IN
                    where ProjectID = @CurProjectID and TaskID = @CurTaskID and ResourceName = @CurResource and ResourceOrg = 'HP INDIA'
                                
                    select @G1_Hours = isnull(sum(Hours),0) from #TEMP_IN
                    where ProjectID = @CurProjectID and TaskID = @CurTaskID and ResourceName = @CurResource and ResourceOrg = 'GCR - SYDNEY'
                                
                    select @G2_Hours = isnull(sum(Hours),0) from #TEMP_IN
                    where ProjectID = @CurProjectID and TaskID = @CurTaskID and ResourceName = @CurResource and ResourceOrg = 'GCR - MEXICO'
                                                                
                    set @TotalHours = @C1_Hours + @C2_Hours + @C3_Hours + @C4_Hours + @C5_Hours + @C6_Onsite_Hours + @C6_Offsite_Hours + @C7_Hours + @G1_Hours + @G2_Hours 
                    set @Billed = @TotalHours * @CurRate        
                    insert #TEMP_OUT (RecNumber, RecType, RecDesc, TotalHours, C1_Hours, C2_Hours, C3_Hours, C4_Hours, C5_Hours, C6_Onsite_Hours, C6_Offsite_Hours, C7_Hours, G1_Hours, G2_Hours, Billed, R10_Client, R30_Project, R40_Task)
                    select 50, 'Resource', @CurResource, @TotalHours, @C1_Hours, @C2_Hours, @C3_Hours, @C4_Hours, @C5_Hours, @C6_Onsite_Hours, @C6_Offsite_Hours, @C7_Hours, @G1_Hours, @G2_Hours, @Billed, @ClientGroup, @CurProjectTitle, @CurTaskName
            
				FETCH NEXT FROM Resource_cursor INTO @CurResource, @CurRate, @onshore, @offshore
                END    
                CLOSE Resource_cursor
                DEALLOCATE Resource_cursor

				-----------------------------------------------------------------------------------------------------------------------
                -- Sum up total hours for each task (vertical)    
                select  @C1_Hours = sum(isnull(C1_Hours,0)), @C2_Hours = sum(isnull(C2_Hours,0)), @C3_Hours = sum(isnull(C3_Hours,0)), @C4_Hours = sum(isnull(C4_Hours,0)), @C5_Hours = sum(isnull(C5_Hours,0)), @C6_Onsite_Hours = sum(isnull(C6_Onsite_Hours,0)), @C6_Offsite_Hours = sum(isnull(C6_Offsite_Hours,0)), @C7_Hours = sum(isnull(C7_Hours,0)), @G1_Hours = sum(isnull(G1_Hours,0)), @G2_Hours = sum(isnull(G2_Hours,0)), @Billed   = sum(isnull(Billed,0)), @TotalHours = sum(isnull(TotalHours,0))
                from #TEMP_OUT where AutoKey > @MaxTask and RecNumber = 50
    
				update #TEMP_OUT set C1_Hours = @C1_Hours, C2_Hours = @C2_Hours, C3_Hours = @C3_Hours, C4_Hours = @C4_Hours, C5_Hours = @C5_Hours, C6_Onsite_Hours = @C6_Onsite_Hours, C6_Offsite_Hours = @C6_Offsite_Hours, C7_Hours = @C7_Hours, G1_Hours = @G1_Hours, G2_Hours = @G2_Hours, Billed = @Billed, TotalHours = @TotalHours
                where AutoKey = @MaxTask
            	
			FETCH NEXT FROM Task_cursor INTO @CurTaskID, @CurTaskName, @CurTaskPct
			END    
            CLOSE Task_cursor
            DEALLOCATE Task_cursor
		END -- IF (@ProjecType = '-1')

		-----------------------------------------------------------------------------------------------------------------------
        set @C1_Hours = 0
        set @C2_Hours = 0
        set @C3_Hours = 0
        set @C4_Hours = 0
        set @C5_Hours = 0
		set @C6_Onsite_Hours = 0
		set @C6_Offsite_Hours = 0                
        set @C7_Hours = 0        
        set @G1_Hours = 0
        set @G2_Hours = 0
                
        select @C1_Hours = sum(isnull(C1_Hours,0)), @C2_Hours = sum(isnull(C2_Hours,0)), @C3_Hours = sum(isnull(C3_Hours,0)), @C4_Hours = sum(isnull(C4_Hours,0)), @C5_Hours = sum(isnull(C5_Hours,0)), @C6_Onsite_Hours = sum(isnull(C6_Onsite_Hours,0)), @C6_Offsite_Hours = sum(isnull(C6_Offsite_Hours,0)), @C7_Hours = sum(isnull(C7_Hours,0)), @G1_Hours = sum(isnull(G1_Hours,0)), @G2_Hours = sum(isnull(G2_Hours,0)), @Billed   = sum(isnull(Billed,0)), @TotalHours = sum(isnull(TotalHours,0))
        from dbo.#TEMP_OUT where AutoKey > @MaxProj and RecNumber = 50
                
        update #TEMP_OUT set C1_Hours = @C1_Hours, C2_Hours = @C2_Hours, C3_Hours = @C3_Hours, C4_Hours = @C4_Hours, C5_Hours = @C5_Hours, C6_Onsite_Hours = @C6_Onsite_Hours, C6_Offsite_Hours = @C6_Offsite_Hours, C7_Hours = @C7_Hours, G1_Hours = @G1_Hours, G2_Hours = @G2_Hours, Billed = @Billed, TotalHours = @TotalHours
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
set @C6_Onsite_Hours = 0
set @C6_Offsite_Hours = 0                
set @C7_Hours = 0
set @G1_Hours = 0
set @G2_Hours = 0

select @C1_Hours = sum(isnull(C1_Hours,0)), @C2_Hours = sum(isnull(C2_Hours,0)), @C3_Hours = sum(isnull(C3_Hours,0)), @C4_Hours = sum(isnull(C4_Hours,0)), @C5_Hours = sum(isnull(C5_Hours,0)), @C6_Onsite_Hours = sum(isnull(C6_Onsite_Hours,0)), @C6_Offsite_Hours = sum(isnull(C6_Offsite_Hours,0)), @C7_Hours = sum(isnull(C7_Hours,0)), @G1_Hours = sum(isnull(G1_Hours,0)), @G2_Hours = sum(isnull(G2_Hours,0)), @Billed   = sum(isnull(Billed,0)), @TotalHours = sum(isnull(TotalHours,0))
from dbo.#TEMP_OUT where AutoKey > @MaxClient and RecNumber = 30

update #TEMP_OUT set C1_Hours = @C1_Hours, C2_Hours = @C2_Hours, C3_Hours = @C3_Hours, C4_Hours = @C4_Hours, C5_Hours = @C5_Hours, C6_Onsite_Hours = @C6_Onsite_Hours, C6_Offsite_Hours = @C6_Offsite_Hours, C7_Hours = @C7_Hours, G1_Hours = @G1_Hours, G2_Hours = @G2_Hours, Billed = @Billed, TotalHours = @TotalHours
where AutoKey = @MaxClient or RecNumber = 0             

update #TEMP_OUT set C1_Hours = @C1_Hours/@FTE_Factor_SCSC, C2_Hours = @C2_Hours/@FTE_Factor_MEXSC, C3_Hours = @C3_Hours/@FTE_Factor_MIRSC, C4_Hours = @C4_Hours/@FTE_Factor_ESOL, C5_Hours = @C5_Hours/@FTE_Factor_HOUSC, C6_Onsite_Hours = @C6_Onsite_Hours/@FTE_Factor_INDIA, C6_Offsite_Hours = @C6_Offsite_Hours/@FTE_Factor_INDIA, C7_Hours = @C7_Hours/@FTE_Factor_INDIA, G1_Hours = @G1_Hours/@FTE_Factor_GCR_SYDNEY, G2_Hours = @G2_Hours/@FTE_Factor_GCR_MEXICO, 
TotalHours = @C1_Hours/@FTE_Factor_SCSC + @C2_Hours/@FTE_Factor_MEXSC + @C3_Hours/@FTE_Factor_MIRSC + @C4_Hours/@FTE_Factor_ESOL + @C5_Hours/@FTE_Factor_HOUSC + @C6_Onsite_Hours/@FTE_Factor_INDIA + @C6_Offsite_Hours/@FTE_Factor_INDIA + @C7_Hours/@FTE_Factor_INDIA + @G1_Hours/@FTE_Factor_GCR_SYDNEY + @G2_Hours/@FTE_Factor_GCR_MEXICO 
where RecNumber = 5

Update #TEMP_OUT set C1_Hours = @FTE_Factor_SCSC, C2_Hours = @FTE_Factor_MEXSC, C3_Hours = @FTE_Factor_MIRSC, C4_Hours = @FTE_Factor_ESOL, C5_Hours = @FTE_Factor_HOUSC, C6_Onsite_Hours = @FTE_Factor_INDIA, C6_Offsite_Hours = @FTE_Factor_INDIA, C7_Hours = @FTE_Factor_INDIA, G1_Hours = @FTE_Factor_GCR_SYDNEY, G2_Hours = @FTE_Factor_GCR_MEXICO
where RecNumber = 7

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------

Select RecNumber, RecType, RecDesc, FundingPct, TotalHours, C1_Hours, C2_Hours, C3_Hours, C4_Hours, C5_Hours, C6_Onsite_Hours, C6_Offsite_Hours, C7_Hours, G1_Hours, G2_Hours, Billed, R10_Client, R20_Type, R30_Project, R40_Task
from #TEMP_OUT order by AutoKey

