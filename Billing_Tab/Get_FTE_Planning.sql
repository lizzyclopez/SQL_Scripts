--PROCEDURE [dbo].[Get_FTE_Planning] (@Month varchar(50) = 'ALL', @ProgGroupID varchar(100) = '-1', @FundCatID int = -1, @FundCatIDList varchar(100) = '-1', @OutputTable varchar(30) = NULL)
drop view [dbo].[SP_Get_FTE_Planning]
drop table #TEMP_IN
drop table #TEMP_OUT

DECLARE @SQL_statement varchar(1000)
set @SQL_statement = 'Create View dbo.SP_Get_FTE_Planning AS select * from FTE_Summary_View 
where CurrentMonth = ''201507'' ' 
exec (@SQL_statement)

select * into dbo.#TEMP_IN from dbo.SP_Get_FTE_Planning

Create Index IDX1 on [dbo].[#TEMP_IN] (Prog_GroupID, ProgramID)

CREATE TABLE [dbo].[#TEMP_OUT] (
	[AutoKey][int] IDENTITY (10, 1) NOT NULL,
	[RecNumber][int] NULL,
	[RecType] [varchar] (100) NULL, -- ProgramGroup / Program / AFEDesc / Total / GrandTotal
	[RecDesc] [varchar] (100) NULL,
    [RecTypeID] [bigint] NULL,      -- Prog_GroupID / ProgramID / AFE_DescID / ProjectID / TaskID 
	[FundingCat] [varchar] (30) NULL, [Location] [varchar] (30) NULL, [AFE_Number] [varchar] (18) NULL, [Capitalized] [bit] NULL, [UAVP] [varchar] (50) NULL, [ProgramMgr] [varchar] (50) NULL,
	[FTE_frcst_mo1] [decimal](10,2) NULL,[FTE_frcst_mo2] [decimal](10,2) NULL,[FTE_frcst_mo3] [decimal](10,2) NULL,[FTE_frcst_mo4] [decimal](10,2) NULL,[FTE_frcst_mo5] [decimal](10,2) NULL,[FTE_frcst_mo6] [decimal](10,2) NULL,[FTE_frcst_mo7] [decimal](10,2) NULL,[FTE_frcst_mo8] [decimal](10,2) NULL,[FTE_frcst_mo9] [decimal](10,2) NULL,[FTE_frcst_mo10] [decimal](10,2) NULL,[FTE_frcst_mo11] [decimal](10,2) NULL,[FTE_frcst_mo12] [decimal](10,2) NULL,[FTE_frcst_mo13] [decimal](10,2) NULL,[FTE_frcst_mo14] [decimal](10,2) NULL, [FTE_frcst_mo15] [decimal](10,2) NULL,[FTE_frcst_mo16] [decimal](10,2) NULL, [FTE_frcst_mo17] [decimal](10,2) NULL, [FTE_frcst_mo18] [decimal](10,2) NULL,	
	[R10_ProgramGroup] [varchar] (100) NULL, [R20_Program] [varchar] (100) NULL
) ON [PRIMARY]

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
DECLARE @CurProgramGroup varchar(100), @CurProg_GroupID int, @UPVP varchar(50), @ManDir varchar(50), @CurProgram varchar(100), @CurProgramID int, @MaxProgGroup int, @MaxProgram int

-- only select Program Groups that have allocation for at least one month
DECLARE ProgramGroup_cursor CURSOR FOR 
    select distinct ProgramGroup, Prog_GroupID, UA_VicePresident from #TEMP_IN
	where FTE_frcst_mo1 > 0 or FTE_frcst_mo2 > 0 or FTE_frcst_mo3 > 0 or FTE_frcst_mo4 > 0 or FTE_frcst_mo5 > 0	or FTE_frcst_mo6 > 0 or FTE_frcst_mo7 > 0 or FTE_frcst_mo8 > 0 or FTE_frcst_mo9 > 0 or FTE_frcst_mo10 > 0 or FTE_frcst_mo11 > 0 or FTE_frcst_mo12 > 0 or FTE_frcst_mo13 > 0 or FTE_frcst_mo14 > 0 or FTE_frcst_mo15 > 0 or FTE_frcst_mo16 > 0 or FTE_frcst_mo17 > 0 or FTE_frcst_mo18 > 0 
OPEN ProgramGroup_cursor
FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID, @UPVP
WHILE @@FETCH_STATUS = 0
BEGIN
	insert #TEMP_OUT (RecNumber) values (10) -- A blank line
	insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, UAVP)
	select 10, 'ProgGroup', @CurProgramGroup, @CurProg_GroupID, @UPVP
    select @MaxProgGroup = max(AutoKey) from #TEMP_OUT
	---------------------------------------------------------------------------------------------------
	
	DECLARE Program_cursor CURSOR FOR 
		select distinct Program, ProgramID, Managing_Director from #TEMP_IN where ProgramGroup = @CurProgramGroup
	OPEN Program_cursor
	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID, @ManDir
    WHILE @@FETCH_STATUS = 0
	BEGIN	
		insert #TEMP_OUT (RecNumber, RecType, RecDesc, RecTypeID, UAVP, R10_ProgramGroup)
        select 20, 'Program', @CurProgram, @CurProgramID, @ManDir, @CurProgramGroup
        select @MaxProgram = max(AutoKey) from #TEMP_OUT
		--insert #TEMP_OUT  (RecNumber, RecType, RecDesc, RecTypeID, FundingCat, Location, AFE_Number, Capitalized, ProgramMgr, FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12, FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18)
   		--select 30, 'AFEDesc', AFEDesc, AFE_DescID, FundingCat, Location, AFE_Number, Capitalized, ProgramMgr, FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12, FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18 from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram order by AFEDesc, CurrentMonth, location                     
		insert #TEMP_OUT  (RecNumber, RecType, RecDesc, RecTypeID, FundingCat, Location, AFE_Number, Capitalized, ProgramMgr, FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12, FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18, R10_ProgramGroup, R20_Program)
   		select 30, 'AFEDesc', AFEDesc, AFE_DescID, FundingCat, Location, AFE_Number, Capitalized, ProgramMgr, FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12, FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18, @CurProgramGroup, @CurProgram from #TEMP_IN where ProgramGroup = @CurProgramGroup and Program = @CurProgram order by AFEDesc, CurrentMonth, location                     
	FETCH NEXT FROM Program_cursor INTO @CurProgram, @CurProgramID, @ManDir
	END
	CLOSE Program_cursor
	DEALLOCATE Program_cursor

	---------------------------------------------------------------------------------------------------
    -- Update total information in type 10 heading records
	DECLARE @mo1 decimal(10,2), @mo2 decimal(10,2), @mo3 decimal(10,2), @mo4 decimal(10,2), @mo5 decimal(10,2), @mo6 decimal(10,2), @mo7 decimal(10,2), @mo8 decimal(10,2), @mo9 decimal(10,2), @mo10 decimal(10,2), @mo11 decimal(10,2), @mo12 decimal(10,2), @mo13 decimal(10,2), @mo14 decimal(10,2), @mo15 decimal(10,2), @mo16 decimal(10,2), @mo17 decimal(10,2), @mo18 decimal(10,2)

    select @mo1 = isnull(sum(FTE_frcst_mo1), 0), @mo2 = isnull(sum(FTE_frcst_mo2), 0), @mo3 = isnull(sum(FTE_frcst_mo3), 0), @mo4 = isnull(sum(FTE_frcst_mo4), 0), @mo5 = isnull(sum(FTE_frcst_mo5), 0), @mo6 = isnull(sum(FTE_frcst_mo6), 0),  @mo7 = isnull(sum(FTE_frcst_mo7), 0), @mo8 = isnull(sum(FTE_frcst_mo8), 0), @mo9 = isnull(sum(FTE_frcst_mo9), 0), @mo10 = isnull(sum(FTE_frcst_mo10), 0), @mo11 = isnull(sum(FTE_frcst_mo11), 0), @mo12 = isnull(sum(FTE_frcst_mo12), 0), @mo13 = isnull(sum(FTE_frcst_mo13), 0), @mo14 = isnull(sum(FTE_frcst_mo14), 0), @mo15 = isnull(sum(FTE_frcst_mo15), 0), @mo16 = isnull(sum(FTE_frcst_mo16), 0), @mo17 = isnull(sum(FTE_frcst_mo17), 0), @mo18 = isnull(sum(FTE_frcst_mo18), 0)                    
    from #TEMP_IN where Prog_GroupID = @CurProg_GroupID
    
    update #TEMP_OUT set FTE_frcst_mo1 = @mo1, FTE_frcst_mo2 = @mo2, FTE_frcst_mo3 = @mo3, FTE_frcst_mo4 = @mo4, FTE_frcst_mo5 = @mo5, FTE_frcst_mo6 = @mo6, FTE_frcst_mo7 = @mo7, FTE_frcst_mo8 = @mo8, FTE_frcst_mo9 = @mo9, FTE_frcst_mo10 = @mo10, FTE_frcst_mo11 = @mo11, FTE_frcst_mo12 = @mo12, FTE_frcst_mo13 = @mo13, FTE_frcst_mo14 = @mo14, FTE_frcst_mo15 = @mo15, FTE_frcst_mo16 = @mo16, FTE_frcst_mo17 = @mo17, FTE_frcst_mo18 = @mo18
    where AutoKey = @MaxProgGroup
FETCH NEXT FROM ProgramGroup_cursor INTO @CurProgramGroup, @CurProg_GroupID, @UPVP
END
CLOSE ProgramGroup_cursor
DEALLOCATE ProgramGroup_cursor

---------------------------------------------------------------------------------------------------
delete #TEMP_OUT where RecNumber = 30 and FTE_frcst_mo1 = 0 and FTE_frcst_mo2 = 0 and FTE_frcst_mo3 = 0 and FTE_frcst_mo4 = 0 and FTE_frcst_mo5 = 0 and FTE_frcst_mo6 = 0 
	and FTE_frcst_mo7 = 0 and FTE_frcst_mo8 = 0 and FTE_frcst_mo9 = 0 and FTE_frcst_mo10 = 0 and FTE_frcst_mo11 = 0 and FTE_frcst_mo12 = 0 
	and FTE_frcst_mo13 = 0 and FTE_frcst_mo14 = 0 and FTE_frcst_mo15 = 0 and FTE_frcst_mo16 = 0 and FTE_frcst_mo17 = 0 and FTE_frcst_mo18 = 0

SET IDENTITY_INSERT [dbo].[#TEMP_OUT] ON

insert #TEMP_OUT ( AutoKey, RecNumber, RecType, RecDesc, FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12, FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18 )
select 1, 0, 'GrandTotal', 'Total Approved',  isnull(sum(FTE_frcst_mo1), 0), isnull(sum(FTE_frcst_mo2), 0), isnull(sum(FTE_frcst_mo3), 0), isnull(sum(FTE_frcst_mo4), 0), isnull(sum(FTE_frcst_mo5), 0), isnull(sum(FTE_frcst_mo6), 0), isnull(sum(FTE_frcst_mo7), 0), isnull(sum(FTE_frcst_mo8), 0), isnull(sum(FTE_frcst_mo9), 0), isnull(sum(FTE_frcst_mo10), 0), isnull(sum(FTE_frcst_mo11), 0), isnull(sum(FTE_frcst_mo12), 0), isnull(sum(FTE_frcst_mo13), 0), isnull(sum(FTE_frcst_mo14), 0), isnull(sum(FTE_frcst_mo15), 0), isnull(sum(FTE_frcst_mo16), 0), isnull(sum(FTE_frcst_mo17), 0), isnull(sum(FTE_frcst_mo18), 0)
from #TEMP_OUT where RecNumber = 30

insert #TEMP_OUT ( AutoKey, RecNumber, RecType, RecDesc, FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12, FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18 )
select 2, 3, 'Total', 'Total for AFE',  isnull(sum(FTE_frcst_mo1), 0), isnull(sum(FTE_frcst_mo2), 0), isnull(sum(FTE_frcst_mo3), 0), isnull(sum(FTE_frcst_mo4), 0), isnull(sum(FTE_frcst_mo5), 0), isnull(sum(FTE_frcst_mo6), 0), isnull(sum(FTE_frcst_mo7), 0), isnull(sum(FTE_frcst_mo8), 0), isnull(sum(FTE_frcst_mo9), 0), isnull(sum(FTE_frcst_mo10), 0), isnull(sum(FTE_frcst_mo11), 0), isnull(sum(FTE_frcst_mo12), 0), isnull(sum(FTE_frcst_mo13), 0), isnull(sum(FTE_frcst_mo14), 0), isnull(sum(FTE_frcst_mo15), 0), isnull(sum(FTE_frcst_mo16), 0), isnull(sum(FTE_frcst_mo17), 0), isnull(sum(FTE_frcst_mo18), 0)
from #TEMP_OUT where RecNumber = 30 and FundingCat in ('AFE-SHR','AFE-NON SHR')

insert #TEMP_OUT ( AutoKey, RecNumber, RecType, RecDesc, FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12, FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18 )
select 3, 6, 'Total', 'Total for Support', isnull(sum(FTE_frcst_mo1), 0), isnull(sum(FTE_frcst_mo2), 0), isnull(sum(FTE_frcst_mo3), 0), isnull(sum(FTE_frcst_mo4), 0), isnull(sum(FTE_frcst_mo5), 0), isnull(sum(FTE_frcst_mo6), 0), isnull(sum(FTE_frcst_mo7), 0), isnull(sum(FTE_frcst_mo8), 0), isnull(sum(FTE_frcst_mo9), 0), isnull(sum(FTE_frcst_mo10), 0), isnull(sum(FTE_frcst_mo11), 0), isnull(sum(FTE_frcst_mo12), 0), isnull(sum(FTE_frcst_mo13), 0), isnull(sum(FTE_frcst_mo14), 0), isnull(sum(FTE_frcst_mo15), 0), isnull(sum(FTE_frcst_mo16), 0), isnull(sum(FTE_frcst_mo17), 0), isnull(sum(FTE_frcst_mo18), 0)
from #TEMP_OUT where RecNumber = 30 and FundingCat = 'SUPPORT'

-- To do the next, PIV_ProdID must have dbo right in tempdb (SQL7 problem)
SET IDENTITY_INSERT [dbo].[#TEMP_OUT] OFF

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
Select RecNumber, RecType, RecDesc, FundingCat, Location, AFE_Number,  Capitalized, UAVP, ProgramMgr, 
FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, 
FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12,
FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18
from dbo.#TEMP_OUT order by AutoKey


select * from dbo.#TEMP_OUT
