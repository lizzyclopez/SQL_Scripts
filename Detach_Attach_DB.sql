exec sp_detach_db 'sap_import', 'false'
exec sp_detach_db 'msps_import', 'false'
exec sp_detach_db 'piv_reports', 'false'
exec sp_detach_db 'aldea_import', 'false'
exec sp_detach_db 'msps_archive', 'false'
exec sp_detach_db 'piv_reports_2008', 'false'

--Copy the dat and log files

exec sp_attach_db 'sap_import', 'E:\SQLData\sap_import_data.mdf', 'D:\SQLLogs\sap_import_log.ldf'
exec sp_attach_db 'msps_import', 'E:\SQLData\msps_import_data.mdf', 'D:\SQLLogs\msps_import_log.ldf'
exec sp_attach_db 'piv_reports', 'E:\SQLData\piv_reports.mdf', 'D:\SQLLogs\piv_reports_log.ldf'
exec sp_attach_db 'aldea_import', 'E:\SQLData\aldea_import.mdf', 'D:\SQLLogs\aldea_import_log.ldf'
exec sp_attach_db 'msps_archive', 'E:\SQLData\msps_archive_data.mdf', 'D:\SQLLogs\msps_archive_log.ldf'
exec sp_attach_db 'piv_reports_2008', 'E:\SQLData\piv_reports_2008_data.mdf', 'D:\SQLLogs\piv_reports_2008_log.ldf'

exec sp_attach_db 'sap_import', 'c:\data\sap_import_data.mdf', 'c:\data\sap_import_log.ldf'
exec sp_attach_db 'piv_reports', 'c:\data\piv_reports.mdf', 'c:\data\piv_reports_log.ldf'
exec sp_attach_db 'msps_import', 'c:\data\msps_import_data.mdf', 'c:\data\msps_import_log.ldf'
exec sp_attach_db 'aldea_import', 'c:\data\aldea_import.mdf', 'c:\data\aldea_import_log.ldf'
exec sp_attach_db 'msps_archive', 'c:\data\msps_archive_data.mdf', 'c:\data\msps_archive_log.ldf'
exec sp_attach_db 'piv_reports_2008', 'c:\data\piv_reports_2008_data.mdf', 'c:\data\piv_reports_2008_log.ldf'


