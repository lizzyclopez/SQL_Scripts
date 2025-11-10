--PROCEDURE [dbo].[GetStaffingPlanDetailWithProject]                                         
drop table #tmpStaffingplan

CREATE TABLE #tmpStaffingplan (ID int identity, AFE_DescID int,Torder char(1), AFEDesc varchar(100), FunCat varchar(50), LocationID int, ProjectID varchar(200), ProjectTitle varchar(100), FTE_frcst_mo1 decimal(7,2), FTE_frcst_mo2 decimal(7,2), FTE_frcst_mo3 decimal(7,2), FTE_frcst_mo4 decimal(7,2), FTE_frcst_mo5 decimal(7,2), FTE_frcst_mo6 decimal(7,2), FTE_frcst_mo7 decimal(7,2), FTE_frcst_mo8 decimal(7,2), FTE_frcst_mo9 decimal(7,2), FTE_frcst_mo10 decimal(7,2), FTE_frcst_mo11 decimal(7,2), FTE_frcst_mo12 decimal(7,2), FTE_frcst_mo13 decimal(7,2), FTE_frcst_mo14 decimal(7,2), FTE_frcst_mo15 decimal(7,2), FTE_frcst_mo16 decimal(7,2), FTE_frcst_mo17 decimal(7,2), FTE_frcst_mo18 decimal(7,2),Totalrow int, UpdateBy varchar(5))      
    
--declare @FromRange varchar(2), @ToRange varchar(2), @Month varchar(7)                
--set @FromRange = 'W'
--set @ToRange = 'Xz'
--set @Month = '201402'                

--INSERT RECORDS AT THE AFE LEVEL 
INSERT INTO #tmpStaffingplan (AFE_DescID, Torder, AFEDesc, FunCat, LocationID, ProjectID, ProjectTitle, FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12, FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18, Totalrow,UpdateBy)       
SELECT distinct des.AFE_DescID, '1', des.Description as AFEDesc, lkFun.Description as FunCat, tspd.LocationID, null, null, tspd.FTE_frcst_mo1, tspd.FTE_frcst_mo2, tspd.FTE_frcst_mo3, tspd.FTE_frcst_mo4, tspd.FTE_frcst_mo5, tspd.FTE_frcst_mo6, tspd.FTE_frcst_mo7, tspd.FTE_frcst_mo8, tspd.FTE_frcst_mo9, tspd.FTE_frcst_mo10, tspd.FTE_frcst_mo11, tspd.FTE_frcst_mo12, tspd.FTE_frcst_mo13, tspd.FTE_frcst_mo14, tspd.FTE_frcst_mo15, tspd.FTE_frcst_mo16, tspd.FTE_frcst_mo17, tspd.FTE_frcst_mo18, 0 as Totalrow,'' as UpdateBy                      
FROM lkAFEDescription des inner join tblAFEDetail det on des.AFE_descID = det.AFE_DescID                       
	inner join lkFundingCat lkFun on det.Funding_catID = lkFun.Funding_CatID                       
    inner join tblStaffingPlanDetail tspd on des.AFE_DescID = tspd.AFE_DescID                       
	inner join tblstaffingplan tsp on tspd.CurrentMonth = tsp.CurrentMonth          
	inner join tblProject tbp on des.AFE_DescID = tbp.AFE_DescID  --Added by Lizzy         
	inner join tblResourceDetail trd on trd.ProjectID = tbp.ProjectID  --Added by Lizzy      
WHERE tspd.LocationID = 4000 AND substring(des.Description,1,2) between 'A' AND 'Zz' AND tspd.CurrentMonth = '201404' 
	and des.AFEStatusID not in ('1201','1204') and CONVERT(VARCHAR(06), trd.workdate, 112) = '201404'  --Added by Lizzy                         
	--and tbp.StatusCode = 'A' and CONVERT(VARCHAR(06), trd.workdate, 112) = '201404'  --Added by Lizzy                         
	or (tspd.LocationID = 4000 AND substring(des.Description,1,2) between 'A' AND 'Zz' AND tspd.CurrentMonth = '201404' and det.ManualStaffing = '1') --Added by Lizzy
order by AFEDesc                      
    
select * from #tmpStaffingplan  
select * from lkAFEDescription
select * from tblAFEDetail where ManualStaffing = 1
select * from lkFundingCat
select * from tblstaffingplan
select * from tblStaffingPlanDetail
select * from tblproject where statusCode = 'A' order by projectTitle
select * from piv_reports..tblResourceDetail

--INSERT RECORDS FROM MSPS AT THE PROJECT LEVEL FROM THE TBLPROJECT TABLE  
--INSERT INTO #tmpStaffingplan (ProjectID,AFE_DescID ,Torder, AFEDesc, FunCat, LocationID, ProjectTitle, FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12, FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18, Totalrow,UpdateBy)                      
--select distinct tspd.ProjectID, tspd.AFE_DescID, '2', ts.AFEDesc, ts.FunCat, ts.LocationID, tbp.ProjectTitle, tspd.FTE_frcst_mo1, tspd.FTE_frcst_mo2, tspd.FTE_frcst_mo3, tspd.FTE_frcst_mo4, tspd.FTE_frcst_mo5, tspd.FTE_frcst_mo6, tspd.FTE_frcst_mo7, tspd.FTE_frcst_mo8, tspd.FTE_frcst_mo9, tspd.FTE_frcst_mo10, tspd.FTE_frcst_mo11, tspd.FTE_frcst_mo12, tspd.FTE_frcst_mo13, tspd.FTE_frcst_mo14, tspd.FTE_frcst_mo15, tspd.FTE_frcst_mo16, tspd.FTE_frcst_mo17, tspd.FTE_frcst_mo18, 0, null                       
--from #tmpStaffingplan ts, tblStaffingPlanDetailByProject tspd       
--	inner join tblproject tbp on tbp.ProjectID=tspd.ProjectID        
--	inner join tblResourceDetail trd on trd.ProjectID = tspd.ProjectID  --Added by Lizzy                 
--where tbp.StatusCode = 'A' and tspd.LocationID = 4000 AND tspd.CurrentMonth = @Month and tspd.AFE_DescID =ts.AFE_DescID        
--and CONVERT(VARCHAR(06), trd.workdate, 112) = @Month --Added by Lizzy      
      
--INSERT MANUAL RECORDS AT THE PROJECT LEVEL FROM THE TBLPROJECTMANUAL TABLE 
INSERT INTO #tmpStaffingplan (ProjectID,AFE_DescID, Torder, AFEDesc, FunCat, LocationID, ProjectTitle, FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12, FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18, Totalrow, UpdateBy)      
select distinct tspd.ProjectID, tspd.AFE_DescID, '2', ts.AFEDesc, ts.FunCat, ts.LocationID, tbp.ProjectTitle, tspd.FTE_frcst_mo1, tspd.FTE_frcst_mo2, tspd.FTE_frcst_mo3, tspd.FTE_frcst_mo4, tspd.FTE_frcst_mo5, tspd.FTE_frcst_mo6, tspd.FTE_frcst_mo7, tspd.FTE_frcst_mo8, tspd.FTE_frcst_mo9, tspd.FTE_frcst_mo10, tspd.FTE_frcst_mo11, tspd.FTE_frcst_mo12, tspd.FTE_frcst_mo13, tspd.FTE_frcst_mo14, tspd.FTE_frcst_mo15, tspd.FTE_frcst_mo16, tspd.FTE_frcst_mo17, tspd.FTE_frcst_mo18, 0, 'Admin' 
from #tmpStaffingplan ts, tblStaffingPlanDetailByProject tspd       
	inner join tblprojectmanual tbp on tbp.ProjectID=tspd.ProjectID                    
where tspd.LocationID = 4000 AND tspd.CurrentMonth = '201404' and tspd.AFE_DescID=ts.AFE_DescID                      
--where tbp.StatusCode = 'A' and tspd.LocationID = 4000 AND tspd.CurrentMonth = @Month and tspd.AFE_DescID=ts.AFE_DescID                      
                    
-- this query is when there is no sub project to display we are going to show summary data itself                    
INSERT INTO #tmpStaffingplan (AFE_DescID, Torder, AFEDesc, FunCat, LocationID, ProjectID, ProjectTitle, FTE_frcst_mo1, FTE_frcst_mo2, FTE_frcst_mo3, FTE_frcst_mo4, FTE_frcst_mo5, FTE_frcst_mo6, FTE_frcst_mo7, FTE_frcst_mo8, FTE_frcst_mo9, FTE_frcst_mo10, FTE_frcst_mo11, FTE_frcst_mo12, FTE_frcst_mo13, FTE_frcst_mo14, FTE_frcst_mo15, FTE_frcst_mo16, FTE_frcst_mo17, FTE_frcst_mo18, Totalrow, UpdateBy)      
SELECT distinct des.AFE_DescID, '3', des.Description as AFEDesc, lkFun.Description as FunCat, tspd.LocationID, null, null, tspd.FTE_frcst_mo1, tspd.FTE_frcst_mo2, tspd.FTE_frcst_mo3, tspd.FTE_frcst_mo4, tspd.FTE_frcst_mo5, tspd.FTE_frcst_mo6, tspd.FTE_frcst_mo7, tspd.FTE_frcst_mo8, tspd.FTE_frcst_mo9, tspd.FTE_frcst_mo10, tspd.FTE_frcst_mo11, tspd.FTE_frcst_mo12, tspd.FTE_frcst_mo13, tspd.FTE_frcst_mo14, tspd.FTE_frcst_mo15, tspd.FTE_frcst_mo16, tspd.FTE_frcst_mo17, tspd.FTE_frcst_mo18, 0, '' as UpdateBy                       
FROM lkAFEDescription des inner join tblAFEDetail det on des.AFE_descID = det.AFE_DescID                       
	inner join lkFundingCat lkFun on det.Funding_catID = lkFun.Funding_CatID                       
    inner join tblStaffingPlanDetail tspd on des.AFE_DescID = tspd.AFE_DescID                       
    inner join tblstaffingplan tsp on tspd.CurrentMonth  = tsp.CurrentMonth               
	-- inner join tblproject tbp on des.AFE_DescID = tbp.AFE_DescID --Added by Lizzy      --commented by Sangeetha        
WHERE tspd.LocationID = 4000 AND substring(des.Description,1,2) between 'A' AND 'Zz' AND tspd.CurrentMonth = '201404'                     
--and tbp.StatusCode = 'A'  --Added by Lizzy  --commented by Sangeetha    
order by AFEDesc                                       
                    
delete from #tmpStaffingplan where Torder=3 and AFE_DescID in (select AFE_DescID from #tmpStaffingplan where Torder=2)                    
update #tmpStaffingplan set Totalrow = (select count (*)-1 from #tmpStaffingplan t where t.AFE_DescID = #tmpStaffingplan.AFE_DescID)                  
--delete from #tmpStaffingplan where Torder > 1 and ProjectID is null --Added by Lizzy      --commented by sangeetha 31Mar2014
delete from #tmpStaffingplan  where AFE_DescID in(select AFE_DescID from #tmpStaffingplan group by AFE_DescID having count(AFE_DescID)=1 ) --Added by Sangeetha 31mar2014
                        
SELECT * FROM #tmpStaffingplan order by AFEDesc, FunCat, Torder asc                     
                      
DROP TABLE #tmpStaffingplan                      
                



