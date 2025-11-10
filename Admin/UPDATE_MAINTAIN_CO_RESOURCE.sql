select distinct ProjectName from sap_import..sap_resourceDetails where recWBSelement in ( 'A-0000029084-100150','A-0000029155-100160','A-0000029438-000100','A-0000038583-101001-IN70','A-0000038583-102008-IN70','K-0000002273-000003-3207','K-0000002273-000003-3228','K-0000012320-100150','K-0000012320-100380','K-0000012321-100130','K-0000012323-100140','K-0000012323-100370','K-0000012433-100240','K-0000018909-100020','K-0000018909-100050','Y-0000800047-TASK','Y-5556800042-TASK')
select distinct Name, IdNumber from sap_import..compass_resourceDetails

select * from sap_import..all_resourceDetails where recWBSelement not in ( 'A-0000029084-100150','A-0000029155-100160','A-0000029438-000100','A-0000038583-101001-IN70','A-0000038583-102008-IN70','K-0000002273-000003-3207','K-0000002273-000003-3228','K-0000012320-100150','K-0000012320-100380','K-0000012321-100130','K-0000012323-100140','K-0000012323-100370','K-0000012433-100240','K-0000018909-100020','K-0000018909-100050','Y-0000800047-TASK','Y-5556800042-TASK') and hours > '0.00' order by name

--82 resources not setup in R2
select distinct name, IdNumber from sap_import..all_resourceDetails where recWBSelement not in ( 'A-0000029084-100150','A-0000029155-100160','A-0000029438-000100','A-0000038583-101001-IN70','A-0000038583-102008-IN70','K-0000002273-000003-3207','K-0000002273-000003-3228','K-0000012320-100150','K-0000012320-100380','K-0000012321-100130','K-0000012323-100140','K-0000012323-100370','K-0000012433-100240','K-0000018909-100020','K-0000018909-100050','Y-0000800047-TASK','Y-5556800042-TASK') and hours > '0.00'
and IdNumber not in (select ResourceNumber from piv_reports..CO_Resource) or IdNumber in (select ResourceNumber from piv_reports..CO_Resource where Billing_CodeId is null)

select * from piv_reports..tblResource where Lastname = 'GANGYADA' and FirstName = 'SWETHA'
select * from piv_reports..CO_Resource where Lastname = 'VENKATESAN' and FirstName = 'PREETHI'

--update piv_reports..CO_Resource set Billing_CodeID = '3002', JobCodeID = '4030', Resource_OrgID = '3065', Onshore = 1 where ResourceNumber = '21591323'
insert into piv_reports..CO_Resource values 
('82038675', '3002', '4029', '3045', 'VENKATESAN', 'PREETHI', ' ', 0, 1, 0, getdate(), '16.15', 0, 0)


