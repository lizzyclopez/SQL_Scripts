--StoredProcedure [dbo].[Get_AFE_Summary_StaffAug]  
drop view [dbo].[SP_Get_AFE_Summary_Airline_View]
drop view [dbo].[SP_Get_AFE_Summary_Airline_View2]
drop table #TEMP_IN
drop table #TEMP_OUT

-- Create new temp VIEW.
Declare @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Summary_Airline_View AS select AFE_Summary_View.*, CO_Resource.Onshore, CO_Resource.Offshore, CO_Resource.Hourly, CO_BillingCode.Billing_CodeID, CO_BillingCode.Description AS NewBillingType
from AFE_Summary_View inner join CO_Resource ON AFE_Summary_View.EDSNETID = CO_Resource.ResourceNumber inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID
where 1=1 and WorkDate >= ''2012-06-01'' and WorkDate <= ''2012-06-30'' '
exec (@SQL_statement) 

-- Copy the data from the temp VIEW into #TEMP_IN working storage.
select * into #TEMP_IN from dbo.SP_Get_AFE_Summary_Airline_View
	
-- Drop the temp VIEW.
exec('Drop View dbo.SP_Get_AFE_Summary_Airline_View')

-- Alter table definitions.
ALTER TABLE #TEMP_IN ADD Appr_FTE_Hours decimal(7,2) NULL
ALTER TABLE #TEMP_IN ADD CurrentMonth varchar(6) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN TaskID varchar(100) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ProjectID uniqueidentifier NULL
ALTER TABLE #TEMP_IN ALTER COLUMN WorkDate datetime NULL
ALTER TABLE #TEMP_IN ALTER COLUMN EDSNETID varchar(15) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN Billing_CodeID int NULL
ALTER TABLE #TEMP_IN ALTER COLUMN NewBillingType varchar(50) NULL

-- Create the second temp VIEW.
Declare @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Summary_Airline_View2 AS select dbo.lkITSABillingCategory.Description AS ITSABillingCat, FTE_Approved_Time.* from FTE_Approved_Time LEFT OUTER JOIN dbo.tblAFEDetail ON FTE_Approved_Time.AFE_DescID = dbo.tblAFEDetail.AFE_DescID LEFT OUTER JOIN dbo.lkITSABillingCategory ON dbo.tblAFEDetail.ITSABillingCategoryID = dbo.lkITSABillingCategory.ITSABillingCategoryID 
where Appr_FTE_Hours > 0 and CurrentMonth = ''201206'' '
exec (@SQL_statement)

--***CHANGED
-- Copy the data from the second temp VIEW into #TEMP_IN.
insert #TEMP_IN (AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, ITSABillingCat, UA_VicePresident)
select AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, ITSABillingCat, UA_VicePresident 
from dbo.SP_Get_AFE_Summary_Airline_View2
	
-- Drop the second temp VIEW.
exec('Drop View dbo.SP_Get_AFE_Summary_Airline_View2')
	
-- Index the #TEMP_IN table.
Create Index IDX1 on #TEMP_IN (Prog_GroupID, ProgramID, AFE_DescID, NewBillingType)

-- Adjust the Hours according to the ClientFundingPct by CO.
update #TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0

------------------------------------------------------------------------------------------------
--drop table #TEMP_OUT

--***CHANGED
-- Create the output table #TEMP_OUT.
CREATE TABLE [dbo].[#TEMP_OUT] ( 
	[AutoKey][int] IDENTITY (0, 1) NOT NULL,
	[RecNumber][int] NULL,
	[RecType] [varchar] (100) NULL, -- ProgramGroup Totals / Program / AFEDesc / Total / FTE Conversion
	[RecDesc] [varchar] (100) NULL, [RecTypeID] [varchar] (100) NULL, [ITSABillingCat] [varchar] (30) NULL, [FundingCat] [varchar] (30) NULL,
	[AFENumber] [varchar] (20) NULL,
	[UAVP] [varchar] (50) NULL,
	[COBusinessLead] [varchar] (100) NULL, [ProgramMgr] [varchar] (50) NULL, [Location] [varchar] (30) NULL, [TotalHours] [decimal](10,2) NULL, [ActualFTEs] [decimal](10,2) NULL, [COApprovedFTEs] [decimal](10,2) NULL, [EDSVariance] [decimal](10,2) NULL, 
	[FTPStaffAugOnshoreHours] [decimal](10,2) NULL, [FTPStaffAugOffshoreHours] [decimal](10,2) NULL, [R10_ProgramGroup] [varchar] (100) NULL, [R20_Program] [varchar] (100) NULL
) ON [PRIMARY]

-- Populate summary rows.
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotal', 'Total United (UA)'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 0, 'GrandTotalConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 1, 'TotalAirline', 'Total Airline'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 1, 'TotalAirlineConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 2, 'TotalADM', 'Total ADM'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 2, 'TotalADMConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 4, 'TotalAFEProd', 'Total AFE Prod'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 4, 'TotalAFEProdConversion', 'FTE Conversion'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'TotalStaffAug', 'Total Staff Augmentation (FTE Based)'
insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 5, 'TotalStafAugConversion', 'FTE Conversion'

-- Data was found, build the report.	
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--***CHANGED
-- Declare additional variables.
DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID varchar(100), @UPVP varchar(50), @CurProgram varchar(100), @CurProgramID varchar(100)
DECLARE @CurCOBusinessLead varchar(100), @CurAFEDesc varchar(100), @CurAFE_DescID int, @MaxProgGroup int, @MaxProgram int, @MaxAFEDesc int, @MaxProj int, @ITSABillingCat varchar(30)
declare @FTPBillingRate decimal(10,2), @year int, @month int, @BillableDays int, @FTPStaffAugOnshore decimal(10,2), @FTPStaffAugOffshore decimal(10,2)
declare	@FTPStaffAugOnshoreHours decimal(10,2), @FTPStaffAugOffshoreHours decimal(10,2), @TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2)

---for testing only
declare @DateFrom datetime, @DateTo datetime
set @DateFrom = '2012-06-01'
set @DateTo = '2012-06-30'

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

--------------------------------------------------------------------------------------------
--***changed
-- ProgramGroup_cursor populates at the Program Group level, record type 10.
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
	-- Program_cursor populates at the Program level, record type 20.
	DECLARE Program_cursor CURSOR FOR 
		select distinct Program, ProgramID from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program is not null order by Program				
	OPEN Program_cursor
	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
	WHILE @@FETCH_STATUS = 0
	BEGIN
    	insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup)
	    select 20, 'Program', @CurProgram, @CurProgramID, @CurProgramGroup
		select @MaxProgram = max(AutoKey) from #TEMP_OUT 

		----------------------------------------------------------------------------------------------
		-- AFEDesc_cursor populates at the AFE level, record type 30.
		DECLARE AFEDesc_cursor CURSOR FOR 
			select distinct AFEDesc, AFE_DescID, COBusinessLead from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFEDesc is not null order by AFEDesc
		OPEN AFEDesc_cursor
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
		WHILE @@FETCH_STATUS = 0
       	BEGIN
       		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, COBusinessLead)
       		select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID, @CurProgramGroup, @CurProgram, @CurCOBusinessLead
			select @MaxAFEDesc = max(AutoKey) from #TEMP_OUT

			--------------------------------------------------------------------------------------------
			-- Populate the ITSA Billing Category.
			select @ITSABillingCat = ITSABillingCat from #TEMP_IN
			where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 

			-- Populate the Hours by the new Billing Type.			
			select @FTPStaffAugOnshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'FTP Staff Aug' and Onshore = 1
								
			select @FTPStaffAugOffshore = sum(isnull(Hours,0)) from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
				NewBillingType = 'FTP Staff Aug' and Offshore = 1				
											
			--GET funding category and location combo  --		
			declare @@out_location varchar (100), @@out_fundingcat varchar (100), @@out_afenumber varchar (20), @@out_programmgr varchar (50), @@Total_FTE float
       		set @@out_fundingcat = NULL
       		set @@out_afenumber = NULL
			set @@out_programmgr = NULL
			set @@out_location = NULL
       		set @@Total_FTE = NULL
			exec GET_Location_Combo @CurAFE_DescID, @DateFrom, @DateTo, @@out_location OUTPUT, @@out_fundingcat OUTPUT, @@out_afenumber OUTPUT,@@out_programmgr OUTPUT, @@Total_FTE OUTPUT
            
			-- Update temporary output table #TEMP_OUT.        
			update #TEMP_OUT set ITSABillingCat = @ITSABillingCat, fundingcat = @@out_fundingcat, AFENumber = @@out_afenumber, ProgramMgr = @@out_programmgr, location = @@out_location, COApprovedFTEs = isnull(@@Total_FTE,0), FTPStaffAugOnshoreHours = isnull(@FTPStaffAugOnshore,0), FTPStaffAugOffshoreHours = isnull(@FTPStaffAugOffshore,0)
			where AutoKey = @MaxAFEDesc				

			FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
			END    
			CLOSE AFEDesc_cursor
			DEALLOCATE AFEDesc_cursor

		------------------------------------------------------------------------------------
		FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
		END
		CLOSE Program_cursor
		DEALLOCATE Program_cursor
	
	------------------------------------------------------------------------------------
	-- Populate TotalHours Column for record type 30 (horizontal add up).
    update #TEMP_OUT set TotalHours = isnull(FTPStaffAugOnshoreHours,0) + isnull(FTPStaffAugOffshoreHours,0) 
    where AutoKey > @MaxProgGroup and RecNumber = 30
        
	-- Populate ActualFTEs column for record type 30. 
    update #TEMP_OUT set ActualFTEs = TotalHours/@FTPBillingRate where AutoKey > @MaxProgGroup and RecNumber = 30

	-- Populate EDSVariance column for record type 30. 
	Update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey > @MaxProgGroup and RecNumber = 30
   
    -- Populate totals for 10 fields (vertical add up).
	Select  @TotalHours = sum(isnull(TotalHours,0)), @ActualFTEs = sum(isnull(ActualFTEs,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @EDSVariance = sum(isnull(EDSVariance,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
    from #TEMP_OUT where AutoKey > @MaxProgGroup

    update #TEMP_OUT set TotalHours = @TotalHours, ActualFTEs = @ActualFTEs, COApprovedFTEs = @COApprovedFTEs, EDSVariance = @EDSVariance, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
    where AutoKey = @MaxProgGroup		
     		
    --***CHANGED
	FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID, @UPVP
	END
	CLOSE ProgramGroup_cursor
	DEALLOCATE ProgramGroup_cursor

----------------------------------------------------------------------------------------------------------------------
-- Calculate and Populate the RecNumber 0 records (Grand Total Continental)
select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
from #TEMP_OUT where RecNumber = 10

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
where RecNumber = 0 and RecType = 'GrandTotal'

update #TEMP_OUT set TotalHours = @TotalHours/@FTPBillingRate, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate
where RecNumber = 0 and RecType = 'GrandTotalConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/@FTPBillingRate where RecNumber = 0 and RecType = 'GrandTotal'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 0 and RecType in ('GrandTotal', 'GrandTotalConversion')

-- Calculate and Populate the 1 records (Total Airline)
select  @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'Airline'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
where RecNumber = 1 and RecType = 'TotalAirline'

update #TEMP_OUT set TotalHours = @TotalHours/@FTPBillingRate, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate
where RecNumber = 1 and RecType = 'TotalAirlineConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/@FTPBillingRate where RecNumber = 1 and RecType = 'TotalAirline'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 1 and RecType in ('TotalAirline', 'TotalAirlineConversion')

-- Calculate and Populate the 2 records (Total ADM)
select  @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'ADM'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
where RecNumber = 2 and RecType = 'TotalADM'

update #TEMP_OUT set TotalHours = @TotalHours/@FTPBillingRate, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate
where RecNumber = 2 and RecType = 'TotalADMConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/@FTPBillingRate where RecNumber = 2 and RecType = 'TotalADM'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 2 and RecType in ('TotalADM', 'TotalADMConversion')

-- Calculate and Populate the 4 records (Total AFE_Prod)
select  @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'AFE_Prod'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
where RecNumber = 4 and RecType = 'TotalAFEProd'

update #TEMP_OUT set TotalHours = @TotalHours/@FTPBillingRate, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/@FTPBillingRate, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/@FTPBillingRate
where RecNumber = 4 and RecType = 'TotalAFEProdConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/@FTPBillingRate where RecNumber = 4 and RecType = 'TotalAFEProd'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber =4 and RecType in ('TotalAFEProd','TotalAFEProdConversion')

-- Calculate and Populate the 5 records (Total Staff Augmentation)
select  @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'Staff Aug'

update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
where RecNumber = 5 and RecType = 'TotalStaffAug'

update #TEMP_OUT set TotalHours = @TotalHours/@FTPBillingRate, ActualFTEs = @TotalHours/@FTPBillingRate, COApprovedFTEs = @COApprovedFTEs, FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/143.5, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/143.5
where RecNumber = 5 and RecType = 'TotalStafAugConversion'

update #TEMP_OUT set ActualFTEs = @TotalHours/@FTPBillingRate where RecNumber = 5 and RecType = 'TotalStaffAug'
update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 5 and RecType in ('TotalStaffAug','TotalStafAugConversion')

-- Remove any rows that have ZERO values in the TotalHours and the COApprovedFTEs
delete #TEMP_OUT where RecNumber in (10,20,30) and (TotalHours = 0 or TotalHours is NULL) 

----------------------------------------------------------------------------------------------------------------------

SELECT * from #TEMP_OUT order by AutoKey		

