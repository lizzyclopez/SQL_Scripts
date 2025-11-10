select * from piv_import..log where ts >= convert(char(8),getdate(),112) and text like '%ended%' order by ts


--delete from piv_import..log where ts >= convert(char(8),getdate(),112)
--select * from piv_import..log where statuscode = 'e' order by ts desc
----------------- MUST verify if the following 'Get' steps ran successful in the logs not SQL - AFTER FINISHED RUNNING.
----------------- 1-1 GetProjectDataCO (master)
	--exec xp_cmdshell 'cscript f:\applications\piv_transfer\download\GetProjectData.vbs 1 A'
----------------- 1-2 GetProjectDataIPD (master)
	--exec xp_cmdshell 'cscript f:\applications\piv_transfer\download\GetProjectData.vbs 2 A'
----------------- 1-3 GetProjectDtaNCL (master)
	--exec xp_cmdshell 'cscript f:\applications\piv_transfer\download\GetProjectData.vbs 3 A'
----------------- 1-4 GetProjectDataGAL (master)
	--exec xp_cmdshell 'cscript f:\applications\piv_transfer\download\GetProjectData.vbs 4 A'
----------------- 1-5 GetProjectDataMIR (master)
	--exec xp_cmdshell 'cscript f:\applications\piv_transfer\download\GetProjectData.vbs 5 A'
----------------- 1-6 Get Aldea Data (master)
	--exec xp_cmdshell 'dtexec /f "f:\Applications\PIV_Transfer\SSIS Package - Import Aldea data.dtsx"'
----------------- 1-7 GetResourceData (master)
	--exec xp_cmdshell 'cscript f:\applications\piv_transfer\download\GetResourceData.vbs'

----------------- 3-1 DTS ProjectDataCO.mdb (master)
	--exec xp_cmdshell 'dtexec /f "f:\Applications\PIV_Transfer\AM SSIS Package - CO.dtsx"'
	--insert into PIV_Import..Log ( StatusCode, ProcessName, Text) values( 'I', 'DTS ProjectDataCO.mdb', '3-1 DTS ProjectDataCO.mdb - Ended At '+convert(varchar(25), getdate(),120))	
----------------- 3-2 DTS ProjectDataCO.mdb Text14 (master)
	--exec xp_cmdshell 'dtexec /f "f:\Applications\PIV_Transfer\AM SSIS Package - CO_Text14.dtsx"'
	--insert into PIV_Import..Log ( StatusCode, ProcessName, Text) values( 'I', 'DTS Text14 ProjectDataCO.mdb', '3-2 DTS Text14 ProjectDataCO.mdb - Ended At '+convert(varchar(25), getdate(),120))
----------------- 3-3 DTS ProjectDataIDP.mdb (master)
	--exec xp_cmdshell 'dtexec /f "f:\Applications\PIV_Transfer\AM SSIS Package - IPD_SQL2000.dtsx"'
	--insert into PIV_Import..Log ( StatusCode, ProcessName, Text) values( 'I', 'DTS ProjectDataIPD.mdb', '3-3 DTS ProjectDataIPD.mdb - Ended At '+convert(varchar(25), getdate(),120))
----------------- 3-4 DTS ProjectDataIDP.mdb Text14 (master)
	--exec xp_cmdshell 'dtexec /f "f:\Applications\PIV_Transfer\AM SSIS Package - IPD_Text14.dtsx"'
	--insert into PIV_Import..Log ( StatusCode, ProcessName, Text) values( 'I', 'DTS Text14 ProjectDataIPD.mdb', '3-4 DTS Text14 ProjectDataIPD.mdb - Ended At '+convert(varchar(25), getdate(),120))
----------------- 3-5 DTS ProjectDataNCL.mdb (master) 
	--exec xp_cmdshell 'dtexec /f "f:\Applications\PIV_Transfer\AM SSIS Package - NCL.dtsx"'
	--insert into PIV_Import..Log ( StatusCode, ProcessName, Text) values( 'I', 'DTS ProjectDataNCL.mdb', '3-5 DTS ProjectDataNCL.mdb - Ended At '+convert(varchar(25), getdate(),120))
----------------- 3-6 DTS ProjectDataGAL.mdb (master) 
	--exec xp_cmdshell 'dtexec /f "f:\Applications\PIV_Transfer\AM SSIS Package - GAL.dtsx" '
	--insert into PIV_Import..Log ( StatusCode, ProcessName, Text) values( 'I', 'DTS ProjectDataGAL.mdb', '3-6 DTS ProjectDataGAL.mdb - Ended At '+convert(varchar(25), getdate(),120))
----------------- 3-7 DTS ProjectDataMIR.mdb (master) 
	--exec xp_cmdshell 'dtexec /f "f:\Applications\PIV_Transfer\AM SSIS Package - MIR.dtsx"'
	--insert into PIV_Import..Log ( StatusCode, ProcessName, Text) values( 'I', 'DTS ProjectDataMIR.mdb', '3-7 DTS ProjectDataMIR.mdb - Ended At '+convert(varchar(25), getdate(),120))
----------------- 3-8 DTS ResourceData.csv (master)
	--exec xp_cmdshell 'dtexec /f "f:\Applications\PIV_Transfer\ResourceDetailsPackage.dtsx"'  
	--insert into PIV_Import..Log ( StatusCode, ProcessName, Text) values( 'I', 'DTS ResourceData.csv', '3-8 DTS ResourceData.csv - Ended At '+convert(varchar(25), getdate(),120))

----------------- Delete the FOT Resource That Were Loaded in Previous Step
	--select count(*) from piv_import..CO_ResourceDetails_CSV where Project# in ('2627','2668','2672','2695','2722','2725','2778','2782')
	--select sum(convert(float,Hours)) from piv_import..CO_ResourceDetails_CSV where Project# in ('2627','2668','2672','2695','2722','2725','2778','2782')
	--delete from piv_import..CO_ResourceDetails_CSV where Project# in ('2627','2668','2672','2695','2722','2725','2778','2782')
----------------- 3-9 DTS FOTResourceDetails.dtsx (master)
	--exec xp_cmdshell 'dtexec /f "f:\Applications\PIV_Transfer\FOTResourceDetails.dtsx"'  
	--select count(*) from piv_import..CO_ResourceDetails_CSV where Project# in ('2627','2668','2672','2695','2722','2725','2778','2782')
	--select sum(convert(float,Hours)) from piv_import..CO_ResourceDetails_CSV where Project# in ('2627','2668','2672','2695','2722','2725','2778','2782')
	--insert into PIV_Import..Log ( StatusCode, ProcessName, Text) values( 'I', 'DTS FOTResourceData.xls', '3-9 DTS FOTResourceData.xls - Ended At '+convert(varchar(25), getdate(),120))

----------------- 5-0 Pre-Process Data (PIV_Import)
	--exec PreProcess_ResourceDetails 
	--exec PreProcess_All_Tables
	--exec PreProcess_Pseudo_Records 
	--insert into PIV_Import..log ( StatusCode, ProcessName, Text) values( 'I', 'Loading PIV_Reports',  '5-0 Pre-Process Data- PIV_Import Ended At '+convert(varchar(25), getdate(),120))

----------------- 5-1 Process SP Loading (PIV_Import)
	--exec Process_Project
	--exec Process_Task
	--exec Process_Requirements
	--exec Process_Resource
	--exec Process_ResourceDetails
	--exec Process_ResourceDetails_NPT
	--insert into PIV_Import..log ( StatusCode, ProcessName, Text) values( 'I', 'Loading PIV_Reports',  '5-1 Process SP Loading PIV_Reports Ended At '+convert(varchar(25), getdate(),120))
	
----------------- 5-2 Pre-build AFE_Resource_Detail Reports (PIV_Reports)
	--exec Pre_Build_Get_AFE_Resource_Detail
	--exec Pre_Build_Solution_Centre_Data	
	--insert into PIV_Import..log ( StatusCode, ProcessName, Text) values( 'I', 'Pre-build Reports',  '5-2 Pre-build AFE_Resource_Detail Reports Ended At '+convert(varchar(25), getdate(),120))
	--exec Load_YTD_Tables	
	--insert into PIV_Import..log ( StatusCode, ProcessName, Text) values( 'I', 'Pre-build Tables',  '5-3 Pre-build YTD Tables Ended At '+convert(varchar(25), getdate(),120))
	
----------------- 5-3 Pre-build YTD Tables (PIV_Reports)
	--insert into PIV_Import..log ( StatusCode, ProcessName, Text) values( 'I', 'Comments',  '*** Loading Complete. All steps above Ended successfully ***')
	--exec Send_Notification @AM_PM_Indicator = 'AM'
	----------------- *** Loading Complete. (PIV_Reports)
	
	----------------- Archive/Purge/Delete (PIV_Import)
	--exec Purge_Archived_Tables
	--exec Archive_Import_Tables
	-- Keep only 7 days of log
	--delete PIV_Import..Log where TS < dateadd(dd, -7, getdate())	
