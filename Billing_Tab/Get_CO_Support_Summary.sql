--------------------------------------------------------------------------------
-- Open the Programme Group Cursor		
--------------------------------------------------------------------------------
DECLARE @CurProgramGroup varchar (100), @CurProgramGroupTotal decimal (10,2), @CurProg_GroupID int, @CurYear int, @CurMonth int, @CurHoursOnshore decimal (10,2), @CurHoursOffshore decimal (10,2)
DECLARE ProgrammeGroup_cursor CURSOR FOR 
    select distinct ProgramGroup, Prog_GroupID from #TEMP_IN order by ProgramGroup
OPEN ProgrammeGroup_cursor
FETCH NEXT FROM ProgrammeGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID
WHILE @@FETCH_STATUS = 0
BEGIN
	insert #TEMP_OUT (RecNumber, RecType, Division, RecTypeID)
	select 20, 'Program Group', @CurProgramGroup, @CurProg_GroupID

	--------------------------------------------------------------------------------
	-- Open the Programme  Cursor		
	--------------------------------------------------------------------------------
	DECLARE @CurProgram  varchar (100), @CurCOBusinessLead varchar (100), @CurProgramID int
	DECLARE Programme_cursor CURSOR FOR 
		select distinct Program, ProgramID from #TEMP_IN where Prog_GroupID = @CurProg_GroupID order by Program
	OPEN Programme_cursor
	FETCH NEXT FROM Programme_cursor INTO @CurProgram, @CurProgramID
	WHILE @@FETCH_STATUS = 0
	BEGIN
  	    insert #TEMP_OUT (RecNumber, RecType, Division, RecDesc, RecTypeID)
		select 25, 'Program ', @CurProgram, Null, @CurProgramID

		--------------------------------------------------------------------------------
		-- Open the AFE Description Cursor		
		--------------------------------------------------------------------------------
		DECLARE @CurAFEDesc varchar (100), @CurAFE_DescID  int
		DECLARE AFEDesc_cursor CURSOR FOR 
			select distinct AFEDesc, AFE_DescID, COBUsinessLead from #TEMP_IN
			where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID order by AFEDesc
		OPEN AFEDesc_cursor
		FETCH NEXT FROM AFEDesc_cursor INTO @CurAFEDesc, @CurAFE_DescID, @CurCOBusinessLead
		WHILE @@FETCH_STATUS = 0
		BEGIN
  		    insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID,Prog_GroupID, ProgramID)
			select 30, 'AFE Desc ', @CurAFEDesc, @CurAFE_DescID, @CurProg_GroupID, @CurProgramID

			---------------------------------------------------------------------------------------------------
			-- sum up the ONSHORE months for this AFE Description code and build out the 12 month buckets ---
			---------------------------------------------------------------------------------------------------
			DECLARE Month_cursor_onshore CURSOR FOR 
				select YYYY_Year,MM_Month, sum(hours) as TotalHours from #TEMP_IN
				where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and Onshore = 1 group by YYYY_Year,MM_Month
                      
				--Declare variables for Buckets
				DECLARE @BucketOnshore1 decimal(12,2), @BucketOnshore2 decimal(12,2), @BucketOnshore3 decimal(12,2), @BucketOnshore4 decimal(12,2),@BucketOnshore5 decimal(12,2), @BucketOnshore6 decimal(12,2), @BucketOnshore7 decimal(12,2), @BucketOnshore8 decimal(12,2),@BucketOnshore9 decimal(12,2), @bucketOnshore10 decimal(12,2), @bucketOnshore11 decimal(12,2),@bucketOnshore12 decimal(12,2)
        	
				-- Clear out all Buckets to Zero 
				set @BucketOnshore1 =0 set @BucketOnshore2 = 0  set @BucketOnshore3 =0  set @BucketOnshore4 = 0
				set @BucketOnshore5 =0 set @BucketOnshore6 = 0  set @BucketOnshore7 =0  set @BucketOnshore8 = 0
				set @BucketOnshore9 =0 set @bucketOnshore10 = 0 set @bucketOnshore11 =0 set @bucketOnshore12 = 0
			OPEN Month_cursor_onshore
			FETCH NEXT FROM Month_cursor_onshore INTO @CurYear, @CurMonth, @CurHoursOnshore
			WHILE @@FETCH_STATUS = 0
			BEGIN
         		-- determing the bucket that this month / year goes into
        		declare @bucket_nbr_onshore int
				select @bucket_nbr_onshore = bucket_nbr from #Temp_Bucket where YYYY_Year = @CurYear and MM_Month = @CurMonth

				-- build output buckets
				if @bucket_nbr_onshore = 1 
					begin
					set @BucketOnshore1 = @CurHoursOnshore
					end
				if @bucket_nbr_onshore = 2 
					begin
					set @BucketOnshore2 = @CurHoursOnshore
					end
				if @bucket_nbr_onshore = 3 
					begin
					set @BucketOnshore3 = @CurHoursOnshore
					end
				if @bucket_nbr_onshore = 4 
					begin
					set @BucketOnshore4 = @CurHoursOnshore
					end
				if @bucket_nbr_onshore = 5 
					begin
					set @BucketOnshore5 = @CurHoursOnshore
					end
				if @bucket_nbr_onshore = 6 
					begin
					set @BucketOnshore6 = @CurHoursOnshore
					end
				if @bucket_nbr_onshore = 7 
					begin
					set @BucketOnshore7 = @CurHoursOnshore
					end
				if @bucket_nbr_onshore = 8 
					begin
					set @BucketOnshore8 = @CurHoursOnshore
					end
				if @bucket_nbr_onshore = 9 
					begin
					set @BucketOnshore9 = @CurHoursOnshore
					end
				if @bucket_nbr_onshore = 10 
					begin
					set @bucketOnshore10 = @CurHoursOnshore
					end
				if @bucket_nbr_onshore = 11 
				   begin
					set @bucketOnshore11 = @CurHoursOnshore
					end
				if @bucket_nbr_onshore = 12 
					begin
					set @bucketOnshore12 = @CurHoursOnshore
					end		
			FETCH NEXT FROM Month_cursor_onshore INTO @CurYear, @CurMonth, @CurHoursOnshore
			END
			CLOSE Month_cursor_onshore
			DEALLOCATE Month_cursor_onshore

			---------------------------------------------------------------------------------------------------
			-- sum up the OFFSHORE months for this AFE Description code and build out the 12 month buckets ---
			---------------------------------------------------------------------------------------------------
			DECLARE Month_cursor_offshore CURSOR FOR 
				select YYYY_Year,MM_Month, sum(hours) as TotalHours from #TEMP_IN
				where Prog_GroupID = @CurProg_GroupID and ProgramID = @CurProgramID and AFE_DescID = @CurAFE_DescID and Offshore = 1 group by YYYY_Year,MM_Month
                      
   				--Declare variables for Buckets
				DECLARE @BucketOffshore1 decimal(12,2), @BucketOffshore2 decimal(12,2), @BucketOffshore3 decimal(12,2), @BucketOffshore4 decimal(12,2),@BucketOffshore5 decimal(12,2), @BucketOffshore6 decimal(12,2), @BucketOffshore7 decimal(12,2), @BucketOffshore8 decimal(12,2),@BucketOffshore9 decimal(12,2), @bucketOffshore10 decimal(12,2), @bucketOffshore11 decimal(12,2),@bucketOffshore12 decimal(12,2)
		
				-- Clear out all Buckets to Zero 
				set @BucketOffshore1 =0 set @BucketOffshore2 = 0  set @BucketOffshore3 =0  set @BucketOffshore4 = 0
				set @BucketOffshore5 =0 set @BucketOffshore6 = 0  set @BucketOffshore7 =0  set @BucketOffshore8 = 0
				set @BucketOffshore9 =0 set @bucketOffshore10 = 0 set @bucketOffshore11 =0 set @bucketOffshore12 = 0
				OPEN Month_cursor_offshore
			FETCH NEXT FROM Month_cursor_offshore INTO @CurYear, @CurMonth, @CurHoursOffshore
			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- determing the bucket that this month / year goes into
				declare @bucket_nbr_offshore int  
				select @bucket_nbr_offshore =  bucket_nbr from #Temp_Bucket where YYYY_Year = @CurYear and MM_Month = @CurMonth

				-- build output buckets
				if @bucket_nbr_offshore = 1 
					begin
					set @BucketOffshore1 = @CurHoursOffshore
					end
				if @bucket_nbr_offshore = 2 
					begin
					set @BucketOffshore2 = @CurHoursOffshore				
					end
				if @bucket_nbr_offshore = 3 
					begin
					set @BucketOffshore3 = @CurHoursOffshore
					end
				if @bucket_nbr_offshore = 4 
					begin
					set @BucketOffshore4 = @CurHoursOffshore
					end
				if @bucket_nbr_offshore = 5 
					begin
					set @BucketOffshore5 = @CurHoursOffshore
					end
				if @bucket_nbr_offshore = 6 
					begin
					set @BucketOffshore6 = @CurHoursOffshore
					end
				if @bucket_nbr_offshore = 7 
					begin
					set @BucketOffshore7 = @CurHoursOffshore
					end
				if @bucket_nbr_offshore = 8 
					begin
					set @BucketOffshore8 = @CurHoursOffshore
					end
				if @bucket_nbr_offshore = 9 
					begin
					set @BucketOffshore9 = @CurHoursOffshore
					end
				if @bucket_nbr_offshore = 10 
					begin
					set @bucketOffshore10 = @CurHoursOffshore
					end
				if @bucket_nbr_offshore = 11 
				   begin
					set @bucketOffshore11 = @CurHoursOffshore
					end
				if @bucket_nbr_offshore = 12 
					begin
					set @bucketOffshore12 = @CurHoursOffshore
					end												
			FETCH NEXT FROM Month_cursor_offshore INTO @CurYear, @CurMonth, @CurHoursOffshore
			END
			CLOSE Month_cursor_offshore
			DEALLOCATE Month_cursor_offshore
			
			
			---------------------------------------------------------------------------------------------------

			DECLARE @FTEFactorOnshore decimal(5,2), @FTEFactorOffshore decimal(5,2)
			set @FTEFactorOnshore = 150
			set @FTEFactorOffshore = 143.5	
		
			-- Update the TEMP_OUT table AFE Desc Record containing all of the 12 buckets totals
			update #TEMP_OUT set 
				Bucket1_Onshore_Hours = isnull(@BucketOnshore1,0), Bucket1_Offshore_Hours = isnull(@BucketOffshore1,0), Bucket1_FTEs = isnull(@BucketOnshore1,0)/@FTEFactorOnshore + isnull(@BucketOffshore1,0)/@FTEFactorOffshore,	Bucket1_FTEs_hover = isnull(@BucketOnshore1,0)/@FTEFactorOnshore + isnull(@BucketOffshore1,0)/@FTEFactorOffshore, 		
				Bucket2_Onshore_Hours = isnull(@BucketOnshore2,0),  Bucket2_Offshore_Hours = isnull(@BucketOffshore2,0), Bucket2_FTEs = isnull(@BucketOnshore2,0)/@FTEFactorOnshore + isnull(@BucketOffshore2,0)/@FTEFactorOffshore, Bucket2_FTEs_hover = isnull(@BucketOnshore2,0)/@FTEFactorOnshore + isnull(@BucketOffshore2,0)/@FTEFactorOffshore, 
				Bucket3_Onshore_Hours = isnull(@BucketOnshore3,0), Bucket3_Offshore_Hours = isnull(@BucketOffshore3,0), Bucket3_FTEs = isnull(@BucketOnshore3,0)/@FTEFactorOnshore + isnull(@BucketOffshore3,0)/@FTEFactorOffshore, Bucket3_FTEs_hover = isnull(@BucketOnshore3,0)/@FTEFactorOnshore + isnull(@BucketOffshore3,0)/@FTEFactorOffshore, 
				Bucket4_Onshore_Hours = isnull(@BucketOnshore4,0), Bucket4_Offshore_Hours = isnull(@BucketOffshore4,0), Bucket4_FTEs = isnull(@BucketOnshore4,0)/@FTEFactorOnshore + isnull(@BucketOffshore4,0)/@FTEFactorOffshore, Bucket4_FTEs_hover = isnull(@BucketOnshore4,0)/@FTEFactorOnshore + isnull(@BucketOffshore4,0)/@FTEFactorOffshore, 
  				Bucket5_Onshore_Hours = isnull(@BucketOnshore5,0), Bucket5_Offshore_Hours = isnull(@BucketOffshore5,0),	Bucket5_FTEs = isnull(@BucketOnshore5,0)/@FTEFactorOnshore + isnull(@BucketOffshore5,0)/@FTEFactorOffshore, Bucket5_FTEs_hover = isnull(@BucketOnshore5,0)/@FTEFactorOnshore + isnull(@BucketOffshore5,0)/@FTEFactorOffshore, 
				Bucket6_Onshore_Hours = isnull(@BucketOnshore6,0), Bucket6_Offshore_Hours = isnull(@BucketOffshore6,0), Bucket6_FTEs = isnull(@BucketOnshore6,0)/@FTEFactorOnshore + isnull(@BucketOffshore6,0)/@FTEFactorOffshore, Bucket6_FTEs_hover = isnull(@BucketOnshore6,0)/@FTEFactorOnshore + isnull(@BucketOffshore6,0)/@FTEFactorOffshore, 
				Bucket7_Onshore_Hours = isnull(@BucketOnshore7,0), Bucket7_Offshore_Hours = isnull(@BucketOffshore7,0), Bucket7_FTEs = isnull(@BucketOnshore7,0)/@FTEFactorOnshore + isnull(@BucketOffshore7,0)/@FTEFactorOffshore, Bucket7_FTEs_hover = isnull(@BucketOnshore7,0)/@FTEFactorOnshore + isnull(@BucketOffshore7,0)/@FTEFactorOffshore, 
				Bucket8_Onshore_Hours = isnull(@BucketOnshore8,0), Bucket8_Offshore_Hours = isnull(@BucketOffshore8,0), Bucket8_FTEs = isnull(@BucketOnshore8,0)/@FTEFactorOnshore + isnull(@BucketOffshore8,0)/@FTEFactorOffshore, Bucket8_FTEs_hover = isnull(@BucketOnshore8,0)/@FTEFactorOnshore + isnull(@BucketOffshore8,0)/@FTEFactorOffshore, 
				Bucket9_Onshore_Hours = isnull(@BucketOnshore9,0), Bucket9_Offshore_Hours = isnull(@BucketOffshore9,0), Bucket9_FTEs = isnull(@BucketOnshore9,0)/@FTEFactorOnshore + isnull(@BucketOffshore9,0)/@FTEFactorOffshore, Bucket9_FTEs_hover = isnull(@BucketOnshore9,0)/@FTEFactorOnshore + isnull(@BucketOffshore9,0)/@FTEFactorOffshore, 
				Bucket10_Onshore_Hours = isnull(@BucketOnshore10,0), Bucket10_Offshore_Hours = isnull(@BucketOffshore10,0), Bucket10_FTEs = isnull(@BucketOnshore10,0)/@FTEFactorOnshore + isnull(@BucketOffshore10,0)/@FTEFactorOffshore, Bucket10_FTEs_hover = isnull(@BucketOnshore10,0)/@FTEFactorOnshore + isnull(@BucketOffshore10,0)/@FTEFactorOffshore, 
				Bucket11_Onshore_Hours = isnull(@BucketOnshore11,0), Bucket11_Offshore_Hours = isnull(@BucketOffshore10,0), Bucket11_FTEs = isnull(@BucketOnshore11,0)/@FTEFactorOnshore + isnull(@BucketOffshore11,0)/@FTEFactorOffshore, Bucket11_FTEs_hover = isnull(@BucketOnshore11,0)/@FTEFactorOnshore + isnull(@BucketOffshore11,0)/@FTEFactorOffshore, 
				Bucket12_Onshore_Hours = isnull(@BucketOnshore12,0), Bucket12_Offshore_Hours = isnull(@BucketOffshore12,0), Bucket12_FTEs = isnull(@BucketOnshore12,0)/@FTEFactorOnshore + isnull(@BucketOffshore12,0)/@FTEFactorOffshore, Bucket12_FTEs_hover = isnull(@BucketOnshore12,0)/@FTEFactorOnshore + isnull(@BucketOffshore12,0)/@FTEFactorOffshore, 
				TotalHours = (isnull(@BucketOnshore1,0))+(isnull(@BucketOnshore2,0))+(isnull(@BucketOnshore3,0))+(isnull(@BucketOnshore4,0))+(isnull(@BucketOnshore5,0))+(isnull(@BucketOnshore6,0))+(isnull(@BucketOnshore7,0))+(isnull(@BucketOnshore8,0))+(isnull(@BucketOnshore9,0))+(isnull(@BucketOnshore10,0))+(isnull(@BucketOnshore11,0))+(isnull(@BucketOnshore12,0)) + (isnull(@BucketOffshore1,0))+(isnull(@BucketOffshore2,0))+(isnull(@BucketOffshore3,0))+(isnull(@BucketOffshore4,0))+(isnull(@BucketOffshore5,0))+(isnull(@BucketOffshore6,0))+(isnull(@BucketOffshore7,0))+(isnull(@BucketOffshore8,0))+(isnull(@BucketOffshore9,0))+(isnull(@BucketOffshore10,0))+(isnull(@BucketOffshore11,0))+(isnull(@BucketOffshore12,0)),
				TotalFTEs = ((isnull(@BucketOnshore1,0))+(isnull(@BucketOnshore2,0))+(isnull(@BucketOnshore3,0))+(isnull(@BucketOnshore4,0))+(isnull(@BucketOnshore5,0))+(isnull(@BucketOnshore6,0))+(isnull(@BucketOnshore7,0))+(isnull(@BucketOnshore8,0))+(isnull(@BucketOnshore9,0))+(isnull(@BucketOnshore10,0))+(isnull(@BucketOnshore11,0))+(isnull(@BucketOnshore12,0)))/@FTEFactorOnshore +	((isnull(@BucketOffshore1,0))+(isnull(@BucketOffshore2,0))+(isnull(@BucketOffshore3,0))+(isnull(@BucketOffshore4,0))+(isnull(@BucketOffshore5,0))+(isnull(@BucketOffshore6,0))+(isnull(@BucketOffshore7,0))+(isnull(@BucketOffshore8,0))+(isnull(@BucketOffshore9,0))+(isnull(@BucketOffshore10,0))+(isnull(@BucketOffshore11,0))+(isnull(@BucketOffshore12,0)))/@FTEFactorOffshore,				
				TotalFTEs_hover = ((isnull(@BucketOnshore1,0))+(isnull(@BucketOnshore2,0))+(isnull(@BucketOnshore3,0))+(isnull(@BucketOnshore4,0))+(isnull(@BucketOnshore5,0))+(isnull(@BucketOnshore6,0))+(isnull(@BucketOnshore7,0))+(isnull(@BucketOnshore8,0))+(isnull(@BucketOnshore9,0))+(isnull(@BucketOnshore10,0))+(isnull(@BucketOnshore11,0))+(isnull(@BucketOnshore12,0)))/@FTEFactorOnshore +	((isnull(@BucketOffshore1,0))+(isnull(@BucketOffshore2,0))+(isnull(@BucketOffshore3,0))+(isnull(@BucketOffshore4,0))+(isnull(@BucketOffshore5,0))+(isnull(@BucketOffshore6,0))+(isnull(@BucketOffshore7,0))+(isnull(@BucketOffshore8,0))+(isnull(@BucketOffshore9,0))+(isnull(@BucketOffshore10,0))+(isnull(@BucketOffshore11,0))+(isnull(@BucketOffshore12,0)))/@FTEFactorOffshore
			where RecNumber = 30  and RecTypeID = @CurAFE_DescID			
			
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
	DECLARE @Total_BucketOnshore1 decimal(12,2), @Total_BucketOnshore2 decimal(12,2), @Total_BucketOnshore3 decimal(12,2), @Total_BucketOnshore4 decimal(12,2),@Total_BucketOnshore5 decimal(12,2), @Total_BucketOnshore6 decimal(12,2), @Total_BucketOnshore7 decimal(12,2), @Total_BucketOnshore8 decimal(12,2),@Total_BucketOnshore9 decimal(12,2), @Total_bucketOnshore10 decimal(12,2), @Total_bucketOnshore11 decimal(12,2),@Total_bucketOnshore12 decimal(12,2)
	DECLARE @Total_BucketOffshore1 decimal(12,2), @Total_BucketOffshore2 decimal(12,2), @Total_BucketOffshore3 decimal(12,2), @Total_BucketOffshore4 decimal(12,2),@Total_BucketOffshore5 decimal(12,2), @Total_BucketOffshore6 decimal(12,2), @Total_BucketOffshore7 decimal(12,2), @Total_BucketOffshore8 decimal(12,2),@Total_BucketOffshore9 decimal(12,2), @Total_bucketOffshore10 decimal(12,2), @Total_bucketOffshore11 decimal(12,2),@Total_bucketOffshore12 decimal(12,2)
             
	select @Total_BucketOnshore1 = sum(isnull(Bucket1_Onshore_Hours,0)), @Total_BucketOnshore2 = sum(isnull(Bucket2_Onshore_Hours,0)), @Total_BucketOnshore3 = sum(isnull(Bucket3_Onshore_Hours,0)), 
		@Total_BucketOnshore4 = sum(isnull(Bucket4_Onshore_Hours,0)), @Total_BucketOnshore5 = sum(isnull(Bucket5_Onshore_Hours,0)), @Total_BucketOnshore6 = sum(isnull(Bucket6_Onshore_Hours,0)), 
		@Total_BucketOnshore7 = sum(isnull(Bucket7_Onshore_Hours,0)), @Total_BucketOnshore8 = sum(isnull(Bucket8_Onshore_Hours,0)), @Total_BucketOnshore9 = sum(isnull(Bucket9_Onshore_Hours,0)), 
		@Total_bucketOnshore10 = sum(isnull(bucket10_Onshore_Hours,0)), @Total_bucketOnshore11 = sum(isnull(bucket11_Onshore_Hours,0)), @Total_bucketOnshore12 = sum(isnull(bucket12_Onshore_Hours,0)),
		@Total_BucketOffshore1 = sum(isnull(Bucket1_Offshore_Hours,0)), @Total_BucketOffshore2 = sum(isnull(Bucket2_Offshore_Hours,0)), @Total_BucketOffshore3 = sum(isnull(Bucket3_Offshore_Hours,0)), 
		@Total_BucketOffshore4 = sum(isnull(Bucket4_Offshore_Hours,0)), @Total_BucketOffshore5 = sum(isnull(Bucket5_Offshore_Hours,0)), @Total_BucketOffshore6 = sum(isnull(Bucket6_Offshore_Hours,0)), 
		@Total_BucketOffshore7 = sum(isnull(Bucket7_Offshore_Hours,0)), @Total_BucketOffshore8 = sum(isnull(Bucket8_Offshore_Hours,0)), @Total_BucketOffshore9 = sum(isnull(Bucket9_Offshore_Hours,0)), 
		@Total_bucketOffshore10 = sum(isnull(bucket10_Offshore_Hours,0)), @Total_bucketOffshore11 = sum(isnull(bucket11_Offshore_Hours,0)), @Total_bucketOffshore12 = sum(isnull(bucket12_Offshore_Hours,0))
	from #TEMP_OUT where RecNumber = 30 and Prog_GroupID = @CurProg_GroupID 

	-- Update Programme Group  Rec Type = 20
	update #TEMP_OUT set
    	Bucket1_Onshore_Hours = isnull(@Total_BucketOnshore1,0), Bucket1_Offshore_Hours = isnull(@Total_BucketOffshore1,0), 
		Bucket1_FTEs = isnull(@Total_BucketOnshore1,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore1,0)/@FTEFactorOffshore, 
		Bucket1_FTEs_hover = isnull(@Total_BucketOnshore1,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore1,0)/@FTEFactorOffshore,	
		Bucket2_Onshore_Hours = isnull(@Total_BucketOnshore2,0), Bucket2_Offshore_Hours = isnull(@Total_BucketOffshore2,0), Bucket2_FTEs = isnull(@Total_BucketOnshore2,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore2,0)/@FTEFactorOffshore, Bucket2_FTEs_hover = isnull(@Total_BucketOnshore2,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore2,0)/@FTEFactorOffshore,
		Bucket3_Onshore_Hours = isnull(@Total_BucketOnshore3,0), Bucket3_Offshore_Hours = isnull(@Total_BucketOffshore3,0), Bucket3_FTEs = isnull(@Total_BucketOnshore3,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore3,0)/@FTEFactorOffshore, Bucket3_FTEs_hover = isnull(@Total_BucketOnshore3,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore3,0)/@FTEFactorOffshore,
		Bucket4_Onshore_Hours = isnull(@Total_BucketOnshore4,0), Bucket4_Offshore_Hours = isnull(@Total_BucketOffshore4,0), Bucket4_FTEs = isnull(@Total_BucketOnshore4,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore4,0)/@FTEFactorOffshore, Bucket4_FTEs_hover = isnull(@Total_BucketOnshore4,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore4,0)/@FTEFactorOffshore,
		Bucket5_Onshore_Hours = isnull(@Total_BucketOnshore5,0), Bucket5_Offshore_Hours = isnull(@Total_BucketOffshore5,0), Bucket5_FTEs = isnull(@Total_BucketOnshore5,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore5,0)/@FTEFactorOffshore, Bucket5_FTEs_hover = isnull(@Total_BucketOnshore5,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore5,0)/@FTEFactorOffshore,
		Bucket6_Onshore_Hours = isnull(@Total_BucketOnshore6,0), Bucket6_Offshore_Hours = isnull(@Total_BucketOffshore6,0), Bucket6_FTEs = isnull(@Total_BucketOnshore6,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore6,0)/@FTEFactorOffshore, Bucket6_FTEs_hover = isnull(@Total_BucketOnshore6,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore6,0)/@FTEFactorOffshore,
		Bucket7_Onshore_Hours = isnull(@Total_BucketOnshore7,0), Bucket7_Offshore_Hours = isnull(@Total_BucketOffshore7,0), Bucket7_FTEs = isnull(@Total_BucketOnshore7,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore7,0)/@FTEFactorOffshore, Bucket7_FTEs_hover = isnull(@Total_BucketOnshore7,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore7,0)/@FTEFactorOffshore,
		Bucket8_Onshore_Hours = isnull(@Total_BucketOnshore8,0), Bucket8_Offshore_Hours = isnull(@Total_BucketOffshore8,0), Bucket8_FTEs = isnull(@Total_BucketOnshore8,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore8,0)/@FTEFactorOffshore, Bucket8_FTEs_hover = isnull(@Total_BucketOnshore8,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore8,0)/@FTEFactorOffshore,
		Bucket9_Onshore_Hours = isnull(@Total_BucketOnshore9,0), Bucket9_Offshore_Hours = isnull(@Total_BucketOffshore9,0), Bucket9_FTEs = isnull(@Total_BucketOnshore9,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore9,0)/@FTEFactorOffshore, Bucket9_FTEs_hover = isnull(@Total_BucketOnshore9,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore9,0)/@FTEFactorOffshore,
		Bucket10_Onshore_Hours = isnull(@Total_BucketOnshore10,0), Bucket10_Offshore_Hours = isnull(@Total_BucketOffshore10,0), Bucket10_FTEs = isnull(@Total_BucketOnshore10,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore10,0)/@FTEFactorOffshore, Bucket10_FTEs_hover = isnull(@Total_BucketOnshore10,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore10,0)/@FTEFactorOffshore,
		Bucket11_Onshore_Hours = isnull(@Total_BucketOnshore11,0), Bucket11_Offshore_Hours = isnull(@Total_BucketOffshore11,0), Bucket11_FTEs = isnull(@Total_BucketOnshore11,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore11,0)/@FTEFactorOffshore, Bucket11_FTEs_hover = isnull(@Total_BucketOnshore11,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore11,0)/@FTEFactorOffshore,
		Bucket12_Onshore_Hours = isnull(@Total_BucketOnshore12,0), Bucket12_Offshore_Hours = isnull(@Total_BucketOffshore12,0), Bucket12_FTEs = isnull(@Total_BucketOnshore12,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore12,0)/@FTEFactorOffshore, Bucket12_FTEs_hover = isnull(@Total_BucketOnshore12,0)/@FTEFactorOnshore + isnull(@Total_BucketOffshore12,0)/@FTEFactorOffshore,
		TotalHours = (isnull(@Total_BucketOnshore1,0))+(isnull(@Total_BucketOnshore2,0))+(isnull(@Total_BucketOnshore3,0))+(isnull(@Total_BucketOnshore4,0))+(isnull(@Total_BucketOnshore5,0))+(isnull(@Total_BucketOnshore6,0))+(isnull(@Total_BucketOnshore7,0))+(isnull(@Total_BucketOnshore8,0))+(isnull(@Total_BucketOnshore9,0))+(isnull(@Total_BucketOnshore10,0))+(isnull(@Total_BucketOnshore11,0))+(isnull(@Total_BucketOnshore12,0))+(isnull(@Total_BucketOffshore1,0))+(isnull(@Total_BucketOffshore2,0))+(isnull(@Total_BucketOffshore3,0))+(isnull(@Total_BucketOffshore4,0))+(isnull(@Total_BucketOffshore5,0))+(isnull(@Total_BucketOffshore6,0))+(isnull(@Total_BucketOffshore7,0))+(isnull(@Total_BucketOffshore8,0))+(isnull(@Total_BucketOffshore9,0))+(isnull(@Total_BucketOffshore10,0))+(isnull(@Total_BucketOffshore11,0))+(isnull(@Total_BucketOffshore12,0)),
		TotalFTEs = ((isnull(@Total_BucketOnshore1,0))+(isnull(@Total_BucketOnshore2,0))+(isnull(@Total_BucketOnshore3,0))+(isnull(@Total_BucketOnshore4,0))+(isnull(@Total_BucketOnshore5,0))+(isnull(@Total_BucketOnshore6,0))+(isnull(@Total_BucketOnshore7,0))+(isnull(@Total_BucketOnshore8,0))+(isnull(@Total_BucketOnshore9,0))+(isnull(@Total_BucketOnshore10,0))+(isnull(@Total_BucketOnshore11,0))+(isnull(@Total_BucketOnshore12,0)))/@FTEFactorOnshore +	((isnull(@Total_BucketOffshore1,0))+(isnull(@Total_BucketOffshore2,0))+(isnull(@Total_BucketOffshore3,0))+(isnull(@Total_BucketOffshore4,0))+(isnull(@Total_BucketOffshore5,0))+(isnull(@Total_BucketOffshore6,0))+(isnull(@Total_BucketOffshore7,0))+(isnull(@Total_BucketOffshore8,0))+(isnull(@Total_BucketOffshore9,0))+(isnull(@Total_BucketOffshore10,0))+(isnull(@Total_BucketOffshore11,0))+(isnull(@Total_BucketOffshore12,0)))/@FTEFactorOffshore,				
		TotalFTEs_hover = ((isnull(@Total_BucketOnshore1,0))+(isnull(@Total_BucketOnshore2,0))+(isnull(@Total_BucketOnshore3,0))+(isnull(@Total_BucketOnshore4,0))+(isnull(@Total_BucketOnshore5,0))+(isnull(@Total_BucketOnshore6,0))+(isnull(@Total_BucketOnshore7,0))+(isnull(@Total_BucketOnshore8,0))+(isnull(@Total_BucketOnshore9,0))+(isnull(@Total_BucketOnshore10,0))+(isnull(@Total_BucketOnshore11,0))+(isnull(@Total_BucketOnshore12,0)))/@FTEFactorOnshore +	((isnull(@Total_BucketOffshore1,0))+(isnull(@Total_BucketOffshore2,0))+(isnull(@Total_BucketOffshore3,0))+(isnull(@Total_BucketOffshore4,0))+(isnull(@Total_BucketOffshore5,0))+(isnull(@Total_BucketOffshore6,0))+(isnull(@Total_BucketOffshore7,0))+(isnull(@Total_BucketOffshore8,0))+(isnull(@Total_BucketOffshore9,0))+(isnull(@Total_BucketOffshore10,0))+(isnull(@Total_BucketOffshore11,0))+(isnull(@Total_BucketOffshore12,0)))/@FTEFactorOffshore
	where RecNumber = 20 and RecTypeID = @CurProg_GroupID
    

FETCH NEXT FROM ProgrammeGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID
END
CLOSE ProgrammeGroup_cursor
DEALLOCATE ProgrammeGroup_cursor

-----------------------------------------------------------------------------------------------------------------



