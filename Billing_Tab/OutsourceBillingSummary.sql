---[Get_AFE_Summary_ConsolidatedTower]
drop view [dbo].[SP_Get_AFE_Summary_Airline_View]
drop view [dbo].[SP_Get_AFE_Summary_Airline_View2]
drop table #TEMP_IN
drop table #TEMP_OUT

-- Create new temp VIEW.
Declare @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Summary_Airline_View AS select AFE_Summary_View.*, CO_Resource.Onshore, CO_Resource.Offshore, CO_Resource.Hourly, CO_Resource.Core, CO_BillingCode.Billing_CodeID, CO_BillingCode.Description AS NewBillingType from AFE_Summary_View inner join CO_Resource ON AFE_Summary_View.EDSNETID = CO_Resource.ResourceNumber inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID where WorkDate >= ''2016-09-01'' and WorkDate <= ''2016-09-30'' and ITSABillingCat = ''Outsource Svcs'' '
exec (@SQL_statement) 

-- Copy the data from the temp VIEW into #TEMP_IN working storage.
select * into #TEMP_IN from dbo.SP_Get_AFE_Summary_Airline_View

-- Alter table definitions.
ALTER TABLE #TEMP_IN ADD Appr_FTE_Hours decimal(7,3) NULL
ALTER TABLE #TEMP_IN ADD CurrentMonth varchar(6) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN TaskID uniqueidentifier NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ProjectID uniqueidentifier NULL
ALTER TABLE #TEMP_IN ALTER COLUMN WorkDate datetime NULL
ALTER TABLE #TEMP_IN ALTER COLUMN EDSNETID varchar(15) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN Billing_CodeID int NULL
ALTER TABLE #TEMP_IN ALTER COLUMN NewBillingType varchar(50) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ResourceOrg varchar(100) NULL

-- Create the second temp VIEW.
--Declare @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_AFE_Summary_Airline_View2 AS select dbo.lkITSABillingCategory.Description AS ITSABillingCat, FTE_Approved_Time.* from FTE_Approved_Time LEFT OUTER JOIN	dbo.tblAFEDetail ON FTE_Approved_Time.AFE_DescID = dbo.tblAFEDetail.AFE_DescID LEFT OUTER JOIN dbo.lkITSABillingCategory ON dbo.tblAFEDetail.ITSABillingCategoryID = dbo.lkITSABillingCategory.ITSABillingCategoryID where Appr_FTE_Hours > 0 and CurrentMonth = ''201609'' '
exec (@SQL_statement)

-- Copy the data from the second temp VIEW into #TEMP_IN.
insert #TEMP_IN (AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, UA_VicePresident, ITSABillingCat )
select AFEDesc, Program, ProgramGroup, Prog_GroupID, ProgramID, Appr_FTE_Hours, CurrentMonth, AFE_DescID, Funding_CatID, COBusinessLead, UA_VicePresident, ITSABillingCat from dbo.SP_Get_AFE_Summary_Airline_View2
	
-- Index the #TEMP_IN table.
Create Index IDX1 on #TEMP_IN (Prog_GroupID, ProgramID, AFE_DescID, NewBillingType)

-- Adjust the Hours according to the ClientFundingPct by CO.
update #TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0

--Delete records that have zero hours.
delete from #TEMP_IN where Hours = '0.00'

---------------------------------------------------------------------------------------------------
--drop table #TEMP_OUT
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
    [UAVP] [varchar] (50) NULL, 
	[COBusinessLead] [varchar] (100) NULL,
	[ProgramMgr] [varchar] (50) NULL,
	[ServiceCategory] [varchar] (50) NULL,
	[TotalHours] [decimal](10,2) NULL,
	[TotalFTEs] [decimal](10,2) NULL, 
	[ApprovedFTEs] [decimal](10,2) NULL,
	[Variance] [decimal](10,2) NULL,
	[JrSEOnshoreHours] [decimal](10,2) NULL, [JrSeOffshoreHours] [decimal](10,2) NULL,
	[MidSEOnshoreHours] [decimal](10,2) NULL, [MidSEOffshoreHours] [decimal](10,2) NULL,
	[AdvSEOnshoreHours] [decimal](10,2) NULL, [AdvSEOffshoreHours] [decimal](10,2) NULL,
	[SenSEOnshoreHours] [decimal](10,2) NULL, [SenSEOffshoreHours] [decimal](10,2) NULL,
	[ConsArchOnshoreHours] [decimal](10,2) NULL, [ConsArchOffshoreHours] [decimal](10,2) NULL,
	[ProjLeadOnshoreHours] [decimal](10,2) NULL, [ProjLeadOffshoreHours] [decimal](10,2) NULL,
	[ProjMgrOnshoreHours] [decimal](10,2) NULL, [ProjMgrOffshoreHours] [decimal](10,2) NULL,
	[ProgMgrOnshoreHours] [decimal](10,2) NULL, [ProgMgrOffshoreHours] [decimal](10,2) NULL				
) ON [PRIMARY]
ALTER TABLE #TEMP_OUT ADD R10_R20_TotalHours decimal(10,3) NULL

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Declare additional variables.
DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID int, @UPVP varchar (50), @CurProgram varchar(100), @CurProgramID int, @CurBusinessLead varchar(100), @ServiceCategory nvarchar(50), @CurAFEDesc varchar(100), @CurAFE_DescID int, @MaxProgGroup int, @MaxProgram int, @MaxAFEDesc int, @MaxProj bigint
DECLARE @FTPBillingRate decimal(10,3), @year int, @month int, @BillableDays int, @OnshoreFTERate decimal(10,3), @OffshoreFTERate decimal(10,3), @ITSABillingCat varchar(30), @R10_R20_TotalHours decimal(10,3), @CheckTotalHours decimal(10,3)
Declare @JrSEOnCommonBillingType nvarchar(50), @JrSEOffCommonBillingType nvarchar(50), @JrSEOnCommonLNDBillingType nvarchar(50), @JrSEOffCommonLNDBillingType nvarchar(50), @JrSEOnCommonRDCBillingType nvarchar(50), @JrSEOffCommonRDCBillingType nvarchar(50), @JrSEOnCommonTSTBillingType nvarchar(50), @JrSEOffCommonTSTBillingType nvarchar(50), @JrSEOnCommonTSTLNDBillingType nvarchar(50), @JrSEOffCommonTSTLNDBillingType nvarchar(50), @JrSEOnCommonTSTOFFBillingType nvarchar(50), @JrSEOffCommonTSTOFFBillingType nvarchar(50), @JrSEOnCommonTSTRDCBillingType nvarchar(50), @JrSEOffCommonTSTRDCBillingType nvarchar(50), @JrSEOnLegacyBillingType nvarchar(50), @JrSEOffLegacyBillingType nvarchar(50), @JrSEOnLegacyLNDBillingType nvarchar(50), @JrSEOffLegacyLNDBillingType nvarchar(50), @JrSEOnNicheBillingType nvarchar(50), @JrSEOffNicheBillingType nvarchar(50), @JrSEOnPremiumBillingType nvarchar(50), @JrSEOffPremiumBillingType nvarchar(50), @MidSEOnCommonBillingType nvarchar(50), @MidSEOffCommonBillingType nvarchar(50), @MidSEOnCommonLNDBillingType nvarchar(50), @MidSEOffCommonLNDBillingType nvarchar(50), @MidSEOnCommonRDCBillingType nvarchar(50), @MidSEOffCommonRDCBillingType nvarchar(50), @MidSEOnCommonTSTBillingType nvarchar(50), @MidSEOffCommonTSTBillingType nvarchar(50), @MidSEOnCommonTSTLNDBillingType nvarchar(50), @MidSEOffCommonTSTLNDBillingType nvarchar(50), @MidSEOnCommonTSTOFFBillingType nvarchar(50), @MidSEOffCommonTSTOFFBillingType nvarchar(50), @MidSEOnCommonTSTRDCBillingType nvarchar(50), @MidSEOffCommonTSTRDCBillingType nvarchar(50), @MidSEOnLegacyBillingType nvarchar(50), @MidSEOffLegacyBillingType nvarchar(50), @MidSEOnLegacyLNDBillingType nvarchar(50), @MidSEOffLegacyLNDBillingType nvarchar(50), @MidSEOnNicheBillingType nvarchar(50), @MidSEOffNicheBillingType nvarchar(50), @MidSEOnPremiumBillingType nvarchar(50), @MidSEOffPremiumBillingType nvarchar(50), @MidSEOnPremiumLNDBillingType nvarchar(50), @MidSEOffPremiumLNDBillingType nvarchar(50), @AdvSEOnCommonBillingType nvarchar(50), @AdvSEOffCommonBillingType nvarchar(50), @AdvSEOnCommonLNDBillingType nvarchar(50), @AdvSEOffCommonLNDBillingType nvarchar(50), @AdvSEOnCommonRDCBillingType nvarchar(50), @AdvSEOffCommonRDCBillingType nvarchar(50), @AdvSEOnCommonTSTBillingType nvarchar(50), @AdvSEOffCommonTSTBillingType nvarchar(50), @AdvSEOnCommonTSTLNDBillingType nvarchar(50), @AdvSEOffCommonTSTLNDBillingType nvarchar(50), @AdvSEOnCommonTSTOFFBillingType nvarchar(50), @AdvSEOffCommonTSTOFFBillingType nvarchar(50), @AdvSEOnCommonTSTRDCBillingType nvarchar(50), @AdvSEOffCommonTSTRDCBillingType nvarchar(50), @AdvSEOnLegacyBillingType nvarchar(50), @AdvSEOffLegacyBillingType nvarchar(50), @AdvSEOnLegacyLNDBillingType nvarchar(50), @AdvSEOffLegacyLNDBillingType nvarchar(50), @AdvSEOnNicheBillingType nvarchar(50), @AdvSEOffNicheBillingType nvarchar(50), @AdvSEOnNicheLNDBillingType nvarchar(50), @AdvSEOffNicheLNDBillingType nvarchar(50), @AdvSEOnPremiumBillingType nvarchar(50), @AdvSEOffPremiumBillingType nvarchar(50), @AdvSEOnPremiumLNDBillingType nvarchar(50), @AdvSEOffPremiumLNDBillingType nvarchar(50), @SenSEOnCommonBillingType nvarchar(50), @SenSEOffCommonBillingType nvarchar(50), @SenSEOnCommonLNDBillingType nvarchar(50), @SenSEOffCommonLNDBillingType nvarchar(50), @SenSEOnCommonRDCBillingType nvarchar(50), @SenSEOffCommonRDCBillingType nvarchar(50), @SenSEOnCommonTSTBillingType nvarchar(50), @SenSEOffCommonTSTBillingType nvarchar(50), @SenSEOnCommonTSTLNDBillingType nvarchar(50), @SenSEOffCommonTSTLNDBillingType nvarchar(50), @SenSEOnCommonTSTOFFBillingType nvarchar(50), @SenSEOffCommonTSTOFFBillingType nvarchar(50), @SenSEOnCommonTSTRDCBillingType nvarchar(50), @SenSEOffCommonTSTRDCBillingType nvarchar(50), @SenSEOnLegacyBillingType nvarchar(50), @SenSEOffLegacyBillingType nvarchar(50), @SenSEOnLegacyLNDBillingType nvarchar(50), @SenSEOffLegacyLNDBillingType nvarchar(50), @SenSEOnNicheBillingType nvarchar(50), @SenSEOffNicheBillingType nvarchar(50), @SenSEOnNicheLNDBillingType nvarchar(50), @SenSEOffNicheLNDBillingType nvarchar(50), @SenSEOnPremiumBillingType nvarchar(50), @SenSEOffPremiumBillingType nvarchar(50), @SenSEOnPremiumLNDBillingType nvarchar(50), @SenSEOffPremiumLNDBillingType nvarchar(50), @ConsArchOnCommonBillingType nvarchar(50), @ConsArchOffCommonBillingType nvarchar(50), @ConsArchOnCommonLNDBillingType nvarchar(50), @ConsArchOffCommonLNDBillingType nvarchar(50), @ConsArchOnCommonRDCBillingType nvarchar(50), @ConsArchOffCommonRDCBillingType nvarchar(50), @ConsArchOnCommonTSTBillingType nvarchar(50), @ConsArchOffCommonTSTBillingType nvarchar(50), @ConsArchOnCommonTSTLNDBillingType nvarchar(50), @ConsArchOffCommonTSTLNDBillingType nvarchar(50), @ConsArchOnCommonTSTOFFBillingType nvarchar(50), @ConsArchOffCommonTSTOFFBillingType nvarchar(50), @ConsArchOnCommonTSTRDCBillingType nvarchar(50), @ConsArchOffCommonTSTRDCBillingType nvarchar(50), @ConsArchOnLegacyBillingType nvarchar(50), @ConsArchOffLegacyBillingType nvarchar(50), @ConsArchOnLegacyLNDBillingType nvarchar(50), @ConsArchOffLegacyLNDBillingType nvarchar(50), @ConsArchOnNicheLNDBillingType nvarchar(50), @ConsArchOffNicheLNDBillingType nvarchar(50), @ConsArchOnNicheBillingType nvarchar(50), @ConsArchOffNicheBillingType nvarchar(50), @ConsArchOnPremiumBillingType nvarchar(50), @ConsArchOffPremiumBillingType nvarchar(50), @ConsArchOnPremiumLNDBillingType nvarchar(50), @ConsArchOffPremiumLNDBillingType nvarchar(50), @PLOnBillingType nvarchar(50), @PLOffBillingType nvarchar(50), @ProjLeadOnCommonBillingType nvarchar(50), @ProjLeadOffCommonBillingType nvarchar(50), @ProjLeadOnLegacyBillingType nvarchar(50), @ProjLeadOffLegacyBillingType nvarchar(50), @ProjLeadOnNicheBillingType nvarchar(50), @ProjLeadOffNicheBillingType nvarchar(50), @ProjLeadOnPremiumBillingType nvarchar(50), @ProjLeadOffPremiumBillingType nvarchar(50), @PMOnBillingType nvarchar(50), @PMOffBillingType nvarchar(50), @ProjMgrOnCommonBillingType nvarchar(50), @ProjMgrOffCommonBillingType nvarchar(50), @ProjMgrOnLegacyBillingType nvarchar(50), @ProjMgrOffLegacyBillingType nvarchar(50), @ProjMgrOnNicheBillingType nvarchar(50), @ProjMgrOffNicheBillingType nvarchar(50), @ProjMgrOnPremiumBillingType nvarchar(50), @ProjMgrOffPremiumBillingType nvarchar(50), @PGMOnBillingType nvarchar(50), @PGMOffBillingType nvarchar(50), @ProgMgrOnCommonBillingType nvarchar(50), @ProgMgrOffCommonBillingType nvarchar(50), @ProgMgrOnLegacyBillingType nvarchar(50), @ProgMgrOffLegacyBillingType nvarchar(50), @ProgMgrOnNicheBillingType nvarchar(50), @ProgMgrOffNicheBillingType nvarchar(50), @ProgMgrOnPremiumBillingType nvarchar(50), @ProgMgrOffPremiumBillingType nvarchar(50)
Declare @JrSEOnshoreCommon decimal(10,3), @JrSEOffshoreCommon decimal(10,3), @JrSEOnshoreCommonLND decimal(10,3), @JrSEOffshoreCommonLND decimal(10,3), @JrSEOnshoreCommonRDC decimal(10,3), @JrSEOffshoreCommonRDC decimal(10,3), @JrSEOnshoreCommonTST decimal(10,3), @JrSEOffshoreCommonTST decimal(10,3), @JrSEOnshoreCommonTSTLND decimal(10,3), @JrSEOffshoreCommonTSTLND decimal(10,3), @JrSEOnshoreCommonTSTOFF decimal(10,3), @JrSEOffshoreCommonTSTOFF decimal(10,3), @JrSEOnshoreCommonTSTRDC decimal(10,3), @JrSEOffshoreCommonTSTRDC decimal(10,3), @JrSEOnshoreLegacy decimal(10,3), @JrSEOffshoreLegacy decimal(10,3), @JrSEOnshoreLegacyLND decimal(10,3), @JrSEOffshoreLegacyLND decimal(10,3), @JrSEOnshoreNiche decimal(10,3), @JrSEOffshoreNiche decimal(10,3), @JrSEOnshorePremium decimal(10,3), @JrSEOffshorePremium decimal(10,3), @MidSEOnshoreCommon decimal(10,3), @MidSEOffshoreCommon decimal(10,3), @MidSEOnshoreCommonLND decimal(10,3), @MidSEOffshoreCommonLND decimal(10,3), @MidSEOnshoreCommonRDC decimal(10,3), @MidSEOffshoreCommonRDC decimal(10,3), @MidSEOnshoreCommonTST decimal(10,3), @MidSEOffshoreCommonTST decimal(10,3), @MidSEOnshoreCommonTSTLND decimal(10,3), @MidSEOffshoreCommonTSTLND decimal(10,3), @MidSEOnshoreCommonTSTOFF decimal(10,3), @MidSEOffshoreCommonTSTOFF decimal(10,3), @MidSEOnshoreCommonTSTRDC decimal(10,3), @MidSEOffshoreCommonTSTRDC decimal(10,3), @MidSEOnshoreLegacy decimal(10,3), @MidSEOffshoreLegacy decimal(10,3), @MidSEOnshoreLegacyLND decimal(10,3), @MidSEOffshoreLegacyLND decimal(10,3), @MidSEOnshoreNiche decimal(10,3), @MidSEOffshoreNiche decimal(10,3), @MidSEOnshorePremium decimal(10,3), @MidSEOffshorePremium decimal(10,3), @MidSEOnshorePremiumLND decimal(10,3), @MidSEOffshorePremiumLND decimal(10,3), @AdvSEOnshoreCommon decimal(10,3), @AdvSEOffshoreCommon decimal(10,3), @AdvSEOnshoreCommonLND decimal(10,3), @AdvSEOffshoreCommonLND decimal(10,3), @AdvSEOnshoreCommonRDC decimal(10,3), @AdvSEOffshoreCommonRDC decimal(10,3), @AdvSEOnshoreCommonTST decimal(10,3), @AdvSEOffshoreCommonTST decimal(10,3), @AdvSEOnshoreCommonTSTLND decimal(10,3), @AdvSEOffshoreCommonTSTLND decimal(10,3), @AdvSEOnshoreCommonTSTOFF decimal(10,3), @AdvSEOffshoreCommonTSTOFF decimal(10,3), @AdvSEOnshoreCommonTSTRDC decimal(10,3), @AdvSEOffshoreCommonTSTRDC decimal(10,3), @AdvSEOnshoreLegacy decimal(10,3), @AdvSEOffshoreLegacy decimal(10,3), @AdvSEOnshoreLegacyLND decimal(10,3), @AdvSEOffshoreLegacyLND decimal(10,3), @AdvSEOnshoreNiche decimal(10,3), @AdvSEOffshoreNiche decimal(10,3), @AdvSEOnshoreNicheLND decimal(10,3), @AdvSEOffshoreNicheLND decimal(10,3), @AdvSEOnshorePremium decimal(10,3), @AdvSEOffshorePremium decimal(10,3), @AdvSEOnshorePremiumLND decimal(10,3), @AdvSEOffshorePremiumLND decimal(10,3), @SenSEOnshoreCommon decimal(10,3), @SenSEOffshoreCommon decimal(10,3), @SenSEOnshoreCommonLND decimal(10,3), @SenSEOffshoreCommonLND decimal(10,3), @SenSEOnshoreCommonRDC decimal(10,3), @SenSEOffshoreCommonRDC decimal(10,3), @SenSEOnshoreCommonTST decimal(10,3), @SenSEOffshoreCommonTST decimal(10,3), @SenSEOnshoreCommonTSTLND decimal(10,3), @SenSEOffshoreCommonTSTLND decimal(10,3), @SenSEOnshoreCommonTSTOFF decimal(10,3), @SenSEOffshoreCommonTSTOFF decimal(10,3), @SenSEOnshoreCommonTSTRDC decimal(10,3), @SenSEOffshoreCommonTSTRDC decimal(10,3), @SenSEOnshoreLegacy decimal(10,3), @SenSEOffshoreLegacy decimal(10,3), @SenSEOnshoreLegacyLND decimal(10,3), @SenSEOffshoreLegacyLND decimal(10,3), @SenSEOnshoreNiche decimal(10,3), @SenSEOffshoreNiche decimal(10,3), @SenSEOnshoreNicheLND decimal(10,3), @SenSEOffshoreNicheLND decimal(10,3), @SenSEOnshorePremium decimal(10,3), @SenSEOffshorePremium decimal(10,3), @SenSEOnshorePremiumLND decimal(10,3), @SenSEOffshorePremiumLND decimal(10,3), @ConsArchOnshoreCommon decimal(10,3), @ConsArchOffshoreCommon decimal(10,3), @ConsArchOnshoreCommonLND decimal(10,3), @ConsArchOffshoreCommonLND decimal(10,3), @ConsArchOnshoreCommonRDC decimal(10,3), @ConsArchOffshoreCommonRDC decimal(10,3), @ConsArchOnshoreCommonTST decimal(10,3), @ConsArchOffshoreCommonTST decimal(10,3), @ConsArchOnshoreCommonTSTLND decimal(10,3), @ConsArchOffshoreCommonTSTLND decimal(10,3), @ConsArchOnshoreCommonTSTOFF decimal(10,3), @ConsArchOffshoreCommonTSTOFF decimal(10,3), @ConsArchOnshoreCommonTSTRDC decimal(10,3), @ConsArchOffshoreCommonTSTRDC decimal(10,3), @ConsArchOnshoreLegacy decimal(10,3), @ConsArchOffshoreLegacy decimal(10,3), @ConsArchOnshoreLegacyLND decimal(10,3), @ConsArchOffshoreLegacyLND decimal(10,3), @ConsArchOnshoreNiche decimal(10,3), @ConsArchOffshoreNiche decimal(10,3), @ConsArchOnshoreNicheLND decimal(10,3), @ConsArchOffshoreNicheLND decimal(10,3), @ConsArchOnshorePremium decimal(10,3), @ConsArchOffshorePremium decimal(10,3), @ConsArchOnshorePremiumLND decimal(10,3), @ConsArchOffshorePremiumLND decimal(10,3), @PLOnshore decimal(10,3), @PLOffshore decimal(10,3), @ProjLeadOnshoreCommon decimal(10,3), @ProjLeadOfshoreCommon decimal(10,3), @ProjLeadOnshoreLegacy decimal(10,3), @ProjLeadOffshoreLegacy decimal(10,3), @ProjLeadOnshoreNiche decimal(10,3), @ProjLeadOffshoreNiche decimal(10,3), @ProjLeadOnshorePremium decimal(10,3), @ProjLeadOffshorePremium decimal(10,3), @PMOnshore decimal(10,3), @PMOffshore decimal(10,3), @ProjMgrOnshoreCommon decimal(10,3), @ProjMgrOffshoreCommon decimal(10,3), @ProjMgrOnshoreLegacy decimal(10,3), @ProjMgrOffshoreLegacy decimal(10,3), @ProjMgrOnshoreNiche decimal(10,3), @ProjMgrOffshoreNiche decimal(10,3), @ProjMgrOnshorePremium decimal(10,3), @ProjMgrOffshorePremium decimal(10,3), @PGMOnshore decimal(10,3), @PGMOffshore decimal(10,3), @ProgMgrOnshoreCommon decimal(10,3), @ProgMgrOffshoreCommon decimal(10,3), @ProgMgrOnshoreLegacy decimal(10,3), @ProgMgrOffshoreLegacy decimal(10,3), @ProgMgrOnshoreNiche decimal(10,3), @ProgMgrOffshoreNiche decimal(10,3), @ProgMgrOnshorePremium decimal(10,3), @ProgMgrOffshorePremium decimal(10,3)     
declare @JrSEOnCommonTotal decimal(10,3), @JrSEOffCommonTotal decimal(10,3), @MidSEOnCommonTotal decimal(10,3), @MidSEOffCommonTotal decimal(10,3), @AdvSEOnCommonTotal decimal(10,3), @AdvSEOffCommonTotal decimal(10,3), @SenSEOnCommonTotal decimal(10,3), @SenSEOffCommonTotal decimal(10,3), @ConsArchSEOnCommonTotal decimal(10,3), @ConsArchSEOffCommonTotal decimal(10,3), @ProjLeadOnCommonTotal decimal(10,3), @ProjLeadSEOffCommonTotal decimal(10,3), @ProjMgrSEOnCommonTotal decimal(10,3), @ProjMgrSEOffCommonTotal decimal(10,3), @ProgMgrSEOnCommonTotal decimal(10,3), @ProgMgrSEOffCommonTotal decimal(10,3), @JrSEOnCommonLNDTotal decimal(10,3), @JrSEOffCommonLNDTotal decimal(10,3), @MidSEOnCommonLNDTotal decimal(10,3), @MidSEOffCommonLNDTotal decimal(10,3), @AdvSEOnCommonLNDTotal decimal(10,3), @AdvSEOffCommonLNDTotal decimal(10,3), @SenSEOnCommonLNDTotal decimal(10,3), @SenSEOffCommonLNDTotal decimal(10,3), @ConsArchSEOnCommonLNDTotal decimal(10,3), @ConsArchSEOffCommonLNDTotal decimal(10,3), @JrSEOnCommonRDCTotal decimal(10,3), @JrSEOffCommonRDCTotal decimal(10,3), @MidSEOnCommonRDCTotal decimal(10,3), @MidSEOffCommonRDCTotal decimal(10,3), @AdvSEOnCommonRDCTotal decimal(10,3), @AdvSEOffCommonRDCTotal decimal(10,3), @SenSEOnCommonRDCTotal decimal(10,3), @SenSEOffCommonRDCTotal decimal(10,3), @ConsArchSEOnCommonRDCTotal decimal(10,3), @ConsArchSEOffCommonRDCTotal decimal(10,3), @JrSEOnCommonTSTTotal decimal(10,3), @JrSEOffCommonTSTTotal decimal(10,3), @MidSEOnCommonTSTTotal decimal(10,3), @MidSEOffCommonTSTTotal decimal(10,3), @AdvSEOnCommonTSTTotal decimal(10,3), @AdvSEOffCommonTSTTotal decimal(10,3), @SenSEOnCommonTSTTotal decimal(10,3), @SenSEOffCommonTSTTotal decimal(10,3), @ConsArchSEOnCommonTSTTotal decimal(10,3), @ConsArchSEOffCommonTSTTotal decimal(10,3), @JrSEOnCommonTSTLNDTotal decimal(10,3), @JrSEOffCommonTSTLNDTotal decimal(10,3), @MidSEOnCommonTSTLNDTotal decimal(10,3), @MidSEOffCommonTSTLNDTotal decimal(10,3), @AdvSEOnCommonTSTLNDTotal decimal(10,3), @AdvSEOffCommonTSTLNDTotal decimal(10,3), @SenSEOnCommonTSTLNDTotal decimal(10,3), @SenSEOffCommonTSTLNDTotal decimal(10,3), @ConsArchSEOnCommonTSTLNDTotal decimal(10,3), @ConsArchSEOffCommonTSTLNDTotal decimal(10,3), @JrSEOnCommonTSTOFFTotal decimal(10,3), @JrSEOffCommonTSTOFFTotal decimal(10,3), @MidSEOnCommonTSTOFFTotal decimal(10,3), @MidSEOffCommonTSTOFFTotal decimal(10,3), @AdvSEOnCommonTSTOFFTotal decimal(10,3), @AdvSEOffCommonTSTOFFTotal decimal(10,3), @SenSEOnCommonTSTOFFTotal decimal(10,3), @SenSEOffCommonTSTOFFTotal decimal(10,3), @ConsArchSEOnCommonTSTOFFTotal decimal(10,3), @ConsArchSEOffCommonTSTOFFTotal decimal(10,3), @JrSEOnCommonTSTRDCTotal decimal(10,3), @JrSEOffCommonTSTRDCTotal decimal(10,3), @MidSEOnCommonTSTRDCTotal decimal(10,3), @MidSEOffCommonTSTRDCTotal decimal(10,3), @AdvSEOnCommonTSTRDCTotal decimal(10,3), @AdvSEOffCommonTSTRDCTotal decimal(10,3), @SenSEOnCommonTSTRDCTotal decimal(10,3), @SenSEOffCommonTSTRDCTotal decimal(10,3), @ConsArchSEOnCommonTSTRDCTotal decimal(10,3), @ConsArchSEOffCommonTSTRDCTotal decimal(10,3), @JrSEOnLegacyTotal decimal(10,3), @JrSEOffLegacyTotal decimal(10,3), @MidSEOnLegacyTotal decimal(10,3), @MidSEOffLegacyTotal decimal(10,3), @AdvSEOnLegacyTotal decimal(10,3), @AdvSEOffLegacyTotal decimal(10,3), @SenSEOnLegacyTotal decimal(10,3), @SenSEOffLegacyTotal decimal(10,3), @ConsArchSEOnLegacyTotal decimal(10,3), @ConsArchSEOffLegacyTotal decimal(10,3), @ProjLeadOnLegacyTotal decimal(10,3), @ProjLeadSEOffLegacyTotal decimal(10,3), @ProjMgrSEOnLegacyTotal decimal(10,3), @ProjMgrSEOffLegacyTotal decimal(10,3), @ProgMgrSEOnLegacyTotal decimal(10,3), @ProgMgrSEOffLegacyTotal decimal(10,3), @JrSEOnLegacyLNDTotal decimal(10,3), @JrSEOffLegacyLNDTotal decimal(10,3), @MidSEOnLegacyLNDTotal decimal(10,3), @MidSEOffLegacyLNDTotal decimal(10,3), @AdvSEOnLegacyLNDTotal decimal(10,3), @AdvSEOffLegacyLNDTotal decimal(10,3), @SenSEOnLegacyLNDTotal decimal(10,3), @SenSEOffLegacyLNDTotal decimal(10,3), @ConsArchSEOnLegacyLNDTotal decimal(10,3), @ConsArchSEOffLegacyLNDTotal decimal(10,3), @JrSEOnNicheTotal decimal(10,3), @JrSEOffNicheTotal decimal(10,3), @MidSEOnNicheTotal decimal(10,3), @MidSEOffNicheTotal decimal(10,3), @AdvSEOnNicheTotal decimal(10,3), @AdvSEOffNicheTotal decimal(10,3), @SenSEOnNicheTotal decimal(10,3), @SenSEOffNicheTotal decimal(10,3), @ConsArchSEOnNicheTotal decimal(10,3), @ConsArchSEOffNicheTotal decimal(10,3), @ProjLeadOnNicheTotal decimal(10,3), @ProjLeadSEOffNicheTotal decimal(10,3), @ProjMgrSEOnNicheTotal decimal(10,3), @ProjMgrSEOffNicheTotal decimal(10,3), @ProgMgrSEOnNicheTotal decimal(10,3), @ProgMgrSEOffNicheTotal decimal(10,3), @AdvSEOnNicheLNDTotal decimal(10,3), @AdvSEOffNicheLNDTotal decimal(10,3), @SenSEOnNicheLNDTotal decimal(10,3), @SenSEOffNicheLNDTotal decimal(10,3), @ConsArchSEOnNicheLNDTotal decimal(10,3), @ConsArchSEOffNicheLNDTotal decimal(10,3), @JrSEOnPremiumTotal decimal(10,3), @JrSEOffPremiumTotal decimal(10,3), @MidSEOnPremiumTotal decimal(10,3), @MidSEOffPremiumTotal decimal(10,3), @AdvSEOnPremiumTotal decimal(10,3), @AdvSEOffPremiumTotal decimal(10,3), @SenSEOnPremiumTotal decimal(10,3), @SenSEOffPremiumTotal decimal(10,3), @ConsArchSEOnPremiumTotal decimal(10,3), @ConsArchSEOffPremiumTotal decimal(10,3), @ProjLeadSEOnPremiumTotal decimal(10,3), @ProjLeadSEOffPremiumTotal decimal(10,3), @ProjMgrSEOnPremiumTotal decimal(10,3), @ProjMgrSEOffPremiumTotal decimal(10,3), @ProgMgrSEOnPremiumTotal decimal(10,3), @ProgMgrSEOffPremiumTotal decimal(10,3), @JrSEOnPremiumLNDTotal decimal(10,3), @JrSEOffPremiumLNDTotal decimal(10,3), @MidSEOnPremiumLNDTotal decimal(10,3), @MidSEOffPremiumLNDTotal decimal(10,3), @AdvSEOnPremiumLNDTotal decimal(10,3), @AdvSEOffPremiumLNDTotal decimal(10,3), @SenSEOnPremiumLNDTotal decimal(10,3), @SenSEOffPremiumLNDTotal decimal(10,3), @ConsArchSEOnPremiumLNDTotal decimal(10,3), @ConsArchSEOffPremiumLNDTotal decimal(10,3), @PLOnTotal decimal(10,3), @PLOffTotal decimal(10,3), @PMOnTotal decimal(10,3), @PMOffTotal decimal(10,3), @PGMOnTotal decimal(10,3), @PGMOffTotal decimal(10,3)

set @JrSEOnCommonTotal = 0			set @JrSEOffCommonTotal = 0			set @MidSEOnCommonTotal = 0			set @MidSEOffCommonTotal = 0		set @AdvSEOnCommonTotal = 0			set @AdvSEOffCommonTotal = 0		set @SenSEOnCommonTotal = 0			set @SenSEOffCommonTotal = 0		set @ConsArchSEOnCommonTotal = 0		set @ConsArchSEOffCommonTotal = 0	set @ProjLeadOnCommonTotal = 0		set @ProjLeadSEOffCommonTotal = 0	set @ProjMgrSEOnCommonTotal = 0		set @ProjMgrSEOffCommonTotal = 0	set @ProgMgrSEOnCommonTotal = 0		set @ProgMgrSEOffCommonTotal = 0
set @JrSEOnCommonLNDTotal = 0		set @JrSEOffCommonLNDTotal = 0		set @MidSEOnCommonLNDTotal = 0		set @MidSEOffCommonLNDTotal = 0		set @AdvSEOnCommonLNDTotal = 0		set @AdvSEOffCommonLNDTotal = 0		set @SenSEOnCommonLNDTotal = 0		set @SenSEOffCommonLNDTotal = 0		set @ConsArchSEOnCommonLNDTotal = 0		set @ConsArchSEOffCommonLNDTotal = 0	
set @JrSEOnCommonRDCTotal = 0		set @JrSEOffCommonRDCTotal = 0		set @MidSEOnCommonRDCTotal = 0		set @MidSEOffCommonRDCTotal = 0		set @AdvSEOnCommonRDCTotal = 0		set @AdvSEOffCommonRDCTotal = 0		set @SenSEOnCommonRDCTotal = 0		set @SenSEOffCommonRDCTotal = 0		set @ConsArchSEOnCommonRDCTotal = 0		set @ConsArchSEOffCommonRDCTotal = 0	
set @JrSEOnCommonTSTTotal = 0		set @JrSEOffCommonTSTTotal = 0		set @MidSEOnCommonTSTTotal = 0		set @MidSEOffCommonTSTTotal = 0		set @AdvSEOnCommonTSTTotal = 0		set @AdvSEOffCommonTSTTotal = 0		set @SenSEOnCommonTSTTotal = 0		set @SenSEOffCommonTSTTotal = 0		set @ConsArchSEOnCommonTSTTotal = 0		set @ConsArchSEOffCommonTSTTotal = 0	
set @JrSEOnCommonTSTLNDTotal = 0	set @JrSEOffCommonTSTLNDTotal = 0	set @MidSEOnCommonTSTLNDTotal = 0	set @MidSEOffCommonTSTLNDTotal = 0	set @AdvSEOnCommonTSTLNDTotal = 0	set @AdvSEOffCommonTSTLNDTotal = 0	set @SenSEOnCommonTSTLNDTotal = 0	set @SenSEOffCommonTSTLNDTotal = 0	set @ConsArchSEOnCommonTSTLNDTotal = 0	set @ConsArchSEOffCommonTSTLNDTotal = 0	
set @JrSEOnCommonTSTOFFTotal = 0	set @JrSEOffCommonTSTOFFTotal = 0	set @MidSEOnCommonTSTOFFTotal = 0	set @MidSEOffCommonTSTOFFTotal = 0	set @AdvSEOnCommonTSTOFFTotal = 0	set @AdvSEOffCommonTSTOFFTotal = 0	set @SenSEOnCommonTSTOFFTotal = 0	set @SenSEOffCommonTSTOFFTotal = 0	set @ConsArchSEOnCommonTSTOFFTotal = 0	set @ConsArchSEOffCommonTSTOFFTotal = 0	
set @JrSEOnCommonTSTRDCTotal = 0	set @JrSEOffCommonTSTRDCTotal = 0	set @MidSEOnCommonTSTRDCTotal = 0	set @MidSEOffCommonTSTRDCTotal = 0	set @AdvSEOnCommonTSTRDCTotal = 0	set @AdvSEOffCommonTSTRDCTotal = 0	set @SenSEOnCommonTSTRDCTotal = 0	set @SenSEOffCommonTSTRDCTotal = 0	set @ConsArchSEOnCommonTSTRDCTotal = 0	set @ConsArchSEOffCommonTSTRDCTotal = 0	
set @JrSEOnLegacyTotal = 0			set @JrSEOffLegacyTotal = 0			set @MidSEOnLegacyTotal = 0			set @MidSEOffLegacyTotal = 0		set @AdvSEOnLegacyTotal = 0			set @AdvSEOffLegacyTotal = 0		set @SenSEOnLegacyTotal = 0			set @SenSEOffLegacyTotal = 0		set @ConsArchSEOnLegacyTotal = 0		set @ConsArchSEOffLegacyTotal = 0	set @ProjLeadOnLegacyTotal = 0		set @ProjLeadSEOffLegacyTotal = 0	set @ProjMgrSEOnLegacyTotal = 0		set @ProjMgrSEOffLegacyTotal = 0	set @ProgMgrSEOnLegacyTotal = 0		set @ProgMgrSEOffLegacyTotal = 0	set @JrSEOnLegacyLNDTotal = 0	set @JrSEOffLegacyLNDTotal = 0		set @MidSEOnLegacyLNDTotal = 0	set @MidSEOffLegacyLNDTotal = 0	set @AdvSEOnLegacyLNDTotal = 0		set @AdvSEOffLegacyLNDTotal = 0		set @SenSEOnLegacyLNDTotal = 0			set @SenSEOffLegacyLNDTotal = 0	set @ConsArchSEOnLegacyLNDTotal = 0	set @ConsArchSEOffLegacyLNDTotal = 0	
set @JrSEOnNicheTotal = 0			set @JrSEOffNicheTotal = 0			set @MidSEOnNicheTotal = 0			set @MidSEOffNicheTotal = 0			set @AdvSEOnNicheTotal = 0			set @AdvSEOffNicheTotal = 0			set @SenSEOnNicheTotal = 0			set @SenSEOffNicheTotal = 0			set @ConsArchSEOnNicheTotal = 0			set @ConsArchSEOffNicheTotal = 0	set @ProjLeadOnNicheTotal = 0		set @ProjLeadSEOffNicheTotal = 0	set @ProjMgrSEOnNicheTotal = 0		set @ProjMgrSEOffNicheTotal = 0		set @ProgMgrSEOnNicheTotal = 0		set @ProgMgrSEOffNicheTotal = 0		set @AdvSEOnNicheLNDTotal = 0	set @AdvSEOffNicheLNDTotal = 0		set @SenSEOnNicheLNDTotal = 0	set @SenSEOffNicheLNDTotal = 0	set @ConsArchSEOnNicheLNDTotal = 0	set @ConsArchSEOffNicheLNDTotal = 0	
set @JrSEOnPremiumTotal = 0			set @JrSEOffPremiumTotal = 0		set @MidSEOnPremiumTotal = 0		set @MidSEOffPremiumTotal = 0		set @AdvSEOnPremiumTotal = 0		set @AdvSEOffPremiumTotal = 0		set @SenSEOnPremiumTotal = 0		set @SenSEOffPremiumTotal = 0		set @ConsArchSEOnPremiumTotal = 0		set @ConsArchSEOffPremiumTotal = 0	set @ProjLeadSEOnPremiumTotal = 0	set @ProjLeadSEOffPremiumTotal = 0	set @ProjMgrSEOnPremiumTotal = 0	set @ProjMgrSEOffPremiumTotal = 0	set @ProgMgrSEOnPremiumTotal = 0	set @ProgMgrSEOffPremiumTotal = 0	set @MidSEOnPremiumLNDTotal = 0	set @MidSEOffPremiumLNDTotal = 0	set @AdvSEOnPremiumLNDTotal = 0	set @AdvSEOffPremiumLNDTotal = 0	set @SenSEOnPremiumLNDTotal = 0	set @SenSEOffPremiumLNDTotal = 0	set @ConsArchSEOnPremiumLNDTotal = 0	set @ConsArchSEOffPremiumLNDTotal = 0	
set @PLOnTotal = 0					set @PLOffTotal = 0					set @PMOnTotal = 0					set @PMOffTotal = 0					set	@PGMOnTotal = 0					set @PGMOffTotal = 0

---for testing only
declare @DateFrom datetime, @DateTo datetime
set @DateFrom = '2016-09-01'
set @DateTo = '2016-09-30'

--Set the FTE rate for onshore and offshore (non FTP).
set @OnshoreFTERate = '149'
set @OffshoreFTERate = '143.5'

-- Populates at the Program Group level, record type 10.
DECLARE ProgramGroup_cursor CURSOR FOR 
	select distinct ProgramGroup, Prog_GroupID, UA_VicePresident from #TEMP_IN where ProgramGroup is not null order by ProgramGroup
OPEN ProgramGroup_cursor
FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID, @UPVP
WHILE @@FETCH_STATUS = 0
BEGIN
	insert #TEMP_OUT (RecNumber) values (10) -- A blank line
	insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, UAVP) select 10, 'ProgGroup/Total', @CurProgramGroup, @CurProg_GroupID, @UPVP
	select @MaxProgGroup = max(AutoKey) from #TEMP_OUT		
--print 'PgmGrp=' print @MaxProgGroup

	---------------------------------------------------------------------------------------------------
	-- Populates at the Program level, record type 20.
	DECLARE Program_cursor CURSOR FOR 
		select distinct Program, ProgramID from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program is not null order by Program					
	OPEN Program_cursor
	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
	WHILE @@FETCH_STATUS = 0
	BEGIN
		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID) 
		select 20, 'Program', @CurProgram, @CurProgramID
		select @MaxProgram = max(AutoKey) from #TEMP_OUT  
--print 'Pgm=' print @MaxProgram

		----------------------------------------------------------------------------------------------
		-- Populates at the AFE level, record type 30.
		DECLARE AFEDesc_cursor CURSOR FOR 
			select distinct AFEDesc, AFE_DescID from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram and AFEDesc is not null order by AFEDesc			
--select * from #TEMP_IN where Prog_GroupID = '6090' and ProgramID = '5154' and AFE_DescID = '2556' and NewBillingType like '%Mid SE%' and Offshore = 1
		OPEN AFEDesc_cursor
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID
		WHILE @@FETCH_STATUS = 0
       	BEGIN
			--insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, COBusinessLead) select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID, @CurBusinessLead
			insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID) 
			select 30, 'AFEDesc', @CurAFEDesc, @CurAFE_DescID
			select @MaxAFEDesc = max(AutoKey) from #TEMP_OUT		
print 'AFEDesc=' print @CurAFEDesc		--print 'AFE=' print @MaxAFEDesc

			--Populate the Business Lead--------
			select @CurBusinessLead = COBusinessLead from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
			
			--Populate the ITSA Billing Category------
			select @ITSABillingCat = ITSABillingCat from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
						
			--Populate the Hours------		
			---JrSE----									
			select @JrSEOnshoreCommon = sum(isnull(Hours,0)), @JrSEOnCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType in ('Jr SE', 'Common Jr SE') and Onshore = 1	group by NewBillingType
			select @JrSEOnshoreCommonLND = sum(isnull(Hours,0)), @JrSEOnCommonLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE LND' and Onshore = 1 group by NewBillingType
			select @JrSEOnshoreCommonRDC = sum(isnull(Hours,0)), @JrSEOnCommonRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE RDC' and Onshore = 1 group by NewBillingType			
			select @JrSEOnshoreCommonTST = sum(isnull(Hours,0)), @JrSEOnCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE TST' and Onshore = 1 group by NewBillingType
			select @JrSEOnshoreCommonTSTLND = sum(isnull(Hours,0)), @JrSEOnCommonTSTLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE TST LND' and Onshore = 1 group by NewBillingType
			select @JrSEOnshoreCommonTSTOFF = sum(isnull(Hours,0)), @JrSEOnCommonTSTOFFBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE TST OFF' and Onshore = 1 group by NewBillingType
			select @JrSEOnshoreCommonTSTRDC = sum(isnull(Hours,0)), @JrSEOnCommonTSTRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE TST RDC' and Onshore = 1 group by NewBillingType			
			select @JrSEOnshoreLegacy = sum(isnull(Hours,0)), @JrSEOnLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Jr SE' and Onshore = 1	group by NewBillingType		
			select @JrSEOnshoreLegacyLND = sum(isnull(Hours,0)), @JrSEOnLegacyLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Jr SE LND' and Onshore = 1	group by NewBillingType		
			select @JrSEOnshoreNiche = sum(isnull(Hours,0)), @JrSEOnNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Jr SE' and Onshore = 1	group by NewBillingType	
			select @JrSEOnshorePremium = sum(isnull(Hours,0)), @JrSEOnPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Jr SE' and Onshore = 1 group by NewBillingType			
			
			If @JrSEOnCommonBillingType in ('Jr SE', 'Common Jr SE')	
				set @JrSEOnCommonTotal = @JrSEOnCommonTotal + @JrSEOnshoreCommon
			If @JrSEOnCommonLNDBillingType = 'Common Jr SE LND'	
				set @JrSEOnCommonLNDTotal = @JrSEOnCommonLNDTotal + @JrSEOnshoreCommonLND
			If @JrSEOnCommonRDCBillingType = 'Common Jr SE RDC'
				set @JrSEOnCommonRDCTotal = @JrSEOnCommonRDCTotal + @JrSEOnshoreCommonRDC
			If @JrSEOnCommonTSTBillingType = 'Common Jr SE TST'
				set @JrSEOnCommonTSTTotal = @JrSEOnCommonTSTTotal + @JrSEOnshoreCommonTST
			If @JrSEOnCommonTSTLNDBillingType = 'Common Jr SE TST LND'
				set @JrSEOnCommonTSTLNDTotal = @JrSEOnCommonTSTLNDTotal + @JrSEOnshoreCommonTSTLND
			If @JrSEOnCommonTSTOFFBillingType = 'Common Jr SE TST OFF'	
				set @JrSEOnCommonTSTOFFTotal = @JrSEOnCommonTSTOFFTotal + @JrSEOnshoreCommonTSTOFF
			If @JrSEOnCommonTSTRDCBillingType = 'Common Jr SE TST RDC'
				set @JrSEOnCommonTSTRDCTotal = @JrSEOnCommonTSTRDCTotal + @JrSEOnshoreCommonTSTRDC
			If @JrSEOnLegacyBillingType = 'Legacy Jr SE'
				set @JrSEOnLegacyTotal = @JrSEOnLegacyTotal + @JrSEOnshoreLegacy
			If @JrSEOnLegacyLNDBillingType = 'Legacy Jr SE LND'
				set @JrSEOnLegacyLNDTotal = @JrSEOnLegacyLNDTotal + @JrSEOnshoreLegacyLND
			If @JrSEOnNicheBillingType = 'Niche Jr SE'
				set @JrSEOnNicheTotal = @JrSEOnNicheTotal + @JrSEOnshoreNiche
			If @JrSEOnPremiumBillingType = 'Premium Jr SE'
				set @JrSEOnPremiumTotal = @JrSEOnPremiumTotal + @JrSEOnshorePremium
			
			select @JrSEOffshoreCommon = sum(isnull(Hours,0)), @JrSEOffCommonBillingType = NewBillingType  from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType in ('Jr SE', 'Common Jr SE') and Offshore = 1 group by NewBillingType		
			select @JrSEOffshoreCommonLND = sum(isnull(Hours,0)), @JrSEOffCommonLNDBillingType = NewBillingType  from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE LND' and Offshore = 1 group by NewBillingType
			select @JrSEOffshoreCommonRDC = sum(isnull(Hours,0)), @JrSEOffCommonRDCBillingType = NewBillingType  from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE RDC' and Offshore = 1 group by NewBillingType					
			select @JrSEOffshoreCommonTST = sum(isnull(Hours,0)), @JrSEOffCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE TST' and Offshore = 1 group by NewBillingType
			select @JrSEOffshoreCommonTSTLND = sum(isnull(Hours,0)), @JrSEOffCommonTSTLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE TST LND' and Offshore = 1 group by NewBillingType
			select @JrSEOffshoreCommonTSTOFF = sum(isnull(Hours,0)), @JrSEOffCommonTSTOFFBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE TST OFF' and Offshore = 1 group by NewBillingType
			select @JrSEOffshoreCommonTSTRDC = sum(isnull(Hours,0)), @JrSEOffCommonTSTRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Jr SE TST RDC' and Offshore = 1 group by NewBillingType
			select @JrSEOffshoreLegacy = sum(isnull(Hours,0)), @JrSEOffLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Jr SE' and Offshore = 1 group by NewBillingType	
			select @JrSEOffshoreLegacyLND = sum(isnull(Hours,0)), @JrSEOffLegacyLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Jr SE LND' and Offshore = 1 group by NewBillingType	
			select @JrSEOffshoreNiche = sum(isnull(Hours,0)), @JrSEOffNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Jr SE' and Offshore = 1	group by NewBillingType			
			select @JrSEOffshorePremium = sum(isnull(Hours,0)), @JrSEOffPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Jr SE' and Offshore = 1 group by NewBillingType

			If @JrSEOffCommonBillingType in ('Jr SE', 'Common Jr SE')	
				set @JrSEOffCommonTotal = @JrSEOffCommonTotal + @JrSEOffshoreCommon
			If @JrSEOffCommonLNDBillingType = 'Common Jr SE LND'	
				set @JrSEOffCommonLNDTotal = @JrSEOffCommonLNDTotal + @JrSEOffshoreCommonLND
			If @JrSEOffCommonRDCBillingType = 'Common Jr SE RDC'	
				set @JrSEOffCommonRDCTotal = @JrSEOffCommonRDCTotal + @JrSEOffshoreCommonRDC
			If @JrSEOffCommonTSTBillingType = 'Common Jr SE TST'	
				set @JrSEOffCommonTSTTotal = @JrSEOffCommonTSTTotal + @JrSEOffshoreCommonTST
			If @JrSEOffCommonTSTLNDBillingType = 'Common Jr SE TST LND'	
				set @JrSEOffCommonTSTLNDTotal = @JrSEOffCommonTSTLNDTotal + @JrSEOffshoreCommonTSTLND
			If @JrSEOffCommonTSTOFFBillingType = 'Common Jr SE TST OFF'	
				set @JrSEOffCommonTSTOFFTotal = @JrSEOffCommonTSTOFFTotal + @JrSEOffshoreCommonTSTOFF
			If @JrSEOffCommonTSTRDCBillingType = 'Common Jr SE TST RDC'	
				set @JrSEOffCommonTSTRDCTotal = @JrSEOffCommonTSTRDCTotal + @JrSEOffshoreCommonTSTRDC
			If @JrSEOffLegacyBillingType = 'Legacy Jr SE'
				set @JrSEOffLegacyTotal = @JrSEOffLegacyTotal + @JrSEOffshoreLegacy
			If @JrSEOffLegacyLNDBillingType = 'Legacy Jr SE LND'
				set @JrSEOffLegacyLNDTotal = @JrSEOffLegacyLNDTotal + @JrSEOffshoreLegacyLND
			If @JrSEOffNicheBillingType = 'Niche Jr SE'
				set @JrSEOffNicheTotal = @JrSEOffNicheTotal + @JrSEOffshoreNiche
			If @JrSEOffPremiumBillingType = 'Premium Jr SE'
				set @JrSEOffPremiumTotal = @JrSEOffPremiumTotal + @JrSEOffshorePremium
			
			--print 'JrSEOnCommon='			print @JrSEOnshoreCommon			print 'JrSEOffCommon='			print @JrSEOffshoreCommon	
			--print 'JrSEOnLegacy='			print @JrSEOnshoreLegacy			print 'JrSEOffLegacy='			print @JrSEOffshoreLegacy	
			--print 'JrSEOnshoreNiche='		print @JrSEOnshoreNiche				print 'JrSEOffshoreNiche='		print @JrSEOffshoreNiche
			--print 'JrSEOnshorePremium='		print @JrSEOnshorePremium			print 'JrSEOffshorePremium='	print @JrSEOffshorePremium		
			--print 'JrSEOnCommonTotal=' print @JrSEOnCommonTotal			print 'JrSEOffCommonTotal=' print @JrSEOffCommonTotal	
			--print 'JrSEOnlegacyTotal=' print @JrSEOnLegacyTotal			print 'JrSEOfflegacyTotal=' print @JrSEOffLegacyTotal
			--print 'JrSEOnPremiumTotal=' print @JrSEOnPremiumTotal			print 'JrSEOffPremiumTotal=' print @JrSEOffPremiumTotal
			--print 'JrSEOnCommonBillingType='	print @JrSEOnCommonBillingType		print 'JrSEOffCommonBillingType='	print @JrSEOffCommonBillingType
			--print 'JrSEOnLegacyBillingType='	print @JrSEOnLegacyBillingType		print 'JrSEOffLegacyBillingType='	print @JrSEOffLegacyBillingType
			--print 'JrSEOnNicheBillingType='		print @JrSEOnNicheBillingType		print 'JrSEOffNicheBillingType='	print @JrSEOffNicheBillingType
			--print 'JrSEOnPremiumBillingType='	print @JrSEOnPremiumBillingType		print 'JrSEOffPremiumBillingType='	print @JrSEOffPremiumBillingType
									
			---MidSE--------------						
			select @MidSEOnshoreCommon = sum(isnull(Hours,0)), @MidSEOnCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType in ('Mid SE', 'Common Mid SE') and Onshore = 1 group by NewBillingType	
			select @MidSEOnshoreCommonLND = sum(isnull(Hours,0)), @MidSEOnCommonLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE LND' and Onshore = 1 group by NewBillingType	
			select @MidSEOnshoreCommonRDC = sum(isnull(Hours,0)), @MidSEOnCommonRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE RDC' and Onshore = 1 group by NewBillingType				
			select @MidSEOnshoreCommonTST = sum(isnull(Hours,0)), @MidSEOnCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE TST' and Onshore = 1 group by NewBillingType				
			select @MidSEOnshoreCommonTSTLND = sum(isnull(Hours,0)), @MidSEOnCommonTSTLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE TST LND' and Onshore = 1 group by NewBillingType		
			select @MidSEOnshoreCommonTSTOFF = sum(isnull(Hours,0)), @MidSEOnCommonTSTOFFBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE TST OFF' and Onshore = 1 group by NewBillingType		
			select @MidSEOnshoreCommonTSTRDC = sum(isnull(Hours,0)), @MidSEOnCommonTSTRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE TST RDC' and Onshore = 1 group by NewBillingType						
			select @MidSEOnshoreLegacy = sum(isnull(Hours,0)), @MidSEOnLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Mid SE' and Onshore = 1 group by NewBillingType				
			select @MidSEOnshoreLegacyLND = sum(isnull(Hours,0)), @MidSEOnLegacyLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Mid SE LND' and Onshore = 1 group by NewBillingType	
			select @MidSEOnshoreNiche = sum(isnull(Hours,0)), @MidSEOnNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Mid SE' and Onshore = 1 group by NewBillingType		
			select @MidSEOnshorePremium = sum(isnull(Hours,0)), @MidSEOnPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Mid SE' and Onshore = 1 group by NewBillingType	
			select @MidSEOnshorePremiumLND = sum(isnull(Hours,0)), @MidSEOnPremiumLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Mid SE LND' and Onshore = 1 group by NewBillingType			

			If @MidSEOnCommonBillingType in ('Mid SE', 'Common Mid SE')
				set @MidSEOnCommonTotal = @MidSEOnCommonTotal + @MidSEOnshoreCommon
			If @MidSEOnCommonLNDBillingType = 'Common Mid SE LND'
				set @MidSEOnCommonLNDTotal = @MidSEOnCommonLNDTotal + @MidSEOnshoreCommonLND
			If @MidSEOnCommonRDCBillingType = 'Common Mid SE RDC'
				set @MidSEOnCommonRDCTotal = @MidSEOnCommonRDCTotal + @MidSEOnshoreCommonRDC			
			If @MidSEOnCommonTSTBillingType = 'Common Mid SE TST'
				set @MidSEOnCommonTSTTotal = @MidSEOnCommonTSTTotal + @MidSEOnshoreCommonTST
			If @MidSEOnCommonTSTLNDBillingType = 'Common Mid SE TST LND'
				set @MidSEOnCommonTSTLNDTotal = @MidSEOnCommonTSTLNDTotal + @MidSEOnshoreCommonTSTLND
			If @MidSEOnCommonTSTOFFBillingType = 'Common Mid SE TST OFF'
				set @MidSEOnCommonTSTOFFTotal = @MidSEOnCommonTSTOFFTotal + @MidSEOnshoreCommonTSTOFF
			If @MidSEOnCommonTSTRDCBillingType = 'Common Mid SE TST RDC'
				set @MidSEOnCommonTSTRDCTotal = @MidSEOnCommonTSTRDCTotal + @MidSEOnshoreCommonTSTRDC
			If @MidSEOnLegacyBillingType = 'Legacy Mid SE'
				set @MidSEOnLegacyTotal = @MidSEOnLegacyTotal + @MidSEOnshoreLegacy
			If @MidSEOnLegacyLNDBillingType = 'Legacy Mid SE LND'
				set @MidSEOnLegacyLNDTotal = @MidSEOnLegacyLNDTotal + @MidSEOnshoreLegacyLND			
			If @MidSEOnNicheBillingType = 'Niche Mid SE'
				set @MidSEOnNicheTotal = @MidSEOnNicheTotal + @MidSEOnshoreNiche
			If @MidSEOnPremiumBillingType = 'Premium Mid SE'
				set @MidSEOnPremiumTotal = @MidSEOnPremiumTotal + @MidSEOnshorePremium	
			If @MidSEOnPremiumLNDBillingType = 'Premium Mid SE LND'
				set @MidSEOnPremiumLNDTotal = @MidSEOnPremiumLNDTotal + @MidSEOnshorePremiumLND			
														
			select @MidSEOffshoreCommon = sum(isnull(Hours,0)), @MidSEOffCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType in ('Mid SE', 'Common Mid SE') and Offshore = 1 group by NewBillingType		
			select @MidSEOffshoreCommonLND = sum(isnull(Hours,0)), @MidSEOffCommonLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE LND' and Offshore = 1 group by NewBillingType
			select @MidSEOffshoreCommonRDC = sum(isnull(Hours,0)), @MidSEOffCommonRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE RDC' and Offshore = 1 group by NewBillingType				
			select @MidSEOffshoreCommonTST = sum(isnull(Hours,0)), @MidSEOffCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE TST' and Offshore = 1 group by NewBillingType	
			select @MidSEOffshoreCommonTSTLND = sum(isnull(Hours,0)), @MidSEOffCommonTSTLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE TST LND' and Offshore = 1 group by NewBillingType				
			select @MidSEOffshoreCommonTSTOFF = sum(isnull(Hours,0)), @MidSEOffCommonTSTOFFBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE TST OFF' and Offshore = 1 group by NewBillingType				
			select @MidSEOffshoreCommonTSTRDC = sum(isnull(Hours,0)), @MidSEOffCommonTSTRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Mid SE TST RDC' and Offshore = 1 group by NewBillingType				
			select @MidSEOffshoreLegacy = sum(isnull(Hours,0)), @MidSEOffLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Mid SE' and Offshore = 1 group by NewBillingType			
			select @MidSEOffshoreLegacyLND = sum(isnull(Hours,0)), @MidSEOffLegacyLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Mid SE LND' and Offshore = 1 group by NewBillingType
			select @MidSEOffshoreNiche = sum(isnull(Hours,0)), @MidSEOffNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Mid SE' and Offshore = 1 group by NewBillingType				
			select @MidSEOffshorePremium = sum(isnull(Hours,0)), @MidSEOffPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Mid SE' and Offshore = 1 group by NewBillingType
			select @MidSEOffshorePremiumLND = sum(isnull(Hours,0)), @MidSEOffPremiumLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Mid SE LND' and Offshore = 1 group by NewBillingType													

			If @MidSEOffCommonBillingType in ('Mid SE', 'Common Mid SE')						
				set @MidSEOffCommonTotal = @MidSEOffCommonTotal + @MidSEOffshoreCommon
			If @MidSEOffCommonLNDBillingType = 'Common Mid SE LND'						
				set @MidSEOffCommonLNDTotal = @MidSEOffCommonLNDTotal + @MidSEOffshoreCommonLND
			If @MidSEOffCommonRDCBillingType = 'Common Mid SE RDC'						
				set @MidSEOffCommonRDCTotal = @MidSEOffCommonRDCTotal + @MidSEOffshoreCommonRDC
			If @MidSEOffCommonTSTBillingType = 'Common Mid SE TST'
				set @MidSEOffCommonTSTTotal = @MidSEOffCommonTSTTotal + @MidSEOffshoreCommonTST
			If @MidSEOffCommonTSTLNDBillingType = 'Common Mid SE TST LND'
				set @MidSEOffCommonTSTLNDTotal = @MidSEOffCommonTSTLNDTotal + @MidSEOffshoreCommonTSTLND
			If @MidSEOffCommonTSTOFFBillingType = 'Common Mid SE TST OFF'
				set @MidSEOffCommonTSTOFFTotal = @MidSEOffCommonTSTOFFTotal + @MidSEOffshoreCommonTSTOFF
			If @MidSEOffCommonTSTRDCBillingType = 'Common Mid SE TST RDC'
				set @MidSEOffCommonTSTRDCTotal = @MidSEOffCommonTSTRDCTotal + @MidSEOffshoreCommonTSTRDC
			If @MidSEOffLegacyBillingType = 'Legacy Mid SE'
				set @MidSEOffLegacyTotal = @MidSEOffLegacyTotal + @MidSEOffshoreLegacy
			If @MidSEOffLegacyLNDBillingType = 'Legacy Mid SE LND'
				set @MidSEOffLegacyLNDTotal = @MidSEOffLegacyLNDTotal + @MidSEOffshoreLegacyLND
			If @MidSEOffNicheBillingType = 'Niche Mid SE'
				set @MidSEOffNicheTotal = @MidSEOffNicheTotal + @MidSEOffshoreNiche
			If @MidSEOffPremiumBillingType = 'Premium Mid SE'
				set @MidSEOffPremiumTotal = @MidSEOffPremiumTotal + @MidSEOffshorePremium
			If @MidSEOffPremiumLNDBillingType = 'Premium Mid SE LND'
				set @MidSEOffPremiumLNDTotal = @MidSEOffPremiumLNDTotal + @MidSEOffshorePremiumLND
							
			--print 'MidSEOnCommon=' print @MidSEOnshoreCommon			print 'MidSEOffCommon='			print @MidSEOffshoreCommon			
			--print 'MidSEOnLegacy=' print @MidSEOnshoreLegacy			print 'MidSEOffLegacy='			print @MidSEOffshoreLegacy		
			--print 'MidSEOnshoreNiche='		print @MidSEOnshoreNiche	print 'MidSEOffshoreNiche='		print @MidSEOffshoreNiche
			--print 'MidSEOnshorePremium=' print @MidSEOnshorePremium		Print 'MidSEOffshorePremium='	print @MidSEOffshorePremium		
			--print 'MidSEOnCommonTotal=' print @MidSEOnCommonTotal				print 'MidSEOffCommonTotal=' print @MidSEOffCommonTotal	
			--print 'MidSEOnlegacyTotal=' print @MidSEOnLegacyTotal				print 'MidSEOfflegacyTotal=' print @MidSEOffLegacyTotal
			--print 'MidSEOnPremiumTotal=' print @MidSEOnPremiumTotal			print 'MidSEOffPremiumTotal=' print @MidSEOffPremiumTotal	
			--print 'MidSEOnCommonBillingType='	print @MidSEOnCommonBillingType		print 'MidSEOffCommonBillingType='	print @MidSEOffCommonBillingType
			--print 'MidSEOnLegacyBillingType='	print @MidSEOnLegacyBillingType		print 'MidSEOffLegacyBillingType='	print @MidSEOffLegacyBillingType
			--print 'MidSEOnPremiumBillingType='	print @MidSEOnPremiumBillingType	print 'MidSEOffPremiumBillingType='	print @MidSEOffPremiumBillingType
			--print 'MidSEOnNicheBillingType='	print @MidSEOnNicheBillingType		print 'MidSEOffNicheBillingType='	print @MidSEOffNicheBillingType
						
			-----------------------AdvSE--------------									
			select @AdvSEOnshoreCommon = sum(isnull(Hours,0)), @AdvSEOnCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType in ('Adv SE', 'Common Adv SE') and Onshore = 1 group by NewBillingType		
			select @AdvSEOnshoreCommonLND = sum(isnull(Hours,0)), @AdvSEOnCommonLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE LND' and Onshore = 1 group by NewBillingType		
			select @AdvSEOnshoreCommonRDC = sum(isnull(Hours,0)), @AdvSEOnCommonRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE RDC' and Onshore = 1 group by NewBillingType					
			select @AdvSEOnshoreCommonTST = sum(isnull(Hours,0)), @AdvSEOnCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE TST' and Onshore = 1 group by NewBillingType	
			select @AdvSEOnshoreCommonTSTLND = sum(isnull(Hours,0)), @AdvSEOnCommonTSTLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE TST LND' and Onshore = 1 group by NewBillingType	
			select @AdvSEOnshoreCommonTSTOFF = sum(isnull(Hours,0)), @AdvSEOnCommonTSTOFFBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE TST OFF' and Onshore = 1 group by NewBillingType	
			select @AdvSEOnshoreCommonTSTRDC = sum(isnull(Hours,0)), @AdvSEOnCommonTSTRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE TST RDC' and Onshore = 1 group by NewBillingType	
			select @AdvSEOnshoreLegacy = sum(isnull(Hours,0)), @AdvSEOnLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Adv SE' and Onshore = 1 group by NewBillingType	
			select @AdvSEOnshoreLegacyLND = sum(isnull(Hours,0)), @AdvSEOnLegacyLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Adv SE LND' and Onshore = 1 group by NewBillingType		
			select @AdvSEOnshoreNiche = sum(isnull(Hours,0)), @AdvSEOnNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Adv SE' and Onshore = 1 group by NewBillingType		
			select @AdvSEOnshoreNicheLND = sum(isnull(Hours,0)), @AdvSEOnNicheLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Adv SE LND' and Onshore = 1 group by NewBillingType			
			select @AdvSEOnshorePremium = sum(isnull(Hours,0)), @AdvSEOnPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Adv SE' and Onshore = 1 group by NewBillingType	
			select @AdvSEOnshorePremiumLND = sum(isnull(Hours,0)), @AdvSEOnPremiumLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Adv SE LND' and Onshore = 1 group by NewBillingType	

			If @AdvSEOnCommonBillingType in ('Adv SE', 'Common Adv SE')
				set @AdvSEOnCommonTotal = @AdvSEOnCommonTotal + @AdvSEOnshoreCommon
			If @AdvSEOnCommonLNDBillingType = 'Common Adv SE LND'
				set @AdvSEOnCommonLNDTotal = @AdvSEOnCommonLNDTotal + @AdvSEOnshoreCommonLND
			If @AdvSEOnCommonRDCBillingType = 'Common Adv SE RDC'
				set @AdvSEOnCommonRDCTotal = @AdvSEOnCommonRDCTotal + @AdvSEOnshoreCommonRDC
			If @AdvSEOnCommonTSTBillingType = 'Common Adv SE TST'
				set @AdvSEOnCommonTSTTotal = @AdvSEOnCommonTSTTotal + @AdvSEOnshoreCommonTST
			If @AdvSEOnCommonTSTLNDBillingType = 'Common Adv SE TST LND'
				set @AdvSEOnCommonTSTLNDTotal = @AdvSEOnCommonTSTLNDTotal + @AdvSEOnshoreCommonTSTLND
			If @AdvSEOnCommonTSTOFFBillingType = 'Common Adv SE TST OFF'
				set @AdvSEOnCommonTSTOFFTotal = @AdvSEOnCommonTSTOFFTotal + @AdvSEOnshoreCommonTSTOFF
			If @AdvSEOnCommonTSTRDCBillingType = 'Common Adv SE TST RDC'
				set @AdvSEOnCommonTSTRDCTotal = @AdvSEOnCommonTSTRDCTotal + @AdvSEOnshoreCommonTSTRDC
			If @AdvSEOnLegacyBillingType = 'Legacy Adv SE'
				set @AdvSEOnLegacyTotal = @AdvSEOnLegacyTotal + @AdvSEOnshoreLegacy
			If @AdvSEOnLegacyLNDBillingType = 'Legacy Adv SE LND'
				set @AdvSEOnLegacyLNDTotal = @AdvSEOnLegacyLNDTotal + @AdvSEOnshoreLegacyLND
			If @AdvSEOnNicheBillingType = 'Niche Adv SE'
				set @AdvSEOnNicheTotal = @AdvSEOnNicheTotal + @AdvSEOnshoreNiche
			If @AdvSEOnNicheLNDBillingType = 'Niche Adv SE LND'
				set @AdvSEOnNicheLNDTotal = @AdvSEOnNicheLNDTotal + @AdvSEOnshoreNicheLND
			If @AdvSEOnPremiumBillingType = 'Premium Adv SE'
				set @AdvSEOnPremiumTotal = @AdvSEOnPremiumTotal + @AdvSEOnshorePremium	
			If @AdvSEOnPremiumLNDBillingType = 'Premium Adv SE LND'
				set @AdvSEOnPremiumLNDTotal = @AdvSEOnPremiumLNDTotal + @AdvSEOnshorePremiumLND			
			
			select @AdvSEOffshoreCommon = sum(isnull(Hours,0)), @AdvSEOffCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType in ('Adv SE', 'Common Adv SE') and Offshore = 1 group by NewBillingType		
			select @AdvSEOffshoreCommonLND = sum(isnull(Hours,0)), @AdvSEOffCommonLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE LND' and Offshore = 1 group by NewBillingType
			select @AdvSEOffshoreCommonRDC = sum(isnull(Hours,0)), @AdvSEOffCommonRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE RDC' and Offshore = 1 group by NewBillingType				
			select @AdvSEOffshoreCommonTST = sum(isnull(Hours,0)), @AdvSEOffCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE TST' and Offshore = 1 group by NewBillingType	
			select @AdvSEOffshoreCommonTSTLND = sum(isnull(Hours,0)), @AdvSEOffCommonTSTLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE TST LND' and Offshore = 1 group by NewBillingType	
			select @AdvSEOffshoreCommonTSTOFF = sum(isnull(Hours,0)), @AdvSEOffCommonTSTOFFBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE TST OFF' and Offshore = 1 group by NewBillingType	
			select @AdvSEOffshoreCommonTSTRDC = sum(isnull(Hours,0)), @AdvSEOffCommonTSTRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Adv SE TST RDC' and Offshore = 1 group by NewBillingType				
			select @AdvSEOffshoreLegacy = sum(isnull(Hours,0)), @AdvSEOffLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Adv SE' and Offshore = 1 group by NewBillingType			
			select @AdvSEOffshoreLegacyLND = sum(isnull(Hours,0)), @AdvSEOffLegacyLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Adv SE LND' and Offshore = 1 group by NewBillingType
			select @AdvSEOffshoreNiche = sum(isnull(Hours,0)), @AdvSEOffNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Adv SE' and Offshore = 1 group by NewBillingType		
			select @AdvSEOffshoreNicheLND = sum(isnull(Hours,0)), @AdvSEOffNicheLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Adv SE LND' and Offshore = 1 group by NewBillingType							
			select @AdvSEOffshorePremium = sum(isnull(Hours,0)), @AdvSEOffPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Adv SE' and Offshore = 1 group by NewBillingType
			select @AdvSEOffshorePremiumLND = sum(isnull(Hours,0)), @AdvSEOffPremiumLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Adv SE LND' and Offshore = 1 group by NewBillingType
					
			If @AdvSEOffCommonBillingType in ('Adv SE', 'Common Adv SE')						
				set @AdvSEOffCommonTotal = @AdvSEOffCommonTotal + @AdvSEOffshoreCommon
			If @AdvSEOffCommonLNDBillingType = 'Common Adv SE LND'						
				set @AdvSEOffCommonLNDTotal = @AdvSEOffCommonLNDTotal + @AdvSEOffshoreCommonLND
			If @AdvSEOffCommonRDCBillingType = 'Common Adv SE RDC'						
				set @AdvSEOffCommonRDCTotal = @AdvSEOffCommonRDCTotal + @AdvSEOffshoreCommonRDC
			If @AdvSEOffCommonTSTBillingType = 'Common Adv SE TST'
				set @AdvSEOffCommonTSTTotal = @AdvSEOffCommonTSTTotal + @AdvSEOffshoreCommonTST
			If @AdvSEOffCommonTSTLNDBillingType = 'Common Adv SE TST LND'
				set @AdvSEOffCommonTSTLNDTotal = @AdvSEOffCommonTSTLNDTotal + @AdvSEOffshoreCommonTSTLND
			If @AdvSEOffCommonTSTOFFBillingType = 'Common Adv SE TST OFF'
				set @AdvSEOffCommonTSTOFFTotal = @AdvSEOffCommonTSTOFFTotal + @AdvSEOffshoreCommonTSTOFF
			If @AdvSEOffCommonTSTRDCBillingType = 'Common Adv SE TST RDC'
				set @AdvSEOffCommonTSTRDCTotal = @AdvSEOffCommonTSTRDCTotal + @AdvSEOffshoreCommonTSTRDC
			If @AdvSEOffLegacyBillingType = 'Legacy Adv SE'
				set @AdvSEOffLegacyTotal = @AdvSEOffLegacyTotal + @AdvSEOffshoreLegacy
			If @AdvSEOffLegacyLNDBillingType = 'Legacy Adv SE LND'
				set @AdvSEOffLegacyLNDTotal = @AdvSEOffLegacyLNDTotal + @AdvSEOffshoreLegacyLND
			If @AdvSEOffNicheBillingType = 'Niche Adv SE'
				set @AdvSEOffNicheTotal = @AdvSEOffNicheTotal + @AdvSEOffshoreNiche
			If @AdvSEOffNicheLNDBillingType = 'Niche Adv SE LND'
				set @AdvSEOffNicheLNDTotal = @AdvSEOffNicheLNDTotal + @AdvSEOffshoreNicheLND
			If @AdvSEOffPremiumBillingType = 'Premium Adv SE'
				set @AdvSEOffPremiumTotal = @AdvSEOffPremiumTotal + @AdvSEOffshorePremium
			If @AdvSEOffPremiumLNDBillingType = 'Premium Adv SE LND'
				set @AdvSEOffPremiumLNDTotal = @AdvSEOffPremiumLNDTotal + @AdvSEOffshorePremiumLND

			--print 'AdvSEOnCommon='			print @AdvSEOnshoreCommon		print 'AdvSEOffCommon='			print @AdvSEOffshoreCommon		
			--print 'AdvSEOnLegacy='			print @AdvSEOnshoreLegacy		print 'AdvSEOffLegacy='			print @AdvSEOffshoreLegacy
			--print 'AdvSEOnshoreNiche='		print @AdvSEOnshoreNiche		print 'AdvSEOffshoreNiche='		print @AdvSEOffshoreNiche
			--print 'AdvSEOnshorePremium='	print @AdvSEOnshorePremium		Print 'AdvSEOffshorePremium='	print @AdvSEOffshorePremium		
			--print 'AdvSEOnCommonTotal=' print @AdvSEOnCommonTotal			print 'AdvSEOffCommonTotal=' print @AdvSEOffCommonTotal	
			--print 'AdvSEOnlegacyTotal=' print @AdvSEOnLegacyTotal			print 'AdvSEOfflegacyTotal=' print @AdvSEOffLegacyTotal
			--print 'AdvSEOnPremiumTotal=' print @AdvSEOnPremiumTotal		print 'AdvSEOffPremiumTotal=' print @AdvSEOffPremiumTotal		
			--print 'AdvSEOnCommonBillingType='	print @AdvSEOnCommonBillingType		print 'AdvSEOffCommonBillingType='	print @AdvSEOffCommonBillingType
			--print 'AdvSEOnLegacyBillingType='	print @AdvSEOnLegacyBillingType		print 'AdvSEOffLegacyBillingType='	print @AdvSEOffLegacyBillingType
			--print 'AdvSEOnNicheBillingType='	print @AdvSEOnNicheBillingType		print 'AdvSEOffNicheBillingType='	print @AdvSEOffNicheBillingType
			--print 'AdvSEOnPremiumBillingType='	print @AdvSEOnPremiumBillingType	print 'AdvSEOffPremiumBillingType='	print @AdvSEOffPremiumBillingType
			
			-----------------------SenSE--------------
			select @SenSEOnshoreCommon = sum(isnull(Hours,0)), @SenSEOnCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType in ('Sen SE', 'Common Sen SE') and Onshore = 1 group by NewBillingType		
			select @SenSEOnshoreCommonLND = sum(isnull(Hours,0)), @SenSEOnCommonLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE LND' and Onshore = 1 group by NewBillingType		
			select @SenSEOnshoreCommonRDC = sum(isnull(Hours,0)), @SenSEOnCommonRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE RDC' and Onshore = 1 group by NewBillingType				
			select @SenSEOnshoreCommonTST = sum(isnull(Hours,0)), @SenSEOnCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE TST' and Onshore = 1 group by NewBillingType	
			select @SenSEOnshoreCommonTST = sum(isnull(Hours,0)), @SenSEOnCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE TST LND' and Onshore = 1 group by NewBillingType	
			select @SenSEOnshoreCommonTST = sum(isnull(Hours,0)), @SenSEOnCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE TST OFF' and Onshore = 1 group by NewBillingType	
			select @SenSEOnshoreCommonTST = sum(isnull(Hours,0)), @SenSEOnCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE TST RDC' and Onshore = 1 group by NewBillingType	
			select @SenSEOnshoreLegacy = sum(isnull(Hours,0)), @SenSEOnLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Sen SE' and Onshore = 1 group by NewBillingType	
			select @SenSEOnshoreLegacyLND = sum(isnull(Hours,0)), @SenSEOnLegacyLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Sen SE LND' and Onshore = 1 group by NewBillingType	
			select @SenSEOnshoreNiche = sum(isnull(Hours,0)), @SenSEOnNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Sen SE' and Onshore = 1 group by NewBillingType		
			select @SenSEOnshoreNicheLND = sum(isnull(Hours,0)), @SenSEOnNicheLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Sen SE LND' and Onshore = 1 group by NewBillingType		
			select @SenSEOnshorePremium = sum(isnull(Hours,0)), @SenSEOnPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Sen SE' and Onshore = 1 group by NewBillingType
			select @SenSEOnshorePremiumLND = sum(isnull(Hours,0)), @SenSEOnPremiumLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Sen SE LND' and Onshore = 1 group by NewBillingType	

			If @SenSEOnCommonBillingType in ('Sen SE', 'Common Sen SE')
				set @SenSEOnCommonTotal = @SenSEOnCommonTotal + @SenSEOnshoreCommon
			If @SenSEOnCommonLNDBillingType = 'Common Sen SE LND'
				set @SenSEOnCommonLNDTotal = @SenSEOnCommonLNDTotal + @SenSEOnshoreCommonLND
			If @SenSEOnCommonRDCBillingType = 'Common Sen SE RDC'
				set @SenSEOnCommonRDCTotal = @SenSEOnCommonRDCTotal + @SenSEOnshoreCommonRDC
			If @SenSEOnCommonTSTBillingType = 'Common Sen SE TST'
				set @SenSEOnCommonTSTTotal = @SenSEOnCommonTSTTotal + @SenSEOnshoreCommonTST
			If @SenSEOnCommonTSTLNDBillingType = 'Common Sen SE TST LND'
				set @SenSEOnCommonTSTLNDTotal = @SenSEOnCommonTSTLNDTotal + @SenSEOnshoreCommonTSTLND
			If @SenSEOnCommonTSTOFFBillingType = 'Common Sen SE TST OFF'
				set @SenSEOnCommonTSTOFFTotal = @SenSEOnCommonTSTOFFTotal + @SenSEOnshoreCommonTSTOFF
			If @SenSEOnCommonTSTRDCBillingType = 'Common Sen SE TST RDC'
				set @SenSEOnCommonTSTRDCTotal = @SenSEOnCommonTSTRDCTotal + @SenSEOnshoreCommonTSTRDC
			If @SenSEOnLegacyBillingType = 'Legacy Sen SE'
				set @SenSEOnLegacyTotal = @SenSEOnLegacyTotal + @SenSEOnshoreLegacy
			If @SenSEOnLegacyLNDBillingType = 'Legacy Sen SE LND'
				set @SenSEOnLegacyLNDTotal = @SenSEOnLegacyLNDTotal + @SenSEOnshoreLegacyLND
			If @SenSEOnNicheBillingType = 'Niche Sen SE'
				set @SenSEOnNicheTotal = @SenSEOnNicheTotal + @SenSEOnshoreNiche
			If @SenSEOnNicheLNDBillingType = 'Niche Sen SE LND'
				set @SenSEOnNicheLNDTotal = @SenSEOnNicheLNDTotal + @SenSEOnshoreNicheLND
			If @SenSEOnPremiumBillingType = 'Premium Sen SE'
				set @SenSEOnPremiumTotal = @SenSEOnPremiumTotal + @SenSEOnshorePremium	
			If @SenSEOnPremiumLNDBillingType = 'Premium Sen SE LND'
				set @SenSEOnPremiumLNDTotal = @SenSEOnPremiumLNDTotal + @SenSEOnshorePremiumLND
			
			select @SenSEOffshoreCommon = sum(isnull(Hours,0)), @SenSEOffCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType in ('Sen SE', 'Common Sen SE') and Offshore = 1 group by NewBillingType	
			select @SenSEOffshoreCommonLND = sum(isnull(Hours,0)), @SenSEOffCommonLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE LND' and Offshore = 1 group by NewBillingType	
			select @SenSEOffshoreCommonRDC = sum(isnull(Hours,0)), @SenSEOffCommonRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE RDC' and Offshore = 1 group by NewBillingType				
			select @SenSEOffshoreCommonTST = sum(isnull(Hours,0)), @SenSEOffCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE TST' and Offshore = 1 group by NewBillingType	
			select @SenSEOffshoreCommonTST = sum(isnull(Hours,0)), @SenSEOffCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE TST LND' and Offshore = 1 group by NewBillingType	
			select @SenSEOffshoreCommonTST = sum(isnull(Hours,0)), @SenSEOffCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE TST OFF' and Offshore = 1 group by NewBillingType	
			select @SenSEOffshoreCommonTST = sum(isnull(Hours,0)), @SenSEOffCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Sen SE TST RDC' and Offshore = 1 group by NewBillingType									
			select @SenSEOffshoreLegacy = sum(isnull(Hours,0)), @SenSEOffLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Sen SE' and Offshore = 1 group by NewBillingType	
			select @SenSEOffshoreLegacyLND = sum(isnull(Hours,0)), @SenSEOffLegacyLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Sen SE LND' and Offshore = 1 group by NewBillingType		
			select @SenSEOffshoreNiche = sum(isnull(Hours,0)), @SenSEOffNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Sen SE' and Offshore = 1 group by NewBillingType	
			select @SenSEOffshoreNicheLND = sum(isnull(Hours,0)), @SenSEOffNicheLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Sen SE LND' and Offshore = 1 group by NewBillingType				
			select @SenSEOffshorePremium = sum(isnull(Hours,0)), @SenSEOnPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Sen SE' and Offshore = 1 group by NewBillingType	
			select @SenSEOffshorePremiumLND = sum(isnull(Hours,0)), @SenSEOnPremiumLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Sen SE LND' and Offshore = 1 group by NewBillingType	

			If @SenSEOffCommonBillingType in ('Sen SE', 'Common Sen SE')						
				set @SenSEOffCommonTotal = @SenSEOffCommonTotal + @SenSEOffshoreCommon
			If @SenSEOffCommonLNDBillingType = 'Common Sen SE LND'						
				set @SenSEOffCommonLNDTotal = @SenSEOffCommonLNDTotal + @SenSEOffshoreCommonLND
			If @SenSEOffCommonRDCBillingType = 'Common Sen SE RDC'						
				set @SenSEOffCommonRDCTotal = @SenSEOffCommonRDCTotal + @SenSEOffshoreCommonRDC
			If @SenSEOffCommonTSTBillingType = 'Common Sen SE TST'
				set @SenSEOffCommonTSTTotal = @SenSEOffCommonTSTTotal + @SenSEOffshoreCommonTST
			If @SenSEOffCommonTSTLNDBillingType = 'Common Sen SE TST LND'
				set @SenSEOffCommonTSTLNDTotal = @SenSEOffCommonTSTLNDTotal + @SenSEOffshoreCommonTSTLND
			If @SenSEOffCommonTSTOFFBillingType = 'Common Sen SE TST OFF'
				set @SenSEOffCommonTSTOFFTotal = @SenSEOnCommonTSTOFFTotal + @SenSEOffshoreCommonTSTOFF
			If @SenSEOffCommonTSTRDCBillingType = 'Common Sen SE TST RDC'
				set @SenSEOffCommonTSTRDCTotal = @SenSEOnCommonTSTRDCTotal + @SenSEOffshoreCommonTSTRDC
			If @SenSEOffLegacyBillingType = 'Legacy Sen SE'
				set @SenSEOffLegacyTotal = @SenSEOffLegacyTotal + @SenSEOffshoreLegacy
			If @SenSEOffLegacyLNDBillingType = 'Legacy Sen SE LND'
				set @SenSEOffLegacyLNDTotal = @SenSEOffLegacyLNDTotal + @SenSEOffshoreLegacyLND
			If @SenSEOffNicheBillingType = 'Niche Sen SE'
				set @SenSEOffNicheTotal = @SenSEOffNicheTotal + @SenSEOffshoreNiche
			If @SenSEOffNicheLNDBillingType = 'Niche Sen SE LND'
				set @SenSEOffNicheLNDTotal = @SenSEOffNicheLNDTotal + @SenSEOffshoreNicheLND
			If @SenSEOnPremiumBillingType = 'Premium Sen SE'
				set @SenSEOffPremiumTotal = @SenSEOffPremiumTotal + @SenSEOffshorePremium
			If @SenSEOnPremiumLNDBillingType = 'Premium Sen SE LND'
				set @SenSEOffPremiumLNDTotal = @SenSEOffPremiumLNDTotal + @SenSEOffshorePremiumLND

			--print 'SenSEOnCommon='			print @SenSEOnshoreCommon		print 'SenSEOffCommon='			print @SenSEOffshoreCommon		
			--print 'SenSEOnLegacy='			print @SenSEOnshoreLegacy		print 'SenSEOffLegacy='			print @SenSEOffshoreLegacy		
			--print 'SenSEOnshoreNiche='		print @SenSEOnshoreNiche		print 'SenSEOffshoreNiche='		print @SenSEOffshoreNiche
			--print 'SenSEOnshorePremium='	print @SenSEOnshorePremium		Print 'SenSEOffshorePremium='	print @SenSEOffshorePremium		
			--print 'SenSEOnCommonTotal='		print @SenSEOnCommonTotal	print 'SenSEOffCommonTotal='	print @SenSEOffCommonTotal	
			--print 'SenSEOnlegacyTotal='		print @SenSEOnLegacyTotal	print 'SenSEOfflegacyTotal='	print @SenSEOffLegacyTotal
			--print 'SenSEOnPremiumTotal='		print @SenSEOnPremiumTotal	print 'SenSEOffPremiumTotal='	print @SenSEOffPremiumTotal										
			--print 'SenSEOnCommonBillingType='	print @SenSEOnCommonBillingType		print 'SenSEOffCommonBillingType='	print @SenSEOffCommonBillingType
			--print 'SenSEOnLegacyBillingType='	print @SenSEOnLegacyBillingType		print 'SenSEOffLegacyBillingType='	print @SenSEOffLegacyBillingType
			--print 'SenSEOnNicheBillingType='	print @SenSEOnNicheBillingType		print 'SenSEOffNicheBillingType='	print @SenSEOffNicheBillingType
			--print 'SenSEOnPremiumBillingType='	print @SenSEOnPremiumBillingType	print 'SenSEOffPremiumBillingType='	print @SenSEOffPremiumBillingType
						
			-----------------------ConsArch-------------
			select @ConsArchOnshoreCommon = sum(isnull(Hours,0)), @ConsArchOnCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType in ('Cons Arch', 'Common Cons Arch') and Onshore = 1 group by NewBillingType		
			select @ConsArchOnshoreCommonLND = sum(isnull(Hours,0)), @ConsArchOnCommonLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch LND' and Onshore = 1 group by NewBillingType		
			select @ConsArchOnshoreCommonRDC = sum(isnull(Hours,0)), @ConsArchOnCommonRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch RDC' and Onshore = 1 group by NewBillingType					
			select @ConsArchOnshoreCommonTST = sum(isnull(Hours,0)), @ConsArchOnCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch TST' and Onshore = 1 group by NewBillingType		
			select @ConsArchOnshoreCommonTSTLND = sum(isnull(Hours,0)), @ConsArchOnCommonTSTLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch TST LND' and Onshore = 1 group by NewBillingType		
			select @ConsArchOnshoreCommonTSTOFF = sum(isnull(Hours,0)), @ConsArchOnCommonTSTOFFBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch TST OFF' and Onshore = 1 group by NewBillingType		
			select @ConsArchOnshoreCommonTSTRDC = sum(isnull(Hours,0)), @ConsArchOnCommonTSTRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch TST RDC' and Onshore = 1 group by NewBillingType									
			select @ConsArchOnshoreLegacy = sum(isnull(Hours,0)), @ConsArchOnLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Cons Arch' and Onshore = 1 group by NewBillingType	
			select @ConsArchOnshoreLegacyLND = sum(isnull(Hours,0)), @ConsArchOnLegacyLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Cons Arch LND' and Onshore = 1 group by NewBillingType	
			select @ConsArchOnshoreNiche = sum(isnull(Hours,0)), @ConsArchOnNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Cons Arch' and Onshore = 1 group by NewBillingType			
			select @ConsArchOnshoreNicheLND = sum(isnull(Hours,0)), @ConsArchOnNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Cons Arch LND' and Onshore = 1 group by NewBillingType			
			select @ConsArchOnshorePremium = sum(isnull(Hours,0)), @ConsArchOnPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Cons Arch' and Onshore = 1 group by NewBillingType
			select @ConsArchOnshorePremiumLND = sum(isnull(Hours,0)), @ConsArchOnPremiumLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Cons Arch LND' and Onshore = 1 group by NewBillingType

			If @ConsArchOnCommonBillingType in ('ConsArch', 'Common Cons Arch')
				set @ConsArchSEOnCommonTotal = @ConsArchSEOnCommonTotal + @ConsArchOnshoreCommon
			If @ConsArchOnCommonLNDBillingType = 'Common Cons Arch LND'
				set @ConsArchSEOnCommonLNDTotal = @ConsArchSEOnCommonLNDTotal + @ConsArchOnshoreCommonLND
			If @ConsArchOnCommonRDCBillingType = 'Common Cons Arch RDC'
				set @ConsArchSEOnCommonRDCTotal = @ConsArchSEOnCommonRDCTotal + @ConsArchOnshoreCommonRDC
			If @ConsArchOnCommonTSTBillingType = 'Common Cons Arch TST'
				set @ConsArchSEOnCommonTSTTotal = @ConsArchSEOnCommonTSTTotal + @ConsArchOnshoreCommonTST
			If @ConsArchOnCommonTSTLNDBillingType = 'Common Cons Arch TST LND'
				set @ConsArchSEOnCommonTSTLNDTotal = @ConsArchSEOnCommonTSTLNDTotal + @ConsArchOnshoreCommonTSTLND
			If @ConsArchOnCommonTSTOFFBillingType = 'Common Cons Arch TST OFF'
				set @ConsArchSEOnCommonTSTOFFTotal = @ConsArchSEOnCommonTSTOFFTotal + @ConsArchOnshoreCommonTSTOFF
			If @ConsArchOnCommonTSTRDCBillingType = 'Common Cons Arch TST RDC'
				set @ConsArchSEOnCommonTSTRDCTotal = @ConsArchSEOnCommonTSTRDCTotal + @ConsArchOnshoreCommonTSTRDC
			If @ConsArchOnLegacyBillingType = 'Legacy Cons Arch'
				set @ConsArchSEOnLegacyTotal = @ConsArchSEOnLegacyTotal + @ConsArchOnshoreLegacy
			If @ConsArchOnLegacyLNDBillingType = 'Legacy Cons Arch LND'
				set @ConsArchSEOnLegacyLNDTotal = @ConsArchSEOnLegacyLNDTotal + @ConsArchOnshoreLegacyLND
			If @ConsArchOnNicheBillingType = 'Niche Cons Arch'
				set @ConsArchSEOnNicheTotal = @ConsArchSEOnNicheTotal + @ConsArchOnshoreNiche
			If @ConsArchOnNicheBillingType = 'Niche Cons Arch LND'
				set @ConsArchSEOnNicheLNDTotal = @ConsArchSEOnNicheLNDTotal + @ConsArchOnshoreNicheLND
			If @ConsArchOnPremiumBillingType = 'Premium Cons Arch'
				set @ConsArchSEOnPremiumTotal = @ConsArchSEOnPremiumTotal + @ConsArchOnshorePremium						
			If @ConsArchOnPremiumLNDBillingType = 'Premium Cons Arch LND'
				set @ConsArchSEOnPremiumLNDTotal = @ConsArchSEOnPremiumLNDTotal + @ConsArchOnshorePremiumLND		

			select @ConsArchOffshoreCommon = sum(isnull(Hours,0)), @ConsArchOffCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType in ('Cons Arch', 'Common Cons Arch') and Offshore = 1 group by NewBillingType	
			select @ConsArchOffshoreCommonLND = sum(isnull(Hours,0)), @ConsArchOffCommonLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch LND' and Offshore = 1 group by NewBillingType	
			select @ConsArchOffshoreCommonRDC = sum(isnull(Hours,0)), @ConsArchOffCommonRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch RDC' and Offshore = 1 group by NewBillingType				
			select @ConsArchOffshoreCommonTST = sum(isnull(Hours,0)), @ConsArchOffCommonTSTBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch TST' and Offshore = 1 group by NewBillingType		
			select @ConsArchOffshoreCommonTSTLND = sum(isnull(Hours,0)), @ConsArchOffCommonTSTLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch TST LND' and Offshore = 1 group by NewBillingType		
			select @ConsArchOffshoreCommonTSTOFF = sum(isnull(Hours,0)), @ConsArchOffCommonTSTOFFBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch TST OFF' and Offshore = 1 group by NewBillingType		
			select @ConsArchOffshoreCommonTSTRDC = sum(isnull(Hours,0)), @ConsArchOffCommonTSTRDCBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Cons Arch TST RDC' and Offshore = 1 group by NewBillingType	
			select @ConsArchOffshoreLegacy = sum(isnull(Hours,0)), @ConsArchOffLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Cons Arch' and Offshore = 1 group by NewBillingType
			select @ConsArchOffshoreLegacyLND = sum(isnull(Hours,0)), @ConsArchOffLegacyLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Cons Arch LND' and Offshore = 1 group by NewBillingType
			select @ConsArchOffshoreNiche = sum(isnull(Hours,0)), @ConsArchOffNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Cons Arch' and Offshore = 1 group by NewBillingType			
			select @ConsArchOffshoreNicheLND = sum(isnull(Hours,0)), @ConsArchOffNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Cons Arch LND' and Offshore = 1 group by NewBillingType					
			select @ConsArchOffshorePremium = sum(isnull(Hours,0)), @ConsArchOnPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Cons Arch' and Offshore = 1 group by NewBillingType	
			select @ConsArchOffshorePremiumLND = sum(isnull(Hours,0)), @ConsArchOnPremiumLNDBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Cons Arch LND' and Offshore = 1 group by NewBillingType	

			If @ConsArchOffCommonBillingType in ('Cons Arch', 'Common Cons Arch')
				set @ConsArchSEOffCommonTotal = @ConsArchSEOffCommonTotal + @ConsArchOffshoreCommon	
			If @ConsArchOffCommonLNDBillingType = 'Common Cons Arch LND'
				set @ConsArchSEOffCommonLNDTotal = @ConsArchSEOffCommonLNDTotal + @ConsArchOffshoreCommonLND
			If @ConsArchOffCommonRDCBillingType = 'Common Cons Arch RDC'
				set @ConsArchSEOffCommonRDCTotal = @ConsArchSEOffCommonRDCTotal + @ConsArchOffshoreCommonRDC	
			If @ConsArchOffCommonTSTBillingType = 'Common Cons Arch TST'
				set @ConsArchSEOffCommonTSTTotal = @ConsArchSEOffCommonTSTTotal + @ConsArchOffshoreCommonTST
			If @ConsArchOffCommonTSTLNDBillingType = 'Common Cons Arch TST LND'
				set @ConsArchSEOffCommonTSTLNDTotal = @ConsArchSEOffCommonTSTLNDTotal + @ConsArchOffshoreCommonTSTLND
			If @ConsArchOffCommonTSTOFFBillingType = 'Common Cons Arch TST OFF'
				set @ConsArchSEOffCommonTSTOFFTotal = @ConsArchSEOffCommonTSTOFFTotal + @ConsArchOffshoreCommonTSTOFF
			If @ConsArchOffCommonTSTRDCBillingType = 'Common Cons Arch TST RDC'
				set @ConsArchSEOffCommonTSTRDCTotal = @ConsArchSEOffCommonTSTRDCTotal + @ConsArchOffshoreCommonTSTRDC
			If @ConsArchOffLegacyBillingType = 'Legacy Cons Arch'
				set @ConsArchSEOffLegacyTotal = @ConsArchSEOffLegacyTotal + @ConsArchOffshoreLegacy
			If @ConsArchOffLegacyLNDBillingType = 'Legacy Cons Arch LND'
				set @ConsArchSEOffLegacyLNDTotal = @ConsArchSEOffLegacyLNDTotal + @ConsArchOffshoreLegacyLND
			If @ConsArchOffNicheBillingType = 'Niche Cons Arch'
				set @ConsArchSEOffNicheTotal = @ConsArchSEOffNicheTotal + @ConsArchOffshoreNiche
			If @ConsArchOffNicheBillingType = 'Niche Cons Arch LND'
				set @ConsArchSEOffNicheLNDTotal = @ConsArchSEOffNicheLNDTotal + @ConsArchOffshoreNicheLND
			If @ConsArchOnPremiumBillingType = 'Premium Cons Arch'
				set @ConsArchSEOffPremiumTotal = @ConsArchSEOffPremiumTotal + @ConsArchOffshorePremium
			If @ConsArchOnPremiumLNDBillingType = 'Premium Cons Arch LND'
				set @ConsArchSEOffPremiumLNDTotal = @ConsArchSEOffPremiumLNDTotal + @ConsArchOffshorePremiumLND
			
			--print 'ConsArchOnshoreCommon='		print @ConsArchOnshoreCommon		print 'ConsArchOffshoreCommon='		print @ConsArchOffshoreCommon	
			--print 'ConsArchOnshoreLegacy='		print @ConsArchOnshoreLegacy		print 'ConsArchOffshoreLegacy='		print @ConsArchOffshoreLegacy
			--print 'ConsArchOnshoreNiche='		print @ConsArchOnshoreNiche			print 'ConsArchOffshoreNiche='	print @ConsArchOffshoreNiche	
			--print 'ConsArchOnshorePremium='		print @ConsArchOnshorePremium		print 'ConsArchOffshorePremium='	print @ConsArchOffshorePremium			
			--print 'ConsArchOnCommonBillingType=' print @ConsArchOnCommonBillingType		print 'ConsArchOffCommonBillingType=' print @ConsArchOffCommonBillingType 
			--print 'ConsArchOnLegacyBillingType='  print @ConsArchOnLegacyBillingType	print 'ConsArchOffLegacyBillingType='  print @ConsArchOffLegacyBillingType
			--print 'ConsArchOnNicheBillingType='  print @ConsArchOnNicheBillingType		print 'ConsArchOffNicheBillingType='  print @ConsArchOffNicheBillingType
			--print 'ConsArchOnPremiumBillingType='	print @ConsArchOnPremiumBillingType print 'ConsArchOffPremiumBillingType='	print @ConsArchOffPremiumBillingType
						
			-----------------------ProjLead-------------			
			select @PLOnshore = sum(isnull(Hours,0)), @PLOnBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Project Lead' and Onshore = 1 group by NewBillingType	
			select @ProjLeadOnshoreCommon = sum(isnull(Hours,0)), @ProjLeadOnCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Project Lead' and Onshore = 1 group by NewBillingType					
			select @ProjLeadOnshoreLegacy = sum(isnull(Hours,0)), @ProjLeadOnLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Project Lead' and Onshore = 1 group by NewBillingType		
			select @ProjLeadOnshoreNiche = sum(isnull(Hours,0)), @ProjLeadOnNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Project Lead' and Onshore = 1 group by NewBillingType				
			select @ProjLeadOnshorePremium = sum(isnull(Hours,0)), @ProjLeadOnPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Project Lead' and Onshore = 1 group by NewBillingType		
														
			If @PLOnBillingType = 'Project Lead'
				set @PLOnTotal = @PLOnTotal + @PLOnshore
			If @ProjLeadOnCommonBillingType = 'Common Project Lead'
				set @ProjLeadOnCommonTotal = @ProjLeadOnLegacyTotal + @ProjLeadOnshoreCommon
			If @ProjLeadOnLegacyBillingType = 'Legacy Project Lead'
				set @ProjLeadOnLegacyTotal = @ProjLeadOnLegacyTotal + @ProjLeadOnshoreLegacy
			If @ProjLeadOnNicheBillingType = 'Niche Project Lead'
				set @ProjLeadOnNicheTotal = @ProjLeadOnNicheTotal + @ProjLeadOnshoreNiche
			If @ProjLeadOnPremiumBillingType = 'Premium Project Lead'
				set @ProjLeadSEOnPremiumTotal = @ProjLeadSEOnPremiumTotal + @ProjLeadOnshorePremium

			select @PLOffshore = sum(isnull(Hours,0)), @PLOffBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Project Lead' and Offshore = 1 group by NewBillingType	
			select @ProjLeadOfshoreCommon = sum(isnull(Hours,0)), @ProjLeadOffCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Project Lead' and Offshore = 1 group by NewBillingType					
			select @ProjLeadOffshoreLegacy = sum(isnull(Hours,0)), @ProjLeadOffLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Project Lead' and Offshore = 1 group by NewBillingType	
			select @ProjLeadOffshoreNiche = sum(isnull(Hours,0)), @ProjLeadOffNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Project Lead' and Offshore = 1 group by NewBillingType		
			select @ProjLeadOffshorePremium = sum(isnull(Hours,0)), @ProjLeadOffPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Project Lead' and Offshore = 1 group by NewBillingType		

			If @PLOffBillingType = 'Project Lead'
				set @PLOffTotal = @PLOffTotal + @PLOffshore			
			If @ProjLeadOffCommonBillingType = 'Common Project Lead'
				set @ProjLeadSEOffCommonTotal = @ProjLeadSEOffCommonTotal + @ProjLeadOfshoreCommon	
			If @ProjLeadOffLegacyBillingType = 'Legacy Project Lead'
				set @ProjLeadSEOffLegacyTotal = @ProjLeadSEOffLegacyTotal + @ProjLeadOffshoreLegacy	
			If @ProjLeadOffNicheBillingType = 'Niche Project Lead'
				set @ProjLeadSEOffNicheTotal = @ProjLeadSEOffNicheTotal + @ProjLeadOffshoreNiche
			If @ProjLeadOffPremiumBillingType = 'Premium Project Lead'
				set @ProjLeadSEOffPremiumTotal = @ProjLeadSEOffPremiumTotal + @ProjLeadOffshorePremium	
		
			--print 'PLOnshore='				print @PLOnshore						print 'PLOffshore='				print @PLOffshore	
			--print 'ProjLeadOnshoreCommon='	print @ProjLeadOnshoreCommon			print 'ProjLeadOffshoreCommon='	print @ProjLeadOfshoreCommon	
			--print 'ProjLeadOnshoreLegacy='	print @ProjLeadOnshoreLegacy			print 'ProjLeadOffshoreLegacy='	print @ProjLeadOffshoreLegacy
			--print 'ProjLeadOnshorePremium='	print @ProjLeadOnshorePremium			print 'ProjLeadOffshorePremium='print @ProjLeadOffshorePremium			
			--print 'ProjLeadOnTotal='			print @PLOnTotal					print 'ProjLeadOffTotal='			print @PLOffTotal	
			--print 'ProjLeadOnshoreCommon='	print @ProjLeadOnCommonTotal		print 'ProjLeadOffshoreCommon='		print @ProjLeadSEOffCommonTotal
			--print 'ProjLeadSEOnLegacyTotal='	print @ProjLeadOnLegacyTotal		print 'ProjLeadSEOffLegacyTotal='	print @ProjLeadSEOffLegacyTotal
			--print 'ProjLeadSEOnPremiumTotal='	print @ProjLeadSEOnPremiumTotal		print 'ProjLeadSEOffPremiumTotal='	print @ProjLeadOffshorePremium
			--print 'ProjLeadOnCommonBillingType=' print @ProjLeadOnCommonBillingType		print 'ProjLeadOffCommonBillingType=' print @ProjLeadOffCommonBillingType
			--print 'ProjLeadOnLegacyBillingType=' print @ProjLeadOnLegacyBillingType		print 'ProjLeadOffLegacyBillingType=' print @ProjLeadOffLegacyBillingType
			--print 'ProjLeadOnPremiumBillingType=' print @ProjLeadOnPremiumBillingType	print 'ProjLeadOffPremiumBillingType=' print @ProjLeadOffPremiumBillingType
						
			-----------------------ProjectMgr-------------
			select @PMOnshore= sum(isnull(Hours,0)), @PMOnBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Project Mgr' and Onshore = 1 group by NewBillingType	
			select @ProjMgrOnshoreCommon = sum(isnull(Hours,0)), @ProjMgrOnCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Project Mgr' and Onshore = 1 group by NewBillingType					
			select @ProjMgrOnshoreLegacy = sum(isnull(Hours,0)), @ProjMgrOnLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Project Mgr' and Onshore = 1 group by NewBillingType	
			select @ProjMgrOnshoreNiche = sum(isnull(Hours,0)), @ProjMgrOnNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Project Mgr' and Onshore = 1 group by NewBillingType			
			select @ProjMgrOnshorePremium = sum(isnull(Hours,0)), @ProjMgrOnPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Project Mgr' and Onshore = 1 group by NewBillingType	

			If @PMOnBillingType = 'Project Mgr'
				set @PMOnTotal = @PMOnTotal + @PMOnshore
			If @ProjMgrOnCommonBillingType = 'Common Project Mgr'
				set @ProjMgrSEOnCommonTotal = @ProjMgrSEOnCommonTotal + @ProjMgrOnshoreCommon
			If @ProjMgrOnLegacyBillingType = 'Legacy Project Mgr'
				set @ProjMgrSEOnLegacyTotal = @ProjMgrSEOnLegacyTotal + @ProjMgrOnshoreLegacy
			If @ProjMgrOnNicheBillingType = 'Niche Project Mgr'
				set @ProjMgrSEOnNicheTotal = @ProjMgrSEOnNicheTotal + @ProjMgrOnshoreNiche
			If @ProjMgrOnPremiumBillingType = 'Premium Project Mgr'
				set @ProjMgrSEOnPremiumTotal = @ProjMgrSEOnPremiumTotal + @ProjMgrOnshorePremium

			select @PMOffshore = sum(isnull(Hours,0)), @PMOffBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Project Mgr' and Offshore = 1 group by NewBillingType	
			select @ProjMgrOffshoreCommon = sum(isnull(Hours,0)), @ProjMgrOffCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Project Mgr' and Offshore = 1 group by NewBillingType					
			select @ProjMgrOffshoreLegacy = sum(isnull(Hours,0)), @ProjMgrOffLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Project Mgr' and Offshore = 1 group by NewBillingType	
			select @ProjMgrOffshoreNiche = sum(isnull(Hours,0)), @ProjMgrOffNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Project Mgr' and Offshore = 1 group by NewBillingType					
			select @ProjMgrOffshorePremium = sum(isnull(Hours,0)), @ProjMgrOffPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Project Mgr' and Offshore = 1 group by NewBillingType			
						
			If @PMOffBillingType = 'Project Mgr'
				set @PMOffTotal = @PMOffTotal + @PMOffshore		
			If @ProjMgrOffCommonBillingType = 'Common Project Mgr'
				set @ProjMgrSEOffCommonTotal = @ProjMgrSEOffCommonTotal + @ProjMgrOffshoreCommon		
			If @ProjMgrOffLegacyBillingType = 'Legacy Project Mgr'
				set @ProjMgrSEOffLegacyTotal = @ProjMgrSEOffLegacyTotal + @ProjMgrOffshoreLegacy
			If @ProjMgrOffNicheBillingType = 'Niche Project Mgr'
				set @ProjMgrSEOffNicheTotal = @ProjMgrSEOffNicheTotal + @ProjMgrOffshoreNiche							
			If @ProjMgrOffPremiumBillingType = 'Premium Project Mgr'
				set @ProjMgrSEOffPremiumTotal = @ProjMgrSEOffPremiumTotal + @ProjMgrOffshorePremium	
			
			--print 'PMOffshore=' print @PMOffshore		print 'ProjMgrOffshoreCommon=' print @ProjMgrOffshoreCommon		print 'ProjMgrOffshoreLegacy=' print @ProjMgrOffshoreLegacy		print 'ProjMgrOffNicheBillingType=' print @ProjMgrOffNicheBillingType	print 'ProjMgrOffPremiumBillingType=' print @ProjMgrOffPremiumBillingType
			--print 'ProjMgrOnCommonBillingType='	 print @ProjMgrOnCommonBillingType	print 'ProjMgrOffCommonBillingType=' print @ProjMgrOffCommonBillingType
			--print 'ProjMgrOnLegacyBillingType='	 print @ProjMgrOnLegacyBillingType	print 'ProjMgrOffLegacyBillingType=' print @ProjMgrOffLegacyBillingType
			--print 'ProjMgrOnPremiumBillingType=' print @ProjMgrOnPremiumBillingType	print 'ProjMgrOffPremiumBillingType=' print @ProjMgrOffPremiumBillingType
			
			-----------------------ProgMgr-------------
			select @PGMOnshore = sum(isnull(Hours,0)), @PGMOnBillingType= NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Program Mgr' and Onshore = 1 group by NewBillingType	
			select @ProgMgrOnshoreCommon = sum(isnull(Hours,0)), @ProgMgrOnCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Program Mgr' and Onshore = 1 group by NewBillingType					
			select @ProgMgrOnshoreLegacy = sum(isnull(Hours,0)), @ProgMgrOnLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Program Mgr' and Onshore = 1 group by NewBillingType	
			select @ProgMgrOnshoreNiche = sum(isnull(Hours,0)), @ProgMgrOnNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Program Mgr' and Onshore = 1 group by NewBillingType					
			select @ProgMgrOnshorePremium = sum(isnull(Hours,0)), @ProgMgrOnPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Program Mgr' and Onshore = 1 group by NewBillingType	

			If @PGMOnBillingType= 'Program Mgr'
				set @PGMOnTotal = @PGMOnTotal + @PGMOnshore
			If @ProgMgrOnCommonBillingType = 'Common Program Mgr'
				set @ProgMgrSEOnCommonTotal = @ProgMgrSEOnCommonTotal + @ProgMgrOnshoreCommon
			If @ProgMgrOnLegacyBillingType = 'Legacy Program Mgr'
				set @ProgMgrSEOnLegacyTotal = @ProgMgrSEOnLegacyTotal + @ProgMgrOnshoreLegacy
			If @ProgMgrOnNicheBillingType = 'Niche Program Mgr'
				set @ProgMgrSEOnNicheTotal = @ProgMgrSEOnNicheTotal + @ProgMgrOnshoreNiche
			If @ProgMgrOnPremiumBillingType = 'Premium Program Mgr'
				set @ProgMgrSEOnPremiumTotal = @ProgMgrSEOnPremiumTotal + @ProgMgrOnshorePremium

			select @PGMOffshore= sum(isnull(Hours,0)), @PGMOffBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Program Mgr' and Offshore = 1 group by NewBillingType	
			select @ProgMgrOffshoreCommon = sum(isnull(Hours,0)), @ProgMgrOffCommonBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Common Program Mgr' and Offshore = 1 group by NewBillingType					
			select @ProgMgrOffshoreLegacy = sum(isnull(Hours,0)), @ProgMgrOffLegacyBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Legacy Program Mgr' and Offshore = 1 group by NewBillingType	
			select @ProgMgrOffshoreNiche = sum(isnull(Hours,0)), @ProgMgrOffNicheBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Niche Program Mgr' and Offshore = 1 group by NewBillingType			
			select @ProgMgrOffshorePremium = sum(isnull(Hours,0)), @ProgMgrOffPremiumBillingType = NewBillingType from #TEMP_IN where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID 
				and NewBillingType = 'Premium Program Mgr' and Offshore = 1 group by NewBillingType	

			If @PGMOffBillingType = 'Program Mgr'
				set @PGMOffTotal = @PGMOffTotal + @PGMOffshore
			If @ProgMgrOffCommonBillingType = 'Common Program Mgr'
				set @ProgMgrSEOffCommonTotal = @ProgMgrSEOffCommonTotal + @ProgMgrOffshoreCommon
			If @ProgMgrOffLegacyBillingType = 'Legacy Program Mgr'
				set @ProgMgrSEOffLegacyTotal = @ProgMgrSEOffLegacyTotal + @ProgMgrOffshoreLegacy
			If @ProgMgrOffNicheBillingType = 'Niche Program Mgr'
				set @ProgMgrSEOffNicheTotal = @ProgMgrSEOffNicheTotal + @ProgMgrOffshoreNiche
			If @ProgMgrOffPremiumBillingType = 'Premium Program Mgr'
				set @ProgMgrSEOffPremiumTotal = @ProgMgrSEOffPremiumTotal + @ProgMgrOffshorePremium			

			--print 'PGMOnshore='				print @PGMOnshore						print 'PGMOffshore='			print @PGMOffshore				
			--print 'ProgMgrOnshoreCommon='	print @ProgMgrOnshoreCommon				print 'ProgMgrOffshoreCommon='	print @ProgMgrOffshoreCommon	
			--print 'ProgMgrOnshoreLegacy='	print @ProgMgrOnshoreLegacy				print 'ProgMgrOffshoreLegacy='	print @ProgMgrOffshoreLegacy	
			--print 'ProgMgrOnshorePremium='	print @ProgMgrOnshorePremium			print 'ProgMgrOffshorePremium='	print @ProgMgrOffshorePremium	
			--print 'PGMOnTotal='					print @PGMOnTotal					print 'PGMOffTotal='				print @PGMOffTotal	
			--print 'ProgMgrSEOnCommonTotal='		print @ProgMgrSEOnCommonTotal		print 'ProgMgrSEOffCommonTotal='	print @ProgMgrSEOffCommonTotal
			--print 'ProgMgrSEOnLegacyTotal='		print @ProgMgrSEOnLegacyTotal		print 'ProgMgrSEOffLegacyTotal='	print @ProgMgrSEOffLegacyTotal
			--print 'ProgMgrSEOnPremiumTotal='		print @ProgMgrSEOnPremiumTotal		print 'ProgMgrSEOffPremiumTotal='	print @ProgMgrSEOffPremiumTotal			
			--print 'ProgMgrOnCommonBillingType='		print @ProgMgrOnCommonBillingType	print 'ProgMgrOffCommonBillingType='	print @ProgMgrOffCommonBillingType
			--print 'ProgMgrOnLegacyBillingType='		print @ProgMgrOnLegacyBillingType	print 'ProgMgrOffLegacyBillingType='	print @ProgMgrOffLegacyBillingType
			--print 'ProgMgrOnPremiumBillingType='	print @ProgMgrOnPremiumBillingType	print 'ProgMgrOffPremiumBillingType='	print @ProgMgrOffPremiumBillingType
			--print 'PGMOnBillingType='				print @PGMOnBillingType				print 'PGMOffBillingType='				print @PGMOffBillingType

			--Populate the ServiceCategory---------				
			If @JrSEOnCommonBillingType = 'Common Jr SE' or @JrSEOffCommonBillingType = 'Common Jr SE' or @MidSEOnCommonBillingType = 'Common Mid SE' or @MidSEOffCommonBillingType = 'Common Mid SE' or @AdvSEOnCommonBillingType = 'Common Adv SE' or @AdvSEOffCommonBillingType = 'Common Adv SE' or @SenSEOnCommonBillingType = 'Common Sen SE' or @SenSEOffCommonBillingType = 'Common Sen SE' or @ConsArchOnCommonBillingType = 'Common Cons Arch' or @ConsArchOffCommonBillingType = 'Common Cons Arch' or @ProjLeadOnCommonBillingType = 'Common Project Lead' or @ProjLeadOffCommonBillingType = 'Common Project Lead' or @ProjMgrOnCommonBillingType = 'Common Project Mgr' or @ProjMgrOffCommonBillingType = 'Common Project Mgr' or @ProgMgrOnCommonBillingType = 'Common Program Mgr' or @ProgMgrOffCommonBillingType = 'Common Program Mgr'
				set @ServiceCategory = 'Common' 			
			If @JrSEOnCommonLNDBillingType = 'Common Jr SE LND' or @JrSEOffCommonLNDBillingType = 'Common Jr SE LND' or @MidSEOnCommonLNDBillingType = 'Common Mid SE LND' or @MidSEOffCommonLNDBillingType = 'Common Mid SE LND' or @AdvSEOnCommonLNDBillingType = 'Common Adv SE LND' or @AdvSEOffCommonLNDBillingType = 'Common Adv SE LND' or @SenSEOnCommonLNDBillingType = 'Common Sen SE LND' or @SenSEOffCommonLNDBillingType = 'Common Sen SE LND' or @ConsArchOnCommonLNDBillingType = 'Common Cons Arch LND' or @ConsArchOffCommonLNDBillingType = 'Common Cons Arch LND'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'CommonLND'					
				Else
					set @ServiceCategory = 'CommonLND'
			If @JrSEOnCommonRDCBillingType = 'Common Jr SE RDC' or @JrSEOffCommonRDCBillingType = 'Common Jr SE RDC' or @MidSEOnCommonRDCBillingType = 'Common Mid SE RDC' or @MidSEOffCommonRDCBillingType = 'Common Mid SE RDC' or @AdvSEOnCommonRDCBillingType = 'Common Adv SE RDC' or @AdvSEOffCommonRDCBillingType = 'Common Adv SE RDC' or @SenSEOnCommonRDCBillingType = 'Common Sen SE RDC' or @SenSEOffCommonRDCBillingType = 'Common Sen SE RDC' or @ConsArchOnCommonRDCBillingType = 'Common Cons Arch RDC' or @ConsArchOffCommonRDCBillingType = 'Common Cons Arch RDC'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'CommonRDC'					
				Else
					set @ServiceCategory = 'CommonRDC'

			If @JrSEOnCommonTSTBillingType = 'Common Jr SE TST' or @JrSEOffCommonTSTBillingType = 'Common Jr SE TST' or @MidSEOnCommonTSTBillingType = 'Common Mid SE TST' or @MidSEOffCommonTSTBillingType = 'Common Mid SE TST' or @AdvSEOnCommonTSTBillingType = 'Common Adv SE TST' or @AdvSEOffCommonTSTBillingType = 'Common Adv SE TST' or @SenSEOnCommonTSTBillingType = 'Common Sen SE TST' or @SenSEOffCommonTSTBillingType = 'Common Sen SE TST' or @ConsArchOnCommonTSTBillingType = 'Common Cons Arch TST' or @ConsArchOffCommonTSTBillingType = 'Common Cons Arch TST'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'CommonTST'					
				Else
					set @ServiceCategory = 'CommonTST'
			If @JrSEOnCommonTSTLNDBillingType = 'Common Jr SE TST LND' or @JrSEOffCommonTSTLNDBillingType = 'Common Jr SE TST LND' or @MidSEOnCommonTSTLNDBillingType = 'Common Mid SE TST LND' or @MidSEOffCommonTSTLNDBillingType = 'Common Mid SE TST LND' or @AdvSEOnCommonTSTLNDBillingType = 'Common Adv SE TST LND' or @AdvSEOffCommonTSTLNDBillingType = 'Common Adv SE TS LND' or @SenSEOnCommonTSTLNDBillingType = 'Common Sen SE TST LND' or @SenSEOffCommonTSTLNDBillingType = 'Common Sen SE TST LND' or @ConsArchOnCommonTSTLNDBillingType = 'Common Cons Arch TST LND' or @ConsArchOffCommonTSTLNDBillingType = 'Common Cons Arch TST LND'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'CommonTSTLND'					
				Else
					set @ServiceCategory = 'CommonTSTLND'
			If @JrSEOnCommonTSTOFFBillingType = 'Common Jr SE TST OFF' or @JrSEOffCommonTSTOFFBillingType = 'Common Jr SE TST OFF' or @MidSEOnCommonTSTOFFBillingType = 'Common Mid SE TST OFF' or @MidSEOffCommonTSTOFFBillingType = 'Common Mid SE TST OFF' or @AdvSEOnCommonTSTOFFBillingType = 'Common Adv SE TST OFF' or @AdvSEOffCommonTSTOFFBillingType = 'Common Adv SE TST OFF' or @SenSEOnCommonTSTOFFBillingType = 'Common Sen SE TST OFF' or @SenSEOffCommonTSTOFFBillingType = 'Common Sen SE TST OFF' or @ConsArchOnCommonTSTOFFBillingType = 'Common Cons Arch TST OFF' or @ConsArchOffCommonTSTOFFBillingType = 'Common Cons Arch TST OFF'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'CommonTSTOFF'					
				Else
					set @ServiceCategory = 'CommonTSTOFF'
			If @JrSEOnCommonTSTRDCBillingType = 'Common Jr SE TST RDC' or @JrSEOffCommonTSTRDCBillingType = 'Common Jr SE TST RDC' or @MidSEOnCommonTSTRDCBillingType = 'Common Mid SE TST RDC' or @MidSEOffCommonTSTRDCBillingType = 'Common Mid SE TST RDC' or @AdvSEOnCommonTSTRDCBillingType = 'Common Adv SE TST RDC' or @AdvSEOffCommonTSTRDCBillingType = 'Common Adv SE TST RDC' or @SenSEOnCommonTSTRDCBillingType = 'Common Sen SE TST RDC' or @SenSEOffCommonTSTRDCBillingType = 'Common Sen SE TST RDC' or @ConsArchOnCommonTSTRDCBillingType = 'Common Cons Arch TST RDC' or @ConsArchOffCommonTSTRDCBillingType = 'Common Cons Arch TST RDC'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'CommonTSTRDC'					
				Else
					set @ServiceCategory = 'CommonTSTRDC'				
					
			If @JrSEOnLegacyBillingType = 'Legacy Jr SE' or @JrSEOffLegacyBillingType = 'Legacy Jr SE' or @MidSEOnLegacyBillingType = 'Legacy Mid SE' or @MidSEOffLegacyBillingType = 'Legacy Mid SE' or @AdvSEOnLegacyBillingType = 'Legacy Adv SE' or @AdvSEOffLegacyBillingType = 'Legacy Adv SE' or @SenSEOnLegacyBillingType = 'Legacy Sen SE' or @SenSEOffLegacyBillingType = 'Legacy Sen SE' or @ConsArchOnLegacyBillingType = 'Legacy Cons Arch' or @ConsArchOffLegacyBillingType = 'Legacy Cons Arch' or @ProjLeadOnLegacyBillingType = 'Legacy Project Lead' or @ProjLeadOffLegacyBillingType = 'Legacy Project Lead' or @ProjMgrOnLegacyBillingType = 'Legacy Project Mgr' or @ProjMgrOffLegacyBillingType = 'Legacy Project Mgr' or @ProgMgrOnLegacyBillingType = 'Legacy Program Mgr' or @ProgMgrOffLegacyBillingType = 'Legacy Program Mgr'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'Legacy'					
				Else
					set @ServiceCategory = 'Legacy'	
			If @JrSEOnLegacyLNDBillingType = 'Legacy Jr SE LND' or @JrSEOffLegacyLNDBillingType = 'Legacy Jr SE LND' or @MidSEOnLegacyLNDBillingType = 'Legacy Mid SE LND' or @MidSEOffLegacyLNDBillingType = 'Legacy Mid SE LND' or @AdvSEOnLegacyLNDBillingType = 'Legacy Adv SE LND' or @AdvSEOffLegacyLNDBillingType = 'Legacy Adv SE LND' or @SenSEOnLegacyLNDBillingType = 'Legacy Sen SE LND' or @SenSEOffLegacyLNDBillingType = 'Legacy Sen SE LND' or @ConsArchOnLegacyLNDBillingType = 'Legacy Cons Arch LND' or @ConsArchOffLegacyLNDBillingType = 'Legacy Cons Arch LND'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'LegacyLND'					
				Else
					set @ServiceCategory = 'LegacyLND'	

			If @JrSEOnNicheBillingType = 'Niche Jr SE' or @JrSEOffNicheBillingType = 'Niche Jr SE' or @MidSEOnNicheBillingType = 'Niche Mid SE' or @MidSEOffNicheBillingType = 'Niche Mid SE' or @AdvSEOnNicheBillingType = 'Niche Adv SE' or @AdvSEOffNicheBillingType = 'Niche Adv SE' or @SenSEOnNicheBillingType = 'Niche Sen SE' or @SenSEOffNicheBillingType = 'Niche Sen SE' or @ConsArchOnNicheBillingType = 'Niche Cons Arch' or @ConsArchOffNicheBillingType = 'Niche Cons Arch' or @ProjLeadOnNicheBillingType = 'Niche Project Lead' or @ProjLeadOffNicheBillingType = 'Niche Project Lead' or @ProjMgrOnNicheBillingType = 'Niche Project Mgr' or @ProjMgrOffNicheBillingType = 'Niche Project Mgr' or @ProgMgrOnNicheBillingType = 'Niche Program Mgr' or @ProgMgrOffNicheBillingType = 'Niche Program Mgr'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'Niche'				
				Else
					set @ServiceCategory = 'Niche'				
			If @AdvSEOnNicheLNDBillingType = 'Niche Adv SE LND' or @AdvSEOffNicheLNDBillingType = 'Niche Adv SE LND' or @SenSEOnNicheLNDBillingType = 'Niche Sen SE LND' or @SenSEOffNicheLNDBillingType = 'Niche Sen SE LND' or @ConsArchOnNicheLNDBillingType = 'Niche Cons Arch LND' or @ConsArchOffNicheLNDBillingType = 'Niche Cons Arch LND'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'NicheLND'				
				Else
					set @ServiceCategory = 'NicheLND'				
														
			If @JrSEOnPremiumBillingType = 'Premium Jr SE' or @JrSEOffPremiumBillingType = 'Premium Jr SE' or @MidSEOnPremiumBillingType = 'Premium Mid SE' or @MidSEOffPremiumBillingType = 'Premium Mid SE' or @AdvSEOnPremiumBillingType = 'Premium Adv SE' or @AdvSEOffPremiumBillingType = 'Premium Adv SE' or @SenSEOnPremiumBillingType = 'Premium Sen SE' or @SenSEOffPremiumBillingType = 'Premium Sen SE' or @ConsArchOnPremiumBillingType = 'Premium Cons Arch' or @ConsArchOffPremiumBillingType = 'Premium Cons Arch' or @ProjLeadOnPremiumBillingType = 'Premium Project Lead' or @ProjLeadOffPremiumBillingType = 'Premium Project Lead' or @ProjMgrOnPremiumBillingType = 'Premium Project Mgr' or @ProjMgrOffPremiumBillingType = 'Premium Project Mgr' or @ProgMgrOnPremiumBillingType = 'Premium Program Mgr' or @ProgMgrOffPremiumBillingType = 'Premium Program Mgr'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'Premium' 				
				Else
					set @ServiceCategory = 'Premium'	
			If @MidSEOnPremiumBillingType = 'Premium Mid SE LND' or @MidSEOffPremiumBillingType = 'Premium Mid SE LND' or @AdvSEOnPremiumBillingType = 'Premium Adv SE LND' or @AdvSEOffPremiumBillingType = 'Premium Adv SE LND' or @SenSEOnPremiumBillingType = 'Premium Sen SE LND' or @SenSEOffPremiumBillingType = 'Premium Sen SE LND' or @ConsArchOnPremiumBillingType = 'Premium Cons Arch LND' or @ConsArchOffPremiumBillingType = 'Premium Cons Arch LND' 
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'PremiumLND' 				
				Else
					set @ServiceCategory = 'PremiumLND'	

			If @PLOnBillingType = 'Project Lead' or @PLOffBillingType = '%Project Lead%' 						
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'PL'						
				Else
					set @ServiceCategory = 'PL'							
			If @PMOnBillingType = 'Project Mgr' or @PMOffBillingType = 'Project Mgr'
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'PM'					
				Else
					set @ServiceCategory = 'PM'					
			If  @PGMOnBillingType= 'Program Mgr' or @PGMOffBillingType = 'Program Mgr'				
				If @ServiceCategory > '' 
					set @ServiceCategory = @ServiceCategory + '/' + 'PGM'					
				Else
					set @ServiceCategory = 'PGM'								
		print 'ServiceCategory=' print @ServiceCategory
							
			--GET funding category  
			Declare @@out_location varchar (100), @@out_fundingcat varchar (100), @@out_afenumber varchar (20), @@out_programmgr varchar (50), @@Total_FTE float             
			set @@out_location  = NULL
			set @@out_fundingcat = NULL
			set @@out_afenumber = NULL
			set @@out_programmgr = NULL
			set @@Total_FTE = NULL
			exec GET_Location_Combo @CurAFE_DescID, @DateFrom, @DateTo, @@out_location OUTPUT, @@out_fundingcat OUTPUT, @@out_afenumber OUTPUT, @@out_programmgr OUTPUT, @@Total_FTE OUTPUT
 		
  			--Populate field 30.
			update #TEMP_OUT set ITSABillingCat = @ITSABillingCat, fundingcat = @@out_fundingcat, AFENumber = @@out_afenumber, COBusinessLead = @CurBusinessLead, ProgramMgr = @@out_programmgr, ServiceCategory = @ServiceCategory, ApprovedFTEs = isnull(@@Total_FTE,0), 
			JrSEOnshoreHours = isnull(@JrSEOnshoreCommon,0) + isnull(@JrSEOnshoreCommonLND,0) + isnull(@JrSEOnshoreCommonRDC,0) + isnull(@JrSEOnshoreCommonTST,0) + isnull(@JrSEOnshoreCommonTSTLND,0) + isnull(@JrSEOnshoreCommonTSTOFF,0) + isnull(@JrSEOnshoreCommonTSTRDC,0) + isnull(@JrSEOnshoreLegacy,0) + isnull(@JrSEOnshoreLegacyLND,0) + isnull(@JrSEOnshoreNiche,0) + isnull(@JrSEOnshorePremium,0), JrSEOffshoreHours = isnull(@JrSEOffshoreCommon,0) + isnull(@JrSEOffshoreCommonLND,0) + isnull(@JrSEOffshoreCommonRDC,0) + isnull(@JrSEOffshoreCommonTST,0) + isnull(@JrSEOffshoreCommonTSTLND,0) + isnull(@JrSEOffshoreCommonTSTOFF,0) + isnull(@JrSEOffshoreCommonTSTRDC,0) + isnull(@JrSEOffshoreLegacy,0) + isnull(@JrSEOffshoreLegacyLND,0) + isnull(@JrSEOffshoreNiche,0) + isnull(@JrSEOffshorePremium,0), 			
			MidSEOnshoreHours = isnull(@MidSEOnshoreCommon,0) + isnull(@MidSEOnshoreCommonLND,0) + isnull(@MidSEOnshoreCommonRDC,0) + isnull(@MidSEOnshoreCommonTST,0) + isnull(@MidSEOnshoreCommonTSTLND,0) + isnull(@MidSEOnshoreCommonTSTOFF,0) + isnull(@MidSEOnshoreCommonTSTRDC,0) + isnull(@MidSEOnshoreLegacy,0) + isnull(@MidSEOnshoreLegacyLND,0) + isnull(@MidSEOnshoreNiche,0) + isnull(@MidSEOnshorePremium,0) + isnull(@MidSEOnshorePremiumLND,0), MidSEOffshoreHours = isnull(@MidSEOffshoreCommon,0) + isnull(@MidSEOffshoreCommonLND,0) + isnull(@MidSEOffshoreCommonRDC,0) + isnull(@MidSEOffshoreCommonTST,0) + isnull(@MidSEOffshoreCommonTSTLND,0) + isnull(@MidSEOffshoreCommonTSTOFF,0) + isnull(@MidSEOffshoreCommonTSTRDC,0) + isnull(@MidSEOffshoreLegacy,0) + isnull(@MidSEOffshoreLegacyLND,0) + isnull(@MidSEOffshoreNiche,0) + isnull(@MidSEOffshorePremium,0) + isnull(@MidSEOffshorePremiumLND,0),		
			AdvSEOnshoreHours = isnull(@AdvSEOnshoreCommon,0) + isnull(@AdvSEOnshoreCommonLND,0) + isnull(@AdvSEOnshoreCommonRDC,0) + isnull(@AdvSEOnshoreCommonTST,0) + isnull(@AdvSEOnshoreCommonTSTLND,0) + isnull(@AdvSEOnshoreCommonTSTOFF,0) + isnull(@AdvSEOnshoreCommonTSTRDC,0) + isnull(@AdvSEOnshoreLegacy,0) + isnull(@AdvSEOnshoreLegacyLND,0) + isnull(@AdvSEOnshoreNiche,0) + isnull(@AdvSEOnshoreNicheLND,0) + isnull(@AdvSEOnshorePremium,0) + isnull(@AdvSEOnshorePremiumLND,0), AdvSEOffshoreHours = isnull(@AdvSEOffshoreCommon,0) + isnull(@AdvSEOffshoreCommonLND,0) + isnull(@AdvSEOffshoreCommonRDC,0) + isnull(@AdvSEOffshoreCommonTST,0) + isnull(@AdvSEOffshoreCommonTSTLND,0) + isnull(@AdvSEOffshoreCommonTSTOFF,0) + isnull(@AdvSEOffshoreCommonTSTRDC,0) + isnull(@AdvSEOffshoreLegacy,0) + isnull(@AdvSEOffshoreLegacyLND,0) + isnull(@AdvSEOffshoreNiche,0) + isnull(@AdvSEOffshoreNicheLND,0) + isnull(@AdvSEOffshorePremium,0) + isnull(@AdvSEOffshorePremiumLND,0), 			
			SenSEOnshoreHours = isnull(@SenSEOnshoreCommon,0) + isnull(@SenSEOnshoreCommonLND,0) + isnull(@SenSEOnshoreCommonRDC,0) + isnull(@SenSEOnshoreCommonTST,0) + isnull(@SenSEOnshoreCommonTSTLND,0) + isnull(@SenSEOnshoreCommonTSTOFF,0) + isnull(@SenSEOnshoreCommonTSTRDC,0) + isnull(@SenSEOnshoreLegacy,0) + isnull(@SenSEOnshoreLegacyLND,0) + isnull(@SenSEOnshoreNiche,0) + isnull(@SenSEOnshoreNicheLND,0) + isnull(@SenSEOnshorePremium,0) + isnull(@SenSEOnshorePremiumLND,0), SenSEOffshoreHours = isnull(@SenSEOffshoreCommon,0) + isnull(@SenSEOffshoreCommonLND,0) + isnull(@SenSEOffshoreCommonRDC,0) + isnull(@SenSEOffshoreCommonTST,0) + isnull(@SenSEOffshoreCommonTSTLND,0) + isnull(@SenSEOffshoreCommonTSTOFF,0) + isnull(@SenSEOffshoreCommonTSTRDC,0) + isnull(@SenSEOffshoreLegacy,0) + isnull(@SenSEOffshoreLegacyLND,0) + isnull(@SenSEOffshoreNiche,0) + isnull(@SenSEOffshoreNicheLND,0) + isnull(@SenSEOffshorePremium,0) + isnull(@SenSEOffshorePremiumLND,0), 			
			ConsArchOnshoreHours = isnull(@ConsArchOnshoreCommon,0) + isnull(@ConsArchOnshoreCommonLND,0) + isnull(@ConsArchOnshoreCommonRDC,0) + isnull(@ConsArchOnshoreCommonTST,0) + isnull(@ConsArchOnshoreCommonTSTLND,0) + isnull(@ConsArchOnshoreCommonTSTOFF,0) + isnull(@ConsArchOnshoreCommonTSTRDC,0) + isnull(@ConsArchOnshoreLegacy,0) + isnull(@ConsArchOnshoreLegacyLND,0) + isnull(@ConsArchOnshoreNiche,0) + isnull(@ConsArchOnshoreNicheLND,0) + isnull(@ConsArchOnshorePremium,0) + isnull(@ConsArchOnshorePremiumLND,0), ConsArchOffshoreHours = isnull(@ConsArchOffshoreCommon,0) + isnull(@ConsArchOffshoreCommonLND,0) + isnull(@ConsArchOffshoreCommonRDC,0) + isnull(@ConsArchOffshoreCommonTST,0) + isnull(@ConsArchOffshoreCommonTSTLND,0) + isnull(@ConsArchOffshoreCommonTSTOFF,0) + isnull(@ConsArchOffshoreCommonTSTRDC,0) + isnull(@ConsArchOffshoreLegacy,0) + isnull(@ConsArchOffshoreLegacyLND,0) + isnull(@ConsArchOffshoreNiche,0) + isnull(@ConsArchOffshoreNicheLND,0) + isnull(@ConsArchOffshorePremium,0) + isnull(@ConsArchOffshorePremiumLND,0), 
			ProjLeadOnshoreHours = isnull(@PLOnshore,0) + isnull(@ProjLeadOnshoreCommon,0) + isnull(@ProjLeadOnshoreLegacy,0) + isnull(@ProjLeadOnshorePremium,0), ProjLeadOffshoreHours = isnull(@PLOffshore,0) + isnull(@ProjLeadOfshoreCommon,0) + isnull(@ProjLeadOffshoreLegacy,0) + isnull(@ProjLeadOffshorePremium,0), 
			ProjMgrOnshoreHours = isnull(@PMOnshore,0) + isnull(@ProjMgrOnshoreCommon,0) + isnull(@ProjMgrOnshoreLegacy,0) + isnull(@ProjMgrOnshorePremium,0), ProjMgrOffshoreHours = isnull(@PMOffshore,0) + isnull(@ProjMgrOffshoreCommon,0) + isnull(@ProjMgrOffshoreLegacy,0) + isnull(@ProjMgrOffshorePremium,0),
			ProgMgrOnshoreHours = isnull(@PGMOnshore,0) + isnull(@ProgMgrOnshoreCommon,0) + isnull(@ProgMgrOnshoreLegacy,0) + isnull(@ProgMgrOnshorePremium,0), ProgMgrOffshoreHours = isnull(@PGMOffshore,0) + isnull(@ProgMgrOffshoreCommon,0) + isnull(@ProgMgrOffshoreLegacy,0) + isnull(@ProgMgrOffshorePremium,0)
			where AutoKey = @MaxAFEDesc				
			
			-- Populate R10_R20_TotalHours for 20 and 30 fields.
			declare @R10_R20_TotalHours3 decimal(10,3)
			select @R10_R20_TotalHours3 = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) + isnull(ProgMgrOffshoreHours,0)
				from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30	
				--print 'R10_R20_TotalHours3=' print @R10_R20_TotalHours3
			If @R10_R20_TotalHours3 > 0
				update #TEMP_OUT set R10_R20_TotalHours = @R10_R20_TotalHours3 where AutoKey= @MaxProgram and RecNumber = 30 	
				update #TEMP_OUT set R10_R20_TotalHours = @R10_R20_TotalHours3 where AutoKey= @MaxProgram and RecNumber = 20 	

			set @JrSEOnshoreCommon = 0		set @JrSEOffshoreCommon = 0		set @JrSEOnshoreCommonLND = 0		set @JrSEOffshoreCommonLND = 0		set @JrSEOnshoreCommonRDC = 0		set @JrSEOffshoreCommonRDC = 0		set @JrSEOnshoreCommonTST = 0		set @JrSEOffshoreCommonTST = 0		set @JrSEOnshoreCommonTSTLND = 0		set @JrSEOffshoreCommonTSTLND = 0		set @JrSEOnshoreCommonTSTOFF = 0		set @JrSEOffshoreCommonTSTOFF = 0		set @JrSEOnshoreCommonTSTRDC = 0		set @JrSEOffshoreCommonTSTRDC = 0		set @JrSEOnshoreLegacy = 0		set @JrSEOffshoreLegacy = 0		set @JrSEOnshoreLegacyLND = 0		set @JrSEOffshoreLegacyLND = 0		set @JrSEOnshoreNiche = 0			set @JrSEOffshoreNiche = 0		set @JrSEOnshorePremium = 0			set @JrSEOffshorePremium = 0
			set @MidSEOnshoreCommon = 0		set @MidSEOffshoreCommon = 0	set @MidSEOnshoreCommonLND = 0		set @MidSEOffshoreCommonLND = 0		set @MidSEOnshoreCommonRDC = 0		set @MidSEOffshoreCommonRDC = 0		set @MidSEOnshoreCommonTST = 0		set @MidSEOffshoreCommonTST = 0		set @MidSEOnshoreCommonTSTLND = 0		set @MidSEOffshoreCommonTSTLND = 0		set @MidSEOnshoreCommonTSTOFF = 0		set @MidSEOffshoreCommonTSTOFF = 0		set @JrSEOnshoreCommonTSTRDC = 0		set @JrSEOffshoreCommonTSTRDC = 0		set @MidSEOnshoreLegacy = 0		set @MidSEOffshoreLegacy = 0	set @MidSEOnshoreLegacyLND = 0		set @MidSEOffshoreLegacyLND = 0		set @MidSEOnshoreNiche = 0			set @MidSEOffshoreNiche = 0		set @MidSEOnshorePremium = 0		set @MidSEOffshorePremium = 0		set @MidSEOnshorePremiumLND = 0	set @MidSEOffshorePremiumLND = 0	
			set @AdvSEOnshoreCommon = 0		set @AdvSEOffshoreCommon = 0	set @AdvSEOnshoreCommonLND = 0		set @AdvSEOffshoreCommonLND = 0		set @AdvSEOnshoreCommonRDC = 0		set @AdvSEOffshoreCommonRDC = 0		set @AdvSEOnshoreCommonTST = 0		set @AdvSEOffshoreCommonTST = 0		set @AdvSEOnshoreCommonTSTLND = 0		set @AdvSEOffshoreCommonTSTLND = 0		set @AdvSEOnshoreCommonTSTOFF = 0		set @AdvSEOffshoreCommonTSTOFF = 0		set @AdvSEOnshoreCommonTSTRDC = 0		set @AdvSEOffshoreCommonTSTRDC = 0		set @AdvSEOnshoreLegacy= 0		set @AdvSEOffshoreLegacy = 0	set @AdvSEOnshoreLegacyLND= 0		set @AdvSEOffshoreLegacyLND = 0		set @AdvSEOnshoreNiche = 0			set @AdvSEOffshoreNiche = 0		set @AdvSEOnshoreNicheLND = 0		set @AdvSEOffshoreNicheLND = 0		set @AdvSEOnshorePremium = 0	set @AdvSEOffshorePremium = 0		set @AdvSEOnshorePremiumLND = 0		set @AdvSEOffshorePremiumLND = 0
			set @SenSEOnshoreCommon	= 0		set @SenSEOffshoreCommon = 0	set @SenSEOnshoreCommonLND	= 0		set @SenSEOffshoreCommonLND = 0		set @SenSEOnshoreCommonRDC	= 0		set @SenSEOffshoreCommonRDC = 0		set @SenSEOnshoreCommonTST	= 0		set @SenSEOffshoreCommonTST = 0		set @SenSEOnshoreCommonTSTLND = 0		set @SenSEOffshoreCommonTSTLND = 0		set @SenSEOnshoreCommonTSTOFF = 0		set @SenSEOffshoreCommonTSTOFF = 0		set @SenSEOnshoreCommonTSTRDC = 0		set @SenSEOffshoreCommonTSTRDC = 0		set @SenSEOnshoreLegacy	= 0		set @SenSEOffshoreLegacy = 0	set @SenSEOnshoreLegacyLND	= 0		set @SenSEOffshoreLegacyLND = 0		set @SenSEOnshoreNiche	= 0			set @SenSEOffshoreNiche = 0		set @SenSEOnshoreNicheLND	= 0		set @SenSEOffshoreNicheLND = 0		set @SenSEOnshorePremium = 0	set @SenSEOffshorePremium = 0		set @SenSEOnshorePremiumLND = 0		set @SenSEOffshorePremiumLND = 0
			set @ConsArchOnshoreCommon = 0	set @ConsArchOffshoreCommon = 0	set @ConsArchOnshoreCommonLND = 0	set @ConsArchOffshoreCommonLND = 0	set @ConsArchOnshoreCommonRDC = 0	set @ConsArchOffshoreCommonRDC = 0	set @ConsArchOnshoreCommonTST = 0	set @ConsArchOffshoreCommonTST = 0	set @ConsArchOnshoreCommonTSTLND = 0	set @ConsArchOffshoreCommonTSTLND = 0	set @ConsArchOnshoreCommonTSTOFF = 0	set @ConsArchOffshoreCommonTSTOFF = 0	set @ConsArchOnshoreCommonTSTRDC = 0	set @ConsArchOffshoreCommonTSTRDC = 0	set @ConsArchOnshoreLegacy = 0	set @ConsArchOffshoreLegacy = 0	set @ConsArchOnshoreLegacyLND = 0	set @ConsArchOffshoreLegacyLND = 0	set @ConsArchOnshoreNiche = 0		set @ConsArchOffshoreNiche = 0	set @ConsArchOnshoreNicheLND = 0	set @ConsArchOffshoreNicheLND = 0	set @ConsArchOnshorePremium = 0	set @ConsArchOffshorePremium = 0	set @ConsArchOnshorePremiumLND = 0	set @ConsArchOffshorePremiumLND = 0
			set @PLOnshore = 0				set @PLOffshore = 0				set @ProjLeadOnshoreCommon = 0		set @ProjLeadOfshoreCommon = 0		set @ProjLeadOnshoreLegacy = 0		set @ProjLeadOffshoreLegacy = 0		set  @ProjLeadOnshorePremium = 0	set @ProjLeadOffshorePremium = 0   
			set @PMOnshore= 0				set @PMOffshore = 0				set @ProjMgrOnshoreCommon = 0		set @ProjMgrOffshoreCommon = 0		set @ProjMgrOnshoreLegacy = 0		set @ProjMgrOffshoreLegacy = 0 		set @ProjMgrOnshorePremium = 0		set @ProjMgrOffshorePremium = 0     
			set @PGMOnshore = 0				set @PGMOffshore= 0				set @ProgMgrOnshoreCommon = 0		set @ProgMgrOffshoreCommon = 0		set @ProgMgrOnshoreLegacy = 0		set @ProgMgrOffshoreLegacy = 0		set @ProgMgrOnshorePremium = 0		set @ProgMgrOffshorePremium = 0   

			set @JrSEOnCommonBillingType = ''		set @JrSEOffCommonBillingType = ''		set @JrSEOnCommonLNDBillingType = ''		set @JrSEOffCommonLNDBillingType = ''		set @JrSEOnCommonRDCBillingType = ''		set @JrSEOffCommonRDCBillingType = ''		set @JrSEOnCommonTSTBillingType = ''		set @JrSEOffCommonTSTBillingType = ''		set @JrSEOnCommonTSTLNDBillingType = ''		set @JrSEOffCommonTSTLNDBillingType = ''		set @JrSEOnCommonTSTOFFBillingType = ''		set @JrSEOffCommonTSTOFFBillingType = ''		set @JrSEOnCommonTSTRDCBillingType = ''		set @JrSEOffCommonTSTRDCBillingType = ''		set @JrSEOnLegacyBillingType = ''		set @JrSEOffLegacyBillingType = ''		set @JrSEOnLegacyLNDBillingType = ''		set @JrSEOffLegacyLNDBillingType = ''		set @JrSEOnNicheBillingType = ''		set @JrSEOffNicheBillingType = ''		set @JrSEOnPremiumBillingType = ''		set @JrSEOffPremiumBillingType = '' 
			set @MidSEOnCommonBillingType = ''		set @MidSEOffCommonBillingType = ''		set @MidSEOnCommonLNDBillingType = ''		set @MidSEOffCommonLNDBillingType = ''		set @MidSEOnCommonRDCBillingType = ''		set @MidSEOffCommonRDCBillingType = ''		set @MidSEOnCommonTSTBillingType = ''		set @MidSEOffCommonTSTBillingType = ''		set @MidSEOnCommonTSTLNDBillingType = ''	set @MidSEOffCommonTSTLNDBillingType = ''		set @MidSEOnCommonTSTOFFBillingType = ''	set @MidSEOffCommonTSTOFFBillingType = ''		set @MidSEOnCommonTSTRDCBillingType = ''	set @MidSEOffCommonTSTRDCBillingType = ''		set @MidSEOnLegacyBillingType = ''		set @MidSEOffLegacyBillingType = ''		set @MidSEOnLegacyLNDBillingType = ''		set @MidSEOffLegacyLNDBillingType = ''		set @MidSEOnNicheBillingType = ''		set @MidSEOffNicheBillingType = ''		set @MidSEOnPremiumBillingType = ''		set @MidSEOffPremiumBillingType = '' 		set @MidSEOnPremiumLNDBillingType = ''	set @MidSEOffPremiumLNDBillingType = '' 	
			set @AdvSEOnCommonBillingType = ''		set @AdvSEOffCommonBillingType = ''		set @AdvSEOnCommonLNDBillingType = ''		set @AdvSEOffCommonLNDBillingType = ''		set @AdvSEOnCommonRDCBillingType = ''		set @AdvSEOffCommonRDCBillingType = ''		set @AdvSEOnCommonTSTBillingType = ''		set @AdvSEOffCommonTSTBillingType = ''		set @AdvSEOnCommonTSTLNDBillingType = ''	set @AdvSEOffCommonTSTLNDBillingType = ''		set @AdvSEOnCommonTSTOFFBillingType = ''	set @AdvSEOffCommonTSTOFFBillingType = ''		set @AdvSEOnCommonTSTRDCBillingType = ''	set @AdvSEOffCommonTSTRDCBillingType = ''		set @AdvSEOnLegacyBillingType = ''		set @AdvSEOffLegacyBillingType = ''		set @AdvSEOnLegacyLNDBillingType = ''		set @AdvSEOffLegacyLNDBillingType = ''		set @AdvSEOnNicheBillingType = ''		set @AdvSEOffNicheBillingType = ''		set @AdvSEOnNicheLNDBillingType = ''	set @AdvSEOffNicheLNDBillingType = ''		set @AdvSEOnPremiumBillingType = ''		set @AdvSEOffPremiumBillingType = ''	set @AdvSEOnPremiumLNDBillingType = ''		set @AdvSEOffPremiumLNDBillingType = ''
			set @SenSEOnCommonBillingType = ''		set @SenSEOffCommonBillingType = ''		set @SenSEOnCommonLNDBillingType = ''		set @SenSEOffCommonLNDBillingType = ''		set @SenSEOnCommonRDCBillingType = ''		set @SenSEOffCommonRDCBillingType = ''		set @SenSEOnCommonTSTBillingType = ''		set @SenSEOffCommonTSTBillingType = ''		set @SenSEOnCommonTSTLNDBillingType = ''	set @SenSEOffCommonTSTLNDBillingType = ''		set @SenSEOnCommonTSTOFFBillingType = ''	set @SenSEOffCommonTSTOFFBillingType = ''		set @SenSEOnCommonTSTRDCBillingType = ''	set @SenSEOffCommonTSTRDCBillingType = ''		set @SenSEOnLegacyBillingType = ''		set @SenSEOffLegacyBillingType = ''		set @SenSEOnLegacyLNDBillingType = ''		set @SenSEOffLegacyLNDBillingType = ''		set @SenSEOnNicheBillingType = ''		set @SenSEOffNicheBillingType = ''		set @SenSEOnNicheLNDBillingType = ''	set @SenSEOffNicheLNDBillingType = ''		set @SenSEOnPremiumBillingType = ''		set @SenSEOffPremiumBillingType = ''	set @SenSEOnPremiumLNDBillingType = ''		set @SenSEOffPremiumLNDBillingType = ''
			set @ConsArchOnCommonBillingType = ''	set @ConsArchOffCommonBillingType = ''  set @ConsArchOnCommonLNDBillingType = ''	set @ConsArchOffCommonLNDBillingType = ''	set @ConsArchOnCommonRDCBillingType = ''	set @ConsArchOffCommonRDCBillingType = ''	set @ConsArchOnCommonTSTBillingType = ''	set @ConsArchOffCommonTSTBillingType = ''	set @ConsArchOnCommonTSTLNDBillingType = ''	set @ConsArchOffCommonTSTLNDBillingType = ''	set @ConsArchOnCommonTSTOFFBillingType = ''	set @ConsArchOffCommonTSTOFFBillingType = ''	set @ConsArchOnCommonTSTRDCBillingType = ''	set @ConsArchOffCommonTSTRDCBillingType = ''	set @ConsArchOnLegacyBillingType = ''	set @ConsArchOffLegacyBillingType = ''  set @ConsArchOnLegacyLNDBillingType = ''	set @ConsArchOffLegacyLNDBillingType = ''	set @ConsArchOnNicheBillingType = ''	set @ConsArchOffNicheBillingType = ''	set @ConsArchOnNicheLNDBillingType = ''	set @ConsArchOffNicheLNDBillingType = ''	set @ConsArchOnPremiumBillingType = ''	set @ConsArchOffPremiumBillingType = ''	set @ConsArchOnPremiumLNDBillingType = ''	set @ConsArchOffPremiumLNDBillingType = ''				
			set @PLOnBillingType = ''				set @PLOffBillingType = ''				set @ProjLeadOnCommonBillingType = ''		set @ProjLeadOffCommonBillingType = ''		set @ProjLeadOnLegacyBillingType = ''		set @ProjLeadOffLegacyBillingType = ''		set @ProjLeadOnPremiumBillingType = ''		set @ProjLeadOffPremiumBillingType = ''
			set @PMOnBillingType = ''				set @PMOffBillingType = ''				set @ProjMgrOnCommonBillingType = ''		set @ProjMgrOffCommonBillingType = ''		set @ProjMgrOnLegacyBillingType = ''		set @ProjMgrOffLegacyBillingType = ''		set @ProjMgrOnPremiumBillingType = ''		set @ProjMgrOffPremiumBillingType = ''
			set @PGMOnBillingType= ''				set @PGMOffBillingType = ''				set @ProgMgrOnCommonBillingType = ''		set @ProgMgrOffCommonBillingType = ''		set @ProgMgrOnLegacyBillingType = ''		set @ProgMgrOffLegacyBillingType = ''		set @ProgMgrOnPremiumBillingType = ''		set @ProgMgrOffPremiumBillingType = ''
						
			set @ServiceCategory = ''	
						
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID
		END    
		CLOSE AFEDesc_cursor
		DEALLOCATE AFEDesc_cursor

	------------------------------------------------------------------------------------
	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID
	END
	CLOSE Program_cursor
	DEALLOCATE Program_cursor
	
	---------------------------------------------------------------------------------------------------------------------------
    -- Populate columns for record type 30.
	update #TEMP_OUT set 
		TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) + isnull(ProgMgrOffshoreHours,0),
		TotalFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours) / @OffshoreFTERate), 
		R10_R20_TotalHours = isnull(JrSEOnshoreHours,0) + isnull(JrSEOffshoreHours,0) + isnull(MidSEOnshoreHours,0) + isnull(MidSEOffshoreHours,0) + isnull(AdvSEOnshoreHours,0) + isnull(AdvSEOffshoreHours,0) + isnull(SenSEOnshoreHours,0) + isnull(SenSEOffshoreHours,0) + isnull(ConsArchOnshoreHours,0) + isnull(ConsArchOffshoreHours,0) + isnull(ProjLeadOnshoreHours,0) + isnull(ProjLeadOffshoreHours,0) + isnull(ProjMgrOnshoreHours,0) + isnull(ProjMgrOffshoreHours,0) + isnull(ProgMgrOnshoreHours,0) + isnull(ProgMgrOffshoreHours,0)
	where AutoKey > @MaxProgGroup and RecNumber = 30 	
	-- Populate Variance column for record type 30. 
	update #TEMP_OUT set Variance = TotalFTEs - ApprovedFTEs where AutoKey > @MaxProgGroup and RecNumber = 30

	-- Populate totals for 10 fields (vertical add up).
	declare @JrSEOnshoreHours decimal(10,3), @JrSEOffshoreHours decimal(10,3), @MidSEOnshoreHours decimal(10,3), @MidSEOffshoreHours decimal(10,3), @AdvSEOnshoreHours decimal(10,3), @AdvSEOffshoreHours decimal(10,3), @SenSEOnshoreHours decimal(10,3), @SenSEOffshoreHours decimal(10,3), @ConsArchOnshoreHours decimal(10,3), @ConsArchOffshoreHours decimal(10,3), @SCEAOnshoreHours decimal(10,3), @SCEAOffshoreHours decimal(10,3), @ProjLeadOnshoreHours decimal(10,3), @ProjLeadOffshoreHours decimal(10,3), @ProjMgrOnshoreHours decimal(10,3), @ProjMgrOffshoreHours decimal(10,3), @ProgMgrOnshoreHours decimal(10,3), @ProgMgrOffshoreHours decimal(10,3), @TotalHours decimal(10,3), @TotalFTEs decimal(10,3), @ApprovedFTEs decimal(10,3), @Variance decimal(10,3)
	select @TotalHours = sum(isnull(TotalHours,0)), @TotalFTEs = sum(isnull(TotalFTEs,0)), @ApprovedFTEs = sum(isnull(ApprovedFTEs,0)), @Variance = sum(isnull(Variance,0)), 
		@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)),
		@R10_R20_TotalHours = sum(isnull(R10_R20_TotalHours,0))
	from #TEMP_OUT where AutoKey > @MaxProgGroup and RecNumber = 30

	update #TEMP_OUT set 
		TotalHours = @TotalHours, TotalFTEs = @TotalFTEs, ApprovedFTEs = @ApprovedFTEs, Variance = @Variance, R10_R20_TotalHours = @TotalHours,
		JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours 
	where AutoKey = @MaxProgGroup and RecNumber = 10

	-- Populate R10_R20_TotalHours for 10 NULL and 20 fields.
	update #TEMP_OUT set R10_R20_TotalHours = @TotalHours where AutoKey = (@MaxProgGroup-1) and RecNumber = 10
	
FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID, @UPVP
END
CLOSE ProgramGroup_cursor
DEALLOCATE ProgramGroup_cursor

-- Remove any rows that have ZERO or NULL values in the R10_R20_TotalHours field 
delete #TEMP_OUT where RecNumber in (10,20,30) and (R10_R20_TotalHours = 0 or R10_R20_TotalHours is NULL)


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-------------Calculate and Populate the 0 records (Total)---------------
select @TotalHours = sum(isnull(TotalHours,0)), @ApprovedFTEs = sum(isnull(ApprovedFTEs,0)), 
@JrSEOnshoreHours = sum(isnull(JrSEOnshoreHours,0)), @JrSEOffshoreHours = sum(isnull(JrSEOffshoreHours,0)), @MidSEOnshoreHours = sum(isnull(MidSEOnshoreHours,0)), @MidSEOffshoreHours = sum(isnull(MidSEOffshoreHours,0)), @AdvSEOnshoreHours = sum(isnull(AdvSEOnshoreHours,0)), @AdvSEOffshoreHours = sum(isnull(AdvSEOffshoreHours,0)), @SenSEOnshoreHours = sum(isnull(SenSEOnshoreHours,0)), @SenSEOffshoreHours = sum(isnull(SenSEOffshoreHours,0)), @ConsArchOnshoreHours = sum(isnull(ConsArchOnshoreHours,0)), @ConsArchOffshoreHours = sum(isnull(ConsArchOffshoreHours,0)), @ProjLeadOnshoreHours = sum(isnull(ProjLeadOnshoreHours,0)), @ProjLeadOffshoreHours = sum(isnull(ProjLeadOffshoreHours,0)), @ProjMgrOnshoreHours = sum(isnull(ProjMgrOnshoreHours,0)), @ProjMgrOffshoreHours = sum(isnull(ProjMgrOffshoreHours,0)), @ProgMgrOnshoreHours = sum(isnull(ProgMgrOnshoreHours,0)), @ProgMgrOffshoreHours = sum(isnull(ProgMgrOffshoreHours,0)) 
from #TEMP_OUT where RecNumber = 10 

update #TEMP_OUT set 
TotalHours = @TotalHours, 
TotalFTEs = ((@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours)/@OnshoreFTERate) + ((@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours)/@OffshoreFTERate),
ApprovedFTEs = @ApprovedFTEs,
JrSEOnshoreHours = @JrSEOnshoreHours, JrSEOffshoreHours = @JrSEOffshoreHours, MidSEOnshoreHours = @MidSEOnshoreHours, MidSEOffshoreHours = @MidSEOffshoreHours, AdvSEOnshoreHours = @AdvSEOnshoreHours, AdvSEOffshoreHours = @AdvSEOffshoreHours, SenSEOnshoreHours = @SenSEOnshoreHours, SenSEOffshoreHours = @SenSEOffshoreHours, ConsArchOnshoreHours = @ConsArchOnshoreHours, ConsArchOffshoreHours = @ConsArchOffshoreHours, ProjLeadOnshoreHours = @ProjLeadOnshoreHours, ProjLeadOffshoreHours = @ProjLeadOffshoreHours, ProjMgrOnshoreHours = @ProjMgrOnshoreHours, ProjMgrOffshoreHours = @ProjMgrOffshoreHours, ProgMgrOnshoreHours = @ProgMgrOnshoreHours, ProgMgrOffshoreHours = @ProgMgrOffshoreHours 
where RecNumber = 0 and RecType = 'GrandTotal'

update #TEMP_OUT set 
TotalHours = ((@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours)/@OnshoreFTERate) + ((@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours)/@OffshoreFTERate), 
TotalFTEs = ((@JrSEOnshoreHours + @MidSEOnshoreHours + @AdvSEOnshoreHours + @SenSEOnshoreHours + @ConsArchOnshoreHours + @ProjLeadOnshoreHours + @ProjMgrOnshoreHours + @ProgMgrOnshoreHours)/@OnshoreFTERate) + ((@JrSEOffshoreHours + @MidSEOffshoreHours + @AdvSEOffshoreHours + @SenSEOffshoreHours + @ConsArchOffshoreHours + @ProjLeadOffshoreHours + @ProjMgrOffshoreHours + @ProgMgrOffshoreHours)/@OffshoreFTERate),
ApprovedFTEs = @ApprovedFTEs,
JrSEOnshoreHours = @JrSEOnshoreHours/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffshoreHours/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnshoreHours/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffshoreHours/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnshoreHours/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffshoreHours/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnshoreHours/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffshoreHours/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchOnshoreHours/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchOffshoreHours/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadOnshoreHours/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadOffshoreHours/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrOnshoreHours/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrOffshoreHours/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrOnshoreHours/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrOffshoreHours/@OffshoreFTERate
where RecNumber = 0 and RecType = 'GrandTotalConversion'		

update #TEMP_OUT set Variance = TotalFTEs - ApprovedFTEs where RecNumber = 0 and RecType in ('GrandTotal', 'GrandTotalConversion')

------------Calculate and Populate the COMMON records-------------------
update #TEMP_OUT set 
TotalHours = @JrSEOnCommonTotal + @JrSEOffCommonTotal + @MidSEOnCommonTotal + @MidSEOffCommonTotal + @AdvSEOnCommonTotal + @AdvSEOffCommonTotal + @SenSEOnCommonTotal + @SenSEOffCommonTotal + @ConsArchSEOnCommonTotal + @ConsArchSEOffCommonTotal + @ProjLeadOnCommonTotal + @ProjLeadSEOffCommonTotal + @ProjMgrSEOnCommonTotal + @ProjMgrSEOffCommonTotal + @ProgMgrSEOnCommonTotal + @ProgMgrSEOffCommonTotal, 
JrSEOnshoreHours = @JrSEOnCommonTotal, JrSEOffshoreHours = @JrSEOffCommonTotal, MidSEOnshoreHours = @MidSEOnCommonTotal, MidSEOffshoreHours = @MidSEOffCommonTotal, AdvSEOnshoreHours = @AdvSEOnCommonTotal, AdvSEOffshoreHours = @AdvSEOffCommonTotal, SenSEOnshoreHours = @SenSEOnCommonTotal, SenSEOffshoreHours = @SenSEOffCommonTotal, ConsArchOnshoreHours = @ConsArchSEOnCommonTotal, ConsArchOffshoreHours = @ConsArchSEOffCommonTotal, ProjLeadOnshoreHours = @ProjLeadOnCommonTotal, ProjLeadOffshoreHours = @ProjLeadSEOffCommonTotal, ProjMgrOnshoreHours = @ProjMgrSEOnCommonTotal, ProjMgrOffshoreHours = @ProjMgrSEOffCommonTotal, ProgMgrOnshoreHours = @ProgMgrSEOnCommonTotal, ProgMgrOffshoreHours = @ProgMgrSEOffCommonTotal
where RecNumber = 1 and RecType = 'TotalCommon'

update #TEMP_OUT set TotalFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours) / @OffshoreFTERate)
where RecNumber = 1 and RecType = 'TotalCommon'

update #TEMP_OUT set 
TotalHours = ((@JrSEOnCommonTotal + @MidSEOnCommonTotal + @AdvSEOnCommonTotal + @SenSEOnCommonTotal + @ConsArchSEOnCommonTotal + @ProjLeadOnCommonTotal + @ProjMgrSEOnCommonTotal + @ProgMgrSEOnCommonTotal)/@OnshoreFTERate) + ((@JrSEOffCommonTotal + @MidSEOffCommonTotal + @AdvSEOffCommonTotal + @SenSEOffCommonTotal + @ConsArchSEOffCommonTotal + @ProjLeadSEOffCommonTotal + @ProjMgrSEOffCommonTotal + @ProgMgrSEOffCommonTotal)/@OffshoreFTERate), 
TotalFTEs = ((@JrSEOnCommonTotal + @MidSEOnCommonTotal + @AdvSEOnCommonTotal + @SenSEOnCommonTotal + @ConsArchSEOnCommonTotal + @ProjLeadOnCommonTotal + @ProjMgrSEOnCommonTotal + @ProgMgrSEOnCommonTotal)/@OnshoreFTERate) + ((@JrSEOffCommonTotal + @MidSEOffCommonTotal + @AdvSEOffCommonTotal + @SenSEOffCommonTotal + @ConsArchSEOffCommonTotal + @ProjLeadSEOffCommonTotal + @ProjMgrSEOffCommonTotal + @ProgMgrSEOffCommonTotal)/@OffshoreFTERate),
JrSEOnshoreHours = @JrSEOnCommonTotal/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffCommonTotal/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnCommonTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffCommonTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnCommonTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffCommonTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnCommonTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffCommonTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnCommonTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffCommonTotal/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadOnCommonTotal/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadSEOffCommonTotal/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrSEOnCommonTotal/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrSEOffCommonTotal/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrSEOnCommonTotal/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrSEOffCommonTotal/@OffshoreFTERate
where RecNumber = 1 and RecType = 'TotalCommonConversion'	

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 1 and RecType = 'TotalCommon'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 1 

------------Calculate and Populate the COMMON LND records-------------------
update #TEMP_OUT set 
TotalHours = @JrSEOnCommonLNDTotal + @JrSEOffCommonLNDTotal + @MidSEOnCommonLNDTotal + @MidSEOffCommonLNDTotal + @AdvSEOnCommonLNDTotal + @AdvSEOffCommonLNDTotal + @SenSEOnCommonLNDTotal + @SenSEOffCommonLNDTotal + @ConsArchSEOnCommonLNDTotal + @ConsArchSEOffCommonLNDTotal, 
JrSEOnshoreHours = @JrSEOnCommonLNDTotal, JrSEOffshoreHours = @JrSEOffCommonLNDTotal, MidSEOnshoreHours = @MidSEOnCommonLNDTotal, MidSEOffshoreHours = @MidSEOffCommonLNDTotal, AdvSEOnshoreHours = @AdvSEOnCommonLNDTotal, AdvSEOffshoreHours = @AdvSEOffCommonLNDTotal, SenSEOnshoreHours = @SenSEOnCommonLNDTotal, SenSEOffshoreHours = @SenSEOffCommonLNDTotal, 
ConsArchOnshoreHours = @ConsArchSEOnCommonLNDTotal, ConsArchOffshoreHours = @ConsArchSEOffCommonLNDTotal, ProjLeadOnshoreHours = 0, ProjLeadOffshoreHours = 0, ProjMgrOnshoreHours = 0, ProjMgrOffshoreHours = 0, ProgMgrOnshoreHours = 0, ProgMgrOffshoreHours = 0
where RecNumber = 11 and RecType = 'TotalCommonLND'

update #TEMP_OUT set TotalFTEs = (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours / @OnshoreFTERate) + (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours / @OffshoreFTERate)
where RecNumber = 11 and RecType = 'TotalCommonLND'

update #TEMP_OUT set 
TotalHours = (@JrSEOnCommonLNDTotal + @MidSEOnCommonLNDTotal + @AdvSEOnCommonLNDTotal + @SenSEOnCommonLNDTotal + @ConsArchSEOnCommonLNDTotal / @OnshoreFTERate) + (@JrSEOffCommonLNDTotal + @MidSEOffCommonLNDTotal + @AdvSEOffCommonLNDTotal + @SenSEOffCommonLNDTotal + @ConsArchSEOffCommonLNDTotal / @OffshoreFTERate), 
TotalFTEs = (@JrSEOnCommonLNDTotal + @MidSEOnCommonLNDTotal + @AdvSEOnCommonLNDTotal + @SenSEOnCommonLNDTotal + @ConsArchSEOnCommonLNDTotal / @OnshoreFTERate) + (@JrSEOffCommonLNDTotal + @MidSEOffCommonLNDTotal + @AdvSEOffCommonLNDTotal + @SenSEOffCommonLNDTotal + @ConsArchSEOffCommonLNDTotal / @OffshoreFTERate), 
JrSEOnshoreHours = @JrSEOnCommonLNDTotal/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffCommonLNDTotal/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnCommonLNDTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffCommonLNDTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnCommonLNDTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffCommonLNDTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnCommonLNDTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffCommonLNDTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnCommonLNDTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffCommonLNDTotal/@OffshoreFTERate, ProjLeadOnshoreHours = 0/@OnshoreFTERate, ProjLeadOffshoreHours = 0/@OffshoreFTERate, ProjMgrOnshoreHours = 0/@OnshoreFTERate, ProjMgrOffshoreHours = 0/@OffshoreFTERate, ProgMgrOnshoreHours = 0/@OnshoreFTERate, ProgMgrOffshoreHours = 0/@OffshoreFTERate
where RecNumber = 11 and RecType = 'TotalCommonLNDConversion'	

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 11 and RecType = 'TotalCommonLND'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 11 

------------Calculate and Populate the COMMON RDC records-------------------
update #TEMP_OUT set 
TotalHours = @JrSEOnCommonRDCTotal + @JrSEOffCommonRDCTotal + @MidSEOnCommonRDCTotal + @MidSEOffCommonRDCTotal + @AdvSEOnCommonRDCTotal + @AdvSEOffCommonRDCTotal + @SenSEOnCommonRDCTotal + @SenSEOffCommonRDCTotal + @ConsArchSEOnCommonRDCTotal + @ConsArchSEOffCommonRDCTotal,
JrSEOnshoreHours =  @JrSEOnCommonRDCTotal, JrSEOffshoreHours =  @JrSEOffCommonRDCTotal, MidSEOnshoreHours = @MidSEOnCommonRDCTotal, MidSEOffshoreHours = @MidSEOffCommonRDCTotal, AdvSEOnshoreHours = @AdvSEOnCommonRDCTotal, AdvSEOffshoreHours = @AdvSEOffCommonRDCTotal, SenSEOnshoreHours = @SenSEOnCommonRDCTotal, SenSEOffshoreHours = @SenSEOffCommonRDCTotal, ConsArchOnshoreHours = @ConsArchSEOnCommonRDCTotal, ConsArchOffshoreHours = @ConsArchSEOffCommonRDCTotal, ProjLeadOnshoreHours = 0, ProjLeadOffshoreHours = 0, ProjMgrOnshoreHours = 0, ProjMgrOffshoreHours = 0, ProgMgrOnshoreHours = 0, ProgMgrOffshoreHours = 0
where RecNumber = 12 and RecType = 'TotalCommonRDC'

update #TEMP_OUT set TotalFTEs = (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours / @OnshoreFTERate) + (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours / @OffshoreFTERate)
where RecNumber = 12 and RecType = 'TotalCommonRDC'

update #TEMP_OUT set 
TotalHours = (@JrSEOnCommonRDCTotal + @MidSEOnCommonRDCTotal + @AdvSEOnCommonRDCTotal + @SenSEOnCommonRDCTotal + @ConsArchSEOnCommonRDCTotal / @OnshoreFTERate) + (@JrSEOffCommonRDCTotal + @MidSEOffCommonRDCTotal + @AdvSEOffCommonRDCTotal + @SenSEOffCommonRDCTotal + @ConsArchSEOffCommonRDCTotal / @OffshoreFTERate), 
TotalFTEs = (@JrSEOnCommonRDCTotal + @MidSEOnCommonRDCTotal + @AdvSEOnCommonRDCTotal + @SenSEOnCommonRDCTotal + @ConsArchSEOnCommonRDCTotal / @OnshoreFTERate) + (@JrSEOffCommonRDCTotal + @MidSEOffCommonRDCTotal + @AdvSEOffCommonRDCTotal + @SenSEOffCommonRDCTotal + @ConsArchSEOffCommonRDCTotal / @OffshoreFTERate), 
JrSEOnshoreHours = @JrSEOnCommonRDCTotal/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffCommonRDCTotal/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnCommonRDCTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffCommonRDCTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnCommonRDCTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffCommonRDCTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnCommonRDCTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffCommonRDCTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnCommonRDCTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffCommonRDCTotal/@OffshoreFTERate, ProjLeadOnshoreHours = 0/@OnshoreFTERate, ProjLeadOffshoreHours = 0/@OffshoreFTERate, ProjMgrOnshoreHours = 0/@OnshoreFTERate, ProjMgrOffshoreHours = 0/@OffshoreFTERate, ProgMgrOnshoreHours = 0/@OnshoreFTERate, ProgMgrOffshoreHours = 0/@OffshoreFTERate
where RecNumber = 12 and RecType = 'TotalCommonRDCConversion'	

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 12 and RecType = 'TotalCommonRDC'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 12 

------------Calculate and Populate the COMMON TST records-------------------
update #TEMP_OUT set 
TotalHours = @JrSEOnCommonTSTTotal + @JrSEOffCommonTSTTotal + @MidSEOnCommonTSTTotal + @MidSEOffCommonTSTTotal + @AdvSEOnCommonTSTTotal + @AdvSEOffCommonTSTTotal + @SenSEOnCommonTSTTotal + @SenSEOffCommonTSTTotal + @ConsArchSEOnCommonTSTTotal + @ConsArchSEOffCommonTSTTotal,
JrSEOnshoreHours =  @JrSEOnCommonTSTTotal, JrSEOffshoreHours =  @JrSEOffCommonTSTTotal, MidSEOnshoreHours = @MidSEOnCommonTSTTotal, MidSEOffshoreHours = @MidSEOffCommonTSTTotal, AdvSEOnshoreHours = @AdvSEOnCommonTSTTotal, AdvSEOffshoreHours = @AdvSEOffCommonTSTTotal, SenSEOnshoreHours = @SenSEOnCommonTSTTotal, SenSEOffshoreHours = @SenSEOffCommonTSTTotal, ConsArchOnshoreHours = @ConsArchSEOnCommonTSTTotal, ConsArchOffshoreHours = @ConsArchSEOffCommonTSTTotal, ProjLeadOnshoreHours = 0, ProjLeadOffshoreHours = 0, ProjMgrOnshoreHours = 0, ProjMgrOffshoreHours = 0, ProgMgrOnshoreHours = 0, ProgMgrOffshoreHours = 0
where RecNumber = 13 and RecType = 'TotalCommonTST'

update #TEMP_OUT set TotalFTEs = (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours / @OnshoreFTERate) + (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours / @OffshoreFTERate)
where RecNumber = 13 and RecType = 'TotalCommonTST'

update #TEMP_OUT set 
TotalHours = (@JrSEOnCommonTSTTotal + @MidSEOnCommonTSTTotal + @AdvSEOnCommonTSTTotal + @SenSEOnCommonTSTTotal + @ConsArchSEOnCommonTSTTotal / @OnshoreFTERate) + (@JrSEOffCommonTSTTotal + @MidSEOffCommonTSTTotal + @AdvSEOffCommonTSTTotal + @SenSEOffCommonTSTTotal + @ConsArchSEOffCommonTSTTotal / @OffshoreFTERate), 
TotalFTEs = (@JrSEOnCommonTSTTotal + @MidSEOnCommonTSTTotal + @AdvSEOnCommonTSTTotal + @SenSEOnCommonTSTTotal + @ConsArchSEOnCommonTSTTotal / @OnshoreFTERate) + (@JrSEOffCommonTSTTotal + @MidSEOffCommonTSTTotal + @AdvSEOffCommonTSTTotal + @SenSEOffCommonTSTTotal + @ConsArchSEOffCommonTSTTotal / @OffshoreFTERate), 
JrSEOnshoreHours = @JrSEOnCommonTSTTotal/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffCommonTSTTotal/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnCommonTSTTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffCommonTSTTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnCommonTSTTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffCommonTSTTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnCommonTSTTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffCommonTSTTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnCommonTSTTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffCommonTSTTotal/@OffshoreFTERate, ProjLeadOnshoreHours = 0/@OnshoreFTERate, ProjLeadOffshoreHours = 0/@OffshoreFTERate, ProjMgrOnshoreHours = 0/@OnshoreFTERate, ProjMgrOffshoreHours = 0/@OffshoreFTERate, ProgMgrOnshoreHours = 0/@OnshoreFTERate, ProgMgrOffshoreHours = 0/@OffshoreFTERate
where RecNumber = 13 and RecType = 'TotalCommonTSTConversion'	

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 13 and RecType = 'TotalCommonTST'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 13 

------------Calculate and Populate the COMMON TST LND records-------------------
update #TEMP_OUT set 
TotalHours = @JrSEOnCommonTSTLNDTotal + @JrSEOffCommonTSTLNDTotal + @MidSEOnCommonTSTLNDTotal + @MidSEOffCommonTSTLNDTotal + @AdvSEOnCommonTSTLNDTotal + @AdvSEOffCommonTSTLNDTotal + @SenSEOnCommonTSTLNDTotal + @SenSEOffCommonTSTLNDTotal + @ConsArchSEOnCommonTSTLNDTotal + @ConsArchSEOffCommonTSTLNDTotal,
JrSEOnshoreHours =  @JrSEOnCommonTSTLNDTotal, JrSEOffshoreHours =  @JrSEOffCommonTSTLNDTotal, MidSEOnshoreHours = @MidSEOnCommonTSTLNDTotal, MidSEOffshoreHours = @MidSEOffCommonTSTLNDTotal, AdvSEOnshoreHours = @AdvSEOnCommonTSTLNDTotal, AdvSEOffshoreHours = @AdvSEOffCommonTSTLNDTotal, SenSEOnshoreHours = @SenSEOnCommonTSTLNDTotal, SenSEOffshoreHours = @SenSEOffCommonTSTLNDTotal, ConsArchOnshoreHours = @ConsArchSEOnCommonTSTLNDTotal, ConsArchOffshoreHours = @ConsArchSEOffCommonTSTLNDTotal, 
ProjLeadOnshoreHours = 0, ProjLeadOffshoreHours = 0, ProjMgrOnshoreHours = 0, ProjMgrOffshoreHours = 0, ProgMgrOnshoreHours = 0, ProgMgrOffshoreHours = 0
where RecNumber = 14 and RecType = 'TotalCommonTSTLND'

update #TEMP_OUT set TotalFTEs = (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours / @OnshoreFTERate) + (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours / @OffshoreFTERate)
where RecNumber = 14 and RecType = 'TotalCommonTSTLND'

update #TEMP_OUT set 
TotalHours = (@JrSEOnCommonTSTLNDTotal + @MidSEOnCommonTSTLNDTotal + @AdvSEOnCommonTSTLNDTotal + @SenSEOnCommonTSTLNDTotal + @ConsArchSEOnCommonTSTLNDTotal / @OnshoreFTERate) + (@JrSEOffCommonTSTLNDTotal + @MidSEOffCommonTSTLNDTotal + @AdvSEOffCommonTSTLNDTotal + @SenSEOffCommonTSTLNDTotal + @ConsArchSEOffCommonTSTLNDTotal / @OffshoreFTERate), 
TotalFTEs = (@JrSEOnCommonTSTLNDTotal + @MidSEOnCommonTSTLNDTotal + @AdvSEOnCommonTSTLNDTotal + @SenSEOnCommonTSTLNDTotal + @ConsArchSEOnCommonTSTLNDTotal / @OnshoreFTERate) + (@JrSEOffCommonTSTLNDTotal + @MidSEOffCommonTSTLNDTotal + @AdvSEOffCommonTSTLNDTotal + @SenSEOffCommonTSTLNDTotal + @ConsArchSEOffCommonTSTLNDTotal / @OffshoreFTERate), 
JrSEOnshoreHours = @JrSEOnCommonTSTLNDTotal/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffCommonTSTLNDTotal/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnCommonTSTLNDTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffCommonTSTLNDTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnCommonTSTLNDTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffCommonTSTLNDTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnCommonTSTLNDTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffCommonTSTLNDTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnCommonTSTLNDTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffCommonTSTLNDTotal/@OffshoreFTERate, ProjLeadOnshoreHours = 0/@OnshoreFTERate, ProjLeadOffshoreHours = 0/@OffshoreFTERate, ProjMgrOnshoreHours = 0/@OnshoreFTERate, ProjMgrOffshoreHours = 0/@OffshoreFTERate, ProgMgrOnshoreHours = 0/@OnshoreFTERate, ProgMgrOffshoreHours = 0/@OffshoreFTERate
where RecNumber = 14 and RecType = 'TotalCommonTSTLNDConversion'	

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 14 and RecType = 'TotalCommonTSTLND'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 14 

------------Calculate and Populate the COMMON TST OFF records-------------------
update #TEMP_OUT set 
TotalHours = @JrSEOnCommonTSTOFFTotal + @JrSEOffCommonTSTOFFTotal + @MidSEOnCommonTSTOFFTotal + @MidSEOffCommonTSTOFFTotal + @AdvSEOnCommonTSTOFFTotal + @AdvSEOffCommonTSTOFFTotal + @SenSEOnCommonTSTOFFTotal + @SenSEOffCommonTSTOFFTotal + @ConsArchSEOnCommonTSTOFFTotal + @ConsArchSEOffCommonTSTOFFTotal,
JrSEOnshoreHours =  @JrSEOnCommonTSTOFFTotal, JrSEOffshoreHours =  @JrSEOffCommonTSTOFFTotal, MidSEOnshoreHours = @MidSEOnCommonTSTOFFTotal, MidSEOffshoreHours = @MidSEOffCommonTSTOFFTotal, AdvSEOnshoreHours = @AdvSEOnCommonTSTOFFTotal, AdvSEOffshoreHours = @AdvSEOffCommonTSTOFFTotal, SenSEOnshoreHours = @SenSEOnCommonTSTOFFTotal, SenSEOffshoreHours = @SenSEOffCommonTSTOFFTotal, ConsArchOnshoreHours = @ConsArchSEOnCommonTSTOFFTotal, ConsArchOffshoreHours = @ConsArchSEOffCommonTSTOFFTotal, ProjLeadOnshoreHours = 0, ProjLeadOffshoreHours = 0, ProjMgrOnshoreHours = 0, ProjMgrOffshoreHours = 0, ProgMgrOnshoreHours = 0, ProgMgrOffshoreHours = 0
where RecNumber = 15 and RecType = 'TotalCommonTSTOFF'

update #TEMP_OUT set TotalFTEs = (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours / @OnshoreFTERate) + (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours / @OffshoreFTERate)
where RecNumber = 15 and RecType = 'TotalCommonTSTOFF'

update #TEMP_OUT set 
TotalHours = (@JrSEOnCommonTSTOFFTotal + @MidSEOnCommonTSTOFFTotal + @AdvSEOnCommonTSTOFFTotal + @SenSEOnCommonTSTOFFTotal + @ConsArchSEOnCommonTSTOFFTotal / @OnshoreFTERate) + (@JrSEOffCommonTSTOFFTotal + @MidSEOffCommonTSTOFFTotal + @AdvSEOffCommonTSTOFFTotal + @SenSEOffCommonTSTOFFTotal + @ConsArchSEOffCommonTSTOFFTotal / @OffshoreFTERate), 
TotalFTEs = (@JrSEOnCommonTSTOFFTotal + @MidSEOnCommonTSTOFFTotal + @AdvSEOnCommonTSTOFFTotal + @SenSEOnCommonTSTOFFTotal + @ConsArchSEOnCommonTSTOFFTotal / @OnshoreFTERate) + (@JrSEOffCommonTSTOFFTotal + @MidSEOffCommonTSTOFFTotal + @AdvSEOffCommonTSTOFFTotal + @SenSEOffCommonTSTOFFTotal + @ConsArchSEOffCommonTSTOFFTotal / @OffshoreFTERate), 
JrSEOnshoreHours = @JrSEOnCommonTSTOFFTotal/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffCommonTSTOFFTotal/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnCommonTSTOFFTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffCommonTSTOFFTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnCommonTSTOFFTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffCommonTSTOFFTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnCommonTSTOFFTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffCommonTSTOFFTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnCommonTSTOFFTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffCommonTSTOFFTotal/@OffshoreFTERate, ProjLeadOnshoreHours = 0/@OnshoreFTERate, ProjLeadOffshoreHours = 0/@OffshoreFTERate, ProjMgrOnshoreHours = 0/@OnshoreFTERate, ProjMgrOffshoreHours = 0/@OffshoreFTERate, ProgMgrOnshoreHours = 0/@OnshoreFTERate, ProgMgrOffshoreHours = 0/@OffshoreFTERate
where RecNumber = 15 and RecType = 'TotalCommonTSTOFFConversion'	

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 15 and RecType = 'TotalCommonTSTOFF'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 15 

------------Calculate and Populate the COMMON TST RDC records-------------------
update #TEMP_OUT set 
TotalHours = @JrSEOnCommonTSTRDCTotal + @JrSEOffCommonTSTRDCTotal + @MidSEOnCommonTSTRDCTotal + @MidSEOffCommonTSTRDCTotal + @AdvSEOnCommonTSTRDCTotal + @AdvSEOffCommonTSTRDCTotal + @SenSEOnCommonTSTRDCTotal + @SenSEOffCommonTSTRDCTotal + @ConsArchSEOnCommonTSTRDCTotal + @ConsArchSEOffCommonTSTRDCTotal,
JrSEOnshoreHours =  @JrSEOnCommonTSTRDCTotal, JrSEOffshoreHours =  @JrSEOffCommonTSTRDCTotal, MidSEOnshoreHours = @MidSEOnCommonTSTRDCTotal, MidSEOffshoreHours = @MidSEOffCommonTSTRDCTotal, AdvSEOnshoreHours = @AdvSEOnCommonTSTRDCTotal, AdvSEOffshoreHours = @AdvSEOffCommonTSTRDCTotal, SenSEOnshoreHours = @SenSEOnCommonTSTRDCTotal, SenSEOffshoreHours = @SenSEOffCommonTSTRDCTotal, ConsArchOnshoreHours = @ConsArchSEOnCommonTSTRDCTotal, ConsArchOffshoreHours = @ConsArchSEOffCommonTSTRDCTotal, ProjLeadOnshoreHours = 0, ProjLeadOffshoreHours = 0, ProjMgrOnshoreHours = 0, ProjMgrOffshoreHours = 0, ProgMgrOnshoreHours = 0, ProgMgrOffshoreHours = 0
where RecNumber = 16 and RecType = 'TotalCommonTSTRDC'

update #TEMP_OUT set TotalFTEs = (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours / @OnshoreFTERate) + (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours / @OffshoreFTERate)
where RecNumber = 16 and RecType = 'TotalCommonTSTRDC'

update #TEMP_OUT set 
TotalHours = (@JrSEOnCommonTSTRDCTotal + @MidSEOnCommonTSTRDCTotal + @AdvSEOnCommonTSTRDCTotal + @SenSEOnCommonTSTRDCTotal + @ConsArchSEOnCommonTSTRDCTotal / @OnshoreFTERate) + (@JrSEOffCommonTSTRDCTotal + @MidSEOffCommonTSTRDCTotal + @AdvSEOffCommonTSTRDCTotal + @SenSEOffCommonTSTRDCTotal + @ConsArchSEOffCommonTSTRDCTotal / @OffshoreFTERate), 
TotalFTEs = (@JrSEOnCommonTSTRDCTotal + @MidSEOnCommonTSTRDCTotal + @AdvSEOnCommonTSTRDCTotal + @SenSEOnCommonTSTRDCTotal + @ConsArchSEOnCommonTSTRDCTotal / @OnshoreFTERate) + (@JrSEOffCommonTSTRDCTotal + @MidSEOffCommonTSTRDCTotal + @AdvSEOffCommonTSTRDCTotal + @SenSEOffCommonTSTRDCTotal + @ConsArchSEOffCommonTSTRDCTotal / @OffshoreFTERate), 
JrSEOnshoreHours = @JrSEOnCommonTSTRDCTotal/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffCommonTSTOFFTotal/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnCommonTSTOFFTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffCommonTSTOFFTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnCommonTSTOFFTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffCommonTSTOFFTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnCommonTSTOFFTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffCommonTSTOFFTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnCommonTSTOFFTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffCommonTSTOFFTotal/@OffshoreFTERate, ProjLeadOnshoreHours = 0/@OnshoreFTERate, ProjLeadOffshoreHours = 0/@OffshoreFTERate, ProjMgrOnshoreHours = 0/@OnshoreFTERate, ProjMgrOffshoreHours = 0/@OffshoreFTERate, ProgMgrOnshoreHours = 0/@OnshoreFTERate, ProgMgrOffshoreHours = 0/@OffshoreFTERate
where RecNumber = 16 and RecType = 'TotalCommonTSTRDCCConversion'	

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 16 and RecType = 'TotalCommonTSTRDC'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 16 
	
------------Calculate and Populate the LEGACY records-------------------
update #TEMP_OUT set 
TotalHours = @JrSEOnLegacyTotal + @JrSEOffLegacyTotal + @MidSEOnLegacyTotal + @MidSEOffLegacyTotal + @AdvSEOnLegacyTotal + @AdvSEOffLegacyTotal + @SenSEOnLegacyTotal + @SenSEOffLegacyTotal + @ConsArchSEOnLegacyTotal + @ConsArchSEOffLegacyTotal + @ProjLeadOnLegacyTotal + @ProjLeadSEOffLegacyTotal + @ProjMgrSEOnLegacyTotal + @ProjMgrSEOffLegacyTotal + @ProgMgrSEOnLegacyTotal + @ProgMgrSEOffLegacyTotal, 
JrSEOnshoreHours = @JrSEOnLegacyTotal, JrSEOffshoreHours = @JrSEOffLegacyTotal, MidSEOnshoreHours = @MidSEOnLegacyTotal, MidSEOffshoreHours = @MidSEOffLegacyTotal, AdvSEOnshoreHours = @AdvSEOnLegacyTotal, AdvSEOffshoreHours = @AdvSEOffLegacyTotal, SenSEOnshoreHours = @SenSEOnLegacyTotal, SenSEOffshoreHours = @SenSEOffLegacyTotal, ConsArchOnshoreHours = @ConsArchSEOnLegacyTotal, ConsArchOffshoreHours = @ConsArchSEOffLegacyTotal, ProjLeadOnshoreHours = @ProjLeadOnLegacyTotal, ProjLeadOffshoreHours = @ProjLeadSEOffLegacyTotal, ProjMgrOnshoreHours = @ProjMgrSEOnLegacyTotal, ProjMgrOffshoreHours = @ProjMgrSEOffLegacyTotal, ProgMgrOnshoreHours = @ProgMgrSEOnLegacyTotal, ProgMgrOffshoreHours = @ProgMgrSEOffLegacyTotal
where RecNumber = 2 and RecType = 'TotalLegacy'

update #TEMP_OUT set TotalFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours) / @OffshoreFTERate)
where RecNumber = 2 and RecType = 'TotalLegacy'

update #TEMP_OUT set 
TotalHours = ((@JrSEOnLegacyTotal + @MidSEOnLegacyTotal + @AdvSEOnLegacyTotal + @SenSEOnLegacyTotal + @ConsArchSEOnLegacyTotal + @ProjLeadOnLegacyTotal + @ProjMgrSEOnLegacyTotal + @ProgMgrSEOnLegacyTotal)/@OnshoreFTERate) + ((@JrSEOffLegacyTotal + @MidSEOffLegacyTotal + @AdvSEOffLegacyTotal + @SenSEOffLegacyTotal + @ConsArchSEOffLegacyTotal + @ProjLeadSEOffLegacyTotal + @ProjMgrSEOffLegacyTotal + @ProgMgrSEOffLegacyTotal)/@OffshoreFTERate), 
TotalFTEs = ((@JrSEOnLegacyTotal + @MidSEOnLegacyTotal + @AdvSEOnLegacyTotal + @SenSEOnLegacyTotal + @ConsArchSEOnLegacyTotal + @ProjLeadOnLegacyTotal + @ProjMgrSEOnLegacyTotal + @ProgMgrSEOnLegacyTotal)/@OnshoreFTERate) + ((@JrSEOffLegacyTotal + @MidSEOffLegacyTotal + @AdvSEOffLegacyTotal + @SenSEOffLegacyTotal + @ConsArchSEOffLegacyTotal + @ProjLeadSEOffLegacyTotal + @ProjMgrSEOffLegacyTotal + @ProgMgrSEOffLegacyTotal)/@OffshoreFTERate),
JrSEOnshoreHours = @JrSEOnLegacyTotal/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffLegacyTotal/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnLegacyTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffLegacyTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnLegacyTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffLegacyTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnLegacyTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffLegacyTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnLegacyTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffLegacyTotal/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadOnLegacyTotal/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadSEOffLegacyTotal/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrSEOnLegacyTotal/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrSEOffLegacyTotal/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrSEOnLegacyTotal/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrSEOffLegacyTotal/@OffshoreFTERate
where RecNumber = 2 and RecType = 'TotalLegacyConversion'		

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 2 and RecType = 'TotalLegacy'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 2 

------------Calculate and Populate the LEGACY LND records-------------------
update #TEMP_OUT set 
TotalHours = @JrSEOnLegacyLNDTotal + @JrSEOffLegacyLNDTotal + @MidSEOnLegacyLNDTotal + @MidSEOffLegacyLNDTotal + @AdvSEOnLegacyLNDTotal + @AdvSEOffLegacyLNDTotal + @SenSEOnLegacyLNDTotal + @SenSEOffLegacyLNDTotal + @ConsArchSEOnLegacyLNDTotal + @ConsArchSEOffLegacyLNDTotal, 
JrSEOnshoreHours = @JrSEOnLegacyLNDTotal, JrSEOffshoreHours = @JrSEOffLegacyLNDTotal, MidSEOnshoreHours = @MidSEOnLegacyLNDTotal, MidSEOffshoreHours = @MidSEOffLegacyLNDTotal, AdvSEOnshoreHours = @AdvSEOnLegacyLNDTotal, AdvSEOffshoreHours = @AdvSEOffLegacyLNDTotal, SenSEOnshoreHours = @SenSEOnLegacyLNDTotal, SenSEOffshoreHours = @SenSEOffLegacyLNDTotal, ConsArchOnshoreHours = @ConsArchSEOnLegacyLNDTotal, ConsArchOffshoreHours = @ConsArchSEOffLegacyLNDTotal, ProjLeadOnshoreHours = 0, ProjLeadOffshoreHours = 0, ProjMgrOnshoreHours = 0, ProjMgrOffshoreHours = 0, ProgMgrOnshoreHours = 0, ProgMgrOffshoreHours = 0
where RecNumber = 21 and RecType = 'TotalLegacyLND'

update #TEMP_OUT set TotalFTEs = (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours / @OnshoreFTERate) + (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours / @OffshoreFTERate)
where RecNumber = 21 and RecType = 'TotalLegacyLND'

update #TEMP_OUT set 
TotalHours = (@JrSEOnLegacyLNDTotal + @MidSEOnLegacyLNDTotal + @AdvSEOnLegacyLNDTotal + @SenSEOnLegacyLNDTotal + @ConsArchSEOnLegacyLNDTotal / @OnshoreFTERate) + (@JrSEOffLegacyLNDTotal + @MidSEOffLegacyLNDTotal + @AdvSEOffLegacyLNDTotal + @SenSEOffLegacyLNDTotal + @ConsArchSEOffLegacyLNDTotal / @OffshoreFTERate), 
TotalFTEs = (@JrSEOnLegacyLNDTotal + @MidSEOnLegacyLNDTotal + @AdvSEOnLegacyLNDTotal + @SenSEOnLegacyLNDTotal + @ConsArchSEOnLegacyLNDTotal / @OnshoreFTERate) + (@JrSEOffLegacyLNDTotal + @MidSEOffLegacyLNDTotal + @AdvSEOffLegacyLNDTotal + @SenSEOffLegacyLNDTotal + @ConsArchSEOffLegacyLNDTotal / @OffshoreFTERate),
JrSEOnshoreHours = @JrSEOnLegacyLNDTotal/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffLegacyLNDTotal/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnLegacyLNDTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffLegacyLNDTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnLegacyLNDTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffLegacyLNDTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnLegacyLNDTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffLegacyLNDTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnLegacyLNDTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOnLegacyLNDTotal/@OffshoreFTERate, ProjLeadOnshoreHours = 0/@OnshoreFTERate, ProjLeadOffshoreHours = 0/@OffshoreFTERate, ProjMgrOnshoreHours = 0/@OnshoreFTERate, ProjMgrOffshoreHours = 0/@OffshoreFTERate, ProgMgrOnshoreHours = 0/@OnshoreFTERate, ProgMgrOffshoreHours = 0/@OffshoreFTERate
where RecNumber = 21 and RecType = 'TotalLegacyLNDConversion'		

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 21 and RecType = 'TotalLegacyLND'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 21 
	
------------Calculate and Populate the NICHE records-------------------
update #TEMP_OUT set 
TotalHours = @JrSEOnNicheTotal + @JrSEOffNicheTotal + @MidSEOnNicheTotal + @MidSEOffNicheTotal + @AdvSEOnNicheTotal + @AdvSEOffNicheTotal + @SenSEOnNicheTotal + @SenSEOffNicheTotal + @ConsArchSEOnNicheTotal + @ConsArchSEOffNicheTotal + @ProjLeadOnNicheTotal + @ProjLeadSEOffNicheTotal + @ProjMgrSEOnNicheTotal + @ProjMgrSEOffNicheTotal + @ProgMgrSEOnNicheTotal + @ProgMgrSEOffNicheTotal, 
JrSEOnshoreHours = @JrSEOnNicheTotal, JrSEOffshoreHours = @JrSEOffNicheTotal, MidSEOnshoreHours = @MidSEOnNicheTotal, MidSEOffshoreHours = @MidSEOffNicheTotal, AdvSEOnshoreHours = @AdvSEOnNicheTotal, AdvSEOffshoreHours = @AdvSEOffNicheTotal, SenSEOnshoreHours = @SenSEOnNicheTotal, SenSEOffshoreHours = @SenSEOffNicheTotal, ConsArchOnshoreHours = @ConsArchSEOnNicheTotal, ConsArchOffshoreHours = @ConsArchSEOffNicheTotal, ProjLeadOnshoreHours = @ProjLeadOnNicheTotal, ProjLeadOffshoreHours = @ProjLeadSEOffNicheTotal, ProjMgrOnshoreHours = @ProjMgrSEOnNicheTotal, ProjMgrOffshoreHours = @ProjMgrSEOffNicheTotal, ProgMgrOnshoreHours = @ProgMgrSEOnNicheTotal, ProgMgrOffshoreHours = @ProgMgrSEOffNicheTotal
where RecNumber = 3 and RecType = 'TotalNiche'

update #TEMP_OUT set 
TotalFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours) / @OffshoreFTERate)
where RecNumber = 3 and RecType = 'TotalNiche'

update #TEMP_OUT set 
TotalHours = ((@JrSEOnNicheTotal + @MidSEOnNicheTotal + @AdvSEOnNicheTotal + @SenSEOnNicheTotal + @ConsArchSEOnNicheTotal + @ProjLeadOnNicheTotal + @ProjMgrSEOnNicheTotal + @ProgMgrSEOnNicheTotal)/@OnshoreFTERate) + ((@JrSEOffNicheTotal + @MidSEOffNicheTotal + @AdvSEOffNicheTotal + @SenSEOffNicheTotal + @ConsArchSEOffNicheTotal + @ProjLeadSEOffNicheTotal + @ProjMgrSEOffNicheTotal + @ProgMgrSEOffNicheTotal)/@OffshoreFTERate), 
TotalFTEs = ((@JrSEOnNicheTotal + @MidSEOnNicheTotal + @AdvSEOnNicheTotal + @SenSEOnNicheTotal + @ConsArchSEOnNicheTotal + @ProjLeadOnNicheTotal + @ProjMgrSEOnNicheTotal + @ProgMgrSEOnNicheTotal)/@OnshoreFTERate) + ((@JrSEOffNicheTotal + @MidSEOffNicheTotal + @AdvSEOffNicheTotal + @SenSEOffNicheTotal + @ConsArchSEOffNicheTotal + @ProjLeadSEOffNicheTotal + @ProjMgrSEOffNicheTotal + @ProgMgrSEOffNicheTotal)/@OffshoreFTERate),
JrSEOnshoreHours = @JrSEOnNicheTotal/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffNicheTotal/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnNicheTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffNicheTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnNicheTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffNicheTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnNicheTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffNicheTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnNicheTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffNicheTotal/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadOnNicheTotal/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadSEOffNicheTotal/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrSEOnNicheTotal/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrSEOffNicheTotal/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrSEOnNicheTotal/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrSEOffNicheTotal/@OffshoreFTERate
where RecNumber = 3 and RecType = 'TotalNicheConversion'	

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 3 and RecType = 'TotalNiche'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 3 

------------Calculate and Populate the NICHE LND records-------------------
update #TEMP_OUT set 
TotalHours = @AdvSEOnNicheLNDTotal + @AdvSEOffNicheLNDTotal + @SenSEOnNicheLNDTotal + @SenSEOffNicheLNDTotal + @ConsArchSEOnNicheLNDTotal + @ConsArchSEOffNicheLNDTotal, 
JrSEOnshoreHours = 0, JrSEOffshoreHours = 0, MidSEOnshoreHours = 0, MidSEOffshoreHours = 0, AdvSEOnshoreHours = @AdvSEOnNicheLNDTotal, AdvSEOffshoreHours = @AdvSEOffNicheLNDTotal, SenSEOnshoreHours = @SenSEOnNicheLNDTotal, SenSEOffshoreHours = @SenSEOffNicheLNDTotal, ConsArchOnshoreHours = @ConsArchSEOnNicheLNDTotal, ConsArchOffshoreHours = @ConsArchSEOffNicheLNDTotal, ProjLeadOnshoreHours = 0, ProjLeadOffshoreHours = 0, ProjMgrOnshoreHours = 0, ProjMgrOffshoreHours = 0, ProgMgrOnshoreHours = 0, ProgMgrOffshoreHours = 0
where RecNumber = 31 and RecType = 'TotalNicheLND'

update #TEMP_OUT set TotalFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours) / @OffshoreFTERate)
where RecNumber = 31 and RecType = 'TotalNicheLND'

update #TEMP_OUT set 
TotalHours = ((@AdvSEOnNicheLNDTotal + @SenSEOnNicheLNDTotal + @ConsArchSEOnNicheLNDTotal)/@OnshoreFTERate) + ((@AdvSEOffNicheLNDTotal + @SenSEOffNicheLNDTotal + @ConsArchSEOffNicheLNDTotal)/@OffshoreFTERate), 
TotalFTEs = ((@AdvSEOnNicheLNDTotal + @SenSEOnNicheLNDTotal + @ConsArchSEOnNicheLNDTotal)/@OnshoreFTERate) + ((@AdvSEOffNicheLNDTotal + @SenSEOffNicheLNDTotal + @ConsArchSEOffNicheLNDTotal)/@OffshoreFTERate),
JrSEOnshoreHours = 0/@OnshoreFTERate, JrSEOffshoreHours = 0/@OffshoreFTERate, MidSEOnshoreHours = 0/@OnshoreFTERate, MidSEOffshoreHours = 0/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnNicheLNDTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffNicheLNDTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnNicheLNDTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffNicheLNDTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnNicheLNDTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffNicheLNDTotal/@OffshoreFTERate, ProjLeadOnshoreHours = 0/@OnshoreFTERate, ProjLeadOffshoreHours = 0/@OffshoreFTERate, ProjMgrOnshoreHours = 0/@OnshoreFTERate, ProjMgrOffshoreHours = 0/@OffshoreFTERate, ProgMgrOnshoreHours = 0/@OnshoreFTERate, ProgMgrOffshoreHours = 0/@OffshoreFTERate
where RecNumber = 31 and RecType = 'TotalNicheLNDConversion'	

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 31 and RecType = 'TotalNicheLND'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 31 

---------Calculate and Populate the PL/PM/PGM Mgmt records---------------
update #TEMP_OUT set 
TotalHours =  @PLOnTotal + @PLOffTotal + @PMOnTotal + @PMOffTotal + @PGMOnTotal + @PGMOffTotal,
JrSEOnshoreHours = 0, JrSEOffshoreHours = 0, MidSEOnshoreHours = 0, MidSEOffshoreHours = 0, AdvSEOnshoreHours = 0, AdvSEOffshoreHours = 0, SenSEOnshoreHours = 0, SenSEOffshoreHours = 0, ConsArchOnshoreHours = 0, ConsArchOffshoreHours = 0, ProjLeadOnshoreHours = @PLOnTotal, ProjLeadOffshoreHours = @PLOffTotal, ProjMgrOnshoreHours = @PMOnTotal, ProjMgrOffshoreHours = @PMOffTotal, ProgMgrOnshoreHours = @PGMOnTotal, ProgMgrOffshoreHours = @PGMOffTotal
where RecNumber = 4 and RecType = 'TotalMgmt'

update #TEMP_OUT set 
TotalFTEs = ((ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours)/@OnshoreFTERate) + ((ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours)/@OffshoreFTERate)
where RecNumber = 4 and RecType = 'TotalMgmt'

update #TEMP_OUT set 
TotalHours = ((@PLOnTotal + @PMOnTotal + @PGMOnTotal) / @OnshoreFTERate) + ((@PLOffTotal + @PMOffTotal + @PGMOffTotal) / @OffshoreFTERate), 
TotalFTEs = ((@PLOnTotal + @PMOnTotal + @PGMOnTotal) / @OnshoreFTERate) + ((@PLOffTotal + @PMOffTotal + @PGMOffTotal) / @OffshoreFTERate),
JrSEOnshoreHours = 0/@OnshoreFTERate, JrSEOffshoreHours = 0/@OffshoreFTERate, MidSEOnshoreHours = 0/@OnshoreFTERate, MidSEOffshoreHours = 0/@OffshoreFTERate, AdvSEOnshoreHours = 0/@OnshoreFTERate, AdvSEOffshoreHours = 0/@OffshoreFTERate, SenSEOnshoreHours = 0/@OnshoreFTERate, SenSEOffshoreHours = 0/@OffshoreFTERate, ConsArchOnshoreHours = 0/@OnshoreFTERate, ConsArchOffshoreHours = 0/@OffshoreFTERate, ProjLeadOnshoreHours = @PLOnTotal/@OnshoreFTERate, ProjLeadOffshoreHours = @PLOffTotal/@OffshoreFTERate, ProjMgrOnshoreHours = @PMOnTotal/@OnshoreFTERate, ProjMgrOffshoreHours = @PMOffTotal/@OffshoreFTERate, ProgMgrOnshoreHours = @PGMOnTotal/@OnshoreFTERate, ProgMgrOffshoreHours = @PGMOffTotal/@OffshoreFTERate 
where RecNumber = 4 and RecType = 'TotalMgmtConversion'		

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 4 and RecType = 'TotalMgmt'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 4 

----------Calculate and Populate the PREMIUM records------------------
update #TEMP_OUT set 
TotalHours = @JrSEOnPremiumTotal + @JrSEOffPremiumTotal + @MidSEOnPremiumTotal + @MidSEOffPremiumTotal + @AdvSEOnPremiumTotal + @AdvSEOffPremiumTotal + @SenSEOnPremiumTotal + @SenSEOffPremiumTotal + @ConsArchSEOnPremiumTotal + @ConsArchSEOffPremiumTotal + @ProjLeadSEOnPremiumTotal + @ProjLeadSEOffPremiumTotal + @ProjMgrSEOnPremiumTotal + @ProjMgrSEOffPremiumTotal + @ProgMgrSEOnPremiumTotal + @ProgMgrSEOffPremiumTotal, 
JrSEOnshoreHours = @JrSEOnPremiumTotal, JrSEOffshoreHours = @JrSEOffPremiumTotal, MidSEOnshoreHours = @MidSEOnPremiumTotal, MidSEOffshoreHours = @MidSEOffPremiumTotal, AdvSEOnshoreHours = @AdvSEOnPremiumTotal, AdvSEOffshoreHours = @AdvSEOffPremiumTotal, SenSEOnshoreHours = @SenSEOnPremiumTotal, SenSEOffshoreHours = @SenSEOffPremiumTotal, ConsArchOnshoreHours = @ConsArchSEOnPremiumTotal, ConsArchOffshoreHours = @ConsArchSEOffPremiumTotal, ProjLeadOnshoreHours = @ProjLeadSEOnPremiumTotal, ProjLeadOffshoreHours = @ProjLeadSEOffPremiumTotal, ProjMgrOnshoreHours = @ProjMgrSEOnPremiumTotal, ProjMgrOffshoreHours = @ProjMgrSEOffPremiumTotal, ProgMgrOnshoreHours = @ProgMgrSEOnPremiumTotal, ProgMgrOffshoreHours = @ProgMgrSEOffPremiumTotal
where RecNumber = 5 and RecType = 'TotalPremium'

update #TEMP_OUT set TotalFTEs = ( (JrSEOnshoreHours + MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours + ProjLeadOnshoreHours + ProjMgrOnshoreHours + ProgMgrOnshoreHours) / @OnshoreFTERate) + ( (JrSEOffshoreHours + MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours + ProjLeadOffshoreHours + ProjMgrOffshoreHours + ProgMgrOffshoreHours) / @OffshoreFTERate)
where RecNumber = 5 and RecType = 'TotalPremium'

update #TEMP_OUT set 
TotalHours = ((@JrSEOnPremiumTotal + @MidSEOnPremiumTotal + @AdvSEOnPremiumTotal + @SenSEOnPremiumTotal + @ConsArchSEOnPremiumTotal + @ProjLeadSEOnPremiumTotal + @ProjMgrSEOnPremiumTotal + @ProgMgrSEOnPremiumTotal)/@OnshoreFTERate) + ((@JrSEOffPremiumTotal + @MidSEOffPremiumTotal + @AdvSEOffPremiumTotal + @SenSEOffPremiumTotal + @ConsArchSEOffPremiumTotal + @ProjLeadSEOffPremiumTotal + @ProjMgrSEOffPremiumTotal + @ProgMgrSEOffPremiumTotal)/@OffshoreFTERate), 
TotalFTEs = ((@JrSEOnPremiumTotal + @MidSEOnPremiumTotal + @AdvSEOnPremiumTotal + @SenSEOnPremiumTotal + @ConsArchSEOnPremiumTotal + @ProjLeadSEOnPremiumTotal + @ProjMgrSEOnPremiumTotal + @ProgMgrSEOnPremiumTotal)/@OnshoreFTERate) + ((@JrSEOffPremiumTotal + @MidSEOffPremiumTotal + @AdvSEOffPremiumTotal + @SenSEOffPremiumTotal + @ConsArchSEOffPremiumTotal + @ProjLeadSEOffPremiumTotal + @ProjMgrSEOffPremiumTotal + @ProgMgrSEOffPremiumTotal)/@OffshoreFTERate),
JrSEOnshoreHours = @JrSEOnPremiumTotal/@OnshoreFTERate, JrSEOffshoreHours = @JrSEOffPremiumTotal/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnPremiumTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffPremiumTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnPremiumTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffPremiumTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnPremiumTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffPremiumTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnPremiumTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffPremiumTotal/@OffshoreFTERate, ProjLeadOnshoreHours = @ProjLeadSEOnPremiumTotal/@OnshoreFTERate, ProjLeadOffshoreHours = @ProjLeadSEOffPremiumTotal/@OffshoreFTERate, ProjMgrOnshoreHours = @ProjMgrSEOnPremiumTotal/@OnshoreFTERate, ProjMgrOffshoreHours = @ProjMgrSEOffPremiumTotal/@OffshoreFTERate, ProgMgrOnshoreHours = @ProgMgrSEOnPremiumTotal/@OnshoreFTERate, ProgMgrOffshoreHours = @ProgMgrSEOffPremiumTotal/@OffshoreFTERate
where RecNumber = 5 and RecType = 'TotalPremiumConversion'	

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 5 and RecType = 'TotalPremium'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 5 
		
----------Calculate and Populate the PREMIUM LND records------------------
update #TEMP_OUT set 
TotalHours = @MidSEOnPremiumLNDTotal + @MidSEOffPremiumLNDTotal + @AdvSEOnPremiumLNDTotal + @AdvSEOffPremiumLNDTotal + @SenSEOnPremiumLNDTotal + @SenSEOffPremiumLNDTotal + @ConsArchSEOnPremiumLNDTotal + @ConsArchSEOffPremiumLNDTotal, 
JrSEOnshoreHours = 0, JrSEOffshoreHours = 0, MidSEOnshoreHours = @MidSEOnPremiumLNDTotal, MidSEOffshoreHours = @MidSEOffPremiumLNDTotal, AdvSEOnshoreHours = @AdvSEOnPremiumLNDTotal, AdvSEOffshoreHours = @AdvSEOffPremiumLNDTotal, SenSEOnshoreHours = @SenSEOnPremiumLNDTotal, SenSEOffshoreHours = @SenSEOffPremiumLNDTotal, ConsArchOnshoreHours = @ConsArchSEOnPremiumLNDTotal, ConsArchOffshoreHours = @ConsArchSEOffPremiumLNDTotal, ProjLeadOnshoreHours = 0, ProjLeadOffshoreHours = 0, ProjMgrOnshoreHours = 0, ProjMgrOffshoreHours = 0, ProgMgrOnshoreHours = 0, ProgMgrOffshoreHours = 0
where RecNumber = 51 and RecType = 'TotalPremiumLND'

update #TEMP_OUT set TotalFTEs = (MidSEOnshoreHours + AdvSEOnshoreHours + SenSEOnshoreHours + ConsArchOnshoreHours / @OnshoreFTERate) + (MidSEOffshoreHours + AdvSEOffshoreHours + SenSEOffshoreHours + ConsArchOffshoreHours / @OffshoreFTERate)
where RecNumber = 51 and RecType = 'TotalPremiumLND'

update #TEMP_OUT set 
TotalHours = (@MidSEOnPremiumLNDTotal + @AdvSEOnPremiumLNDTotal + @SenSEOnPremiumLNDTotal + @ConsArchSEOnPremiumLNDTotal / @OnshoreFTERate) + (@MidSEOffPremiumLNDTotal + @AdvSEOffPremiumLNDTotal + @SenSEOffPremiumLNDTotal + @ConsArchSEOffPremiumLNDTotal / @OffshoreFTERate), 
TotalFTEs = (@MidSEOnPremiumLNDTotal + @AdvSEOnPremiumLNDTotal + @SenSEOnPremiumLNDTotal + @ConsArchSEOnPremiumLNDTotal / @OnshoreFTERate) + (@MidSEOffPremiumLNDTotal + @AdvSEOffPremiumLNDTotal + @SenSEOffPremiumLNDTotal + @ConsArchSEOffPremiumLNDTotal / @OffshoreFTERate),
JrSEOnshoreHours = 0/@OnshoreFTERate, JrSEOffshoreHours = 0/@OffshoreFTERate, MidSEOnshoreHours = @MidSEOnPremiumLNDTotal/@OnshoreFTERate, MidSEOffshoreHours = @MidSEOffPremiumLNDTotal/@OffshoreFTERate, AdvSEOnshoreHours = @AdvSEOnPremiumLNDTotal/@OnshoreFTERate, AdvSEOffshoreHours = @AdvSEOffPremiumLNDTotal/@OffshoreFTERate, SenSEOnshoreHours = @SenSEOnPremiumLNDTotal/@OnshoreFTERate, SenSEOffshoreHours = @SenSEOffPremiumLNDTotal/@OffshoreFTERate, ConsArchOnshoreHours = @ConsArchSEOnPremiumLNDTotal/@OnshoreFTERate, ConsArchOffshoreHours = @ConsArchSEOffPremiumLNDTotal/@OffshoreFTERate, ProjLeadOnshoreHours = 0/@OnshoreFTERate, ProjLeadOffshoreHours = 0/@OffshoreFTERate, ProjMgrOnshoreHours = 0/@OnshoreFTERate, ProjMgrOffshoreHours = 0/@OffshoreFTERate, ProgMgrOnshoreHours = 0/@OnshoreFTERate, ProgMgrOffshoreHours = 0/@OffshoreFTERate
where RecNumber = 51 and RecType = 'TotalPremiumLNDConversion'	

select @CheckTotalHours = TotalHours from #TEMP_OUT where RecNumber = 51 and RecType = 'TotalPremiumLND'
if @CheckTotalHours = '0.000'
	delete from #TEMP_OUT where RecNumber = 51 	
	
-- Calculate and Populate the PROGRAM records
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 6, 'TotalProgram', 'Total Program'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 6, 'TotalProgramConversion', 'FTE Conversion'	
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 6.1, 'TotalProgramLND', 'Total Program LND'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 6.1, 'TotalProgramLNDConversion', 'FTE Conversion'	
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 6.2, 'TotalProgramRDC', 'Total Program RDC'
--insert #TEMP_OUT (RecNumber, RecType, RecDesc) select 6.2, 'TotalProgramRDCConversion', 'FTE Conversion'	

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

--select AutoKey, RecNumber, RecType, RecDesc, ServiceCategory, TotalHours, TotalFTEs, ApprovedFTEs, Variance, JrSEOnshoreHours, JrSEOffshoreHours, MidSEOnshoreHours, MidSEOffshoreHours, AdvSEOnshoreHours, AdvSEOffshoreHours, SenSEOnshoreHours, SenSEOffshoreHours, ProjLeadOnshoreHours, ProjLeadOffshoreHours, ProgMgrOnshoreHours, ProgMgrOffshoreHours, R10_R20_TotalHours from #TEMP_OUT order by AutoKey		

select * from #TEMP_OUT order by AutoKey		
