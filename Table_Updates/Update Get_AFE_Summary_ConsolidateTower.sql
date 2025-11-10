
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =======================================================================
-- Author:		Lizzy Lopez
-- Create date: 05/22/2008
-- Description:	Create the Consolidated Tower Summary Report.
-- =======================================================================

ALTER PROCEDURE [dbo].[Get_AFE_Summary_ConsolidatedTower] 
(	@DateFrom datetime = NULL, 
	@DateTo datetime = NULL, 
	@CurrentMonth varchar(6) = NULL, 
	@ProgGroupID varchar(100) = '-1', 
	@FundCatIDList varchar(100) = '-1', 
	@ITSABillingCat varchar(30) = '-1',
	@SolutionCentreList varchar(500) = '-1',
	@BillingShoreWhere varchar(20) = Null,
	@OutputTable varchar(30) = NULL)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;

	--Default the From and To Dates.
	if ( @DateFrom is NULL )
		Set @DateFrom = '2000-01-01'
	if ( @DateTo is NULL )
		Set @DateTo = GetDate()

	-- Declare common variables.
	Declare @SQL_statement varchar(1000), @ITSABillingCatSelection varchar(30)
	set @SQL_statement = ''
	set @ITSABillingCatSelection = ''

	-- Set ITSA Billing Category selection criteria.
	if ( @ITSABillingCat = '-1' )
		set @ITSABillingCatSelection = '-1'

	-- Build the WHERE clause for the new VIEW.
	if ( @DateFrom is not NULL )
	    select @SQL_statement = @SQL_statement+' and WorkDate >= '''+convert(varchar(25), @DateFrom, 101)+''''
	if ( @DateTo is not NULL )
	    select @SQL_statement = @SQL_statement+' and WorkDate <= '''+convert(varchar(25), @DateTo, 101)+''''
	if ( @ProgGroupID <> '-1' )
	    select @SQL_statement = @SQL_statement+' and Prog_GroupID in ('+@ProgGroupID+')'
	if ( @FundCatIDList <> '-1' )
	    select @SQL_statement = @SQL_statement+' and Funding_CatID in ('+@FundCatIDList+')'
	if ( @SolutionCentreList <> '-1' )
		select @SQL_statement = @SQL_statement+' and ResourceOrg in ('+@SolutionCentreList+')'
	if ( @ITSABillingCat <> '-1' )
	    select @SQL_statement = @SQL_statement+' and ITSABillingCat in ('+@ITSABillingCat+')'
	if ( @BillingShoreWhere is not NULL )
	    select @SQL_statement = @SQL_statement + @BillingShoreWhere

	-- Drop the temp VIEW if it exists.
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_Get_AFE_Summary_Airline_View]') and OBJECTPROPERTY(id, N'IsView') = 1)
	drop view [dbo].[SP_Get_AFE_Summary_Airline_View]

	-- Create new temp VIEW.
	set @SQL_statement = 'Create View dbo.SP_Get_AFE_Summary_Airline_View AS select AFE_Summary_View.*, CO_Resource.Onshore, CO_Resource.Offshore, 
		CO_Resource.Hourly, CO_BillingCode.Billing_CodeID, CO_BillingCode.Description AS NewBillingType
		from AFE_Summary_View inner join CO_Resource ON AFE_Summary_View.EDSNETID = CO_Resource.ResourceNumber
		inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID
		where 1=1 ' + @SQL_statement
	exec (@SQL_statement) 

	-- Copy the data from the temp VIEW into #TEMP_IN working storage.
	select * into #TEMP_IN from dbo.SP_Get_AFE_Summary_Airline_View
	
	-- Drop the temp VIEW.
	exec('Drop View dbo.SP_Get_AFE_Summary_Airline_View')

	-- Alter table definitions.
	ALTER TABLE #TEMP_IN ADD Appr_FTE_Hours decimal(7,2) NULL
	ALTER TABLE #TEMP_IN ADD CurrentMonth varchar(6) NULL
	ALTER TABLE #TEMP_IN ALTER COLUMN TaskID uniqueidentifier NULL
	ALTER TABLE #TEMP_IN ALTER COLUMN ProjectID uniqueidentifier NULL
	ALTER TABLE #TEMP_IN ALTER COLUMN WorkDate datetime NULL
	ALTER TABLE #TEMP_IN ALTER COLUMN EDSNETID varchar(15) NULL
	ALTER TABLE #TEMP_IN ALTER COLUMN Billing_CodeID int NULL
	ALTER TABLE #TEMP_IN ALTER COLUMN NewBillingType varchar(50) NULL

	-- Drop the second temp VIEW if it exists.
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_Get_AFE_Summary_Airline_View2]') and OBJECTPROPERTY(id, N'IsView') = 1)
	drop view [dbo].[SP_Get_AFE_Summary_Airline_View2]

	-- Build the where statement for View2.
	set @SQL_statement = ''
	if ( @CurrentMonth is not NULL )
		select @SQL_statement = @SQL_statement+' and CurrentMonth = '+@CurrentMonth
	if ( @ProgGroupID <> '-1' )
	    select @SQL_statement = @SQL_statement+' and FTE_Approved_Time.Prog_GroupID in ('+@ProgGroupID+')'
	if ( @FundCatIDList <> '-1' )
	    select @SQL_statement = @SQL_statement+' and FTE_Approved_Time.Funding_CatID in ('+@FundCatIDList+')'
	if ( @SolutionCentreList <> '-1' )
		select @SQL_statement = @SQL_statement+' and ResourceOrg in ('+@SolutionCentreList+')'
	if ( @ITSABillingCat <> '-1' )
	    select @SQL_statement = @SQL_statement+' and lkITSABillingCategory.Description in ('+@ITSABillingCat+')'

	-- Create the second temp VIEW.
	set @SQL_statement = 'Create View dbo.SP_Get_AFE_Summary_Airline_View2 AS select dbo.lkITSABillingCategory.Description AS ITSABillingCat, 
			FTE_Approved_Time.* from FTE_Approved_Time LEFT OUTER JOIN	dbo.tblAFEDetail 
			ON FTE_Approved_Time.AFE_DescID = dbo.tblAFEDetail.AFE_DescID 
			LEFT OUTER JOIN dbo.lkITSABillingCategory 
			ON dbo.tblAFEDetail.ITSABillingCategoryID = dbo.lkITSABillingCategory.ITSABillingCategoryID 
			where Appr_FTE_Hours > 0' + @SQL_statement

	exec (@SQL_statement)

	-- Copy the data from the second temp VIEW into #TEMP_IN.
	insert #TEMP_IN (AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, ITSABillingCat )
	select AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, ITSABillingCat from dbo.SP_Get_AFE_Summary_Airline_View2
	
	-- Drop the second temp VIEW.
	exec('Drop View dbo.SP_Get_AFE_Summary_Airline_View2')
	
	-- Index the #TEMP_IN table.
	Create Index IDX1 on #TEMP_IN (Prog_GroupID, ProgramID, AFE_DescID, NewBillingType)

	-- Adjust the Hours according to the ClientFundingPct by CO.
	update #TEMP_IN set Hours = isnull(ClientFundingPct,100)/100*Hours where isnull( ClientFundingPct,0) > 0
	update #TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0

	-- Create the output table #TEMP_OUT.
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
		[ProgMgrOffshoreHours] [decimal](10,2) NULL
	) ON [PRIMARY]

	-- Add FTP Staff Aug columns if ITSA Billing Category selection is ALL.
	if ( @ITSABillingCatSelection = '-1' )
	begin
		ALTER TABLE #TEMP_OUT ADD FTPStaffAugOnshoreHours decimal(10,2) NULL
		ALTER TABLE #TEMP_OUT ADD FTPStaffAugOffshoreHours decimal(10,2) NULL
	end

	ALTER TABLE #TEMP_OUT ADD R10_ProgramGroup varchar(100) NULL
	ALTER TABLE #TEMP_OUT ADD R20_Program varchar(100) NULL
	
	-- Check to see if we have data to process.
	declare @row_count int
	select @row_count = count(*) from #TEMP_IN
	if @row_count = 0
	begin
		insert #TEMP_OUT (RecNumber) values (99)
		goto No_Data_To_Process	
	end

	-- Data was found, build the report.	
	---------------------------------------------------------------------------------------------------
	-- Declare additional variables.
	DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID int, @CurProgram varchar(100), @CurProgramID int, @CurCOBusinessLead varchar(100), @CurAFEDesc varchar(100), @CurAFE_DescID int, @MaxProgGroup int, @MaxProgram int, @MaxAFEDesc int, @MaxProj bigint

	-- Populate summary rows.
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

	-- ProgramGroup_cursor populates at the Program Group level, record type 10.
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

			---------------------------------------------------------------------------------------------------
	
			-- Program_cursor populates at the Program level, record type 20.
			DECLARE Program_cursor CURSOR FOR 
				select distinct Program, ProgramID from #TEMP_IN
				where ProgramGroup = @CurProgramGroup and Program is not null order by Program				
			OPEN Program_cursor
			FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
				WHILE @@FETCH_STATUS = 0
				BEGIN
					--insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, COBusinessLead)  select 20, 'Program', @CurProgram, @CurProgramID, @CurCOBusinessLead
	        		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup)
		            select 20, 'Program', @CurProgram, @CurProgramID, @CurProgramGroup
					select @MaxProgram = max(AutoKey) from #TEMP_OUT 
	
					----------------------------------------------------------------------------------------------
	
					-- AFEDesc_cursor populates at the AFE level, record type 30.
					DECLARE AFEDesc_cursor CURSOR FOR 
						select distinct AFEDesc, AFE_DescID, COBusinessLead from #TEMP_IN 
						where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFEDesc is not null order by AFEDesc
					OPEN AFEDesc_cursor
					FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
						WHILE @@FETCH_STATUS = 0
        				BEGIN
        					--insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID) select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID
        					insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, R10_ProgramGroup, R20_Program, COBusinessLead)
           		   			select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID, @CurProgramGroup, @CurProgram, @CurCOBusinessLead
							select @MaxAFEDesc = max(AutoKey) from #TEMP_OUT

							--------------------------------------------------------------------------------------------
					
							-- Populate the ITSA Billing Category.
							select @ITSABillingCat = ITSABillingCat from #TEMP_IN
							where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 

							-- Populate the Hours by the new Billing Type.
							declare @JrSEOnshore decimal(10,2), @JrSEOffshore decimal(10,2), @MidSEOnshore decimal(10,2), @MidSEOffshore decimal(10,2), @AdvSEOnshore decimal(10,2), @AdvSEOffshore decimal(10,2), @SenSEOnshore decimal(10,2), @SenSEOffshore decimal(10,2), @ConsArchOnshore decimal(10,2), @ConsArchOffshore decimal(10,2), @ProjLeadOnshore decimal(10,2), @ProjLeadOffshore decimal(10,2), @ProjMgrOnshore decimal(10,2), @ProjMgrOffshore decimal(10,2), @ProgMgrOnshore decimal(10,2), @ProgMgrOffshore decimal(10,2)

							if ( @ITSABillingCatSelection = '-1' )
							begin
								declare @FTPStaffAugOnshore decimal(10,2), @FTPStaffAugOffshore decimal(10,2)
							end
							
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
							select @ProgMgrOffshore = sum(isnull(Hours,0)) from #TEMP_IN
							where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
								NewBillingType = 'Program Mgr' and Offshore = 1	

							if ( @ITSABillingCatSelection = '-1' )
							begin
								select @FTPStaffAugOnshore = sum(isnull(Hours,0)) from #TEMP_IN
								where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
									NewBillingType = 'FTP Staff Aug' and Onshore = 1
								select @FTPStaffAugOffshore = sum(isnull(Hours,0)) from #TEMP_IN
								where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and 
									NewBillingType = 'FTP Staff Aug' and Offshore = 1				
							end
												
							--GET funding category and location combo  --		
							declare @@out_location varchar (100), @@out_fundingcat varchar (100), @@out_afenumber varchar (20), @@out_programmgr varchar (50), @@Total_FTE float
       						set @@out_fundingcat = NULL
       						set @@out_afenumber = NULL
							set @@out_programmgr = NULL
							set @@out_location = NULL
       						set @@Total_FTE = NULL
							exec GET_Location_Combo @CurAFE_DescID, @DateFrom, @DateTo, @@out_location OUTPUT, @@out_fundingcat OUTPUT, @@out_afenumber OUTPUT,@@out_programmgr OUTPUT, @@Total_FTE OUTPUT
               
							-- Update temporary output table #TEMP_OUT.   
							if ( @ITSABillingCatSelection = '-1' )
							begin 
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
								ProgMgrOnshoreHours = isnull(@ProgMgrOnshore,0),
								ProgMgrOffshoreHours = isnull(@ProgMgrOffshore,0),
								FTPStaffAugOnshoreHours = isnull(@FTPStaffAugOnshore,0),
								FTPStaffAugOffshoreHours = isnull(@FTPStaffAugOffshore,0)
								where AutoKey = @MaxAFEDesc				
							end
							else
							begin
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
								ProgMgrOnshoreHours = isnull(@ProgMgrOnshore,0),
								ProgMgrOffshoreHours = isnull(@ProgMgrOffshore,0)
								where AutoKey = @MaxAFEDesc				
							end
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
		if ( @ITSABillingCatSelection = '-1' )
		begin
			update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + 
			isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + 
			isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + 
			isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + 
			isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + 
			isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + 
			isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + 
			isnull(ProgMgrOnshoreHours,0) + isnull(ProgMgrOffshoreHours,0) + 
			isnull(FTPStaffAugOnshoreHours,0) + isnull(FTPStaffAugOffshoreHours,0) 
			where AutoKey > @MaxProgGroup and RecNumber = 30
		end
		else
 		begin
			update #TEMP_OUT set TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + 
			isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + 
			isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) +
			isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + 
			isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + 
			isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + 
			isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + 
			isnull(ProgMgrOnshoreHours,0) + isnull(ProgMgrOffshoreHours,0)
			where AutoKey > @MaxProgGroup and RecNumber = 30
		end
       
		-- Populate ActualFTEs column for record type 30. 
		update #TEMP_OUT set ActualFTEs = TotalHours/143.5 where AutoKey > @MaxProgGroup and RecNumber = 30
        
		-- Populate EDSVariance column for record type 30. 
		update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where AutoKey > @MaxProgGroup and RecNumber = 30
   
        -- Populate totals for 10 fields (vertical add up).
		-- Update total information for 10 fields (vertical add up)
        declare @JrSEOnshoreHours decimal(10,2), @JrSEOffshoreHours decimal(10,2), 
				@MidSEOnshoreHours decimal(10,2), @MidSEOffshoreHours decimal(10,2),  
				@AdvSEOnshoreHours decimal(10,2), @AdvSEOffshoreHours decimal(10,2),
				@SenSEOnshoreHours decimal(10,2), @SenSEOffshoreHours decimal(10,2), 
				@ConsArchOnshoreHours decimal(10,2), @ConsArchOffshoreHours decimal(10,2), 
				@SCEAOnshoreHours decimal(10,2), @SCEAOffshoreHours decimal(10,2), 
				@ProjLeadOnshoreHours decimal(10,2), @ProjLeadOffshoreHours decimal(10,2), 
				@ProjMgrOnshoreHours decimal(10,2), @ProjMgrOffshoreHours decimal(10,2), 
				@ProgMgrOnshoreHours decimal(10,2), @ProgMgrOffshoreHours decimal(10,2),
				@TotalHours decimal(10,2), @ActualFTEs decimal(10,2), @COApprovedFTEs decimal(10,2), @EDSVariance decimal(10,2)

		if ( @ITSABillingCatSelection = '-1' )
		begin
			declare @FTPStaffAugOnshoreHours decimal(10,2), @FTPStaffAugOffshoreHours decimal(10,2)
		end

		if ( @ITSABillingCatSelection = '-1' )
		begin
			select @TotalHours = sum(isnull(TotalHours,0)),
                @ActualFTEs = sum(isnull(ActualFTEs,0)),
                @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
                @EDSVariance = sum(isnull(EDSVariance,0)),
				@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), 
				@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)),
				@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)),
				@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)),
				@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)),
				@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
				@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), 
				@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)),
				@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
			from #TEMP_OUT where AutoKey > @MaxProgGroup
		end
		else
		begin
			select @TotalHours = sum(isnull(TotalHours,0)),
                @ActualFTEs = sum(isnull(ActualFTEs,0)),
                @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
                @EDSVariance = sum(isnull(EDSVariance,0)),
				@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), 
				@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)),
				@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)),
				@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)),
				@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)),
				@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
				@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), 
				@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
			from #TEMP_OUT where AutoKey > @MaxProgGroup
		end
	
		if ( @ITSABillingCatSelection = '-1' )
		begin
	        update #TEMP_OUT
		    set TotalHours = @TotalHours, ActualFTEs = @ActualFTEs, COApprovedFTEs = @COApprovedFTEs, EDSVariance = @EDSVariance,
			JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours,
			MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
			AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
			SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
			ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, 
			ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours,
			ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
			ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours,
			FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
			where AutoKey = @MaxProgGroup		
		end
		else
   		begin
	        update #TEMP_OUT
		    set TotalHours = @TotalHours, ActualFTEs = @ActualFTEs, COApprovedFTEs = @COApprovedFTEs, EDSVariance = @EDSVariance,
			JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours,
			MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
			AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
			SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
			ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, 
			ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours,
			ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
			ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours
			where AutoKey = @MaxProgGroup		
		end
  		
		FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID
		END
	CLOSE ProgramGroup_cursor
	DEALLOCATE ProgramGroup_cursor

	----------------------------------------------------------------------------------------------------------------------

	-- Calculate and Populate the RecNumber 0 records (Grand Total Continental)
	if ( @ITSABillingCatSelection = '-1' )
	begin
		select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)),
		@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 10
	end
	else
	begin
		select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 10
	end

	if ( @ITSABillingCatSelection = '-1' )
	begin
		update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours,
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
		where RecNumber = 0 and RecType = 'GrandTotal'
	end
	else
	begin
		update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours
		where RecNumber = 0 and RecType = 'GrandTotal'
	end

	if ( @ITSABillingCatSelection = '-1' )
	begin
		update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/143.5,
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/143.5, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/143.5
		where RecNumber = 0 and RecType = 'GrandTotalConversion'
	end
	else
	begin
		update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/143.5
		where RecNumber = 0 and RecType = 'GrandTotalConversion'
	end

	update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 0 and RecType = 'GrandTotal'
	update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 0 and RecType in ('GrandTotal', 'GrandTotalConversion')

	-- Calculate and Populate the 1 records (Total Airline)
	if ( @ITSABillingCatSelection = '-1' )
	begin
		select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)),
		@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'Airline'
	end
	else
	begin
		select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'Airline'
	end

	if ( @ITSABillingCatSelection = '-1' )
	begin
		update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours,
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
		where RecNumber = 1 and RecType = 'TotalAirline'
	end
	else
	begin
		update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours
		where RecNumber = 1 and RecType = 'TotalAirline'
	end

	if ( @ITSABillingCatSelection = '-1' )
	begin
		update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/143.5,
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/143.5, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/143.5
		where RecNumber = 1 and RecType = 'TotalAirlineConversion'
	end
	else
	begin
		update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/143.5
		where RecNumber = 1 and RecType = 'TotalAirlineConversion'
	end

	update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 1 and RecType = 'TotalAirline'
	update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 1 and RecType in ('TotalAirline', 'TotalAirlineConversion')

	-- Calculate and Populate the 2 records (Total ADM)
	if ( @ITSABillingCatSelection = '-1' )
	begin
		select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)),
		@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'ADM'
	end
	else
	begin
		select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'ADM'
	end

	if ( @ITSABillingCatSelection = '-1' )
	begin
		update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours,
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
		where RecNumber = 2 and RecType = 'TotalADM'
	end
	else
	begin
		update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours
		where RecNumber = 2 and RecType = 'TotalADM'
	end

	if ( @ITSABillingCatSelection = '-1' )
	begin
		update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/143.5,
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/143.5, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/143.5
		where RecNumber = 2 and RecType = 'TotalADMConversion'
	end
	else
	begin
		update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/143.5
		where RecNumber = 2 and RecType = 'TotalADMConversion'
	end

	update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 2 and RecType = 'TotalADM'
	update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 2 and RecType in ('TotalADM', 'TotalADMConversion')

	-- Calculate and Populate the 4 records (Total AFE_Prod)
	if ( @ITSABillingCatSelection = '-1' )
	begin
		select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)),
		@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'AFE_Prod'
	end
	else
	begin
		select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)),
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'AFE_Prod'
	end

	if ( @ITSABillingCatSelection = '-1' )
	begin
		update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours,
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
		where RecNumber = 4 and RecType = 'TotalAFEProd'
	end
	else
	begin
		update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours
		where RecNumber = 4 and RecType = 'TotalAFEProd'
	end

	if ( @ITSABillingCatSelection = '-1' )
	begin
		update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/143.5,
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/143.5, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/143.5
		where RecNumber = 4 and RecType = 'TotalAFEProdConversion'
	end
	else
	begin
		update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/143.5
		where RecNumber = 4 and RecType = 'TotalAFEProdConversion'
	end

	update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 4 and RecType = 'TotalAFEProd'
	update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber =4 and RecType in ('TotalAFEProd','TotalAFEProdConversion')

	-- Calculate and Populate the 5 records (Total Staff Augmentation)
	if ( @ITSABillingCatSelection = '-1' )
	begin
		select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)),
		@FTPStaffAugOnshoreHours = sum(isnull(FTPStaffAugOnshoreHours,0)), @FTPStaffAugOffshoreHours = sum(isnull(FTPStaffAugOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'Staff Aug'
	end
	else
	begin
		select @TotalHours = sum(isnull(TotalHours,0)), @COApprovedFTEs = sum(isnull(COApprovedFTEs,0)), @JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)),
		@MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), 
		@AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), 
		@SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), 
		@ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), 
		@ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), 
		@ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)),
		@ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0))
		from #TEMP_OUT where RecNumber = 30 and ITSABillingCat = 'Staff Aug'
	end

	if ( @ITSABillingCatSelection = '-1' )
	begin
		update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours,
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours
		where RecNumber = 5 and RecType = 'TotalStaffAug'
	end
	else
	begin
		update #TEMP_OUT set TotalHours = @TotalHours, COApprovedFTEs = @COApprovedFTEs, 
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, 
		MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, 
		AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, 
		SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours,
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours
		where RecNumber = 5 and RecType = 'TotalStaffAug'
	end

	if ( @ITSABillingCatSelection = '-1' )
	begin
		update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, 
		COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/143.5,
		FTPStaffAugOnshoreHours = @FTPStaffAugOnshoreHours/143.5, FTPStaffAugOffshoreHours = @FTPStaffAugOffshoreHours/143.5
		where RecNumber = 5 and RecType = 'TotalStafAugConversion'
	end
	else
	begin
		update #TEMP_OUT set TotalHours = @TotalHours/143.5, ActualFTEs = @TotalHours/143.5, 
		COApprovedFTEs = @COApprovedFTEs,
		JrSEOnshoreHours = @JrSEOnshoreHours/143.5, JrSEOffshoreHours = @JrSEOffshoreHours/143.5, 
		MidSEOnshoreHours = @MidSEOnshoreHours/143.5, MidSEOffshoreHours = @MidSEOffshoreHours/143.5,
		AdvSEOnshoreHours = @AdvSEOnshoreHours/143.5, AdvSEOffshoreHours = @AdvSEOffshoreHours/143.5, 
		SenSEOnshoreHours = @SenSEOnshoreHours/143.5, SenSEOffshoreHours = @SenSEOffshoreHours/143.5, 
		ConsArchOnshoreHours = @ConsArchOnshoreHours/143.5, ConsArchOffshoreHours = @ConsArchOffshoreHours/143.5, 
		ProjLeadOnshoreHours = @ProjLeadOnshoreHours/143.5, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/143.5, 
		ProjMgrOnshoreHours = @ProjMgrOnshoreHours/143.5, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/143.5, 
		ProgMgrOnshoreHours = @ProgMgrOnshoreHours/143.5, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/143.5
		where RecNumber = 5 and RecType = 'TotalStafAugConversion'
	end

	update #TEMP_OUT set ActualFTEs = @TotalHours/143.5 where RecNumber = 5 and RecType = 'TotalStaffAug'
	update #TEMP_OUT set EDSVariance = ActualFTEs - COApprovedFTEs where RecNumber = 5 and RecType in ('TotalStaffAug','TotalStafAugConversion')

	----------------------------------------------------------------------------------------------------------------------

	No_Data_To_Process:
	SET NOCOUNT OFF

	If @ITSABillingCatSelection = '-1'
	begin
		If ( @OutputTable is NULL )
		begin
			Select RecNumber, RecType, RecDesc, RecTypeID, ITSABillingCat, FundingCat, AFENumber, 
			CASE
			WHEN RTRIM(COBusinessLead) = '' THEN NULL
			ELSE COBusinessLead 
			END AS COBusinessLead, 
			Programmgr, Location, TotalHours, ActualFTEs, COApprovedFTEs, EDSVariance,
			JrSEOnshoreHours, JrSEOffshoreHours, MidSEOnshoreHours, MidSEOffshoreHours, 
			AdvSEOnshoreHours, AdvSEOffshoreHours, SenSEOnshoreHours, SenSEOffshoreHours, 
			ConsArchOnshoreHours, ConsArchOffshoreHours, ProjLeadOnshoreHours, ProjLeadOffshoreHours,  
			ProjMgrOnshoreHours, ProjMgrOffshoreHours, ProgMgrOnshoreHours, ProgMgrOffshoreHours,
			FTPStaffAugOnshoreHours, FTPStaffAugOffshoreHours, R10_ProgramGroup, R20_Program
			from #TEMP_OUT order by AutoKey		
		end
		else
		begin
			-- Order by AutoKey will be included in the calling
			set @SQL_statement = 'Select * into '+@OutputTable+' from #TEMP_OUT'
			exec (@SQL_statement)
		end	
	end
	else
	begin
		If ( @OutputTable is NULL )
		begin
			Select RecNumber, RecType, RecDesc, RecTypeID, ITSABillingCat, FundingCat, AFENumber, 
			CASE
			WHEN RTRIM(COBusinessLead) = '' THEN NULL
			ELSE COBusinessLead 
			END AS COBusinessLead, 
			Programmgr, Location, TotalHours, ActualFTEs, COApprovedFTEs, EDSVariance,
			JrSEOnshoreHours, JrSEOffshoreHours, MidSEOnshoreHours, MidSEOffshoreHours, 
			AdvSEOnshoreHours, AdvSEOffshoreHours, SenSEOnshoreHours, SenSEOffshoreHours, 
			ConsArchOnshoreHours, ConsArchOffshoreHours, ProjLeadOnshoreHours, ProjLeadOffshoreHours,  
			ProjMgrOnshoreHours, ProjMgrOffshoreHours, ProgMgrOnshoreHours, ProgMgrOffshoreHours, R10_ProgramGroup, R20_Program
			from #TEMP_OUT order by AutoKey		
		end
		else
		begin
			-- Order by AutoKey will be included in the calling
			set @SQL_statement = 'Select * into '+@OutputTable+' from #TEMP_OUT'
			exec (@SQL_statement)
		end	
	end

END
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

