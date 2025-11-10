select * from piv_import..log where ts >= '2006-07-18 13:00' and text like '%ended%'
order by ts


select * from piv_import..log where statuscode = 'e' order by ts desc