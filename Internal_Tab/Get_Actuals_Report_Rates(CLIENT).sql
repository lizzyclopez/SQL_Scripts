--[Get_Actuals_Report_Rates] (@DateFrom datetime = NULL, @DateTo datetime = NULL, @ClientGroup varchar(100) = NULL, @ClientList varchar(500) = '-1', @SummaryLevel varchar(30) = NULL, @ProductList varchar(500) = '-1', @OutputTable varchar(30) = NULL )
--DETATIL BY CLIENT REPORT

drop table #TEMP_IN
drop table #TEMP_OUT
drop view [dbo].[SP_Get_AR_View]

DECLARE @SQL_statement varchar(1400) 
set @SQL_statement = 'Create View dbo.SP_Get_AR_View AS select * from InternalBilling_View where WorkDate >= ''2016-07-01'' and WorkDate <= ''2016-07-31'' and Hours > 0'
exec (@SQL_statement)

select Client, ProjectID, ProjectTitle, TaskID, TaskName, ResourceName, WorkDate, ActualWork AS HrsToDate, ProjClientFundingPct, ProjClientFundedBy, TaskClientFundingPct, TaskClientFundedBy, ResourceOrg, Hours, Keyword, JobCode, BillingRate As ResBillingRate, Onshore, Offshore
into #TEMP_IN from dbo.SP_Get_AR_View order by Client, ProjectID, ProjectTitle, TaskID, TaskName, ResourceName, WorkDate, ProjClientFundingPct, ProjClientFundedBy, TaskClientFundingPct, TaskClientFundedBy, ResourceOrg

ALTER TABLE #TEMP_IN ADD ID int IDENTITY(1,1) NOT NULL PRIMARY KEY 

delete T1 from #TEMP_IN T1, #TEMP_IN T2
where T1.Client = 'Multiple' and T2.Client = 'Multiple' and T1.ProjectID = T2.ProjectID and T1.ProjectTitle = T2.ProjectTitle and T1.TaskID = T1.TaskID and T1.TaskName = T2.TaskName and T1.ResourceName = T2.ResourceName and T1.WorkDate = T2.WorkDate and T1.HrsToDate = T2.HrsToDate and T1.TaskClientFundingPct = T2.TaskClientFundingPct and T1.TaskClientFundedBy = T2.TaskClientFundedBy and T1.ResourceOrg = T2.ResourceOrg and T1.Hours = T2.Hours and T1.ID > T2.ID

-- Redefine ResourceOrg for reports
update #TEMP_IN set ResourceOrg = 'GCR - SYDNEY' where ResourceOrg like '%SYDNEY%'
update #TEMP_IN set ResourceOrg = 'GCR - MEXICO' where ResourceOrg = 'GCR - AD-MX-JUAREZ ADU'
update #TEMP_IN set ResourceOrg = 'MPHASIS' where ResourceOrg = 'BSSC INDIA'	

--CHANGED
-- Set ResourceOrg field to OTHER if ResourceOrg is not in one of the fixed buckets.
update #TEMP_IN set ResourceOrg = 'OTHER' where ResourceOrg not in ('Korea', 'MPHASIS', 'HP INDIA', 'SOUTHERN CALIFORNIA SOLUTION CEN', 'MIRAMAR SOLUTION CENTRE', 'HOUSTON SOLUTION CENTRE', 'RDC', 'GCR - SYDNEY', 'GCR - MEXICO') AND (ResourceOrg not like '%MEXICO%') and ( ResourceOrg not like '%AD-MX%')

-- Adjust Hours by applying Funding Percentage, TaskClientFundingPct or ProjClientFundingPct > 0, not both
update #TEMP_IN set Hours = Hours * (TaskClientFundingPct/100) where TaskClientFundingPct is not NULL 

Update #TEMP_IN set TaskClientFundedBy = 'PORT' where TaskClientFundedBy = 'POR'
Update #TEMP_IN set ProjClientFundingPct = TaskClientFundingPct where TaskClientFundingPct is Not NULL
Update #TEMP_IN set Client = 'Continental Airlines' where Client = 'Multiple' and TaskClientFundedBy Like 'CO%'
Update #TEMP_IN set Client = (Select Client from [R2_Reports].dbo.lkClientGroupClientRef where ClientCode = TaskClientFundedBy) where Client = 'Multiple' and TaskClientFundedBy is Not NULL and TaskClientFundedBy Not Like 'CO%'

Create Index IDX1 on #TEMP_IN (Client, ProjectID, ResourceName, ResourceOrg)
Create Index IDX2 on #TEMP_IN (ProjectID, ResourceName, ResourceOrg)

----------------------------------------------------------------------------------
--CHANGED
--drop table #TEMP_OUT

CREATE TABLE [dbo].[#TEMP_OUT] (
	[AutoKey][int] IDENTITY (0, 1) NOT NULL,
	[RecNumber][int] NULL,          -- 0, 3, 6, 10, 20, 30, 40, 50, 55, 56, 60, 99
	[RecType] [varchar] (100) NULL, -- Client / Project / Resource
	[RecDesc] [varchar] (100) NULL,
	[HourlyBillingRate] [decimal](10,2) NULL,
	[FundingPct] [decimal](10,2) NULL,
	[TotalHours] [decimal](10,2) NULL,
	[TotalBilled] [decimal](10,2) NULL,	
	[SCSC_Hours] [decimal](10,2) NULL,				--SCSC - SOUTHERN CALIFORNIA SOLUTION CEN - HOURS
	[SCSC_Billed] [decimal](10,2) NULL,				--SCSC - SOUTHERN CALIFORNIA SOLUTION CEN - BILLED
	[RDC_Hours] [decimal](10,2) NULL,				--RDC EL PASO - HOURS
	[RDC_Billed] [decimal](10,2) NULL,				--RDC EL PASO - BILLED
	[MEXSC_Hours] [decimal](10,2) NULL,				--MEXICO CITY SOLUTION CENTRE - HOURS
	[MEXSC_Billed] [decimal](10,2) NULL,			--MEXICO CITY SOLUTION CENTRE - BILLED
	[GCR_MEX_Hours] [decimal](10,2) NULL,			--GCR MEXICO - HOURS
	[GCR_MEX_Billed] [decimal](10,2) NULL,			--GCR MEXICO - BILLED
	[MPHASIS_Onsite_Hours] [decimal](10,2) NULL,	--MPHASIS ONSITE - HOURS
	[MPHASIS_Onsite_Billed] [decimal](10,2) NULL,	--MPHASIS ONSITE - BILLED
	[MPHASIS_Offsite_Hours] [decimal](10,2) NULL,	--MPHASIS OFFSITE - HOURS
	[MPHASIS_Offsite_Billed] [decimal](10,2) NULL,	--MPHASIS OFFSITE - BILLED
	[HPINDIA_Hours] [decimal](10,2) NULL,			--HP INDIA - HOURS
	[HPINDIA_Billed] [decimal](10,2) NULL,			--HP INDIA - BILLED
	[GCR_SYD_Hours] [decimal](10,2) NULL,			--GCR BSSC SYDNEY - HOURS
	[GCR_SYD_Billed] [decimal](10,2) NULL,			--GCR BSSC SYDNEY - BILLED
	[KOREA_Hours] [decimal](10,2) NULL,				--KOREA - HOURS
	[KOREA_Billed] [decimal](10,2) NULL,			--KOREA - BILLED
	[OTHER_Hours] [decimal](10,2) NULL,				--OTHER - HOURS
	[OTHER_Billed] [decimal](10,2) NULL,			--OTHER - BILLED
	[R10_Client] [varchar] (100) NULL,
	[R30_Project] [varchar] (100) NULL
) ON [PRIMARY]

insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Grand Total'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'GrandTotal', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 7, 'GrandTotal', 'FTE Factors'

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Set FTEFactors for the ClientGroup
--CHANGED
DECLARE @FTE_Factor float, @FTE_Factor_SCSC float, @FTE_Factor_RDC float, @FTE_Factor_MEXSC float, @FTE_Factor_INDIA float, @FTE_Factor_GCR_SYDNEY float, @FTE_Factor_KOREA float, @FTE_Factor_OTHER float, @CurFTEFactor float, @CurSolutionCentreCode varchar(50)
declare @ClientGroup varchar(100)

-- Set FTE Factors for ALL Solution Centres
set @FTE_Factor_SCSC = 143.5
set @FTE_Factor_RDC = 143.5
set @FTE_Factor_MEXSC = 143.5
set @FTE_Factor_INDIA = 143.5
set @FTE_Factor_GCR_SYDNEY = 143.5
set @FTE_Factor_KOREA = 143.5
set @FTE_Factor_OTHER = 143.5

--Select the FTE Factor for the listed Client Group
select @FTE_Factor = FTEFactor from lkClientGroup where ClientGroup = @ClientGroup

--Update FTE Factors for the Client Group
set @FTE_Factor_SCSC = @FTE_Factor
set @FTE_Factor_RDC = @FTE_Factor
set @FTE_Factor_MEXSC = @FTE_Factor
set @FTE_Factor_INDIA = @FTE_Factor
set @FTE_Factor_GCR_SYDNEY = @FTE_Factor
set @FTE_Factor_KOREA = @FTE_Factor
set @FTE_Factor_OTHER = @FTE_Factor

--CHANGED
-- Check if there are any FTE overrides for ClientGroup/Solution Centre reset FTE Factor
DECLARE FTEOverride_cursor CURSOR FOR 
    select FTEFactor,ResourceOrg from lkClientGroupFTEOverride where ClientGroup = @ClientGroup
OPEN FTEOverride_cursor
FETCH NEXT FROM FTEOverride_cursor INTO @CurFTEFactor, @CurSolutionCentreCode
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @CurSolutionCentreCode = 'Southern California Solution Cen'
		set @FTE_Factor_SCSC = @CurFTEFactor
	IF @CurSolutionCentreCode = 'RDC'
		set @FTE_Factor_RDC = @CurFTEFactor
    IF @CurSolutionCentreCode in ('Mexico City Solution Centre','GCR - Mexico City Solution Centre','GCR - NORTHERN MEXICO SOLUTION CENTRE')
       	set @FTE_Factor_MEXSC = @CurFTEFactor
    IF @CurSolutionCentreCode in ('MPHASIS','HP INDIA')
        set @FTE_Factor_INDIA = @CurFTEFactor        
    IF @CurSolutionCentreCode = 'GCR - Sydney Solution Centre'
        set @FTE_Factor_GCR_Sydney = @CurFTEFactor
    IF @CurSolutionCentreCode = 'KOREA'
		set @FTE_Factor_KOREA = @CurFTEFactor
    IF @CurSolutionCentreCode = 'OTHER'
		set @FTE_Factor_OTHER = @CurFTEFactor
FETCH NEXT FROM FTEOverride_cursor INTO @CurFTEFactor, @CurSolutionCentreCode
END    
CLOSE FTEOverride_cursor
DEALLOCATE FTEOverride_cursor

----------------------------------------------------------------------------------
--CHANGED
DECLARE @SCSC_Hours decimal(10,2), @SCSC_Billed decimal(10,2), @RDC_Hours decimal(10,2), @RDC_Billed decimal(10,2), @MEXSC_Hours decimal(10,2), @MEXSC_Billed decimal(10,2), @GCR_MEX_Hours decimal(10,2), @GCR_MEX_Billed decimal(10,2), @MPHASIS_Onsite_Hours decimal(10,2), @MPHASIS_Onsite_Billed decimal(10,2), @MPHASIS_Offsite_Hours decimal(10,2), @MPHASIS_Offsite_Billed decimal(10,2), @GCR_SYD_Hours decimal(10,2), @GCR_SYD_Billed decimal(10,2), @KOREA_Hours decimal(10,2), @KOREA_Billed decimal(10,2), @OTHER_Hours decimal(10,2), @OTHER_Billed decimal(10,2), @HPINDIA_Hours decimal(10,2), @HPINDIA_Billed decimal(10,2), @TotalHours decimal(10,2), @TotalBilled decimal(10,2)
DECLARE @CurClient varchar(50), @CurType varchar(50), @CurProjectID uniqueidentifier, @CurProjectTitle varchar(100), @CurProjPct float, @CurTaskID uniqueidentifier, @CurTaskName varchar(100), @CurTaskPct float, @CurResource varchar(100),@CurTaskFundedPct decimal (5,2)
DECLARE @MaxClient int, @MaxType int, @MaxProj bigint, @MaxTask int, @MaxResource int, @ProjectActualStartDate datetime, @SAPHours decimal(10,2), @SAPHours2 float
declare @CurJobCode varchar(25),  @CurJobCodeRate decimal(10,2), @BillingRate decimal(10,2), @Onshore bit, @Offshore bit, @ResourceOrg varchar(50)
declare @DateFrom datetime, @DateTo datetime

--------------------------------------------------------------------------------------------------------------
---Client_Report: 
--------------------------------------------------------------------------------------------------------------
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
				
			select @SAPHours = sum(hours) from R2_reports..tblResourceDetail where projectid = @CurProjectID and workdate >= CONVERT(nvarchar(10), @ProjectActualStartDate, 112) and workdate <= CONVERT(nvarchar(10), @DateTo, 112)
			select @CurProjPct = ProjClientFundingPct from #TEMP_IN where ProjectID = @CurProjectID and Client = @CurClient			
       		insert #TEMP_OUT (RecNumber, RecType, RecDesc, FundingPct, R10_Client)
       		select 30, 'Project/Total', @CurProjectTitle, @CurProjPct, @CurClient
           	select @MaxProj = max(AutoKey) from #TEMP_OUT

			-----------------------------------------------------------------------------------------------------------------------
        	DECLARE Resource_cursor CURSOR FOR
           		select distinct ResourceName, TaskClientFundingPct, JobCode, ResourceOrg, Onshore, Offshore from #TEMP_IN
        		where Client = @CurClient and ProjectID = @CurProjectID order by ResourceName
        	OPEN Resource_cursor
        	FETCH NEXT FROM Resource_cursor INTO @CurResource, @CurTaskFundedPct, @CurJobCode, @ResourceOrg, @Onshore, @Offshore
        	WHILE @@FETCH_STATUS = 0
            BEGIN
			--CHANGED
				set @SCSC_Hours = 0
				set @SCSC_Billed = 0
				set @RDC_Hours = 0
				set @RDC_Billed = 0
                set @MEXSC_Hours = 0
                set @MEXSC_Billed = 0
                set @GCR_MEX_Hours = 0
                set @GCR_MEX_Billed = 0
                set @MPHASIS_Onsite_Hours = 0
                set @MPHASIS_Onsite_Billed = 0
                set @MPHASIS_Offsite_Hours = 0
                set @MPHASIS_Offsite_Billed = 0
                set @GCR_SYD_Hours = 0
                set @GCR_SYD_Billed = 0
                set @KOREA_Hours = 0
                set @KOREA_Billed = 0
                set @OTHER_Hours = 0
                set @OTHER_Billed = 0
                set @HPINDIA_Hours = 0
                set @HPINDIA_Billed = 0			
				set @CurJobCodeRate = 0
				set @BillingRate = 0
				
				-- Set the billing rate to be the Resource Billing Rate from the CO_RESOURCE table.
				select @BillingRate = ResBillingRate from #TEMP_IN where ProjectID = @CurProjectID and ResourceName = @CurResource

				--print 'BillingRate_PRE=' 
				--print	@BillingRate

				--CHANGED
				-- If the billing rate from the CO_RESOURCE table is zero and ResourceOrg is not RDC or OTHER, use the Job Code billing rate.
				--if @BillingRate = 0	and @ResourceOrg <> 'OTHER'
				if @BillingRate = 0	and @ResourceOrg not in ('OTHER','RDC')
					begin
					-- JobCodeBillingRate_cursor populates the hourly billing rate for resources.
					DECLARE JobCodeBillingRate_cursor CURSOR FOR 
						Select BillingRate from lkBillingRateJobCode where EDSJobCode = @CurJobCode --and ResourceOrg like '%RDC%' 
					OPEN JobCodeBillingRate_cursor
					FETCH NEXT FROM JobCodeBillingRate_cursor INTO @CurJobCodeRate
					WHILE @@FETCH_STATUS = 0
					BEGIN				
						-- Set the billing rate to be the Job Code billing rate.
						set @BillingRate = @CurJobCodeRate

						FETCH NEXT FROM JobCodeBillingRate_cursor INTO @CurJobCodeRate 
					END
					CLOSE JobCodeBillingRate_cursor
					DEALLOCATE JobCodeBillingRate_cursor
					end							

				--print 'Resource=' + @curResource
				--print 'ResourceOrg=' + @ResourceOrg          
				--print 'BillingRate_POST=' 
				--print	@BillingRate

                select @SCSC_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'SOUTHERN CALIFORNIA SOLUTION CEN'
				select @SCSC_Billed = isnull(@SCSC_Hours * @BillingRate,0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'SOUTHERN CALIFORNIA SOLUTION CEN'

				--CHANGED
                select @RDC_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'RDC'
				select @RDC_Billed = isnull(@RDC_Hours * @BillingRate,0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'RDC'
                
                select @MEXSC_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and (ResourceOrg like '%MEXICO%' or ResourceOrg like '%AD-MX%' ) and ResourceOrg <> 'GCR - MEXICO'
				select @MEXSC_Billed = isnull(@MEXSC_Hours * @BillingRate,0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and (ResourceOrg like '%MEXICO%' or ResourceOrg like '%AD-MX%' ) and ResourceOrg <> 'GCR - MEXICO'

                select @GCR_MEX_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'GCR - MEXICO'
				select @GCR_MEX_Billed = isnull(@GCR_MEX_Hours * @BillingRate,0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'GCR - MEXICO'
                
                select @MPHASIS_Onsite_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'MPHASIS' and Onshore = 1
				select @MPHASIS_Onsite_Billed = isnull(@MPHASIS_Onsite_Hours * @BillingRate,0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'MPHASIS' and Onshore = 1

                select @MPHASIS_Offsite_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'MPHASIS' and Offshore = 1
				select @MPHASIS_Offsite_Billed = isnull(@MPHASIS_Offsite_Hours * @BillingRate,0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'MPHASIS' and Offshore = 1

				select @GCR_SYD_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'GCR - SYDNEY'
				select @GCR_SYD_Billed = isnull(@GCR_SYD_Hours * @BillingRate,0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'GCR - SYDNEY'
               
                select @KOREA_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'KOREA'
				select @KOREA_Billed = isnull(@KOREA_Hours * @BillingRate,0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'KOREA'

                select @OTHER_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'OTHER'
				select @OTHER_Billed = isnull(@OTHER_Hours * @BillingRate,0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'OTHER'
					
                select @HPINDIA_Hours = isnull(sum(Hours),0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'HP INDIA'
				select @HPINDIA_Billed = isnull(@HPINDIA_Hours * @BillingRate,0) from #TEMP_IN where Client = @CurClient and ProjectID = @CurProjectID and ResourceName = @CurResource and (TaskClientFundingPct = @CurTaskFundedPct or TaskClientFundingPct is null)
					and ResourceOrg = 'HP INDIA'					
                
				--CHANGED
                set @TotalHours = @SCSC_Hours + @RDC_Hours + @MEXSC_Hours + @GCR_MEX_Hours + @MPHASIS_Onsite_Hours + @MPHASIS_Offsite_Hours  + @GCR_SYD_Hours + @KOREA_Hours + @OTHER_Hours + @HPINDIA_Hours 
				set @TotalBilled = @SCSC_Billed + @RDC_Billed + @MEXSC_Billed +  @GCR_MEX_Billed + @MPHASIS_Onsite_Billed + @MPHASIS_Offsite_Billed + @GCR_SYD_Billed + @KOREA_Billed + @OTHER_Billed + @HPINDIA_Billed

				--CHANGED
		        insert #TEMP_OUT (RecNumber, RecType, RecDesc, HourlyBillingRate, FundingPct, TotalHours, TotalBilled, SCSC_Hours, SCSC_Billed, RDC_Hours, RDC_Billed, MEXSC_Hours, MEXSC_Billed, GCR_MEX_Hours, GCR_MEX_Billed, MPHASIS_Onsite_Hours, MPHASIS_Onsite_Billed, MPHASIS_Offsite_Hours, MPHASIS_Offsite_Billed, GCR_SYD_Hours, GCR_SYD_Billed, KOREA_Hours, KOREA_Billed, OTHER_Hours, OTHER_Billed, HPINDIA_Hours, HPINDIA_Billed, R10_Client, R30_Project)
		        select 50, 'Resource', @CurResource, @BillingRate,  @CurProjPct, @TotalHours, @TotalBilled, @SCSC_Hours, @SCSC_Billed, @RDC_Hours, @RDC_Billed, @MEXSC_Hours, @MEXSC_Billed, @GCR_MEX_Hours, @GCR_MEX_Billed, @MPHASIS_Onsite_Hours, @MPHASIS_Onsite_Billed, @MPHASIS_Offsite_Hours, @MPHASIS_Offsite_Billed, @GCR_SYD_Hours, @GCR_SYD_Billed, @KOREA_Hours, @KOREA_Billed, @OTHER_Hours, @OTHER_Billed, @HPINDIA_Hours, @HPINDIA_Billed, @CurClient, @CurProjectTitle

            FETCH NEXT FROM Resource_cursor INTO @CurResource, @CurTaskFundedPct, @CurJobCode, @ResourceOrg, @Onshore, @Offshore
            END    
            CLOSE Resource_cursor
            DEALLOCATE Resource_cursor

			-----------------------------------------------------------------------------------------------------------------------
			--CHANGED
            set @SCSC_Hours = 0
            set @SCSC_Billed = 0
			set @RDC_Hours = 0
			set @RDC_Billed = 0
            set @MEXSC_Hours = 0
            set @MEXSC_Billed = 0
            set @GCR_MEX_Hours = 0
            set @GCR_MEX_Billed = 0
            set @MPHASIS_Onsite_Hours = 0
            set @MPHASIS_Onsite_Billed = 0
            set @MPHASIS_Offsite_Hours = 0
            set @MPHASIS_Offsite_Billed = 0
            set @GCR_SYD_Hours = 0
            set @GCR_SYD_Billed = 0            
            set @KOREA_Hours = 0
            set @KOREA_Billed = 0
            set @OTHER_Hours = 0
            set @OTHER_Billed = 0
            set @HPINDIA_Hours = 0
            set @HPINDIA_Billed = 0

			--CHANGED
			select @SCSC_Hours = sum(isnull(SCSC_Hours,0)), @SCSC_Billed = sum(isnull(SCSC_Billed,0)), @RDC_Hours = sum(isnull(RDC_Hours,0)), @RDC_Billed = sum(isnull(RDC_Billed,0)), @MEXSC_Hours = sum(isnull(MEXSC_Hours,0)), @MEXSC_Billed = sum(isnull(MEXSC_Billed,0)), @GCR_MEX_Hours = sum(isnull(GCR_MEX_Hours,0)), @GCR_MEX_Billed = sum(isnull(GCR_MEX_Billed,0)), @MPHASIS_Onsite_Hours = sum(isnull(MPHASIS_Onsite_Hours,0)), @MPHASIS_Onsite_Billed = sum(isnull(MPHASIS_Onsite_Billed,0)), @MPHASIS_Offsite_Hours = sum(isnull(MPHASIS_Offsite_Hours,0)), @MPHASIS_Offsite_Billed = sum(isnull(MPHASIS_Offsite_Billed,0)), @GCR_SYD_Hours = sum(isnull(GCR_SYD_Hours,0)), @GCR_SYD_Billed = sum(isnull(GCR_SYD_Billed,0)), @KOREA_Hours = sum(isnull(KOREA_Hours,0)), @KOREA_Billed = sum(isnull(KOREA_Billed,0)), @OTHER_Hours = sum(isnull(OTHER_Hours,0)), @OTHER_Billed = sum(isnull(OTHER_Billed,0)), @HPINDIA_Hours = sum(isnull(HPINDIA_Hours,0)), @HPINDIA_Billed = sum(isnull(HPINDIA_Billed,0)), @TotalHours = sum(isnull(TotalHours,0)), @TotalBilled = sum(isnull(TotalBilled,0))
            from dbo.#TEMP_OUT where AutoKey > @MaxProj and RecNumber = 50

			--CHANGED
		    update #TEMP_OUT set SCSC_Hours = @SCSC_Hours, SCSC_Billed = @SCSC_Billed, RDC_Hours = @RDC_Hours, RDC_Billed = @RDC_Billed, MEXSC_Hours = @MEXSC_Hours, MEXSC_Billed = @MEXSC_Billed, GCR_MEX_Hours = @GCR_MEX_Hours, GCR_MEX_Billed = @GCR_MEX_Billed, MPHASIS_Onsite_Hours = @MPHASIS_Onsite_Hours, MPHASIS_Onsite_Billed = @MPHASIS_Onsite_Billed, MPHASIS_Offsite_Hours = @MPHASIS_Offsite_Hours, MPHASIS_Offsite_Billed = @MPHASIS_Offsite_Billed, GCR_SYD_Hours = @GCR_SYD_Hours, GCR_SYD_Billed = @GCR_SYD_Billed, KOREA_Hours = @KOREA_Hours, KOREA_Billed = @KOREA_Billed, OTHER_Hours = @OTHER_Hours, OTHER_Billed = @OTHER_Billed, HPINDIA_Hours = @HPINDIA_Hours, HPINDIA_Billed = @HPINDIA_Billed, TotalHours = @TotalHours, TotalBilled = @TotalBilled
            where AutoKey = @MaxProj
            
		FETCH NEXT FROM Project_cursor INTO @CurProjectID, @CurProjectTitle
        END
        CLOSE Project_cursor
        DEALLOCATE Project_cursor

	---------------------------------------------------------------------------------------------------
	--CHANGED
    set @SCSC_Hours = 0
    set @SCSC_Billed = 0
	set @RDC_Hours = 0
	set @RDC_Billed = 0
    set @MEXSC_Hours = 0
    set @MEXSC_Billed = 0
    set @GCR_MEX_Hours = 0
    set @GCR_MEX_Billed = 0
    set @MPHASIS_Onsite_Hours = 0
    set @MPHASIS_Onsite_Billed = 0
    set @MPHASIS_Offsite_Hours = 0
    set @MPHASIS_Offsite_Billed = 0
    set @GCR_SYD_Hours = 0
    set @GCR_SYD_Billed = 0            
    set @KOREA_Hours = 0
    set @KOREA_Billed = 0
    set @OTHER_Hours = 0
    set @OTHER_Billed = 0
    set @HPINDIA_Hours = 0
    set @HPINDIA_Billed = 0

	--CHANGED
    select @SCSC_Hours = sum(isnull(SCSC_Hours,0)), @SCSC_Billed = sum(isnull(SCSC_Billed,0)), @RDC_Hours = sum(isnull(RDC_Hours,0)), @RDC_Billed = sum(isnull(RDC_Billed,0)), @MEXSC_Hours = sum(isnull(MEXSC_Hours,0)), @MEXSC_Billed = sum(isnull(MEXSC_Billed,0)), @GCR_MEX_Hours = sum(isnull(GCR_MEX_Hours,0)), @GCR_MEX_Billed = sum(isnull(GCR_MEX_Billed,0)), @MPHASIS_Onsite_Hours = sum(isnull(MPHASIS_Onsite_Hours,0)), @MPHASIS_Onsite_Billed = sum(isnull(MPHASIS_Onsite_Billed,0)),@MPHASIS_Offsite_Hours = sum(isnull(MPHASIS_Offsite_Hours,0)), @MPHASIS_Offsite_Billed = sum(isnull(MPHASIS_Offsite_Billed,0)), @GCR_SYD_Hours = sum(isnull(GCR_SYD_Hours,0)), @GCR_SYD_Billed = sum(isnull(GCR_SYD_Billed,0)), @KOREA_Hours = sum(isnull(KOREA_Hours,0)), @KOREA_Billed = sum(isnull(KOREA_Billed,0)), @OTHER_Hours = sum(isnull(OTHER_Hours,0)), @OTHER_Billed = sum(isnull(OTHER_Billed,0)), @HPINDIA_Hours = sum(isnull(HPINDIA_Hours,0)), @HPINDIA_Billed = sum(isnull(HPINDIA_Billed,0)), @TotalHours = sum(isnull(TotalHours,0)), @TotalBilled = sum(isnull(TotalBilled,0))
    from dbo.#TEMP_OUT where AutoKey > @MaxClient and RecNumber = 30

	--CHANGED
    update #TEMP_OUT set SCSC_Hours = @SCSC_Hours, SCSC_Billed = @SCSC_Billed, RDC_Hours = @RDC_Hours, RDC_Billed = @RDC_Billed, MEXSC_Hours = @MEXSC_Hours, MEXSC_Billed = @MEXSC_Billed, GCR_MEX_Hours = @GCR_MEX_Hours, GCR_MEX_Billed = @GCR_MEX_Billed, MPHASIS_Onsite_Hours = @MPHASIS_Onsite_Hours, MPHASIS_Onsite_Billed = @MPHASIS_Onsite_Billed, MPHASIS_Offsite_Hours = @MPHASIS_Offsite_Hours, MPHASIS_Offsite_Billed = @MPHASIS_Offsite_Billed, GCR_SYD_Hours = @GCR_SYD_Hours, GCR_SYD_Billed = @GCR_SYD_Billed, KOREA_Hours = @KOREA_Hours, KOREA_Billed = @KOREA_Billed, OTHER_Hours = @OTHER_Hours, OTHER_Billed = @OTHER_Billed, HPINDIA_Hours = @HPINDIA_Hours, HPINDIA_Billed = @HPINDIA_Billed, TotalHours = @TotalHours, TotalBilled = @TotalBilled
    where AutoKey = @MaxClient

	--CHANGED
    update #TEMP_OUT set SCSC_Hours = @SCSC_Hours/@FTE_Factor_SCSC, SCSC_Billed = @SCSC_Billed/@FTE_Factor_SCSC, RDC_Hours = @RDC_Hours/@FTE_Factor_RDC, RDC_Billed = @RDC_Billed/@FTE_Factor_RDC, MEXSC_Hours = @MEXSC_Hours/@FTE_Factor_MEXSC, MEXSC_Billed = @MEXSC_Billed/@FTE_Factor_MEXSC, GCR_MEX_Hours = @GCR_MEX_Hours/@FTE_Factor_MEXSC, GCR_MEX_Billed = @GCR_MEX_Billed/@FTE_Factor_MEXSC, MPHASIS_Onsite_Hours = @MPHASIS_Onsite_Hours/@FTE_Factor_INDIA, MPHASIS_Onsite_Billed = @MPHASIS_Onsite_Billed/@FTE_Factor_INDIA,MPHASIS_Offsite_Hours = @MPHASIS_Offsite_Hours/@FTE_Factor_INDIA, MPHASIS_Offsite_Billed = @MPHASIS_Offsite_Billed/@FTE_Factor_INDIA, GCR_SYD_Hours = @GCR_SYD_Hours/@FTE_Factor_GCR_SYDNEY, GCR_SYD_Billed = @GCR_SYD_Billed/@FTE_Factor_GCR_SYDNEY, KOREA_Hours = @KOREA_Hours/@FTE_Factor_KOREA, KOREA_Billed = @KOREA_Billed/@FTE_Factor_KOREA, OTHER_Hours = @OTHER_Hours/@FTE_Factor_OTHER, OTHER_Billed = @OTHER_Billed/@FTE_Factor_OTHER, HPINDIA_Hours = @HPINDIA_Hours/@FTE_Factor_INDIA, HPINDIA_Billed = @HPINDIA_Billed/@FTE_Factor_INDIA, 
    TotalHours = @SCSC_Hours/@FTE_Factor_SCSC + @RDC_Hours/@FTE_Factor_RDC + @MEXSC_Hours/@FTE_Factor_MEXSC + @GCR_MEX_Hours/@FTE_Factor_MEXSC + @MPHASIS_Onsite_Hours/@FTE_Factor_INDIA + @MPHASIS_Offsite_Hours/@FTE_Factor_INDIA + @GCR_SYD_Hours/@FTE_Factor_GCR_SYDNEY + @KOREA_Hours/@FTE_Factor_KOREA + @OTHER_Hours/@FTE_Factor_OTHER + @HPINDIA_Hours/@FTE_Factor_INDIA,
	TotalBilled = @SCSC_Billed/@FTE_Factor_SCSC + @RDC_Billed/@FTE_Factor_RDC + @MEXSC_Billed/@FTE_Factor_MEXSC + @GCR_MEX_Billed/@FTE_Factor_MEXSC + @MPHASIS_Onsite_Billed/@FTE_Factor_INDIA + @MPHASIS_Offsite_Billed/@FTE_Factor_INDIA + @GCR_SYD_Billed/@FTE_Factor_GCR_SYDNEY + @KOREA_Billed/@FTE_Factor_KOREA + @OTHER_Billed/@FTE_Factor_OTHER + @HPINDIA_Billed/@FTE_Factor_INDIA
    where AutoKey > @MaxClient and RecNumber = 15
    
FETCH NEXT FROM Client_cursor INTO @CurClient
END
CLOSE Client_cursor
DEALLOCATE Client_cursor

---------------------------------------------------------------------------------------------------
--CHANGED ALL 4
select @SCSC_Hours = sum(isnull(SCSC_Hours,0)), @SCSC_Billed = sum(isnull(SCSC_Billed,0)), @RDC_Hours = sum(isnull(RDC_Hours,0)), @RDC_Billed = sum(isnull(RDC_Billed,0)), @MEXSC_Hours = sum(isnull(MEXSC_Hours,0)), @MEXSC_Billed = sum(isnull(MEXSC_Billed,0)), @GCR_MEX_Hours = sum(isnull(GCR_MEX_Hours,0)), @GCR_MEX_Billed = sum(isnull(GCR_MEX_Billed,0)), @MPHASIS_Onsite_Hours = sum(isnull(MPHASIS_Onsite_Hours,0)), @MPHASIS_Onsite_Billed = sum(isnull(MPHASIS_Onsite_Billed,0)), @MPHASIS_Offsite_Hours = sum(isnull(MPHASIS_Offsite_Hours,0)), @MPHASIS_Offsite_Billed = sum(isnull(MPHASIS_Offsite_Billed,0)), @GCR_SYD_Hours = sum(isnull(GCR_SYD_Hours,0)), @GCR_SYD_Billed = sum(isnull(GCR_SYD_Billed,0)), @KOREA_Hours = sum(isnull(KOREA_Hours,0)), @KOREA_Billed = sum(isnull(KOREA_Billed,0)), @OTHER_Hours = sum(isnull(OTHER_Hours,0)), @OTHER_Billed = sum(isnull(OTHER_Billed,0)),  @HPINDIA_Hours = sum(isnull(HPINDIA_Hours,0)), @HPINDIA_Billed = sum(isnull(HPINDIA_Billed,0)), @TotalHours = sum(isnull(TotalHours,0)), @TotalBilled = sum(isnull(TotalBilled,0))
from dbo.#TEMP_OUT where RecNumber = 10

update #TEMP_OUT set SCSC_Hours = @SCSC_Hours, SCSC_Billed = @SCSC_Billed, RDC_Hours = @RDC_Hours, RDC_Billed = @RDC_Billed, MEXSC_Hours = @MEXSC_Hours, MEXSC_Billed = @MEXSC_Billed, GCR_MEX_Hours = @GCR_MEX_Hours, GCR_MEX_Billed = @GCR_MEX_Billed, MPHASIS_Onsite_Hours = @MPHASIS_Onsite_Hours, MPHASIS_Onsite_Billed = @MPHASIS_Onsite_Billed, MPHASIS_Offsite_Hours = @MPHASIS_Offsite_Hours, MPHASIS_Offsite_Billed = @MPHASIS_Offsite_Billed, GCR_SYD_Hours = @GCR_SYD_Hours, GCR_SYD_Billed = @GCR_SYD_Billed, KOREA_Hours = @KOREA_Hours, KOREA_Billed = @KOREA_Billed, OTHER_Hours = @OTHER_Hours, OTHER_Billed = @OTHER_Billed, HPINDIA_Hours = @HPINDIA_Hours, HPINDIA_Billed = @HPINDIA_Billed, TotalHours = @TotalHours, TotalBilled = @TotalBilled
where RecNumber = 0

update #TEMP_OUT set SCSC_Hours = @SCSC_Hours/@FTE_Factor_SCSC, SCSC_Billed = @SCSC_Billed/@FTE_Factor_SCSC, RDC_Hours = @RDC_Hours/@FTE_Factor_RDC, RDC_Billed = @RDC_Billed/@FTE_Factor_RDC, MEXSC_Hours = @MEXSC_Hours/@FTE_Factor_MEXSC, MEXSC_Billed = @MEXSC_Billed/@FTE_Factor_MEXSC, GCR_MEX_Hours = @GCR_MEX_Hours/@FTE_Factor_MEXSC, GCR_MEX_Billed = @GCR_MEX_Billed/@FTE_Factor_MEXSC, MPHASIS_Onsite_Hours = @MPHASIS_Onsite_Hours/@FTE_Factor_INDIA, MPHASIS_Onsite_Billed = @MPHASIS_Onsite_Billed/@FTE_Factor_INDIA, MPHASIS_Offsite_Hours = @MPHASIS_Offsite_Hours/@FTE_Factor_INDIA, MPHASIS_Offsite_Billed = @MPHASIS_Offsite_Billed/@FTE_Factor_INDIA, GCR_SYD_Hours = @GCR_SYD_Hours/@FTE_Factor_GCR_SYDNEY, GCR_SYD_Billed = @GCR_SYD_Billed/@FTE_Factor_GCR_SYDNEY, KOREA_Hours = @KOREA_Hours/@FTE_Factor_KOREA, KOREA_Billed = @KOREA_Billed/@FTE_Factor_KOREA, OTHER_Hours = @OTHER_Hours/@FTE_Factor_OTHER, OTHER_Billed = @OTHER_Billed/@FTE_Factor_OTHER, HPINDIA_Hours = @HPINDIA_Hours/@FTE_Factor_INDIA, HPINDIA_Billed = @HPINDIA_Billed/@FTE_Factor_INDIA,
TotalHours = @SCSC_Hours/@FTE_Factor_SCSC + @RDC_Hours/@FTE_Factor_RDC + @MEXSC_Hours/@FTE_Factor_MEXSC + @GCR_MEX_Hours/@FTE_Factor_MEXSC + @MPHASIS_Onsite_Hours/@FTE_Factor_INDIA + @MPHASIS_Offsite_Hours/@FTE_Factor_INDIA + @GCR_SYD_Hours/@FTE_Factor_GCR_SYDNEY + @KOREA_Hours/@FTE_Factor_KOREA + @OTHER_Hours/@FTE_Factor_OTHER + @HPINDIA_Hours/@FTE_Factor_INDIA,
TotalBilled = @SCSC_Billed/@FTE_Factor_SCSC + @RDC_Billed/@FTE_Factor_RDC + @MEXSC_Billed/@FTE_Factor_MEXSC + @GCR_MEX_Billed/@FTE_Factor_MEXSC + @MPHASIS_Onsite_Billed/@FTE_Factor_INDIA + @MPHASIS_Offsite_Billed/@FTE_Factor_INDIA + @GCR_SYD_Billed/@FTE_Factor_GCR_SYDNEY + @KOREA_Billed/@FTE_Factor_KOREA + @OTHER_Billed/@FTE_Factor_OTHER + @HPINDIA_Billed/@FTE_Factor_INDIA
where RecNumber = 5

Update #TEMP_OUT set SCSC_Hours = @FTE_Factor_SCSC, RDC_Hours = @FTE_Factor_RDC, MEXSC_Hours = @FTE_Factor_MEXSC, GCR_MEX_Hours = @FTE_Factor_MEXSC, MPHASIS_Onsite_Hours = @FTE_Factor_INDIA, MPHASIS_Offsite_Hours = @FTE_Factor_INDIA, GCR_SYD_Hours = @FTE_Factor_GCR_SYDNEY, KOREA_Hours = @FTE_Factor_KOREA, OTHER_Hours = @FTE_Factor_OTHER, HPINDIA_Hours = @FTE_Factor_INDIA
where RecNumber = 7

----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

Select RecNumber, RecType, RecDesc, HourlyBillingRate, FundingPct, TotalHours, TotalBilled, SCSC_Hours, SCSC_Billed, RDC_Hours, RDC_Billed, MEXSC_Hours, MEXSC_Billed, GCR_MEX_Hours, GCR_MEX_Billed, MPHASIS_Onsite_Hours, MPHASIS_Onsite_Billed, MPHASIS_Offsite_Hours, MPHASIS_Offsite_Billed, HPINDIA_Hours, HPINDIA_Billed, GCR_SYD_Hours, GCR_SYD_Billed, KOREA_Hours, KOREA_Billed, OTHER_Hours, OTHER_Billed, R10_Client, R30_Project
from #TEMP_OUT order by AutoKey

select * from #TEMP_OUT order by AutoKey
