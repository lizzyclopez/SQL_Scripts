SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

/* ==========================================================================================
 2004-12-01 - RG Change exec('Drop View dbo.SP_Get_AFE_Resource_Detail') to If Exists.
 2004-12-01 - RG Change exec('Drop View dbo.SP_Get_AFE_Resource_Detail2') to If Exists.
 2005-03-15 - LL Change @ProjectID and ProjectID from int to bigint.
 2005-09-12 - RG Add new column COBusinessLead after the AFE Number. The AFE_Summary_View & FTE_Approved_Time view was changed to include new column. 
 2005-10-11 - RG Eliminate the ZERO rows (TotalHours=0, COApprovedFTEs=0, RecordType in (10,20,30 ) and create TOTALS on RecNumber 20 line (Program).
 2005-11-08 - RG Change Parameter list to allow multiple Program Groups.
 2008-06-27 - LL Change the column descriptons to the new titles and add onshore and offshore.
 ========================================================================================== */
-- Get_AFE_Resource_Detail @DateFrom='2005-8-1', @DateTo='2005-8-30',@ProgGroupID = '6000,6001,6002,6003'
-- Get_AFE_Resource_Detail_GCR @DateFrom='2002-8-1', @DateTo='2002-8-31', @SolutionCentreList='''MIRAMAR SOLUTION CENTRE'', ''MEXICO CITY SOLUTION CENTRE'''

ALTER PROCEDURE [dbo].[Get_AFE_Resource_Detail] (@DateFrom datetime = NULL, @DateTo datetime = NULL, @ProgGroupID varchar(100) = '-1', @FundCatID int = -1, @FundCatIDList varchar(100) = '-1', @StatusID int = -1, @AFEID int = -1, @ProjectID bigint = -1, @SolutionCentreList varchar(500) = '-1', @CurrentMonth varchar(6) = NULL, @OutputTable varchar(30) = NULL)
AS
-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
SET NOCOUNT ON

-- Declare common variables.
DECLARE @SQL_statement varchar(1000)
set @SQL_statement = ''

-- Build the WHERE clause for the new VIEW.
if ( @DateFrom is not NULL )
    select @SQL_statement = @SQL_statement+' and WorkDate >= '''+convert(varchar(25), @DateFrom, 101)+''''
if ( @DateTo is not NULL )
    select @SQL_statement = @SQL_statement+' and WorkDate <= '''+convert(varchar(25), @DateTo, 101)+''''
if ( @ProgGroupID <> '-1' )
    select @SQL_statement = @SQL_statement+' and Prog_GroupID in ('+@ProgGroupID+')'
if ( @FundCatID > 0 )
    select @SQL_statement = @SQL_statement+' and Funding_CatID = '+convert(varchar(10), @FundCatID)
if ( @FundCatIDList <> '-1' )
    select @SQL_statement = @SQL_statement+' and Funding_CatID in ('+@FundCatIDList+')'
if ( @StatusID > 0 )
    select @SQL_statement = @SQL_statement+' and ProjectStatusID = '+convert(varchar(10), @StatusID)
if ( @AFEID > 0 )
    select @SQL_statement = @SQL_statement+' and AFE_DescID = '+convert(varchar(10), @AFEID)
if ( @ProjectID > 0 )
    select @SQL_statement = @SQL_statement+' and ProjectID = '+convert(varchar(25), @ProjectID)
if ( @SolutionCentreList <> '-1' )
    select @SQL_statement = @SQL_statement+' and ResourceOrg in ('+@SolutionCentreList+')'

-- Drop the temp VIEW if it exists.
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_Get_AFE_Resource_Detail]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[SP_Get_AFE_Resource_Detail]

-- Create new temp VIEW.
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Resource_Detail AS 
select * from AFE_Resource_Summary_View  where 1=1 ' + @SQL_statement
exec (@SQL_statement)

-- Copy the group hours data from the temp VIEW into #TEMP_IN working storage.
select ProgramGroup,Program,AFEDesc,ProjectTitle,TaskName,EventList,eventname,ResourceName,
    billingid,Prog_GroupID,ProgramID,AFE_DescID,Client,BillingFlag,ClientFundingPct,
    ClientFundedBy,BillingType,Type,TaskClientFundingPct,TaskClientFundedBy,Funding_CatID,ProjectStatusID,
    ResourceNumber,ProjectID,TaskID,eventlistid,sum(hours) as hours, COBusinessLead
into #TEMP_IN
from dbo.SP_Get_AFE_Resource_Detail
group by ProgramGroup,Program,AFEDesc,ProjectTitle,TaskName,EventList,eventname,ResourceName,
    billingid,Prog_GroupID,ProgramID,AFE_DescID,Client,BillingFlag,ClientFundingPct,
    ClientFundedBy,BillingType,Type,TaskClientFundingPct,TaskClientFundedBy,
    Funding_CatID,ProjectStatusID,ResourceNumber,ProjectID,TaskID,eventlistid, COBusinessLead
order by ProgramGroup,Program,AFEDesc,ProjectTitle,TaskName,EventList,eventname,ResourceName

-- drop temporary view 
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_Get_AFE_Resource_Detail]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[SP_Get_AFE_Resource_Detail]

-- Alter table definitions.
ALTER TABLE #TEMP_IN ADD Appr_FTE_Hours decimal(7,2) NULL
ALTER TABLE #TEMP_IN ADD CurrentMonth varchar(6) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN TaskID int NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ProjectID bigint NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ResourceNumber varchar(15) NULL

-- Build the WHERE clause for the second temp VIEW.
set @SQL_statement = ''
if ( @ProgGroupID <> '-1' )
    select @SQL_statement = @SQL_statement+' and Prog_GroupID in ('+@ProgGroupID+')'
if ( @CurrentMonth is not NULL )
    select @SQL_statement = @SQL_statement+' and CurrentMonth = '+@CurrentMonth
if ( @FundCatID > 0 )
    select @SQL_statement = @SQL_statement+' and Funding_CatID = '+convert(varchar(10), @FundCatID)
if ( @FundCatIDList <> '-1' )
    select @SQL_statement = @SQL_statement+' and Funding_CatID in ('+@FundCatIDList+')'
if ( @AFEID > 0 )
    select @SQL_statement = @SQL_statement+' and AFE_DescID = '+convert(varchar(10), @AFEID)
if ( @SolutionCentreList <> '-1' )
    select @SQL_statement = @SQL_statement+' and 1=2' 

-- Drop the second temp VIEW if it exists.
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_Get_AFE_Resource_Detail2]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[SP_Get_AFE_Resource_Detail2]

-- Create the second temp VIEW.
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Resource_Detail2 AS 
select * from FTE_Approved_Time where Appr_FTE_Hours > 0 ' + @SQL_statement
exec (@SQL_statement)

-- Copy the data from the second temp VIEW into #TEMP_IN.
insert #TEMP_IN ( AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead )
select AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID ,COBusinessLead from dbo.SP_Get_AFE_Resource_Detail2

-- Drop the second temp VIEW.
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_Get_AFE_Resource_Detail2]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[SP_Get_AFE_Resource_Detail2]

-- Adjust the Hours according to the ClientFundingPct by CO
update #TEMP_IN set Hours = isnull(ClientFundingPct,100)/100*Hours where isnull(ClientFundingPct,0) > 0
update #TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0

-- Set the Factor.
Declare @Factor decimal(5,2)
if ( month(@datefrom) <> month(getdate())) or ( year(@datefrom) <> year(getdate()))
    set @Factor = 1
else
    select @Factor = convert(float, day(getdate())) / convert(float, day(DATEADD(d, -DAY(DATEADD(m,1,getdate())),DATEADD(m,1,getdate()))))

-- Create the output table #TEMP_OUT.
CREATE TABLE [dbo].[#TEMP_OUT] ( 
 [AutoKey][int] IDENTITY (0, 1) NOT NULL,
 [RecNumber][int] NULL,           -- 0, 3, 6, 10, 20, 30, 40, 50, 55, 56, 60, 99
 [RecType] [varchar] (100) NULL, -- ProgramGroup / Program / AFEDesc / Project / Task / Event / Resource
 [RecDesc] [varchar] (100) NULL, -- PIV Data
 [RecTypeID] [bigint] NULL,          -- Prog_GroupID / ProgramID / AFE_DescID / ProjectID / TaskID 
 [FundingCat] [varchar] (30) NULL,
 [AFENumber] [varchar] (20) NULL ,
 [COBusinessLead] [varchar] (100) NULL ,
 [Location] [varchar] (30) NULL,
 [TotalHours] [decimal](10,2) NULL,
 [ActualFTEs] [decimal](10,2) NULL,
 [COApprovedFTEs] [decimal](10,2) NULL,
 [EDSVariance] [decimal](10,2) NULL,
 [JuniorSEHours] [decimal](10,2) NULL,
 [SEHours] [decimal](10,2) NULL,
 [ADVSEHours] [decimal](10,2) NULL,
 [SeniorSEHours] [decimal](10,2) NULL,
 [PLHours] [decimal](10,2) NULL,
 [JuniorTPFHours] [decimal](10,2) NULL,
 [SETPFHours] [decimal](10,2) NULL,
 [ADVTPFHours] [decimal](10,2) NULL,
 [SeniorTPFHours] [decimal](10,2) NULL,
 [PLTPFHours] [decimal](10,2) NULL,
 [ExpectedMTDFTE] [decimal](10,2) NULL,
 [VarianceMTDFTE] [decimal](10,2) NULL,
 [R10_ProgramGroup] [varchar] (100) NULL,
 [R20_Program] [varchar] (100) NULL,
 [R30_AFEDesc] [varchar] (100) NULL,
 [R40_Project] [varchar] (100) NULL,
 [R50_Task] [varchar] (100) NULL,
 [R55_EventTitle] [varchar] (100) NULL,
 [R56_Event] [varchar] (100) NULL
) ON [PRIMARY]

-- Check to see if we have data to process.
Declare @row_count int
select @row_count = count(*) from #TEMP_IN
if @row_count = 0
begin
    insert #TEMP_OUT (RecNumber) values (99)
    goto No_Data_To_Process
end

-- Data was found, build the report, populate summary rows.
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Total Continental (CO)'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 3, 'Conversion', 'FTE Conversion'

-- Declare variables.
DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID int, @CurProgram varchar(100), @CurProgramID  int, @CurCOBusinessLead varchar (100), @CurAFEDesc varchar (100), @CurAFE_DescID int, @CurProjectTitle varchar(100), @CurProjID bigint, @CurTaskName varchar(100), @CurTaskID int, @CurResourceName varchar(100), @CurEventList varchar(100), @CurEventName varchar(100), @Billing_Type varchar(150), @Hours decimal(10,2), @MaxProgGroup int, @MaxProg int, @MaxAFEDesc int, @MaxProj bigint, @MaxTask int, @MaxEvent int

-- Declare additional variables for Hours calculation.   
DECLARE @JRSE decimal(10,2), @SE decimal(10,2), @ADVSE decimal(10,2), @SENSE decimal(10,2), @PL decimal(10,2),
        @JRTPF decimal(10,2), @SETPF decimal(10,2), @ADVTPF decimal(10,2), @SENTPF decimal(10,2), @PLTPF decimal(10,2)

-- Declare variables additional variables for Summary calculation.  
DECLARE @JuniorSEHours decimal(10,2), @SEHours decimal(10,2), @ADVSEHours decimal(10,2), @SeniorSEHours decimal(10,2),
        @PLHours decimal(10,2), @JuniorTPFHours decimal(10,2), @SETPFHours decimal(10,2), @ADVTPFHours decimal(10,2),
        @SeniorTPFHours decimal(10,2), @PLTPFHours decimal(10,2), @TotalHours decimal(10,2), @COApprovedFTEs decimal(10,2)

-----------------------------------------------------------------------------------------------------------------------
-- ProgramGroup_cursor, populates record type 10.
DECLARE ProgramGroup_cursor CURSOR FOR 
    select distinct ProgramGroup, Prog_GroupID from #TEMP_IN
    where ProgramGroup is not null order by ProgramGroup 
OPEN ProgramGroup_cursor
FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID 
WHILE @@FETCH_STATUS = 0
BEGIN
	insert #TEMP_OUT (RecNumber) values (10) -- A blank line
	insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID) 
	select 10, 'ProgGroup/Total', @CurProgramGroup, @CurProg_GroupID
	select @MaxProgGroup = max(AutoKey) from #TEMP_OUT

	-----------------------------------------------------------------------------------------------------------------------
	-- Program_cursor, populates record type 20.
	DECLARE Program_cursor CURSOR FOR 
		select distinct Program, ProgramID, COBusinessLead from #TEMP_IN
		where ProgramGroup = @CurProgramGroup and Program is not null order by Program
	OPEN Program_cursor
	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID, @CurCOBusinessLead
    WHILE @@FETCH_STATUS = 0
    BEGIN
		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, COBusinessLead)
        select 20, 'Program', @CurProgram, @CurProgramID, @CurProgramGroup, @CurCOBusinessLead
		select @MaxProg = max(AutoKey) from #TEMP_OUT

		-----------------------------------------------------------------------------------------------------------------------                
		-- AFEDesc_cursor, populates record type 30.
		DECLARE AFEDesc_cursor CURSOR FOR 
			select distinct AFEDesc, AFE_DescID from #TEMP_IN
			where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFEDesc is not null order by AFEDesc
		OPEN AFEDesc_cursor
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID
		WHILE @@FETCH_STATUS = 0
        BEGIN
			insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program)
            select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID, @CurProgramGroup, @CurProgram
            select @MaxAFEDesc = max(AutoKey) from #TEMP_OUT

			-----------------------------------------------------------------------------------------------------------------------
			-- ProjDesc_cursor, populates record type 40.
			DECLARE ProjDesc_cursor CURSOR FOR 
				select distinct ProjectID, ProjectTitle from #TEMP_IN
				where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID is not null order by ProjectTitle 
			OPEN ProjDesc_cursor    
			FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
			WHILE @@FETCH_STATUS = 0
            BEGIN
				insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, R30_AFEDesc)
                select 40, 'ProjDesc', @CurProjectTitle, @CurProjID, @CurProgramGroup, @CurProgram, @CurAFEDesc
                select @MaxProj = max(AutoKey) from #TEMP_OUT 

				-----------------------------------------------------------------------------------------------------------------------
                -- Task_cursor, populates record type 50.
				DECLARE Task_cursor CURSOR FOR
					select distinct TaskID, TaskName from #TEMP_IN
					where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID order by TaskName
				OPEN Task_cursor            
                FETCH NEXT FROM Task_cursor INTO @CurTaskID, @CurTaskName
                WHILE @@FETCH_STATUS = 0
                BEGIN
					insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project)
                    select 50, 'TaskDesc', @CurTaskName, @CurTaskID, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle
                    select @MaxTask = max(AutoKey) from #TEMP_OUT

					----------------------------------------------------------------------------------------------------------------------
					--Resource_cursor, populates Resources under Tasks, record type 60. Resources directly under Tasks (EventList and EventName is NULL).
					DECLARE Resource_cursor CURSOR FOR
						select  ResourceName,BillingType, Hours from #TEMP_IN
                        where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and TaskID = @CurTaskID and EventList is NULL and EventName is NULL and ResourceName is not NULL order by ResourceName
					OPEN Resource_cursor                    
					FETCH NEXT FROM Resource_cursor INTO @CurResourceName,@Billing_Type, @hours
                    WHILE @@FETCH_STATUS = 0
                    BEGIN    
						-- determine billing type for Resource and then insert record
                        if @Billing_Type = 'Junior SE'
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, JuniorSEHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
                            select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName            
						if @Billing_Type = 'SE'
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, SEHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
                            select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Advanced SE'
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, ADVSEHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
                            select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Senior SE'
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, SeniorSEHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
                            select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Project Leader'
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, PLHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
							select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Junior SE TPF'
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, JuniorTPFHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
							select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'SE TPF'
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, SETPFHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
							select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Advanced SE TPF'
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, ADVTPFHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
							select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Senior SE TPF'
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, SeniorTPFHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
                            select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
						if @Billing_Type = 'Project Leader TPF'
							insert #TEMP_OUT (RecNumber, RecType, RecDesc, PLTPFHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
                            select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
                                            
					FETCH NEXT FROM Resource_cursor INTO @CurResourceName,@Billing_Type, @hours
                    END    
                    CLOSE Resource_cursor
                    DEALLOCATE Resource_cursor

					----------------------------------------------------------------------------------------------------------------------
					-- Resources under Events of Tasks (EventList and EventName is NOT NULL)
					DECLARE Event_cursor CURSOR FOR
						select distinct EventList, EventName from #TEMP_IN
					    where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and TaskID = @CurTaskID and EventList is not NULL and EventName is not NULL 
					    order by EventList, EventName
					OPEN Event_cursor                    
					FETCH NEXT FROM Event_cursor INTO @CurEventList, @CurEventName
					WHILE @@FETCH_STATUS = 0
					BEGIN
						if not exists (select * from #TEMP_OUT where AutoKey > @MaxTask and RecNumber = 55 and RecDesc = @CurEventList)
						insert #TEMP_OUT (RecNumber, RecType, RecDesc , R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task)
						select 55, 'EventTitle', @CurEventList, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName
    
						insert #TEMP_OUT (RecNumber, RecType, RecDesc, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle)
						select 56, 'EventDesc', @CurEventName, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList
						select @MaxEvent = max(AutoKey) from #TEMP_OUT

						-----------------------------------------------------------------------------------------------------------------------
						DECLARE Resource_cursor CURSOR FOR
							select  ResourceName,BillingType, Hours from #TEMP_IN
						    where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFE_DescID = @CurAFE_DescID and ProjectID = @CurProjID and TaskID = @CurTaskID and EventList = @CurEventList and EventName = @CurEventName and ResourceName is not null
						    order by ResourceName
						OPEN Resource_cursor
						FETCH NEXT FROM Resource_cursor INTO @CurResourceName, @Billing_Type, @hours
						WHILE @@FETCH_STATUS = 0
						BEGIN
							-- Determine billing type for Resource and then insert record.
							if @Billing_Type = 'Junior SE'
								insert #TEMP_OUT (RecNumber, RecType, RecDesc, JuniorSEHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
								select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
							if @Billing_Type = 'SE'
								insert #TEMP_OUT (RecNumber, RecType, RecDesc, SEHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
								select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
							if @Billing_Type = 'Advanced SE'
								insert #TEMP_OUT (RecNumber, RecType, RecDesc, ADVSEHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
								select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
							if @Billing_Type = 'Senior SE'								insert #TEMP_OUT (RecNumber, RecType, RecDesc, SeniorSEHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
								select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
							if @Billing_Type = 'Project Leader'
								insert #TEMP_OUT (RecNumber, RecType, RecDesc, PLHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
							    select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
							if @Billing_Type = 'Junior SE TPF'
								insert #TEMP_OUT (RecNumber, RecType, RecDesc, JuniorTPFHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
								select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
							if @Billing_Type = 'SE TPF'
								insert #TEMP_OUT (RecNumber, RecType, RecDesc, SETPFHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
								select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
							if @Billing_Type = 'Advanced SE TPF'
								insert #TEMP_OUT (RecNumber, RecType, RecDesc, ADVTPFHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
							    select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
							if @Billing_Type = 'Senior SE TPF'
								insert #TEMP_OUT (RecNumber, RecType, RecDesc, SeniorTPFHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
							    select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
							if @Billing_Type = 'Project Leader TPF'
								insert #TEMP_OUT (RecNumber, RecType, RecDesc, PLTPFHours, R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R55_EventTitle, R56_Event)
								select 60, 'ResourceName', @CurResourceName, @hours, @CurProgramGroup, @CurProgram, @CurAFEDesc, @CurProjectTitle, @CurTaskName, @CurEventList, @CurEventName
                
						FETCH NEXT FROM Resource_cursor INTO @CurResourceName,@Billing_Type, @hours
						END    
						CLOSE Resource_cursor
						DEALLOCATE Resource_cursor

					-----------------------------------------------------------------------------------------------------------------------
					-- SUMMARIZE Total Hours for each event (vertical), record type 60.  
					select @JuniorSEHours = sum(isnull(JuniorSEHours,0)),
					       @SEHours = sum(isnull(SEHours,0)),
					       @ADVSEHours = sum(isnull(ADVSEHours,0)),
					       @SeniorSEHours = sum(isnull(SeniorSEHours,0)),
					       @PLHours = sum(isnull(PLHours,0)),
					       @JuniorTPFHours = sum(isnull(JuniorTPFHours,0)),
						   @SETPFHours = sum(isnull(SETPFHours,0)),
						   @ADVTPFHours = sum(isnull(ADVTPFHours,0)),
					       @SeniorTPFHours = sum(isnull(SeniorTPFHours,0)),
					       @PLTPFHours = sum(isnull(PLTPFHours,0)),
					       @TotalHours = sum(isnull(TotalHours,0))
					from #TEMP_OUT where AutoKey > @MaxEvent and RecNumber = 60

					update #TEMP_OUT
					set JuniorSEHours = @JuniorSEHours,
						SEHours = @SEHours,
					    ADVSEHours = @ADVSEHours,
					    SeniorSEHours = @SeniorSEHours,
					    PLHours = @PLHours,
					    JuniorTPFHours = @JuniorTPFHours,
					    SETPFHours = @SETPFHours,
					    ADVTPFHours = @ADVTPFHours,
					    SeniorTPFHours = @SeniorTPFHours,
					    PLTPFHours = @PLTPFHours,
					    TotalHours = @TotalHours
					where AutoKey = @MaxEvent
    
				FETCH NEXT FROM Event_cursor INTO @CurEventList, @CurEventName
				END    
				CLOSE Event_cursor
				DEALLOCATE Event_cursor

			-----------------------------------------------------------------------------------------------------------------------
			-- SUMMARIZE Total Hours for each task (vertical), record type 60.
			select @JuniorSEHours = sum(isnull(JuniorSEHours,0)),
				@SEHours = sum(isnull(SEHours,0)),
                @ADVSEHours = sum(isnull(ADVSEHours,0)),
                @SeniorSEHours = sum(isnull(SeniorSEHours,0)),
                @PLHours = sum(isnull(PLHours,0)),
                @JuniorTPFHours = sum(isnull(JuniorTPFHours,0)),
                @SETPFHours = sum(isnull(SETPFHours,0)),
                @ADVTPFHours = sum(isnull(ADVTPFHours,0)),
                @SeniorTPFHours = sum(isnull(SeniorTPFHours,0)),
                @PLTPFHours = sum(isnull(PLTPFHours,0)),
                @TotalHours = sum(isnull(TotalHours,0))
			from #TEMP_OUT where AutoKey > @MaxTask and RecNumber = 60

            update #TEMP_OUT
            set JuniorSEHours = @JuniorSEHours,
				SEHours = @SEHours,
				ADVSEHours = @ADVSEHours,
                SeniorSEHours = @SeniorSEHours,
                PLHours = @PLHours,
                JuniorTPFHours = @JuniorTPFHours,
                SETPFHours = @SETPFHours,
                ADVTPFHours = @ADVTPFHours,
                SeniorTPFHours = @SeniorTPFHours,
                PLTPFHours = @PLTPFHours,
                TotalHours = @TotalHours
			where AutoKey = @MaxTask

		FETCH NEXT FROM Task_cursor INTO @CurTaskID, @CurTaskName
        END    
        CLOSE Task_cursor
        DEALLOCATE Task_cursor

	-----------------------------------------------------------------------------------------------------------------------
               
		-- SUMMARIZE Total Hours at Project Level on 10 fields (vertical), record type 50.
		select @JuniorSEHours = sum(isnull(JuniorSEHours,0)),
			@SEHours = sum(isnull(SEHours,0)),
		    @ADVSEHours = sum(isnull(ADVSEHours,0)),
		    @SeniorSEHours = sum(isnull(SeniorSEHours,0)),
		    @PLHours = sum(isnull(PLHours,0)),
			@JuniorTPFHours = sum(isnull(JuniorTPFHours,0)),
		    @SETPFHours = sum(isnull(SETPFHours,0)),
		    @ADVTPFHours = sum(isnull(ADVTPFHours,0)),
		    @SeniorTPFHours = sum(isnull(SeniorTPFHours,0)),
		    @PLTPFHours = sum(isnull(PLTPFHours,0)),
		    @TotalHours = sum(isnull(TotalHours,0))
		from #TEMP_OUT where AutoKey > @MaxProj and RecNumber = 50 

		update #TEMP_OUT
		set JuniorSEHours = @JuniorSEHours,
			SEHours = @SEHours,
		    ADVSEHours = @ADVSEHours,
			SeniorSEHours = @SeniorSEHours,
			PLHours = @PLHours,
			JuniorTPFHours = @JuniorTPFHours,
			SETPFHours = @SETPFHours,
			ADVTPFHours = @ADVTPFHours,
			SeniorTPFHours = @SeniorTPFHours,
			PLTPFHours = @PLTPFHours,
			TotalHours = @TotalHours
		where AutoKey = @MaxProj
                
        FETCH NEXT FROM ProjDesc_cursor INTO @CurProjID, @CurProjectTitle
        END    
		CLOSE ProjDesc_cursor
		DEALLOCATE ProjDesc_cursor

		-----------------------------------------------------------------------------------------------------------------------
        -- GET funding category and location combo.
		Declare @@out_location varchar (100), @@out_fundingcat varchar (100), @@out_afenumber varchar (20), @@out_programmgr varchar (50), @@Total_FTE float             
        set @@out_location  = NULL
        set @@out_fundingcat = NULL
        set @@out_afenumber = NULL
        set @@Total_FTE = NULL
        exec GET_Location_Combo @CurAFE_DescID, @DateFrom, @DateTo, @@out_location OUTPUT, @@out_fundingcat OUTPUT, @@out_afenumber OUTPUT, @@out_programmgr OUTPUT, @@Total_FTE OUTPUT
        -- print '--- Call GET_Location_Combo ---'
        -- print '@CurAFE_DescID   = '+ isnull(convert(varchar(10),@CurAFE_DescID),'NULL1')
        -- print '@DateFrom        = '+ isnull(convert(varchar(20),@DateFrom),'NULL2')
        -- print '@DateTo          = '+ isnull(convert(varchar(20),@DateTo),'NULL3')
        -- print '@@out_location   = '+ isnull(@@out_location,'NULL4')
        -- print '@@out_fundingcat = '+ isnull(@@out_fundingcat,'NULL5')
        -- print '@@out_afenumber = '+ isnull(@@out_afenumber,'NULL55')
        -- print '@@Total_FTE      = '+ isnull(convert(varchar(10),@@Total_FTE),'NULL6')
                
        -- UPDATE temporary table --        
		update #TEMP_OUT
        set location = @@out_location,
			fundingcat = @@out_fundingcat,
            AFENumber = @@out_afenumber,
            COApprovedFTEs = isnull(@@Total_FTE,0)
		where AutoKey = @MaxAFEDesc

        -- Populate TotalHours Column for record type 40, 50, 56, 60 (horizontal add up)    
		update #TEMP_OUT
        set TotalHours = isnull(JuniorSEHours,0)+isnull(SEHours,0)+isnull(ADVSEHours,0)+
			isnull(SeniorSEHours,0)+isnull(PLHours,0)+isnull(JuniorTPFHours,0)+isnull(SETPFHours,0)+
            isnull(ADVTPFHours,0)+isnull(SeniorTPFHours,0)+isnull(PLTPFHours,0)
		where AutoKey > @MaxProgGroup and RecNumber in (40, 50, 56, 60)

		-- UPDATE Summary Fields --
        update #TEMP_OUT set ActualFTEs = TotalHours/143.5 where AutoKey > @MaxAFEDesc and RecNumber in (40, 50, 56, 60)
        update #TEMP_OUT set TotalHours = (select isnull(sum(TotalHours),0) from #TEMP_OUT where AutoKey > @MaxAFEDesc and RecNumber = 40), 
				ActualFTEs = (select isnull(sum(ActualFTEs),0) from #TEMP_OUT where AutoKey > @MaxAFEDesc and RecNumber = 40) where AutoKey = @MaxAFEDesc 
		update #TEMP_OUT set ActualFTEs = TotalHours/143.5 where AutoKey = @MaxAFEDesc
		update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey = @MaxAFEDesc

    FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID
    END    
	CLOSE AFEDesc_cursor
	DEALLOCATE AFEDesc_cursor

	-----------------------------------------------------------------------------------------------------------------------
	-- Update Program Record (20) with summary totals, populate TotalHours and COApprovedFTEs.
	-- Populate TotalHours and COApprovedFTEs only        
	select @JuniorSEHours = sum(isnull(JuniorSEHours,0)),
		@SEHours = sum(isnull(SEHours,0)),
		@ADVSEHours = sum(isnull(ADVSEHours,0)),
		@SeniorSEHours = sum(isnull(SeniorSEHours,0)),
		@PLHours = sum(isnull(PLHours,0)),
        @JuniorTPFHours = sum(isnull(JuniorTPFHours,0)),
        @SETPFHours = sum(isnull(SETPFHours,0)),
        @ADVTPFHours = sum(isnull(ADVTPFHours,0)),
        @SeniorTPFHours = sum(isnull(SeniorTPFHours,0)),
        @PLTPFHours = sum(isnull(PLTPFHours,0)),
        @TotalHours = sum(isnull(TotalHours,0))
	from #TEMP_OUT where AutoKey > @MaxProg and RecNumber = 40

	select @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)) from #TEMP_OUT where AutoKey > @MaxProg and RecNumber = 30

    update #TEMP_OUT
    set JuniorSEHours = @JuniorSEHours,
		SEHours = @SEHours,
        ADVSEHours = @ADVSEHours,
        SeniorSEHours = @SeniorSEHours,
        PLHours = @PLHours,
        JuniorTPFHours = @JuniorTPFHours,
        SETPFHours = @SETPFHours,
        ADVTPFHours = @ADVTPFHours,
        SeniorTPFHours = @SeniorTPFHours,
        PLTPFHours = @PLTPFHours,
        TotalHours = @TotalHours,
        ActualFTEs = @TotalHours/143.5,
        COApprovedFTEs = @COApprovedFTEs,
        EDSVariance = @TotalHours/143.5 - @COApprovedFTEs
	where AutoKey = @MaxProg

	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID, @CurCOBusinessLead
	END
	CLOSE Program_cursor
	DEALLOCATE Program_cursor

	-----------------------------------------------------------------------------------------------------------------------
	-- Update total information for 10 fields (vertical add up)
    select @JuniorSEHours = sum(isnull(JuniorSEHours,0)),
		@SEHours = sum(isnull(SEHours,0)),
        @ADVSEHours = sum(isnull(ADVSEHours,0)),
        @SeniorSEHours = sum(isnull(SeniorSEHours,0)),
        @PLHours = sum(isnull(PLHours,0)),
        @JuniorTPFHours = sum(isnull(JuniorTPFHours,0)),
        @SETPFHours = sum(isnull(SETPFHours,0)),
        @ADVTPFHours = sum(isnull(ADVTPFHours,0)),
        @SeniorTPFHours = sum(isnull(SeniorTPFHours,0)),
        @PLTPFHours = sum(isnull(PLTPFHours,0)),
        @TotalHours = sum(isnull(TotalHours,0))
	from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 40

	select @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)) from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30
        
	update #TEMP_OUT
    set JuniorSEHours = @JuniorSEHours,
		SEHours = @SEHours,
        ADVSEHours = @ADVSEHours,
        SeniorSEHours = @SeniorSEHours,
        PLHours = @PLHours,
        JuniorTPFHours = @JuniorTPFHours,
        SETPFHours = @SETPFHours,
        ADVTPFHours = @ADVTPFHours,
        SeniorTPFHours = @SeniorTPFHours,
        PLTPFHours = @PLTPFHours,
        TotalHours = @TotalHours,
        ActualFTEs = @TotalHours/143.5,
        COApprovedFTEs = @COApprovedFTEs,
        EDSVariance = @TotalHours/143.5 - @COApprovedFTEs
	where AutoKey = @MaxProgGroup

FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID
END
CLOSE ProgramGroup_cursor
DEALLOCATE ProgramGroup_cursor

-----------------------------------------------------------------------------------------------------------------------
-- Set all the NULL values to 0 for 60 records
update #TEMP_OUT set JuniorSEHours = 0 where RecNumber = 60 and JuniorSEHours is null 
update #TEMP_OUT set SEHours = 0 where RecNumber = 60 and SEHours is null 
update #TEMP_OUT set ADVSEHours = 0 where RecNumber = 60 and ADVSEHours is null 
update #TEMP_OUT set SeniorSEHours = 0 where RecNumber = 60 and SeniorSEHours is null 
update #TEMP_OUT set PLHours = 0 where RecNumber = 60 and PLHours is null 
update #TEMP_OUT set JuniorTPFHours = 0 where RecNumber = 60 and JuniorTPFHours is null 
update #TEMP_OUT set SETPFHours = 0 where RecNumber = 60 and SETPFHours is null 
update #TEMP_OUT set ADVTPFHours = 0 where RecNumber = 60 and ADVTPFHours is null 
update #TEMP_OUT set SeniorTPFHours = 0 where RecNumber = 60 and SeniorTPFHours is null 
update #TEMP_OUT set PLTPFHours = 0 where RecNumber = 60 and PLTPFHours is null 

-- Calculate and Populate the 0 and 3 records for 12 fields (vertical add up)
select  @JuniorSEHours = sum(isnull(JuniorSEHours,0)),
        @SEHours = sum(isnull(SEHours,0)),
        @ADVSEHours = sum(isnull(ADVSEHours,0)),
        @SeniorSEHours = sum(isnull(SeniorSEHours,0)),
        @PLHours = sum(isnull(PLHours,0)),
        @JuniorTPFHours = sum(isnull(JuniorTPFHours,0)),
        @SETPFHours = sum(isnull(SETPFHours,0)),
        @ADVTPFHours = sum(isnull(ADVTPFHours,0)),
        @SeniorTPFHours = sum(isnull(SeniorTPFHours,0)),
        @PLTPFHours = sum(isnull(PLTPFHours,0)),
        @TotalHours = sum(isnull(TotalHours,0)),
        @COApprovedFTEs = sum(isnull(COApprovedFTEs,0))
from #TEMP_OUT where RecNumber = 10

update #TEMP_OUT
set JuniorSEHours = @JuniorSEHours,
    SEHours = @SEHours,
    ADVSEHours = @ADVSEHours,
    SeniorSEHours = @SeniorSEHours,
    PLHours = @PLHours,
    JuniorTPFHours = @JuniorTPFHours,
    SETPFHours = @SETPFHours,
    ADVTPFHours = @ADVTPFHours,
    SeniorTPFHours = @SeniorTPFHours,
    PLTPFHours = @PLTPFHours,
    TotalHours = @TotalHours,
    COApprovedFTEs = @COApprovedFTEs
where RecNumber = 0

update #TEMP_OUT
set JuniorSEHours = @JuniorSEHours/143.5,
    SEHours = @SEHours/143.5,
    ADVSEHours = @ADVSEHours/143.5,
    SeniorSEHours = @SeniorSEHours/143.5,
    PLHours = @PLHours/143.5,
    JuniorTPFHours = @JuniorTPFHours/143.5,
    SETPFHours = @SETPFHours/143.5,
    ADVTPFHours = @ADVTPFHours/143.5,
    SeniorTPFHours = @SeniorTPFHours/143.5,
    PLTPFHours = @PLTPFHours/143.5,
    TotalHours = @TotalHours/143.5, -- value 1
    ActualFTEs = @TotalHours/143.5, -- value 1
    COApprovedFTEs = @COApprovedFTEs
where RecNumber = 3

update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 0
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber in (0,3)
update #TEMP_OUT set ExpectedMTDFTE = COApprovedFTEs * @Factor where COApprovedFTEs is not NULL
update #TEMP_OUT set VarianceMTDFTE = ActualFTEs - ExpectedMTDFTE where COApprovedFTEs is not NULL

-- Remove any rows that have ZERO values in the TotalHours and the COApprovedFTEs
delete #TEMP_OUT where RecNumber in (10,20,30) and (TotalHours = 0 or TotalHours is NULL) and COApprovedFTEs = 0

No_Data_To_Process:
SET NOCOUNT OFF
If ( @OutputTable is NULL )
    Select  RecNumber, RecType, RecDesc, RecTypeID, 
            FundingCat, AFENumber, COBusinessLead, Location,
            TotalHours, ActualFTEs, COApprovedFTEs, EDSVariance,
            JuniorSEHours, SEHours, ADVSEHours, SeniorSEHours, PLHours,
            JuniorTPFHours, SETPFHours, ADVTPFHours, SeniorTPFHours, PLTPFHours,
            ExpectedMTDFTE, VarianceMTDFTE,
            R10_ProgramGroup, R20_Program, R30_AFEDesc, R40_Project, R50_Task, R56_Event
    from #TEMP_OUT order by AutoKey
else 
begin
    -- order by AutoKey will be included in the calling
    set @SQL_statement = 'Select * into '+@OutputTable+' from #TEMP_OUT'
    exec (@SQL_statement)
end
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

