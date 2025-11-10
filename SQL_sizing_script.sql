USE [DATABASENAME]
select 'LOG',fileid, sf.groupid, grp=left([groupname],20), lname=left([name],20), size_mb=[size]/128 
,used_mb=FILEPROPERTY([name], 'SpaceUsed')/128
,file_growth=case when (sf.status&0x100000) > 0 then str(growth)+' %'
			else str(growth/128)+' mb' end
,max_mb=case when [maxsize]<0 then 'Unrestricted'
			else str([maxsize]/128) end
,phname=left(filename,70)
from sysfiles sf left outer join sysfilegroups sfg on sf.groupid=sfg.groupid
Where sf.groupid = 0
order by 1
GO


select 'DATA',fileid, sf.groupid, grp=left([groupname],20), lname=left([name],20), size_mb=[size]/128 
,used_mb=FILEPROPERTY([name], 'SpaceUsed')/128
,file_growth=case when (sf.status&0x100000) > 0 then str(growth)+' %'
			else str(growth/128)+' mb' end
,max_mb=case when [maxsize]<0 then 'Unrestricted'
			else str([maxsize]/128) end
,phname=left(filename,70)
from sysfiles sf left outer join sysfilegroups sfg on sf.groupid=sfg.groupid
Where sf.groupid = 1
order by 1
