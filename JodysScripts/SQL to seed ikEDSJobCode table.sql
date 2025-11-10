Use PIV_Reports

Select Distinct EDSJobCode
Into #temp
From tblResource
Order By EDSJobCode

Delete from #temp
Where EDSJobCode Is Null

Insert into lkEDSJobCode
select	EDSJobCode as JobCodeDesc,
		'A' as StatusCode,
		GetDate() as LastUpdateDate
from #temp

select * from lkEDSJobCode
