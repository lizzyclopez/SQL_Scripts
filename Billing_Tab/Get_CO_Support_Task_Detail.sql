drop view [dbo].[SP_CO_Support_View]
drop table #TEMP_IN
drop table #Temp_Bucket
drop table #TEMP_OUT

DECLARE @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_CO_Support_View AS select CO_Support_View.*, CO_BillingCode.Billing_CodeID AS NewBilling_CodeID, CO_BillingCode.Description AS NewBillingType , CO_Resource.Onshore, CO_Resource.Offshore from CO_Support_View inner join CO_Resource ON CO_Support_View.EDSNETID = CO_Resource.ResourceNumber inner join CO_BillingCode ON CO_BillingCode.Billing_CodeID = CO_Resource.Billing_CodeID 
where WorkDate >= ''2010-02-01'' and WorkDate <= ''2010-03-31'' '
exec (@SQL_statement)

select * into #TEMP_IN from dbo.SP_CO_Support_View
exec('Drop View dbo.SP_CO_Support_View')

ALTER TABLE #TEMP_IN ALTER COLUMN TaskID varchar(100) NULL
ALTER TABLE #TEMP_IN ALTER COLUMN ProjectID varchar(100) NULL
-- Adjust the hours according  to the Task CoFundingPct by CO *******
update #TEMP_IN set Hours = isnull(TaskClientFundingPct,100)/100*Hours where isnull(TaskClientFundingPct,0) > 0
-- Adjust the Category Code to Other if NULL *******
update #TEMP_IN set TaskCategorycode = 'Other' where TaskCategorycode is null
-- Delete records that are not set up correctly for CO Billable  ******
delete #TEMP_IN where AFE_DescID is null OR ProgramID is NULL or Prog_GroupID is NULL or Funding_CatID is NULL or Funding_CatID <> 3000

-- Create temporary table.
CREATE TABLE [dbo].[#Temp_Bucket] (
	[Bucket_Nbr] [int] IDENTITY (1, 1) NOT NULL , 	[YYYY_Year] [int] NOT NULL , 	[MM_Month] [int] NOT NULL 
) ON [PRIMARY]

-- Build the Temp Bucket Table 
DECLARE @Count int, @Month varchar(6), @Year varchar(6), @Mint int, @Yint int, @WorkDate varchar(30), @CompFrom varchar(8), @CompTo varchar(8), @DatFro datetime, @DatTo datetime, @NextMo datetime, @DateFrom datetime, @DateTo datetime
set @DateFrom = '2010-02-01'
set @DateTo = '2010-03-31'
select @DatFro = (convert (datetime, @DateFrom))
select @DatTo  = (convert (datetime, @DateTo))
set @NextMo = @DatTo
set @CompFrom = convert(varchar(8),@DatFro,112)
set @CompTo   = convert(varchar(8),@DatTo,112)
set @WorkDate = convert(varchar(30),@DatTo,101)
set @Count = 1

-- Do Month 1.
Tbl_Insert:
set @Month = substring(@workdate,1,2)
set @Year  = substring(@workdate,7,4)
set @Mint  = convert(int, @Month)
set @Yint  = convert(int,  @Year)
insert #Temp_Bucket (YYYY_Year, MM_Month) select @Yint, @Mint

if Month(@NextMo) = Month(@DatFro) goto EndBucket
else
   begin
     select @NextMo = (dateadd (mm, -1, @NextMo))
     set @WorkDate = convert(varchar(30),@NextMo,101)
     goto Tbl_Insert
   end
EndBucket: ----------- Stop running.

---------------------------------------------------------------------------------------------------
--drop table #TEMP_OUT

CREATE TABLE [dbo].[#TEMP_OUT] ( 
	[AutoKey][int] IDENTITY (0, 1) NOT NULL,
	[RecNumber][int] NULL,  --0=Grand Total/10=Task Category Totals/15=blank/20=PG with totals/25=Prog/30=AFE Desc with Totals
	[RecType] [varchar] (100) NULL,	[RecDesc] [varchar] (100) NULL,	[TaskCategory] [varchar] (100) NULL,	[TaskCategoryRecNum50] [varchar] (100) NULL,	[RecTypeID] [varchar] (100) NULL,	[Division] [varchar] (100) NULL, 	[Prog_GroupID] [int] NULL,	[ProgramID] [varchar] (100) NULL,	[TaskID] [varchar] (100) NULL,	[ResourceNumber] [varchar] (25) NULL, 
	[YTD_Hours] [decimal](10,2) NULL,       [YTD_FTEs] [decimal](10,2) NULL,    
	[TotalHours] [decimal](12,2) NULL DEFAULT 0,    [TotalFTEs] [decimal](10,2) NULL  DEFAULT 0,	[TotalFTEs_hover] [decimal](17,7) NULL DEFAULT 0,
	[Bucket1_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket1_FTEs] [decimal](10,2) NULL DEFAULT 0,	[Bucket1_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,
    [Bucket2_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket2_FTEs] [decimal](10,2) NULL DEFAULT 0,	[Bucket2_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,
    [Bucket3_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket3_FTEs] [decimal](10,2) NULL DEFAULT 0,	[Bucket3_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,
    [Bucket4_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket4_FTEs] [decimal](10,2) NULL  DEFAULT 0,	[Bucket4_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,
    [Bucket5_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket5_FTEs] [decimal](10,2) NULL DEFAULT 0,	[Bucket5_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,
    [Bucket6_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket6_FTEs] [decimal](10,2) NULL DEFAULT 0,	[Bucket6_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,
    [Bucket7_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket7_FTEs] [decimal](10,2) NULL DEFAULT 0,	[Bucket7_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,
    [Bucket8_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket8_FTEs] [decimal](10,2) NULL DEFAULT 0,	[Bucket8_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,
    [Bucket9_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket9_FTEs] [decimal](10,2) NULL DEFAULT 0,	[Bucket9_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,
    [Bucket10_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket10_FTEs] [decimal](10,2) NULL DEFAULT 0,	[Bucket10_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,
    [Bucket11_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket11_FTEs] [decimal](10,2) NULL DEFAULT 0,	[Bucket11_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,
    [Bucket12_Hours] [decimal](10,2) NULL DEFAULT 0,	[Bucket12_FTEs] [decimal](10,2) NULL DEFAULT 0,	[Bucket12_FTEs_hover] [decimal](15,7) NULL DEFAULT 0,        
    [Sort_Key]  [int] 
 ) ON [PRIMARY]
 
insert #TEMP_OUT (RecNumber, RecType)
select 0, 'GrandTotal'

---------------------------------------------------------------------------------------------------

-- Summarize the Task Category Codes --
DECLARE @CurTaskCategoryCode  varchar (100), @CurTaskCategoryTotal  decimal (10,2), @CurYear int, @CurMonth int, @CurHours decimal (10,2), @bucket_nbr int

DECLARE TaskCategory_cursor CURSOR FOR 
    select distinct TaskCategoryCode from #TEMP_IN order by TaskCategoryCode
OPEN TaskCategory_cursor
FETCH NEXT FROM TaskCategory_cursor INTO @CurTaskCategoryCode
	WHILE @@FETCH_STATUS = 0
	BEGIN
	    insert #TEMP_OUT (RecNumber, RecType, TaskCategory)
		select 10, 'Task Category', @CurTaskCategoryCode
				
		---------------------------------------------------------------------------------------------------
		-- sum up the onshore months for this Task Category code and build out the 12 month buckets ---
		---------------------------------------------------------------------------------------------------
		DECLARE Month_cursor_onshore CURSOR FOR 
			select YYYY_Year, MM_Month, sum(hours) as TotalHours from #TEMP_IN
			where TaskCategoryCode = @CurTaskCategoryCode and NewBillingType <> 'FTP Staff Aug' and Onshore = 1 group by YYYY_Year, MM_Month	

			--Declare variables for Buckets
			DECLARE @BucketOnshore1 decimal(12,2), @BucketOnshore2 decimal(12,2), @BucketOnshore3 decimal(12,2), @BucketOnshore4 decimal(12,2),@BucketOnshore5 decimal(12,2), @BucketOnshore6 decimal(12,2), @BucketOnshore7 decimal(12,2), @BucketOnshore8 decimal(12,2),@BucketOnshore9 decimal(12,2), @bucketOnshore10 decimal(12,2), @bucketOnshore11 decimal(12,2),@bucketOnshore12 decimal(12,2)
        	
			-- Clear out all Buckets to Zero 
			set @BucketOnshore1 = 0 set @BucketOnshore2 = 0 set @BucketOnshore3 = 0 set @BucketOnshore4 = 0  set @BucketOnshore5 = 0 set @BucketOnshore6 = 0 
			set @BucketOnshore7 = 0 set @BucketOnshore8 = 0 set @BucketOnshore9 = 0 set @bucketOnshore10 = 0 set @bucketOnshore11 =0 set @bucketOnshore12 = 0
			
        OPEN Month_cursor_onshore
		FETCH NEXT FROM Month_cursor_onshore INTO @CurYear, @CurMonth, @CurHours
		WHILE @@FETCH_STATUS = 0
		BEGIN	
			-- determing the bucket that this month / year goes into
			select @bucket_nbr =  bucket_nbr from #Temp_Bucket where YYYY_Year = @CurYear and MM_Month = @CurMonth
			
			-- build output buckets
			if @bucket_nbr = 1 
				begin
				set @BucketOnshore1 = @CurHours
				end
			if @bucket_nbr = 2 
				begin
				set @BucketOnshore2 = @CurHours
				end
			if @bucket_nbr = 3 
				begin
				set @BucketOnshore3 = @CurHours
				end
			if @bucket_nbr = 4 
				begin
				set @BucketOnshore4 = @CurHours
				end
			if @bucket_nbr = 5 
				begin
				set @BucketOnshore5 = @CurHours
				end
			if @bucket_nbr = 6 
				begin
				set @BucketOnshore6 = @CurHours
				end
			if @bucket_nbr = 7 
				begin
				set @BucketOnshore7 = @CurHours
				end
			if @bucket_nbr = 8 
				begin
				set @BucketOnshore8 = @CurHours
				end
			if @bucket_nbr = 9 
				begin
				set @BucketOnshore9 = @CurHours
				end
			if @bucket_nbr = 10 
				begin
				set @bucketOnshore10 = @CurHours
				end
			if @bucket_nbr = 11 
			   begin
				set @bucketOnshore11 = @CurHours
				end
			if @bucket_nbr = 12 
				begin
				set @bucketOnshore12 = @CurHours
				end				
		FETCH NEXT FROM Month_cursor_onshore INTO @CurYear, @CurMonth, @CurHours
		END
		CLOSE Month_cursor_onshore
		DEALLOCATE Month_cursor_onshore			
	
		---------------------------------------------------------------------------------------------------
		-- sum up the FTP onshore months for this Task Category code and build out the 12 month buckets ---
		---------------------------------------------------------------------------------------------------
		DECLARE Month_cursor_FTPonshore CURSOR FOR 
			select YYYY_Year, MM_Month, sum(hours) as TotalHours from #TEMP_IN
			where TaskCategoryCode = @CurTaskCategoryCode and NewBillingType = 'FTP Staff Aug' and Onshore = 1 group by YYYY_Year, MM_Month	

			--Declare variables for Buckets
			DECLARE @BucketFTPOnshore1 decimal(12,2), @BucketFTPOnshore2 decimal(12,2), @BucketFTPOnshore3 decimal(12,2), @BucketFTPOnshore4 decimal(12,2),@BucketFTPOnshore5 decimal(12,2), @BucketFTPOnshore6 decimal(12,2), @BucketFTPOnshore7 decimal(12,2), @BucketFTPOnshore8 decimal(12,2),@BucketFTPOnshore9 decimal(12,2), @bucketFTPOnshore10 decimal(12,2), @bucketFTPOnshore11 decimal(12,2),@bucketFTPOnshore12 decimal(12,2)
        	
			-- Clear out all Buckets to Zero 
			set @BucketFTPOnshore1 =0 set @BucketFTPOnshore2 = 0 set @BucketFTPOnshore3 =0 set @BucketFTPOnshore4 = 0  set @BucketFTPOnshore5 = 0 set @BucketFTPOnshore6 = 0  
			set @BucketFTPOnshore7 =0 set @BucketFTPOnshore8 = 0 set @BucketFTPOnshore9 =0 set @bucketFTPOnshore10 = 0 set @bucketFTPOnshore11 =0 set @bucketFTPOnshore12 = 0
		OPEN Month_cursor_FTPonshore
		FETCH NEXT FROM Month_cursor_FTPonshore INTO @CurYear, @CurMonth, @CurHours
		WHILE @@FETCH_STATUS = 0
		BEGIN	
			-- determing the bucket that this month / year goes into
			select @bucket_nbr =  bucket_nbr from #Temp_Bucket where YYYY_Year = @CurYear and MM_Month = @CurMonth
			
			-- build output buckets
			if @bucket_nbr = 1 
				begin
				set @BucketFTPOnshore1 = @CurHours
				end
			if @bucket_nbr = 2 
				begin
				set @BucketFTPOnshore2 = @CurHours
				end
			if @bucket_nbr = 3 
				begin
				set @BucketFTPOnshore3 = @CurHours
				end
			if @bucket_nbr = 4 
				begin
				set @BucketFTPOnshore4 = @CurHours
				end
			if @bucket_nbr = 5 
				begin
				set @BucketFTPOnshore5 = @CurHours
				end
			if @bucket_nbr = 6 
				begin
				set @BucketFTPOnshore6 = @CurHours
				end
			if @bucket_nbr = 7 
				begin
				set @BucketFTPOnshore7 = @CurHours
				end
			if @bucket_nbr = 8 
				begin
				set @BucketFTPOnshore8 = @CurHours
				end
			if @bucket_nbr = 9 
				begin
				set @BucketFTPOnshore9 = @CurHours
				end
			if @bucket_nbr = 10 
				begin
				set @BucketFTPOnshore10 = @CurHours
				end
			if @bucket_nbr = 11 
			   begin
				set @BucketFTPOnshore11 = @CurHours
				end
			if @bucket_nbr = 12 
				begin
				set @BucketFTPOnshore12 = @CurHours
				end				
		FETCH NEXT FROM Month_cursor_FTPonshore INTO @CurYear, @CurMonth, @CurHours
		END
		CLOSE Month_cursor_FTPonshore
		DEALLOCATE Month_cursor_FTPonshore		
		
		---------------------------------------------------------------------------------------------------
		-- sum up the offshore months for this Task Category code and build out the 12 month buckets ---
		---------------------------------------------------------------------------------------------------
		DECLARE Month_cursor_offshore CURSOR FOR 
   			select YYYY_Year, MM_Month, sum(hours) as TotalHours from #TEMP_IN
			where TaskCategoryCode = @CurTaskCategoryCode and NewBillingType <> 'FTP Staff Aug' and Offshore = 1 group by YYYY_Year, MM_Month	
            
   			--Declare variables for Buckets
			DECLARE @BucketOffshore1 decimal(12,2), @BucketOffshore2 decimal(12,2), @BucketOffshore3 decimal(12,2), @BucketOffshore4 decimal(12,2),@BucketOffshore5 decimal(12,2), @BucketOffshore6 decimal(12,2), @BucketOffshore7 decimal(12,2), @BucketOffshore8 decimal(12,2),@BucketOffshore9 decimal(12,2), @bucketOffshore10 decimal(12,2), @bucketOffshore11 decimal(12,2),@bucketOffshore12 decimal(12,2)
	
    		-- Clear out all Buckets to Zero 
			set @BucketOffshore1 =0 set @BucketOffshore2 = 0 set @BucketOffshore3 =0 set @BucketOffshore4 = 0  set @BucketOffshore5 =0  set @BucketOffshore6 = 0  
			set @BucketOffshore7 =0 set @BucketOffshore8 = 0 set @BucketOffshore9 =0 set @bucketOffshore10 = 0 set @bucketOffshore11 =0 set @bucketOffshore12 = 0
      	OPEN Month_cursor_offshore
		FETCH NEXT FROM Month_cursor_offshore INTO @CurYear, @CurMonth, @CurHours
        WHILE @@FETCH_STATUS = 0
        BEGIN
			-- determing the bucket that this month / year goes into
			select @bucket_nbr =  bucket_nbr from #Temp_Bucket where YYYY_Year = @CurYear and MM_Month = @CurMonth

			-- build output buckets
			if @bucket_nbr = 1 
				begin
				set @BucketOffshore1 = @CurHours
				end
			if @bucket_nbr = 2 
				begin
				set @BucketOffshore2 = @CurHours				
				end
			if @bucket_nbr = 3 
				begin
				set @BucketOffshore3 = @CurHours
				end
			if @bucket_nbr = 4 
				begin
				set @BucketOffshore4 = @CurHours
				end
			if @bucket_nbr = 5 
				begin
				set @BucketOffshore5 = @CurHours
				end
			if @bucket_nbr = 6 
				begin
				set @BucketOffshore6 = @CurHours
				end
			if @bucket_nbr = 7 
				begin
				set @BucketOffshore7 = @CurHours
				end
			if @bucket_nbr = 8 
				begin
				set @BucketOffshore8 = @CurHours
				end
			if @bucket_nbr = 9 
				begin
				set @BucketOffshore9 = @CurHours
				end
			if @bucket_nbr = 10 
				begin
				set @bucketOffshore10 = @CurHours
				end
			if @bucket_nbr = 11 
			   begin
				set @bucketOffshore11 = @CurHours
				end
			if @bucket_nbr = 12 
				begin
				set @bucketOffshore12 = @CurHours
				end						
		FETCH NEXT FROM Month_cursor_offshore INTO @CurYear, @CurMonth, @CurHours
		END
		CLOSE Month_cursor_offshore
		DEALLOCATE Month_cursor_offshore
		
		---------------------------------------------------------------------------------------------------
		-- sum up the FTP offshore months for this Task Category code and build out the 12 month buckets ---
		---------------------------------------------------------------------------------------------------
		DECLARE Month_cursor_FTPoffshore CURSOR FOR 
   			select YYYY_Year, MM_Month, sum(hours) as TotalHours from #TEMP_IN
			where TaskCategoryCode = @CurTaskCategoryCode and NewBillingType = 'FTP Staff Aug' and Offshore = 1 group by YYYY_Year, MM_Month	
            
   			--Declare variables for Buckets
			DECLARE @BucketFTPOffshore1 decimal(12,2), @BucketFTPOffshore2 decimal(12,2), @BucketFTPOffshore3 decimal(12,2), @BucketFTPOffshore4 decimal(12,2),@BucketFTPOffshore5 decimal(12,2), @BucketFTPOffshore6 decimal(12,2), @BucketFTPOffshore7 decimal(12,2), @BucketFTPOffshore8 decimal(12,2),@BucketFTPOffshore9 decimal(12,2), @bucketFTPOffshore10 decimal(12,2), @bucketFTPOffshore11 decimal(12,2),@bucketFTPOffshore12 decimal(12,2)
	
    		-- Clear out all Buckets to Zero 
			set @BucketFTPOffshore1 =0 set @BucketFTPOffshore2 = 0 set @BucketFTPOffshore3 =0 set @BucketFTPOffshore4 = 0  set @BucketFTPOffshore5 =0  set @BucketFTPOffshore6 = 0  
			set @BucketFTPOffshore7 =0 set @BucketFTPOffshore8 = 0 set @BucketFTPOffshore9 =0 set @bucketFTPOffshore10 = 0 set @bucketFTPOffshore11 =0 set @bucketFTPOffshore12 = 0
      	OPEN Month_cursor_FTPoffshore
		FETCH NEXT FROM Month_cursor_FTPoffshore INTO @CurYear, @CurMonth, @CurHours
        WHILE @@FETCH_STATUS = 0
        BEGIN
			-- determing the bucket that this month / year goes into
			select @bucket_nbr =  bucket_nbr from #Temp_Bucket where YYYY_Year = @CurYear and MM_Month = @CurMonth

			-- build output buckets
			if @bucket_nbr = 1 
				begin
				set @BucketFTPOffshore1 = @CurHours
				end
			if @bucket_nbr = 2 
				begin
				set @BucketFTPOffshore2 = @CurHours				
				end
			if @bucket_nbr = 3 
				begin
				set @BucketFTPOffshore3 = @CurHours
				end
			if @bucket_nbr = 4 
				begin
				set @BucketFTPOffshore4 = @CurHours
				end
			if @bucket_nbr = 5 
				begin
				set @BucketFTPOffshore5 = @CurHours
				end
			if @bucket_nbr = 6 
				begin
				set @BucketFTPOffshore6 = @CurHours
				end
			if @bucket_nbr = 7 
				begin
				set @BucketFTPOffshore7 = @CurHours
				end
			if @bucket_nbr = 8 
				begin
				set @BucketFTPOffshore8 = @CurHours
				end
			if @bucket_nbr = 9 
				begin
				set @BucketFTPOffshore9 = @CurHours
				end
			if @bucket_nbr = 10 
				begin
				set @BucketFTPOffshore10 = @CurHours
				end
			if @bucket_nbr = 11 
			   begin
				set @BucketFTPOffshore11 = @CurHours
				end
			if @bucket_nbr = 12 
				begin
				set @BucketFTPOffshore12 = @CurHours
				end						
		FETCH NEXT FROM Month_cursor_FTPoffshore INTO @CurYear, @CurMonth, @CurHours
		END
		CLOSE Month_cursor_FTPoffshore
		DEALLOCATE Month_cursor_FTPoffshore
		
	---------------------------------------------------------------------------------------------------
 	---------------------------------------------------------------------------------------------------
	DECLARE @FTPBillingRate decimal(10,2), @year int, @month int, @BillableDays int, @FTEFactorOnshore decimal(5,2), @FTEFactorOffshore decimal(5,2)
--erase when loading to prod
declare @DateFrom datetime, @DateTo datetime
set @DateFrom = '2010-02-01'
set @DateTo = '2010-03-31'

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

	--Set the FTE rate for onshore and offshore (non FTP).
	set @FTEFactorOnshore = '149'
	set @FTEFactorOffshore = '143.5'

	-- Populate the #TEMP_OUT table with the Task Category Code Record containing all of the 12 buckets
	update #TEMP_OUT set
		Bucket1_Hours = isnull(@BucketOnshore1,0) + isnull(@BucketFTPOnshore1,0) + isnull(@BucketOffshore1,0) + isnull(@BucketFTPOffshore1,0), Bucket1_FTEs = isnull(@BucketOnshore1,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore1,0)/@FTPBillingRate + isnull(@BucketOffshore1,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore1,0)/@FTPBillingRate, Bucket1_FTEs_hover = isnull(@BucketOnshore1,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore1,0)/@FTPBillingRate + isnull(@BucketOffshore1,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore1,0)/@FTPBillingRate,	 		
		Bucket2_Hours = isnull(@BucketOnshore2,0) + isnull(@BucketFTPOnshore2,0) + isnull(@BucketOffshore2,0) + isnull(@BucketFTPOffshore2,0), Bucket2_FTEs = isnull(@BucketOnshore2,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore2,0)/@FTPBillingRate + isnull(@BucketOffshore2,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore2,0)/@FTPBillingRate, Bucket2_FTEs_hover = isnull(@BucketOnshore2,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore2,0)/@FTPBillingRate + isnull(@BucketOffshore2,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore2,0)/@FTPBillingRate,	 		
		Bucket3_Hours = isnull(@BucketOnshore3,0) + isnull(@BucketFTPOnshore3,0) + isnull(@BucketOffshore3,0) + isnull(@BucketFTPOffshore3,0), Bucket3_FTEs = isnull(@BucketOnshore3,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore3,0)/@FTPBillingRate + isnull(@BucketOffshore3,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore3,0)/@FTPBillingRate, Bucket3_FTEs_hover = isnull(@BucketOnshore3,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore3,0)/@FTPBillingRate + isnull(@BucketOffshore3,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore3,0)/@FTPBillingRate,	 		
		Bucket4_Hours = isnull(@BucketOnshore4,0) + isnull(@BucketFTPOnshore4,0) + isnull(@BucketOffshore4,0) + isnull(@BucketFTPOffshore4,0), Bucket4_FTEs = isnull(@BucketOnshore4,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore4,0)/@FTPBillingRate + isnull(@BucketOffshore4,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore4,0)/@FTPBillingRate, Bucket4_FTEs_hover = isnull(@BucketOnshore4,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore4,0)/@FTPBillingRate + isnull(@BucketOffshore4,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore4,0)/@FTPBillingRate,	 		
		Bucket5_Hours = isnull(@BucketOnshore5,0) + isnull(@BucketFTPOnshore5,0) + isnull(@BucketOffshore5,0) + isnull(@BucketFTPOffshore5,0), Bucket5_FTEs = isnull(@BucketOnshore5,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore5,0)/@FTPBillingRate + isnull(@BucketOffshore5,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore5,0)/@FTPBillingRate, Bucket5_FTEs_hover = isnull(@BucketOnshore5,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore5,0)/@FTPBillingRate + isnull(@BucketOffshore5,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore5,0)/@FTPBillingRate,	 		
		Bucket6_Hours = isnull(@BucketOnshore6,0) + isnull(@BucketFTPOnshore6,0) + isnull(@BucketOffshore6,0) + isnull(@BucketFTPOffshore6,0), Bucket6_FTEs = isnull(@BucketOnshore6,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore6,0)/@FTPBillingRate + isnull(@BucketOffshore6,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore6,0)/@FTPBillingRate, Bucket6_FTEs_hover = isnull(@BucketOnshore6,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore6,0)/@FTPBillingRate + isnull(@BucketOffshore6,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore6,0)/@FTPBillingRate,	 		
		Bucket7_Hours = isnull(@BucketOnshore7,0) + isnull(@BucketFTPOnshore7,0) + isnull(@BucketOffshore7,0) + isnull(@BucketFTPOffshore7,0), Bucket7_FTEs = isnull(@BucketOnshore7,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore7,0)/@FTPBillingRate + isnull(@BucketOffshore7,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore7,0)/@FTPBillingRate, Bucket7_FTEs_hover = isnull(@BucketOnshore7,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore7,0)/@FTPBillingRate + isnull(@BucketOffshore7,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore7,0)/@FTPBillingRate,	 		
		Bucket8_Hours = isnull(@BucketOnshore8,0) + isnull(@BucketFTPOnshore8,0) + isnull(@BucketOffshore8,0) + isnull(@BucketFTPOffshore8,0), Bucket8_FTEs = isnull(@BucketOnshore8,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore8,0)/@FTPBillingRate + isnull(@BucketOffshore8,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore8,0)/@FTPBillingRate, Bucket8_FTEs_hover = isnull(@BucketOnshore8,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore8,0)/@FTPBillingRate + isnull(@BucketOffshore8,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore8,0)/@FTPBillingRate,	 		
		Bucket9_Hours = isnull(@BucketOnshore9,0) + isnull(@BucketFTPOnshore9,0) + isnull(@BucketOffshore9,0) + isnull(@BucketFTPOffshore9,0), Bucket9_FTEs = isnull(@BucketOnshore9,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore9,0)/@FTPBillingRate + isnull(@BucketOffshore9,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore9,0)/@FTPBillingRate, Bucket9_FTEs_hover = isnull(@BucketOnshore9,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore9,0)/@FTPBillingRate + isnull(@BucketOffshore9,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore9,0)/@FTPBillingRate,	 		
		Bucket10_Hours = isnull(@BucketOnshore10,0) + isnull(@BucketFTPOnshore10,0) + isnull(@BucketOffshore10,0) + isnull(@BucketFTPOffshore10,0), Bucket10_FTEs = isnull(@BucketOnshore10,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore10,0)/@FTPBillingRate + isnull(@BucketOffshore10,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore10,0)/@FTPBillingRate,	Bucket10_FTEs_hover = isnull(@BucketOnshore10,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore10,0)/@FTPBillingRate + isnull(@BucketOffshore10,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore10,0)/@FTPBillingRate,	 		
		Bucket11_Hours = isnull(@BucketOnshore11,0) + isnull(@BucketFTPOnshore11,0) + isnull(@BucketOffshore11,0) + isnull(@BucketFTPOffshore11,0), Bucket11_FTEs = isnull(@BucketOnshore11,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore11,0)/@FTPBillingRate + isnull(@BucketOffshore11,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore11,0)/@FTPBillingRate,	Bucket11_FTEs_hover = isnull(@BucketOnshore11,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore11,0)/@FTPBillingRate + isnull(@BucketOffshore11,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore11,0)/@FTPBillingRate,	 	
		Bucket12_Hours = isnull(@BucketOnshore12,0) + isnull(@BucketFTPOnshore12,0) + isnull(@BucketOffshore12,0) + isnull(@BucketFTPOffshore12,0), Bucket12_FTEs = isnull(@BucketOnshore12,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore12,0)/@FTPBillingRate + isnull(@BucketOffshore12,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore12,0)/@FTPBillingRate,	Bucket12_FTEs_hover = isnull(@BucketOnshore12,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore12,0)/@FTPBillingRate + isnull(@BucketOffshore12,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore12,0)/@FTPBillingRate,	 		
		TotalHours = (isnull(@BucketOnshore1,0))+(isnull(@BucketOnshore2,0))+(isnull(@BucketOnshore3,0))+(isnull(@BucketOnshore4,0))+(isnull(@BucketOnshore5,0))+(isnull(@BucketOnshore6,0))+(isnull(@BucketOnshore7,0))+(isnull(@BucketOnshore8,0))+(isnull(@BucketOnshore9,0))+(isnull(@BucketOnshore10,0))+(isnull(@BucketOnshore11,0))+(isnull(@BucketOnshore12,0)) + (isnull(@BucketFTPOnshore1,0))+(isnull(@BucketFTPOnshore2,0))+(isnull(@BucketFTPOnshore3,0))+(isnull(@BucketFTPOnshore4,0))+(isnull(@BucketFTPOnshore5,0))+(isnull(@BucketFTPOnshore6,0))+(isnull(@BucketFTPOnshore7,0))+(isnull(@BucketFTPOnshore8,0))+(isnull(@BucketFTPOnshore9,0))+(isnull(@BucketFTPOnshore10,0))+(isnull(@BucketFTPOnshore11,0))+(isnull(@BucketFTPOnshore12,0)) + (isnull(@BucketOffshore1,0))+(isnull(@BucketOffshore2,0))+(isnull(@BucketOffshore3,0))+(isnull(@BucketOffshore4,0))+(isnull(@BucketOffshore5,0))+(isnull(@BucketOffshore6,0))+(isnull(@BucketOffshore7,0))+(isnull(@BucketOffshore8,0))+(isnull(@BucketOffshore9,0))+(isnull(@BucketOffshore10,0))+(isnull(@BucketOffshore11,0))+(isnull(@BucketOffshore12,0)) + (isnull(@BucketFTPOffshore1,0))+(isnull(@BucketFTPOffshore2,0))+(isnull(@BucketFTPOffshore3,0))+(isnull(@BucketFTPOffshore4,0))+(isnull(@BucketFTPOffshore5,0))+(isnull(@BucketFTPOffshore6,0))+(isnull(@BucketFTPOffshore7,0))+(isnull(@BucketFTPOffshore8,0))+(isnull(@BucketFTPOffshore9,0))+(isnull(@BucketFTPOffshore10,0))+(isnull(@BucketFTPOffshore11,0))+(isnull(@BucketFTPOffshore12,0)),
		TotalFTEs = ((isnull(@BucketOnshore1,0))+(isnull(@BucketOnshore2,0))+(isnull(@BucketOnshore3,0))+(isnull(@BucketOnshore4,0))+(isnull(@BucketOnshore5,0))+(isnull(@BucketOnshore6,0))+(isnull(@BucketOnshore7,0))+(isnull(@BucketOnshore8,0))+(isnull(@BucketOnshore9,0))+(isnull(@BucketOnshore10,0))+(isnull(@BucketOnshore11,0))+(isnull(@BucketOnshore12,0)))/@FTEFactorOnshore +	
		((isnull(@BucketFTPOnshore1,0))+(isnull(@BucketFTPOnshore2,0))+(isnull(@BucketFTPOnshore3,0))+(isnull(@BucketFTPOnshore4,0))+(isnull(@BucketFTPOnshore5,0))+(isnull(@BucketFTPOnshore6,0))+(isnull(@BucketFTPOnshore7,0))+(isnull(@BucketFTPOnshore8,0))+(isnull(@BucketFTPOnshore9,0))+(isnull(@BucketFTPOnshore10,0))+(isnull(@BucketFTPOnshore11,0))+(isnull(@BucketFTPOnshore12,0)))/@FTPBillingRate +	
		((isnull(@BucketOffshore1,0))+(isnull(@BucketOffshore2,0))+(isnull(@BucketOffshore3,0))+(isnull(@BucketOffshore4,0))+(isnull(@BucketOffshore5,0))+(isnull(@BucketOffshore6,0))+(isnull(@BucketOffshore7,0))+(isnull(@BucketOffshore8,0))+(isnull(@BucketOffshore9,0))+(isnull(@BucketOffshore10,0))+(isnull(@BucketOffshore11,0))+(isnull(@BucketOffshore12,0)))/@FTEFactorOffshore +
		((isnull(@BucketFTPOffshore1,0))+(isnull(@BucketFTPOffshore2,0))+(isnull(@BucketFTPOffshore3,0))+(isnull(@BucketFTPOffshore4,0))+(isnull(@BucketFTPOffshore5,0))+(isnull(@BucketFTPOffshore6,0))+(isnull(@BucketFTPOffshore7,0))+(isnull(@BucketFTPOffshore8,0))+(isnull(@BucketFTPOffshore9,0))+(isnull(@BucketFTPOffshore10,0))+(isnull(@BucketFTPOffshore11,0))+(isnull(@BucketFTPOffshore12,0)))/@FTPBillingRate,				
		TotalFTEs_hover = ((isnull(@BucketOnshore1,0))+(isnull(@BucketOnshore2,0))+(isnull(@BucketOnshore3,0))+(isnull(@BucketOnshore4,0))+(isnull(@BucketOnshore5,0))+(isnull(@BucketOnshore6,0))+(isnull(@BucketOnshore7,0))+(isnull(@BucketOnshore8,0))+(isnull(@BucketOnshore9,0))+(isnull(@BucketOnshore10,0))+(isnull(@BucketOnshore11,0))+(isnull(@BucketOnshore12,0)))/@FTEFactorOnshore +	
		((isnull(@BucketFTPOnshore1,0))+(isnull(@BucketFTPOnshore2,0))+(isnull(@BucketFTPOnshore3,0))+(isnull(@BucketFTPOnshore4,0))+(isnull(@BucketFTPOnshore5,0))+(isnull(@BucketFTPOnshore6,0))+(isnull(@BucketFTPOnshore7,0))+(isnull(@BucketFTPOnshore8,0))+(isnull(@BucketFTPOnshore9,0))+(isnull(@BucketFTPOnshore10,0))+(isnull(@BucketFTPOnshore11,0))+(isnull(@BucketFTPOnshore12,0)))/@FTPBillingRate +	
		((isnull(@BucketOffshore1,0))+(isnull(@BucketOffshore2,0))+(isnull(@BucketOffshore3,0))+(isnull(@BucketOffshore4,0))+(isnull(@BucketOffshore5,0))+(isnull(@BucketOffshore6,0))+(isnull(@BucketOffshore7,0))+(isnull(@BucketOffshore8,0))+(isnull(@BucketOffshore9,0))+(isnull(@BucketOffshore10,0))+(isnull(@BucketOffshore11,0))+(isnull(@BucketOffshore12,0)))/@FTEFactorOffshore +
		((isnull(@BucketFTPOffshore1,0))+(isnull(@BucketFTPOffshore2,0))+(isnull(@BucketFTPOffshore3,0))+(isnull(@BucketFTPOffshore4,0))+(isnull(@BucketFTPOffshore5,0))+(isnull(@BucketFTPOffshore6,0))+(isnull(@BucketFTPOffshore7,0))+(isnull(@BucketFTPOffshore8,0))+(isnull(@BucketFTPOffshore9,0))+(isnull(@BucketFTPOffshore10,0))+(isnull(@BucketFTPOffshore11,0))+(isnull(@BucketFTPOffshore12,0)))/@FTPBillingRate
	where RecNumber = 10 and TaskCategory = @CurTaskCategoryCode

FETCH NEXT FROM TaskCategory_cursor INTO @CurTaskCategoryCode
END
CLOSE TaskCategory_cursor
DEALLOCATE TaskCategory_cursor

-----------------------------------------------------------------------------------------------------------------
			
-- Populate Grand TOTAL information from Rec Type 10  by Month (vertical add up)
DECLARE @Total_Bucket1 decimal(12,2), @Total_Bucket2 decimal(12,2), @Total_Bucket3 decimal(12,2), @Total_Bucket4 decimal(12,2), @Total_Bucket5 decimal(12,2), @Total_Bucket6 decimal(12,2), @Total_Bucket7 decimal(12,2), @Total_Bucket8 decimal(12,2),@Total_Bucket9 decimal(12,2), @Total_bucket10 decimal(12,2), @Total_bucket11 decimal(12,2),@Total_bucket12 decimal(12,2)
select @Total_Bucket1 = sum(isnull(Bucket1_Hours,0)), @Total_Bucket2 = sum(isnull(Bucket2_Hours,0)), @Total_Bucket3 = sum(isnull(Bucket3_Hours,0)), @Total_Bucket4 = sum(isnull(Bucket4_Hours,0)), @Total_Bucket5 = sum(isnull(Bucket5_Hours,0)), @Total_Bucket6 = sum(isnull(Bucket6_Hours,0)), @Total_Bucket7 = sum(isnull(Bucket7_Hours,0)), @Total_Bucket8 = sum(isnull(Bucket8_Hours,0)), @Total_Bucket9 = sum(isnull(Bucket9_Hours,0)), @Total_Bucket10 = sum(isnull(Bucket10_Hours,0)), @Total_Bucket11 = sum(isnull(Bucket11_Hours,0)), @Total_Bucket12 = sum(isnull(Bucket12_Hours,0))
from #TEMP_OUT where RecNumber = 10

DECLARE @Total_FTE1 decimal(5,2), @Total_FTE2 decimal(5,2), @Total_FTE3 decimal(5,2), @Total_FTE4 decimal(5,2), @Total_FTE5 decimal(5,2), @Total_FTE6 decimal(5,2), @Total_FTE7 decimal(5,2), @Total_FTE8 decimal(5,2), @Total_FTE9 decimal(5,2), @Total_FTE10 decimal(5,2), @Total_FTE11 decimal(5,2), @Total_FTE12 decimal(5,2)
select @Total_FTE1 = sum(isnull(Bucket1_FTEs,0)), @Total_FTE2 = sum(isnull(Bucket2_FTEs,0)), @Total_FTE3 = sum(isnull(Bucket3_FTEs,0)), @Total_FTE4 = sum(isnull(Bucket4_FTEs,0)), @Total_FTE5 = sum(isnull(Bucket5_FTEs,0)), @Total_FTE6 = sum(isnull(Bucket6_FTEs,0)), @Total_FTE7 = sum(isnull(Bucket7_FTEs,0)), @Total_FTE8 = sum(isnull(Bucket8_FTEs,0)), @Total_FTE9 = sum(isnull(Bucket9_FTEs,0)), @Total_FTE10 = sum(isnull(Bucket10_FTEs,0)), @Total_FTE11 = sum(isnull(Bucket11_FTEs,0)), @Total_FTE12 = sum(isnull(Bucket12_FTEs,0))
from #TEMP_OUT where RecNumber = 10

DECLARE @Total_FTE1_hover decimal(15,7), @Total_FTE2_hover decimal(15,7), @Total_FTE3_hover decimal(15,7), @Total_FTE4_hover decimal(15,7), @Total_FTE5_hover decimal(15,7), @Total_FTE6_hover decimal(15,7), @Total_FTE7_hover decimal(15,7), @Total_FTE8_hover decimal(15,7), @Total_FTE9_hover decimal(15,7), @Total_FTE10_hover decimal(15,7), @Total_FTE11_hover decimal(15,7), @Total_FTE12_hover decimal(15,7)
select @Total_FTE1_hover = sum(isnull(Bucket1_FTEs_hover,0)), @Total_FTE2_hover = sum(isnull(Bucket2_FTEs_hover,0)), @Total_FTE3_hover = sum(isnull(Bucket3_FTEs_hover,0)), @Total_FTE4_hover = sum(isnull(Bucket4_FTEs_hover,0)), @Total_FTE5_hover = sum(isnull(Bucket5_FTEs_hover,0)), @Total_FTE6_hover = sum(isnull(Bucket6_FTEs_hover,0)), @Total_FTE7_hover = sum(isnull(Bucket7_FTEs_hover,0)), @Total_FTE8_hover = sum(isnull(Bucket8_FTEs_hover,0)), @Total_FTE9_hover = sum(isnull(Bucket9_FTEs_hover,0)), @Total_FTE10_hover = sum(isnull(Bucket10_FTEs_hover,0)), @Total_FTE11_hover = sum(isnull(Bucket11_FTEs_hover,0)), @Total_FTE12_hover = sum(isnull(Bucket12_FTEs_hover,0))
from #TEMP_OUT where RecNumber = 10

-- Update Grand total Rec Type = 0
update #TEMP_OUT set
	Bucket1_Hours = isnull(@Total_Bucket1,0), Bucket1_FTEs = isnull(@Total_FTE1,0), Bucket1_FTEs_hover = isnull(@Total_FTE1_hover,0),	
	Bucket2_Hours = isnull(@Total_Bucket2,0), Bucket2_FTEs = isnull(@Total_FTE2,0), Bucket2_FTEs_hover = isnull(@Total_FTE2_hover,0),
	Bucket3_Hours = isnull(@Total_Bucket3,0), Bucket3_FTEs = isnull(@Total_FTE3,0), Bucket3_FTEs_hover = isnull(@Total_FTE3_hover,0),
	Bucket4_Hours = isnull(@Total_Bucket4,0), Bucket4_FTEs = isnull(@Total_FTE4,0), Bucket4_FTEs_hover = isnull(@Total_FTE4_hover,0),
	Bucket5_Hours = isnull(@Total_Bucket5,0), Bucket5_FTEs = isnull(@Total_FTE5,0), Bucket5_FTEs_hover = isnull(@Total_FTE5_hover,0),
	Bucket6_Hours = isnull(@Total_Bucket6,0), Bucket6_FTEs = isnull(@Total_FTE6,0), Bucket6_FTEs_hover = isnull(@Total_FTE6_hover,0),
	Bucket7_Hours = isnull(@Total_Bucket7,0), Bucket7_FTEs = isnull(@Total_FTE7,0), Bucket7_FTEs_hover = isnull(@Total_FTE7_hover,0),
	Bucket8_Hours = isnull(@Total_Bucket8,0), Bucket8_FTEs = isnull(@Total_FTE8,0), Bucket8_FTEs_hover = isnull(@Total_FTE8_hover,0),
	Bucket9_Hours = isnull(@Total_Bucket9,0), Bucket9_FTEs = isnull(@Total_FTE9,0), Bucket9_FTEs_hover = isnull(@Total_FTE9_hover,0),
	Bucket10_Hours = isnull(@Total_Bucket10,0), Bucket10_FTEs = isnull(@Total_FTE10,0), Bucket10_FTEs_hover = isnull(@Total_FTE10_hover,0),
	Bucket11_Hours = isnull(@Total_Bucket11,0), Bucket11_FTEs = isnull(@Total_FTE11,0), Bucket11_FTEs_hover = isnull(@Total_FTE11_hover,0),
	Bucket12_Hours = isnull(@Total_Bucket12,0), Bucket12_FTEs = isnull(@Total_FTE12,0), Bucket12_FTEs_hover = isnull(@Total_FTE12_hover,0),
	TotalHours = (isnull(@Total_Bucket1,0))+(isnull(@Total_Bucket2,0))+(isnull(@Total_Bucket3,0))+(isnull(@Total_Bucket4,0))+(isnull(@Total_Bucket5,0))+(isnull(@Total_Bucket6,0))+(isnull(@Total_Bucket7,0))+(isnull(@Total_Bucket8,0))+(isnull(@Total_Bucket9,0))+(isnull(@Total_bucket10,0))+(isnull(@Total_bucket11,0))+(isnull(@Total_bucket12,0)),
	TotalFTEs = ( (isnull(@Total_FTE1,0)) + (isnull(@Total_FTE2,0)) +	(isnull(@Total_FTE3,0)) + (isnull(@Total_FTE4,0)) + (isnull(@Total_FTE5,0)) + (isnull(@Total_FTE6,0)) +	(isnull(@Total_FTE7,0)) + (isnull(@Total_FTE8,0)) + (isnull(@Total_FTE9,0)) + (isnull(@Total_FTE10,0)) +	(isnull(@Total_FTE11,0)) + (isnull(@Total_FTE12,0)) ),
	TotalFTEs_hover = ( (isnull(@Total_FTE1_hover,0)) + (isnull(@Total_FTE2_hover,0)) + (isnull(@Total_FTE3_hover,0)) + (isnull(@Total_FTE4_hover,0)) + (isnull(@Total_FTE5_hover,0)) + (isnull(@Total_FTE6_hover,0)) + (isnull(@Total_FTE7_hover,0)) + (isnull(@Total_FTE8_hover,0)) + (isnull(@Total_FTE9_hover,0)) + (isnull(@Total_FTE10_hover,0)) + (isnull(@Total_FTE11_hover,0)) + (isnull(@Total_FTE12_hover,0)) )
where RecNumber = 0

--select * from #TEMP_OUT

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------






-- Declare common variables.
DECLARE @YTD_Table varchar(50), @SQL_statement varchar(1000), @row_count int
DECLARE @CurProgramGroup varchar(100), @CurProgramGroupTotal decimal(10,2), @CurProg_GroupID int, @CurProgram varchar(100), @CurCOBusinessLead varchar(100), @CurProgramID int, @CurAFEDesc varchar(100), @CurAFE_DescID int, @CurTaskCatCode varchar(100)
DECLARE @CurYear int, @CurMonth int, @CurHours decimal (10,2), @bucket_nbr int, @FTPBillingRate decimal(10,2), @FTEFactorOnshore decimal(5,2), @FTEFactorOffshore decimal(5,2), @BillableDays int
declare @DateFrom datetime

-- Get the FTE Billing hours for FTP records and set the FTE rate.
select @CurYear = datepart(year, @DateFrom) 
select @CurMonth = datepart(month, @DateFrom) 
select @BillableDays = BillableDays from piv_reports..CO_PTD_Calendar where Year = @CurYear and Month = @CurMonth

if @BillableDays > 0
	begin
	set @FTPBillingRate = 8 * @BillableDays
	end
else
	begin
	set @FTPBillingRate = '143.5'
	end

--Set the FTE rate for onshore and offshore (non FTP).
set @FTEFactorOnshore = '149'
set @FTEFactorOffshore = '143.5'

--------------------------------------------------------------------------------
-- Open the Programme Group Cursor		
--------------------------------------------------------------------------------
DECLARE ProgrammeGroup_cursor CURSOR FOR 
	select  distinct ProgramGroup, Prog_GroupID from #TEMP_IN order by ProgramGroup
OPEN ProgrammeGroup_cursor
FETCH NEXT FROM ProgrammeGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID
WHILE @@FETCH_STATUS = 0
BEGIN
	insert #TEMP_OUT (RecNumber, RecType, Division, RecTypeID)
	select 20, 'Program Group', @CurProgramGroup, @CurProg_GroupID

	--------------------------------------------------------------------------------
	-- Open the Programme  Cursor		
	--------------------------------------------------------------------------------
	DECLARE Programme_cursor CURSOR FOR 
   		select  distinct Program, ProgramID from #TEMP_IN where Prog_GroupID = @CurProg_GroupID order by Program
	OPEN Programme_cursor
	FETCH NEXT FROM Programme_cursor INTO @CurProgram, @CurProgramID
	WHILE @@FETCH_STATUS = 0
	BEGIN
		insert #TEMP_OUT (RecNumber, RecType, Division, RecDesc, RecTypeID)
		select 25, 'Program ', @CurProgram, Null, @CurProgramID

		--------------------------------------------------------------------------------
		-- Open the AFE Description  Cursor		
		--------------------------------------------------------------------------------
		DECLARE AFEDesc_cursor CURSOR FOR 
   			select distinct AFEDesc, AFE_DescID, COBUsinessLead from #TEMP_IN
			where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID order by AFEDesc
		OPEN AFEDesc_cursor
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
		WHILE @@FETCH_STATUS = 0
		BEGIN
			insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID,Prog_GroupID, ProgramID)
			select 30,  'AFE Desc ', @CurAFEDesc, @CurAFE_DescID, @CurProg_GroupID, @CurProgramID

			--------------------------------------------------------------------------------
			-- Open the Task Category Code  Cursor		
			--------------------------------------------------------------------------------
			DECLARE TaskCatCode_cursor CURSOR FOR 
   				select distinct TaskCategoryCode from #TEMP_IN
				where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID order by TaskCategoryCode
			OPEN TaskCatCode_cursor
			FETCH NEXT FROM TaskCatCode_cursor INTO @CurTaskCatCode
			WHILE @@FETCH_STATUS = 0
			BEGIN
	  			insert #TEMP_OUT (RecNumber, RecType,  TaskCategory, RecTypeID,Prog_GroupID, ProgramID)
				select 40, 'Task Category Code ', @CurTaskCatCode, @CurAFE_DescID, @CurProg_GroupID, @CurProgramID

				---------------------------------------------------------------------------------------------------
				-- sum up the ONSHORE months for this Task Category code build out the 12 month buckets			---
				---------------------------------------------------------------------------------------------------
				DECLARE Month_cursor_onshore CURSOR FOR 
					select YYYY_Year, MM_Month, sum(hours) as TotalHours from #TEMP_IN
					where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and TaskCategoryCode = @CurTaskCatCode and NewBillingType <> 'FTP Staff Aug' and Onshore = 1 group by YYYY_Year, MM_Month

					--Declare variables for Buckets
					DECLARE @BucketOnshore1 decimal(12,2), @BucketOnshore2 decimal(12,2), @BucketOnshore3 decimal(12,2), @BucketOnshore4 decimal(12,2),@BucketOnshore5 decimal(12,2), @BucketOnshore6 decimal(12,2), @BucketOnshore7 decimal(12,2), @BucketOnshore8 decimal(12,2),@BucketOnshore9 decimal(12,2), @bucketOnshore10 decimal(12,2), @bucketOnshore11 decimal(12,2),@bucketOnshore12 decimal(12,2)
        	
					-- Clear out all Buckets to Zero 
					set @BucketOnshore1 = 0 set @BucketOnshore2 = 0 set @BucketOnshore3 = 0 set @BucketOnshore4 = 0  set @BucketOnshore5 = 0  set @BucketOnshore6 = 0  
					set @BucketOnshore7 = 0 set @BucketOnshore8 = 0 set @BucketOnshore9 = 0 set @bucketOnshore10 = 0 set @bucketOnshore11 = 0 set @bucketOnshore12 = 0
				OPEN Month_cursor_onshore
				FETCH NEXT FROM Month_cursor_onshore INTO @CurYear, @CurMonth, @CurHours
				WHILE @@FETCH_STATUS = 0
				BEGIN
         			-- determing the bucket that this month / year goes into
         			select @bucket_nbr = bucket_nbr from #Temp_Bucket where YYYY_Year = @CurYear and MM_Month = @CurMonth
					
					-- build output buckets
					if @bucket_nbr = 1 
						begin
						set @BucketOnshore1 = @CurHours
						end
					if @bucket_nbr = 2 
						begin
						set @BucketOnshore2 = @CurHours
						end
					if @bucket_nbr = 3 
						begin
						set @BucketOnshore3 = @CurHours
						end
					if @bucket_nbr = 4 
						begin
						set @BucketOnshore4 = @CurHours
						end
					if @bucket_nbr = 5 
						begin
						set @BucketOnshore5 = @CurHours
						end
					if @bucket_nbr = 6 
						begin
						set @BucketOnshore6 = @CurHours
						end
					if @bucket_nbr = 7 
						begin
						set @BucketOnshore7 = @CurHours
						end
					if @bucket_nbr = 8 
						begin
						set @BucketOnshore8 = @CurHours
						end
					if @bucket_nbr = 9 
						begin
						set @BucketOnshore9 = @CurHours
						end
					if @bucket_nbr = 10 
						begin
						set @bucketOnshore10 = @CurHours
						end
					if @bucket_nbr = 11 
					begin
						set @bucketOnshore11 = @CurHours
						end
					if @bucket_nbr = 12 
					begin
						set @bucketOnshore12 = @CurHours
					end		
				FETCH NEXT FROM Month_cursor_onshore INTO @CurYear, @CurMonth, @CurHours
				END
				CLOSE Month_cursor_onshore
				DEALLOCATE Month_cursor_onshore
	
                                
   				---------------------------------------------------------------------------------------------------
				-- sum up the FTP ONSHORE months for this Task Category code build out the 12 month buckets		---
				---------------------------------------------------------------------------------------------------
				DECLARE Month_cursor_FTPonshore CURSOR FOR 
					select YYYY_Year, MM_Month, sum(hours) as TotalHours from #TEMP_IN
					where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and TaskCategoryCode = @CurTaskCatCode and NewBillingType = 'FTP Staff Aug' and Onshore = 1 group by YYYY_Year, MM_Month

					--Declare variables for Buckets
					DECLARE @BucketFTPOnshore1 decimal(12,2), @BucketFTPOnshore2 decimal(12,2), @BucketFTPOnshore3 decimal(12,2), @BucketFTPOnshore4 decimal(12,2),@BucketFTPOnshore5 decimal(12,2), @BucketFTPOnshore6 decimal(12,2), @BucketFTPOnshore7 decimal(12,2), @BucketFTPOnshore8 decimal(12,2),@BucketFTPOnshore9 decimal(12,2), @bucketFTPOnshore10 decimal(12,2), @bucketFTPOnshore11 decimal(12,2),@bucketFTPOnshore12 decimal(12,2)
        	
					-- Clear out all Buckets to Zero 
					set @BucketFTPOnshore1 =0 set @BucketFTPOnshore2 = 0 set @BucketFTPOnshore3 =0 set @BucketFTPOnshore4 = 0  set @BucketFTPOnshore5 = 0 set @BucketFTPOnshore6 = 0  
					set @BucketFTPOnshore7 =0 set @BucketFTPOnshore8 = 0 set @BucketFTPOnshore9 =0 set @bucketFTPOnshore10 = 0 set @bucketFTPOnshore11 =0 set @bucketFTPOnshore12 = 0
				OPEN Month_cursor_FTPonshore
				FETCH NEXT FROM Month_cursor_FTPonshore INTO @CurYear, @CurMonth, @CurHours
				WHILE @@FETCH_STATUS = 0
				BEGIN	
					-- determing the bucket that this month / year goes into
					select @bucket_nbr =  bucket_nbr from #Temp_Bucket where YYYY_Year = @CurYear and MM_Month = @CurMonth
			
					-- build output buckets
					if @bucket_nbr = 1 
						begin
						set @BucketFTPOnshore1 = @CurHours
						end
					if @bucket_nbr = 2 
						begin
						set @BucketFTPOnshore2 = @CurHours
						end
					if @bucket_nbr = 3 
						begin
						set @BucketFTPOnshore3 = @CurHours
						end
					if @bucket_nbr = 4 
						begin
						set @BucketFTPOnshore4 = @CurHours
						end
					if @bucket_nbr = 5 
						begin
						set @BucketFTPOnshore5 = @CurHours
						end
					if @bucket_nbr = 6 
						begin
						set @BucketFTPOnshore6 = @CurHours
						end
					if @bucket_nbr = 7 
						begin
						set @BucketFTPOnshore7 = @CurHours
						end
					if @bucket_nbr = 8 
						begin
						set @BucketFTPOnshore8 = @CurHours
						end
					if @bucket_nbr = 9 
						begin
						set @BucketFTPOnshore9 = @CurHours
						end
					if @bucket_nbr = 10 
						begin
						set @BucketFTPOnshore10 = @CurHours
						end
					if @bucket_nbr = 11 
					   begin
						set @BucketFTPOnshore11 = @CurHours
						end
					if @bucket_nbr = 12 
						begin
						set @BucketFTPOnshore12 = @CurHours
						end				
				FETCH NEXT FROM Month_cursor_FTPonshore INTO @CurYear, @CurMonth, @CurHours
				END
				CLOSE Month_cursor_FTPonshore
				DEALLOCATE Month_cursor_FTPonshore					

				---------------------------------------------------------------------------------------------------
				-- sum up the OFFSHORE months for this Task Category code build out the 12 month buckets		---
				---------------------------------------------------------------------------------------------------
				DECLARE Month_cursor_offshore CURSOR FOR 
					select YYYY_Year, MM_Month, sum(hours) as TotalHours from #TEMP_IN
					where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and TaskCategoryCode = @CurTaskCatCode and NewBillingType <> 'FTP Staff Aug' and Offshore = 1 group by YYYY_Year, MM_Month
             
   					--Declare variables for Buckets
					DECLARE @BucketOffshore1 decimal(12,2), @BucketOffshore2 decimal(12,2), @BucketOffshore3 decimal(12,2), @BucketOffshore4 decimal(12,2),@BucketOffshore5 decimal(12,2), @BucketOffshore6 decimal(12,2), @BucketOffshore7 decimal(12,2), @BucketOffshore8 decimal(12,2),@BucketOffshore9 decimal(12,2), @bucketOffshore10 decimal(12,2), @bucketOffshore11 decimal(12,2),@bucketOffshore12 decimal(12,2)
		
					-- Clear out all Buckets to Zero 
					set @BucketOffshore1 = 0 set @BucketOffshore2 = 0 set @BucketOffshore3 = 0 set @BucketOffshore4 = 0  set @BucketOffshore5 = 0  set @BucketOffshore6 = 0  
					set @BucketOffshore7 = 0 set @BucketOffshore8 = 0 set @BucketOffshore9 = 0 set @bucketOffshore10 = 0 set @bucketOffshore11 = 0 set @bucketOffshore12 = 0
				OPEN Month_cursor_offshore
				FETCH NEXT FROM Month_cursor_offshore INTO @CurYear, @CurMonth, @CurHours
				WHILE @@FETCH_STATUS = 0
				BEGIN
					-- determing the bucket that this month / year goes into
					select @bucket_nbr =  bucket_nbr from #Temp_Bucket where YYYY_Year = @CurYear and MM_Month = @CurMonth

					-- build output buckets
					if @bucket_nbr = 1 
						begin
						set @BucketOffshore1 = @CurHours
						end
					if @bucket_nbr = 2 
						begin
						set @BucketOffshore2 = @CurHours				
						end
					if @bucket_nbr = 3 
						begin
						set @BucketOffshore3 = @CurHours
						end
					if @bucket_nbr = 4 
						begin
						set @BucketOffshore4 = @CurHours
						end
					if @bucket_nbr = 5 
						begin
						set @BucketOffshore5 = @CurHours
						end
					if @bucket_nbr = 6 
						begin
						set @BucketOffshore6 = @CurHours
						end
					if @bucket_nbr = 7 
						begin
						set @BucketOffshore7 = @CurHours
						end
					if @bucket_nbr = 8 
						begin
						set @BucketOffshore8 = @CurHours
						end
					if @bucket_nbr = 9 
						begin
						set @BucketOffshore9 = @CurHours
						end
					if @bucket_nbr = 10 
						begin
						set @bucketOffshore10 = @CurHours
						end
					if @bucket_nbr = 11 
						begin
						set @bucketOffshore11 = @CurHours
						end
					if @bucket_nbr = 12 
						begin
						set @bucketOffshore12 = @CurHours
						end												
				FETCH NEXT FROM Month_cursor_offshore INTO @CurYear, @CurMonth, @CurHours
				END
				CLOSE Month_cursor_offshore
				DEALLOCATE Month_cursor_offshore
					
					
				---------------------------------------------------------------------------------------------------
				-- sum up the FTP OFFSHORE months for this Task Category code build out the 12 month buckets	---
				---------------------------------------------------------------------------------------------------
				DECLARE Month_cursor_FTPoffshore CURSOR FOR 
					select YYYY_Year, MM_Month, sum(hours) as TotalHours from #TEMP_IN
					where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and TaskCategoryCode = @CurTaskCatCode and NewBillingType = 'FTP Staff Aug' and Offshore = 1 group by YYYY_Year, MM_Month

 					--Declare variables for Buckets
					DECLARE @BucketFTPOffshore1 decimal(12,2), @BucketFTPOffshore2 decimal(12,2), @BucketFTPOffshore3 decimal(12,2), @BucketFTPOffshore4 decimal(12,2),@BucketFTPOffshore5 decimal(12,2), @BucketFTPOffshore6 decimal(12,2), @BucketFTPOffshore7 decimal(12,2), @BucketFTPOffshore8 decimal(12,2),@BucketFTPOffshore9 decimal(12,2), @bucketFTPOffshore10 decimal(12,2), @bucketFTPOffshore11 decimal(12,2),@bucketFTPOffshore12 decimal(12,2)
	
    				-- Clear out all Buckets to Zero 
					set @BucketFTPOffshore1 =0 set @BucketFTPOffshore2 = 0 set @BucketFTPOffshore3 =0 set @BucketFTPOffshore4 = 0  set @BucketFTPOffshore5 =0  set @BucketFTPOffshore6 = 0  
					set @BucketFTPOffshore7 =0 set @BucketFTPOffshore8 = 0 set @BucketFTPOffshore9 =0 set @bucketFTPOffshore10 = 0 set @bucketFTPOffshore11 =0 set @bucketFTPOffshore12 = 0
				OPEN Month_cursor_FTPoffshore
				FETCH NEXT FROM Month_cursor_FTPoffshore INTO @CurYear, @CurMonth, @CurHours
				WHILE @@FETCH_STATUS = 0
				BEGIN
					-- determing the bucket that this month / year goes into
					select @bucket_nbr =  bucket_nbr from #Temp_Bucket where YYYY_Year = @CurYear and MM_Month = @CurMonth

					-- build output buckets
					if @bucket_nbr = 1 
						begin
						set @BucketFTPOffshore1 = @CurHours
						end
					if @bucket_nbr = 2 
						begin
						set @BucketFTPOffshore2 = @CurHours				
						end
					if @bucket_nbr = 3 
						begin
						set @BucketFTPOffshore3 = @CurHours
						end
					if @bucket_nbr = 4 
						begin
						set @BucketFTPOffshore4 = @CurHours
						end
					if @bucket_nbr = 5 
						begin
						set @BucketFTPOffshore5 = @CurHours
						end
					if @bucket_nbr = 6 
						begin
						set @BucketFTPOffshore6 = @CurHours
						end
					if @bucket_nbr = 7 
						begin
						set @BucketFTPOffshore7 = @CurHours
						end
					if @bucket_nbr = 8 
						begin
						set @BucketFTPOffshore8 = @CurHours
						end
					if @bucket_nbr = 9 
						begin
						set @BucketFTPOffshore9 = @CurHours
						end
					if @bucket_nbr = 10 
						begin
						set @BucketFTPOffshore10 = @CurHours
						end
					if @bucket_nbr = 11 
					   begin
						set @BucketFTPOffshore11 = @CurHours
						end
					if @bucket_nbr = 12 
						begin
						set @BucketFTPOffshore12 = @CurHours
						end						
				FETCH NEXT FROM Month_cursor_FTPoffshore INTO @CurYear, @CurMonth, @CurHours
				END
				CLOSE Month_cursor_FTPoffshore
				DEALLOCATE Month_cursor_FTPoffshore				


				--------------------------------------------------------------------------------------------------
				-- Update the TEMP_OUT table Task Category Code Record containing all of the 12 buckets totals
				update #TEMP_OUT set
					Bucket1_Hours = isnull(@BucketOnshore1,0) + isnull(@BucketFTPOnshore1,0) + isnull(@BucketOffshore1,0) + isnull(@BucketFTPOffshore1,0), Bucket1_FTEs = isnull(@BucketOnshore1,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore1,0)/@FTPBillingRate + isnull(@BucketOffshore1,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore1,0)/@FTPBillingRate, Bucket1_FTEs_hover = isnull(@BucketOnshore1,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore1,0)/@FTPBillingRate + isnull(@BucketOffshore1,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore1,0)/@FTPBillingRate,	 		
					Bucket2_Hours = isnull(@BucketOnshore2,0) + isnull(@BucketFTPOnshore2,0) + isnull(@BucketOffshore2,0) + isnull(@BucketFTPOffshore2,0), Bucket2_FTEs = isnull(@BucketOnshore2,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore2,0)/@FTPBillingRate + isnull(@BucketOffshore2,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore2,0)/@FTPBillingRate, Bucket2_FTEs_hover = isnull(@BucketOnshore2,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore2,0)/@FTPBillingRate + isnull(@BucketOffshore2,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore2,0)/@FTPBillingRate,	 		
					Bucket3_Hours = isnull(@BucketOnshore3,0) + isnull(@BucketFTPOnshore3,0) + isnull(@BucketOffshore3,0) + isnull(@BucketFTPOffshore3,0), Bucket3_FTEs = isnull(@BucketOnshore3,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore3,0)/@FTPBillingRate + isnull(@BucketOffshore3,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore3,0)/@FTPBillingRate, Bucket3_FTEs_hover = isnull(@BucketOnshore3,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore3,0)/@FTPBillingRate + isnull(@BucketOffshore3,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore3,0)/@FTPBillingRate,	 		
					Bucket4_Hours = isnull(@BucketOnshore4,0) + isnull(@BucketFTPOnshore4,0) + isnull(@BucketOffshore4,0) + isnull(@BucketFTPOffshore4,0), Bucket4_FTEs = isnull(@BucketOnshore4,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore4,0)/@FTPBillingRate + isnull(@BucketOffshore4,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore4,0)/@FTPBillingRate, Bucket4_FTEs_hover = isnull(@BucketOnshore4,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore4,0)/@FTPBillingRate + isnull(@BucketOffshore4,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore4,0)/@FTPBillingRate,	 		
					Bucket5_Hours = isnull(@BucketOnshore5,0) + isnull(@BucketFTPOnshore5,0) + isnull(@BucketOffshore5,0) + isnull(@BucketFTPOffshore5,0), Bucket5_FTEs = isnull(@BucketOnshore5,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore5,0)/@FTPBillingRate + isnull(@BucketOffshore5,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore5,0)/@FTPBillingRate, Bucket5_FTEs_hover = isnull(@BucketOnshore5,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore5,0)/@FTPBillingRate + isnull(@BucketOffshore5,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore5,0)/@FTPBillingRate,	 		
					Bucket6_Hours = isnull(@BucketOnshore6,0) + isnull(@BucketFTPOnshore6,0) + isnull(@BucketOffshore6,0) + isnull(@BucketFTPOffshore6,0), Bucket6_FTEs = isnull(@BucketOnshore6,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore6,0)/@FTPBillingRate + isnull(@BucketOffshore6,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore6,0)/@FTPBillingRate, Bucket6_FTEs_hover = isnull(@BucketOnshore6,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore6,0)/@FTPBillingRate + isnull(@BucketOffshore6,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore6,0)/@FTPBillingRate,	 		
					Bucket7_Hours = isnull(@BucketOnshore7,0) + isnull(@BucketFTPOnshore7,0) + isnull(@BucketOffshore7,0) + isnull(@BucketFTPOffshore7,0), Bucket7_FTEs = isnull(@BucketOnshore7,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore7,0)/@FTPBillingRate + isnull(@BucketOffshore7,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore7,0)/@FTPBillingRate, Bucket7_FTEs_hover = isnull(@BucketOnshore7,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore7,0)/@FTPBillingRate + isnull(@BucketOffshore7,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore7,0)/@FTPBillingRate,	 		
					Bucket8_Hours = isnull(@BucketOnshore8,0) + isnull(@BucketFTPOnshore8,0) + isnull(@BucketOffshore8,0) + isnull(@BucketFTPOffshore8,0), Bucket8_FTEs = isnull(@BucketOnshore8,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore8,0)/@FTPBillingRate + isnull(@BucketOffshore8,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore8,0)/@FTPBillingRate, Bucket8_FTEs_hover = isnull(@BucketOnshore8,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore8,0)/@FTPBillingRate + isnull(@BucketOffshore8,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore8,0)/@FTPBillingRate,	 		
					Bucket9_Hours = isnull(@BucketOnshore9,0) + isnull(@BucketFTPOnshore9,0) + isnull(@BucketOffshore9,0) + isnull(@BucketFTPOffshore9,0), Bucket9_FTEs = isnull(@BucketOnshore9,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore9,0)/@FTPBillingRate + isnull(@BucketOffshore9,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore9,0)/@FTPBillingRate, Bucket9_FTEs_hover = isnull(@BucketOnshore9,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore9,0)/@FTPBillingRate + isnull(@BucketOffshore9,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore9,0)/@FTPBillingRate,	 		
					Bucket10_Hours = isnull(@BucketOnshore10,0) + isnull(@BucketFTPOnshore10,0) + isnull(@BucketOffshore10,0) + isnull(@BucketFTPOffshore10,0), Bucket10_FTEs = isnull(@BucketOnshore10,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore10,0)/@FTPBillingRate + isnull(@BucketOffshore10,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore10,0)/@FTPBillingRate,	Bucket10_FTEs_hover = isnull(@BucketOnshore10,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore10,0)/@FTPBillingRate + isnull(@BucketOffshore10,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore10,0)/@FTPBillingRate,	 		
					Bucket11_Hours = isnull(@BucketOnshore11,0) + isnull(@BucketFTPOnshore11,0) + isnull(@BucketOffshore11,0) + isnull(@BucketFTPOffshore11,0), Bucket11_FTEs = isnull(@BucketOnshore11,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore11,0)/@FTPBillingRate + isnull(@BucketOffshore11,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore11,0)/@FTPBillingRate,	Bucket11_FTEs_hover = isnull(@BucketOnshore11,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore11,0)/@FTPBillingRate + isnull(@BucketOffshore11,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore11,0)/@FTPBillingRate,	 	
					Bucket12_Hours = isnull(@BucketOnshore12,0) + isnull(@BucketFTPOnshore12,0) + isnull(@BucketOffshore12,0) + isnull(@BucketFTPOffshore12,0), Bucket12_FTEs = isnull(@BucketOnshore12,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore12,0)/@FTPBillingRate + isnull(@BucketOffshore12,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore12,0)/@FTPBillingRate,	Bucket12_FTEs_hover = isnull(@BucketOnshore12,0)/@FTEFactorOnshore + isnull(@BucketFTPOnshore12,0)/@FTPBillingRate + isnull(@BucketOffshore12,0)/@FTEFactorOffshore + isnull(@BucketFTPOffshore12,0)/@FTPBillingRate,	 		
					TotalHours = (isnull(@BucketOnshore1,0))+(isnull(@BucketOnshore2,0))+(isnull(@BucketOnshore3,0))+(isnull(@BucketOnshore4,0))+(isnull(@BucketOnshore5,0))+(isnull(@BucketOnshore6,0))+(isnull(@BucketOnshore7,0))+(isnull(@BucketOnshore8,0))+(isnull(@BucketOnshore9,0))+(isnull(@BucketOnshore10,0))+(isnull(@BucketOnshore11,0))+(isnull(@BucketOnshore12,0)) + (isnull(@BucketFTPOnshore1,0))+(isnull(@BucketFTPOnshore2,0))+(isnull(@BucketFTPOnshore3,0))+(isnull(@BucketFTPOnshore4,0))+(isnull(@BucketFTPOnshore5,0))+(isnull(@BucketFTPOnshore6,0))+(isnull(@BucketFTPOnshore7,0))+(isnull(@BucketFTPOnshore8,0))+(isnull(@BucketFTPOnshore9,0))+(isnull(@BucketFTPOnshore10,0))+(isnull(@BucketFTPOnshore11,0))+(isnull(@BucketFTPOnshore12,0)) + (isnull(@BucketOffshore1,0))+(isnull(@BucketOffshore2,0))+(isnull(@BucketOffshore3,0))+(isnull(@BucketOffshore4,0))+(isnull(@BucketOffshore5,0))+(isnull(@BucketOffshore6,0))+(isnull(@BucketOffshore7,0))+(isnull(@BucketOffshore8,0))+(isnull(@BucketOffshore9,0))+(isnull(@BucketOffshore10,0))+(isnull(@BucketOffshore11,0))+(isnull(@BucketOffshore12,0)) + (isnull(@BucketFTPOffshore1,0))+(isnull(@BucketFTPOffshore2,0))+(isnull(@BucketFTPOffshore3,0))+(isnull(@BucketFTPOffshore4,0))+(isnull(@BucketFTPOffshore5,0))+(isnull(@BucketFTPOffshore6,0))+(isnull(@BucketFTPOffshore7,0))+(isnull(@BucketFTPOffshore8,0))+(isnull(@BucketFTPOffshore9,0))+(isnull(@BucketFTPOffshore10,0))+(isnull(@BucketFTPOffshore11,0))+(isnull(@BucketFTPOffshore12,0)),
					TotalFTEs = ((isnull(@BucketOnshore1,0))+(isnull(@BucketOnshore2,0))+(isnull(@BucketOnshore3,0))+(isnull(@BucketOnshore4,0))+(isnull(@BucketOnshore5,0))+(isnull(@BucketOnshore6,0))+(isnull(@BucketOnshore7,0))+(isnull(@BucketOnshore8,0))+(isnull(@BucketOnshore9,0))+(isnull(@BucketOnshore10,0))+(isnull(@BucketOnshore11,0))+(isnull(@BucketOnshore12,0)))/@FTEFactorOnshore + ((isnull(@BucketFTPOnshore1,0))+(isnull(@BucketFTPOnshore2,0))+(isnull(@BucketFTPOnshore3,0))+(isnull(@BucketFTPOnshore4,0))+(isnull(@BucketFTPOnshore5,0))+(isnull(@BucketFTPOnshore6,0))+(isnull(@BucketFTPOnshore7,0))+(isnull(@BucketFTPOnshore8,0))+(isnull(@BucketFTPOnshore9,0))+(isnull(@BucketFTPOnshore10,0))+(isnull(@BucketFTPOnshore11,0))+(isnull(@BucketFTPOnshore12,0)))/@FTPBillingRate +	((isnull(@BucketOffshore1,0))+(isnull(@BucketOffshore2,0))+(isnull(@BucketOffshore3,0))+(isnull(@BucketOffshore4,0))+(isnull(@BucketOffshore5,0))+(isnull(@BucketOffshore6,0))+(isnull(@BucketOffshore7,0))+(isnull(@BucketOffshore8,0))+(isnull(@BucketOffshore9,0))+(isnull(@BucketOffshore10,0))+(isnull(@BucketOffshore11,0))+(isnull(@BucketOffshore12,0)))/@FTEFactorOffshore + ((isnull(@BucketFTPOffshore1,0))+(isnull(@BucketFTPOffshore2,0))+(isnull(@BucketFTPOffshore3,0))+(isnull(@BucketFTPOffshore4,0))+(isnull(@BucketFTPOffshore5,0))+(isnull(@BucketFTPOffshore6,0))+(isnull(@BucketFTPOffshore7,0))+(isnull(@BucketFTPOffshore8,0))+(isnull(@BucketFTPOffshore9,0))+(isnull(@BucketFTPOffshore10,0))+(isnull(@BucketFTPOffshore11,0))+(isnull(@BucketFTPOffshore12,0)))/@FTPBillingRate,				
					TotalFTEs_hover = ((isnull(@BucketOnshore1,0))+(isnull(@BucketOnshore2,0))+(isnull(@BucketOnshore3,0))+(isnull(@BucketOnshore4,0))+(isnull(@BucketOnshore5,0))+(isnull(@BucketOnshore6,0))+(isnull(@BucketOnshore7,0))+(isnull(@BucketOnshore8,0))+(isnull(@BucketOnshore9,0))+(isnull(@BucketOnshore10,0))+(isnull(@BucketOnshore11,0))+(isnull(@BucketOnshore12,0)))/@FTEFactorOnshore + ((isnull(@BucketFTPOnshore1,0))+(isnull(@BucketFTPOnshore2,0))+(isnull(@BucketFTPOnshore3,0))+(isnull(@BucketFTPOnshore4,0))+(isnull(@BucketFTPOnshore5,0))+(isnull(@BucketFTPOnshore6,0))+(isnull(@BucketFTPOnshore7,0))+(isnull(@BucketFTPOnshore8,0))+(isnull(@BucketFTPOnshore9,0))+(isnull(@BucketFTPOnshore10,0))+(isnull(@BucketFTPOnshore11,0))+(isnull(@BucketFTPOnshore12,0)))/@FTPBillingRate +	((isnull(@BucketOffshore1,0))+(isnull(@BucketOffshore2,0))+(isnull(@BucketOffshore3,0))+(isnull(@BucketOffshore4,0))+(isnull(@BucketOffshore5,0))+(isnull(@BucketOffshore6,0))+(isnull(@BucketOffshore7,0))+(isnull(@BucketOffshore8,0))+(isnull(@BucketOffshore9,0))+(isnull(@BucketOffshore10,0))+(isnull(@BucketOffshore11,0))+(isnull(@BucketOffshore12,0)))/@FTEFactorOffshore + ((isnull(@BucketFTPOffshore1,0))+(isnull(@BucketFTPOffshore2,0))+(isnull(@BucketFTPOffshore3,0))+(isnull(@BucketFTPOffshore4,0))+(isnull(@BucketFTPOffshore5,0))+(isnull(@BucketFTPOffshore6,0))+(isnull(@BucketFTPOffshore7,0))+(isnull(@BucketFTPOffshore8,0))+(isnull(@BucketFTPOffshore9,0))+(isnull(@BucketFTPOffshore10,0))+(isnull(@BucketFTPOffshore11,0))+(isnull(@BucketFTPOffshore12,0)))/@FTPBillingRate
				where RecNumber = 40  and TaskCategory = @CurTaskCatCode and RecTypeID = @CurAFE_DescID
	
			FETCH NEXT FROM TaskCatCode_cursor INTO @CurTaskCatCode
			END
			CLOSE TaskCatCode_cursor
			DEALLOCATE TaskCatCode_cursor
		
			------------------------------------------------------------------------------------
			-- Sum all Task Category Code Records for this AFE (type = 40) with current AFE Desc ID 
			-- Then Update #TEMP_OUT with the AFE Desc Totals Record Type = 30 by Month
			DECLARE @Total_Bucket1 decimal(12,2), @Total_Bucket2 decimal(12,2), @Total_Bucket3 decimal(12,2), @Total_Bucket4 decimal(12,2),@Total_Bucket5 decimal(12,2), @Total_Bucket6 decimal(12,2), @Total_Bucket7 decimal(12,2), @Total_Bucket8 decimal(12,2),@Total_Bucket9 decimal(12,2), @Total_bucket10 decimal(12,2), @Total_bucket11 decimal(12,2),@Total_bucket12 decimal(12,2)
			select  @Total_Bucket1 = sum(isnull(Bucket1_Hours,0)), @Total_Bucket2 = sum(isnull(Bucket2_hours,0)), @Total_Bucket3 = sum(isnull(Bucket3_hours,0)), @Total_Bucket4 = sum(isnull(Bucket4_hours,0)), @Total_Bucket5 = sum(isnull(Bucket5_hours,0)), @Total_Bucket6 = sum(isnull(Bucket6_hours,0)), @Total_Bucket7 = sum(isnull(Bucket7_hours,0)), @Total_Bucket8 = sum(isnull(Bucket8_hours,0)), @Total_Bucket9 = sum(isnull(Bucket9_hours,0)), @Total_bucket10 = sum(isnull(bucket10_hours,0)), @Total_bucket11 = sum(isnull(bucket11_hours,0)), @Total_bucket12 = sum(isnull(bucket12_hours,0))
			from #TEMP_OUT where RecNumber = 40 and RecTypeID = @CurAFE_DescID 

			declare @Total_FTE1 decimal(5,2), @Total_FTE2 decimal(5,2), @Total_FTE3 decimal(5,2), @Total_FTE4 decimal(5,2), @Total_FTE5 decimal(5,2), @Total_FTE6 decimal(5,2), @Total_FTE7 decimal(5,2), @Total_FTE8 decimal(5,2), @Total_FTE9 decimal(5,2), @Total_FTE10 decimal(5,2), @Total_FTE11 decimal(5,2), @Total_FTE12 decimal(5,2)
			select @Total_FTE1 = sum(isnull(Bucket1_FTEs,0)), @Total_FTE2 = sum(isnull(Bucket2_FTEs,0)), @Total_FTE3 = sum(isnull(Bucket3_FTEs,0)), @Total_FTE4 = sum(isnull(Bucket4_FTEs,0)), @Total_FTE5 = sum(isnull(Bucket5_FTEs,0)), @Total_FTE6 = sum(isnull(Bucket6_FTEs,0)), @Total_FTE7 = sum(isnull(Bucket7_FTEs,0)), @Total_FTE8 = sum(isnull(Bucket8_FTEs,0)), @Total_FTE9 = sum(isnull(Bucket9_FTEs,0)), @Total_FTE10 = sum(isnull(Bucket10_FTEs,0)), @Total_FTE11 = sum(isnull(Bucket11_FTEs,0)), @Total_FTE12 = sum(isnull(Bucket12_FTEs,0))
			from #TEMP_OUT where RecNumber = 40 and RecTypeID = @CurAFE_DescID 

			declare @Total_FTE1_hover decimal(15,7), @Total_FTE2_hover decimal(15,7), @Total_FTE3_hover decimal(15,7), @Total_FTE4_hover decimal(15,7), @Total_FTE5_hover decimal(15,7), @Total_FTE6_hover decimal(15,7), @Total_FTE7_hover decimal(15,7), @Total_FTE8_hover decimal(15,7), @Total_FTE9_hover decimal(15,7), @Total_FTE10_hover decimal(15,7), @Total_FTE11_hover decimal(15,7), @Total_FTE12_hover decimal(15,7)
			select @Total_FTE1_hover = sum(isnull(Bucket1_FTEs_hover,0)), @Total_FTE2_hover = sum(isnull(Bucket2_FTEs_hover,0)), @Total_FTE3_hover = sum(isnull(Bucket3_FTEs_hover,0)), @Total_FTE4_hover = sum(isnull(Bucket4_FTEs_hover,0)), @Total_FTE5_hover = sum(isnull(Bucket5_FTEs_hover,0)), @Total_FTE6_hover = sum(isnull(Bucket6_FTEs_hover,0)), @Total_FTE7_hover = sum(isnull(Bucket7_FTEs_hover,0)), @Total_FTE8_hover = sum(isnull(Bucket8_FTEs_hover,0)), @Total_FTE9_hover = sum(isnull(Bucket9_FTEs_hover,0)), @Total_FTE10_hover = sum(isnull(Bucket10_FTEs_hover,0)), @Total_FTE11_hover = sum(isnull(Bucket11_FTEs_hover,0)), @Total_FTE12_hover = sum(isnull(Bucket12_FTEs_hover,0))
			from #TEMP_OUT where RecNumber = 40 and RecTypeID = @CurAFE_DescID 

			-- Update AFE Desc  Rec Type = 30
			update #TEMP_OUT set
       			Bucket1_Hours = isnull(@Total_Bucket1,0), Bucket1_FTEs = isnull(@Total_FTE1,0), Bucket1_FTEs_hover = isnull(@Total_FTE1_hover,0),	
				Bucket2_Hours = isnull(@Total_Bucket2,0), Bucket2_FTEs = isnull(@Total_FTE2,0), Bucket2_FTEs_hover = isnull(@Total_FTE2_hover,0),
				Bucket3_Hours = isnull(@Total_Bucket3,0), Bucket3_FTEs = isnull(@Total_FTE3,0), Bucket3_FTEs_hover = isnull(@Total_FTE3_hover,0),
				Bucket4_Hours = isnull(@Total_Bucket4,0), Bucket4_FTEs = isnull(@Total_FTE4,0), Bucket4_FTEs_hover = isnull(@Total_FTE4_hover,0),
				Bucket5_Hours = isnull(@Total_Bucket5,0), Bucket5_FTEs = isnull(@Total_FTE5,0), Bucket5_FTEs_hover = isnull(@Total_FTE5_hover,0),
				Bucket6_Hours = isnull(@Total_Bucket6,0), Bucket6_FTEs = isnull(@Total_FTE6,0), Bucket6_FTEs_hover = isnull(@Total_FTE6_hover,0),
				Bucket7_Hours = isnull(@Total_Bucket7,0), Bucket7_FTEs = isnull(@Total_FTE7,0), Bucket7_FTEs_hover = isnull(@Total_FTE7_hover,0),
				Bucket8_Hours = isnull(@Total_Bucket8,0), Bucket8_FTEs = isnull(@Total_FTE8,0), Bucket8_FTEs_hover = isnull(@Total_FTE8_hover,0),
				Bucket9_Hours = isnull(@Total_Bucket9,0), Bucket9_FTEs = isnull(@Total_FTE9,0), Bucket9_FTEs_hover = isnull(@Total_FTE9_hover,0),
				Bucket10_Hours = isnull(@Total_Bucket10,0), Bucket10_FTEs = isnull(@Total_FTE10,0), Bucket10_FTEs_hover = isnull(@Total_FTE10_hover,0),
				Bucket11_Hours = isnull(@Total_Bucket11,0), Bucket11_FTEs = isnull(@Total_FTE11,0), Bucket11_FTEs_hover = isnull(@Total_FTE11_hover,0),
				Bucket12_Hours = isnull(@Total_Bucket12,0), Bucket12_FTEs = isnull(@Total_FTE12,0), Bucket12_FTEs_hover = isnull(@Total_FTE12_hover,0),
				TotalHours = (isnull(@Total_Bucket1,0))+(isnull(@Total_Bucket2,0))+(isnull(@Total_Bucket3,0))+(isnull(@Total_Bucket4,0))+(isnull(@Total_Bucket5,0))+(isnull(@Total_Bucket6,0))+(isnull(@Total_Bucket7,0))+(isnull(@Total_Bucket8,0))+(isnull(@Total_Bucket9,0))+(isnull(@Total_bucket10,0))+(isnull(@Total_bucket11,0))+(isnull(@Total_bucket12,0)),
				TotalFTEs = ( (isnull(@Total_FTE1,0)) + (isnull(@Total_FTE2,0)) +	(isnull(@Total_FTE3,0)) + (isnull(@Total_FTE4,0)) + (isnull(@Total_FTE5,0)) + (isnull(@Total_FTE6,0)) +	(isnull(@Total_FTE7,0)) + (isnull(@Total_FTE8,0)) + (isnull(@Total_FTE9,0)) + (isnull(@Total_FTE10,0)) +	(isnull(@Total_FTE11,0)) + (isnull(@Total_FTE12,0)) ),
				TotalFTEs_hover = ( (isnull(@Total_FTE1_hover,0)) + (isnull(@Total_FTE2_hover,0)) + (isnull(@Total_FTE3_hover,0)) + (isnull(@Total_FTE4_hover,0)) + (isnull(@Total_FTE5_hover,0)) + (isnull(@Total_FTE6_hover,0)) + (isnull(@Total_FTE7_hover,0)) + (isnull(@Total_FTE8_hover,0)) + (isnull(@Total_FTE9_hover,0)) + (isnull(@Total_FTE10_hover,0)) + (isnull(@Total_FTE11_hover,0)) + (isnull(@Total_FTE12_hover,0)) )
			where RecNumber = 30 and RecTypeID = @CurAFE_DescID

		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
		END
 		CLOSE AFEDesc_cursor
		DEALLOCATE AFEDesc_cursor
		------------------------------------------------------------------------------------
	
	FETCH NEXT FROM Programme_cursor INTO @CurProgram, @CurProgramID
	END
	CLOSE Programme_cursor
	DEALLOCATE Programme_cursor
	----------------------------------------------------------------------------
	
	-- Sum all AFE Records (type = 30) with current Program Group ID 
	-- Then Update #TEMP_OUT with the Program Group Totals Record Type = 20 by Month
	DECLARE @GrpTotal_Bucket1 decimal(12,2), @GrpTotal_Bucket2 decimal(12,2), @GrpTotal_Bucket3 decimal(12,2), @GrpTotal_Bucket4 decimal(12,2),@GrpTotal_Bucket5 decimal(12,2), @GrpTotal_Bucket6 decimal(12,2), @GrpTotal_Bucket7 decimal(12,2), @GrpTotal_Bucket8 decimal(12,2),@GrpTotal_Bucket9 decimal(12,2), @GrpTotal_bucket10 decimal(12,2), @GrpTotal_bucket11 decimal(12,2),@GrpTotal_bucket12 decimal(12,2)
	select @GrpTotal_Bucket1 = sum(isnull(Bucket1_Hours,0)), @GrpTotal_Bucket2 = sum(isnull(Bucket2_hours,0)), @GrpTotal_Bucket3 = sum(isnull(Bucket3_hours,0)), @GrpTotal_Bucket4 = sum(isnull(Bucket4_hours,0)), @GrpTotal_Bucket5 = sum(isnull(Bucket5_hours,0)), @GrpTotal_Bucket6 = sum(isnull(Bucket6_hours,0)), @GrpTotal_Bucket7 = sum(isnull(Bucket7_hours,0)), @GrpTotal_Bucket8 = sum(isnull(Bucket8_hours,0)), @GrpTotal_Bucket9 = sum(isnull(Bucket9_hours,0)), @GrpTotal_bucket10 = sum(isnull(bucket10_hours,0)), @GrpTotal_bucket11 = sum(isnull(bucket11_hours,0)), @GrpTotal_bucket12 = sum(isnull(bucket12_hours,0))  
	from #TEMP_OUT where RecNumber = 30 and Prog_GroupID = @CurProg_GroupID 

	DECLARE @GrpTotal_FTE1 decimal(12,2), @GrpTotal_FTE2 decimal(12,2), @GrpTotal_FTE3 decimal(12,2), @GrpTotal_FTE4 decimal(12,2), @GrpTotal_FTE5 decimal(12,2), @GrpTotal_FTE6 decimal(12,2), @GrpTotal_FTE7 decimal(12,2), @GrpTotal_FTE8 decimal(12,2), @GrpTotal_FTE9 decimal(12,2), @GrpTotal_FTE10 decimal(12,2), @GrpTotal_FTE11 decimal(12,2),@GrpTotal_FTE12 decimal(12,2)
	select @GrpTotal_FTE1 = sum(isnull(Bucket1_FTEs,0)), @GrpTotal_FTE2 = sum(isnull(Bucket2_FTEs,0)), @GrpTotal_FTE3 = sum(isnull(Bucket3_FTEs,0)), @GrpTotal_FTE4 = sum(isnull(Bucket4_FTEs,0)), @GrpTotal_FTE5 = sum(isnull(Bucket5_FTEs,0)), @GrpTotal_FTE6 = sum(isnull(Bucket6_FTEs,0)), @GrpTotal_FTE7 = sum(isnull(Bucket7_FTEs,0)), @GrpTotal_FTE8 = sum(isnull(Bucket8_FTEs,0)), @GrpTotal_FTE9 = sum(isnull(Bucket9_FTEs,0)), @GrpTotal_FTE10 = sum(isnull(bucket10_FTEs,0)), @GrpTotal_FTE11 = sum(isnull(bucket11_FTEs,0)), @GrpTotal_FTE12 = sum(isnull(bucket12_FTEs,0))  
	from #TEMP_OUT where RecNumber = 30 and Prog_GroupID = @CurProg_GroupID 

	DECLARE @GrpTotal_FTE1_hover decimal(15,7), @GrpTotal_FTE2_hover decimal(15,7), @GrpTotal_FTE3_hover decimal(15,7), @GrpTotal_FTE4_hover decimal(15,7), @GrpTotal_FTE5_hover decimal(15,7), @GrpTotal_FTE6_hover decimal(15,7), @GrpTotal_FTE7_hover decimal(15,7), @GrpTotal_FTE8_hover decimal(15,7), @GrpTotal_FTE9_hover decimal(15,7), @GrpTotal_FTE10_hover decimal(15,7), @GrpTotal_FTE11_hover decimal(15,7),@GrpTotal_FTE12_hover decimal(15,7)
	select @GrpTotal_FTE1_hover = sum(isnull(Bucket1_FTEs_hover,0)), @GrpTotal_FTE2_hover = sum(isnull(Bucket2_FTEs_hover,0)), @GrpTotal_FTE3_hover = sum(isnull(Bucket3_FTEs_hover,0)), @GrpTotal_FTE4_hover = sum(isnull(Bucket4_FTEs_hover,0)), @GrpTotal_FTE5_hover = sum(isnull(Bucket5_FTEs_hover,0)), @GrpTotal_FTE6_hover = sum(isnull(Bucket6_FTEs_hover,0)), @GrpTotal_FTE7_hover = sum(isnull(Bucket7_FTEs_hover,0)), @GrpTotal_FTE8_hover = sum(isnull(Bucket8_FTEs_hover,0)), @GrpTotal_FTE9_hover = sum(isnull(Bucket9_FTEs_hover,0)), @GrpTotal_FTE10_hover = sum(isnull(Bucket10_FTEs_hover,0)), @GrpTotal_FTE11_hover = sum(isnull(Bucket11_FTEs_hover,0)), @GrpTotal_FTE12_hover = sum(isnull(Bucket12_FTEs_hover,0))
	from #TEMP_OUT where RecNumber = 30 and Prog_GroupID = @CurProg_GroupID 

	-- Update Programme Group  Rec Type = 20
	update #TEMP_OUT set
		Bucket1_Hours = isnull(@GrpTotal_Bucket1,0), Bucket1_FTEs = isnull(@GrpTotal_FTE1,0), Bucket1_FTEs_hover = isnull(@GrpTotal_FTE1_hover,0),
		Bucket2_Hours = isnull(@GrpTotal_Bucket2,0), Bucket2_FTEs = isnull(@GrpTotal_FTE2,0), Bucket2_FTEs_hover = isnull(@GrpTotal_FTE2_hover,0),
		Bucket3_Hours = isnull(@GrpTotal_Bucket3,0), Bucket3_FTEs = isnull(@GrpTotal_FTE3,0), Bucket3_FTEs_hover = isnull(@GrpTotal_FTE3_hover,0),
		Bucket4_Hours = isnull(@GrpTotal_Bucket4,0), Bucket4_FTEs = isnull(@GrpTotal_FTE4,0), Bucket4_FTEs_hover = isnull(@GrpTotal_FTE4_hover,0),
		Bucket5_Hours = isnull(@GrpTotal_Bucket5,0), Bucket5_FTEs = isnull(@GrpTotal_FTE5,0), Bucket5_FTEs_hover = isnull(@GrpTotal_FTE5_hover,0),
		Bucket6_Hours = isnull(@GrpTotal_Bucket6,0), Bucket6_FTEs = isnull(@GrpTotal_FTE6,0), Bucket6_FTEs_hover = isnull(@GrpTotal_FTE6_hover,0),
		Bucket7_Hours = isnull(@GrpTotal_Bucket7,0), Bucket7_FTEs = isnull(@GrpTotal_FTE7,0), Bucket7_FTEs_hover = isnull(@GrpTotal_FTE7_hover,0),
		Bucket8_Hours = isnull(@GrpTotal_Bucket8,0), Bucket8_FTEs = isnull(@GrpTotal_FTE8,0), Bucket8_FTEs_hover = isnull(@GrpTotal_FTE8_hover,0),
		Bucket9_Hours = isnull(@GrpTotal_Bucket9,0), Bucket9_FTEs = isnull(@GrpTotal_FTE9,0), Bucket9_FTEs_hover = isnull(@GrpTotal_FTE9_hover,0),
		Bucket10_Hours = isnull(@GrpTotal_bucket10,0), Bucket10_FTEs = isnull(@GrpTotal_FTE10,0), Bucket10_FTEs_hover = isnull(@GrpTotal_FTE10_hover,0),
		Bucket11_Hours = isnull(@GrpTotal_bucket11,0), Bucket11_FTEs = isnull(@GrpTotal_FTE11,0), Bucket11_FTEs_hover = isnull(@GrpTotal_FTE11_hover,0),
		Bucket12_Hours = isnull(@GrpTotal_bucket12,0), Bucket12_FTEs = isnull(@GrpTotal_FTE12,0), Bucket12_FTEs_hover = isnull(@GrpTotal_FTE12_hover,0),
		TotalHours = (isnull(@GrpTotal_Bucket1,0))+(isnull(@GrpTotal_Bucket2,0))+(isnull(@GrpTotal_Bucket3,0))+(isnull(@GrpTotal_Bucket4,0))+(isnull(@GrpTotal_Bucket5,0))+(isnull(@GrpTotal_Bucket6,0))+(isnull(@GrpTotal_Bucket7,0))+(isnull(@GrpTotal_Bucket8,0))+(isnull(@GrpTotal_Bucket9,0))+(isnull(@GrpTotal_bucket10,0))+(isnull(@GrpTotal_bucket11,0))+(isnull(@GrpTotal_bucket12,0)),
		TotalFTEs = ( (isnull(@GrpTotal_FTE1,0)) + (isnull(@GrpTotal_FTE2,0)) +	(isnull(@GrpTotal_FTE3,0)) + (isnull(@GrpTotal_FTE4,0)) + (isnull(@GrpTotal_FTE5,0)) + (isnull(@GrpTotal_FTE6,0)) +	(isnull(@GrpTotal_FTE7,0)) + (isnull(@GrpTotal_FTE8,0)) + (isnull(@GrpTotal_FTE9,0)) + (isnull(@GrpTotal_FTE10,0)) +	(isnull(@GrpTotal_FTE11,0)) + (isnull(@GrpTotal_FTE12,0)) ),
		TotalFTEs_hover = ( (isnull(@GrpTotal_FTE1_hover,0)) + (isnull(@GrpTotal_FTE2_hover,0)) + (isnull(@GrpTotal_FTE3_hover,0)) + (isnull(@GrpTotal_FTE4_hover,0)) + (isnull(@GrpTotal_FTE5_hover,0)) + (isnull(@GrpTotal_FTE6_hover,0)) + (isnull(@GrpTotal_FTE7_hover,0)) + (isnull(@GrpTotal_FTE8_hover,0)) + (isnull(@GrpTotal_FTE9_hover,0)) + (isnull(@GrpTotal_FTE10_hover,0)) + (isnull(@GrpTotal_FTE11_hover,0)) + (isnull(@GrpTotal_FTE12_hover,0)) )
	where RecNumber = 20 and RecTypeID = @CurProg_GroupID

FETCH NEXT FROM ProgrammeGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID
END
CLOSE ProgrammeGroup_cursor
DEALLOCATE ProgrammeGroup_cursor


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------             
				                     
				                  
				                
select * from #TEMP_OUT
