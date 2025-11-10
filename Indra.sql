MSPS unique id: 43668
Work date: Jan 2011 to Feb 2012

select * from msps_import..all_project where mspsScheduleUniqueID = '43668'
ASA_US_TRAN_CO_CO SHARES PLOGS 2012

select p.ProjectTitle, t.Name, r.LastName, r.FirstName, rd.ResourceNumber, SUM(rd.Hours) AS Hours 
from tblResourceDetail As rd									
INNER JOIN CO_Resource As r on r.ResourceNumber = rd.ResourceNumber									
INNER JOIN tblProject As p on p.projectid = rd.projectid			
INNER JOIN tblTask As t on t.projectid = p.projectid						
where rd.WorkDate >= '2012-02-01' and rd.WorkDate <= '2012-02-29' 
--and rd.projectid = 'AE088569-A643-46BC-AB80-BC8344289D5D' 
and p.ProjectTitle like '%Plogs%' and rd.Hours > 0					
GROUP BY p.ProjectTitle, t.Name, r.LastName, r.FirstName, rd.ResourceNumber ORDER BY p.ProjectTitle, t.Name, r.LastName


