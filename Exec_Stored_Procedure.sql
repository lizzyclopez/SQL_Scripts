exec Get_AFE_Project_Detail
	@DateFrom = '04/01/2009', 	
	@DateTo = '04/30/2009',  
	@ProgGroupID = '-1', 
	@FundCatID = -1, 
	@FundCatIDList = '-1', 
	@StatusID = -1, 
	@AFEID = -1, 
	@SolutionCentreList = '-1', 
	@CurrentMonth = '200904',
	@ITSABillingCat = '-1',
	@BillingShoreWhere = NULL,
	@OutputTable = NULL



DECLARE @DateFrom datetime
DECLARE @DateTo datetime
DECLARE @CurrentMonth varchar(6)
DECLARE @ProgGroupID varchar(100)
DECLARE @FundCatID int
DECLARE @FundCatIDList varchar(100)
DECLARE @StatusID int
DECLARE @AFEID int
DECLARE @ProjectID bigint
DECLARE @ITSABillingCat varchar(30)
DECLARE @SolutionCentreList varchar(500)
DECLARE @BillingShoreWhere varchar(20)
DECLARE @OutputTable varchar(30)

EXECUTE Get_AFE_Detail_ConsolidatedTower
   @DateFrom = '09/01/2012'
  ,@DateTo = '09/30/2012'
  ,@CurrentMonth = '201209'
  ,@ProgGroupID = '-1'
  ,@FundCatID = -1
  ,@FundCatIDList = '-1'
  ,@StatusID = -1
  ,@AFEID = -1
  ,@ProjectID = -1
  ,@ITSABillingCat = '-1'
  ,@SolutionCentreList = '-1'
  ,@BillingShoreWhere = null
  ,@OutputTable = null