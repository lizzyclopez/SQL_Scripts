declare @PreviousDate as varchar(8), @CurrentDate as varchar(8), @strSQL as varchar(1000)

--Copy PIV_Reports database backup
set @strSQL = ''copy f:\SQLBackups\PIV_Reports_backup_'' + @CurrentDate + ''*.bak \\USHOSEDS131-A\PIV_Transfer\SQLServerBackups''
exec xp_cmdshell @strSQL
set @strSQL = ''copy f:\SQLBackups\PIV_Reports_backup_'' + @CurrentDate + ''*.bak \\USHOSEDS130A\SQLBackups\PIV''
exec xp_cmdshell @strSQL

--Cleanup backup file in USHOSEDS132-A TEST server.
set @strSQL = ''del \\USHOSEDS132-A\PIV_Transfer\SQLServerBackups\PIV_Reports_PROD.bak''
exec master..xp_cmdshell @strSQL

--Copy PIV_Reports database backup to the TEST server and rename file to standard name.
declare @OldName as varchar(100), @NewName as varchar(100)
set @OldName = ''PIV_Reports_backup_'' + @CurrentDate + ''*.bak''
set @NewName = ''PIV_Reports_PROD.bak''
set @strSQL = ''copy f:\SQLBackups\PIV_Reports_backup_'' + @CurrentDate + ''*.bak \\USHOSEDS132-A\PIV_Transfer\SQLServerBackups''
exec xp_cmdshell @strSQL
set @strSQL = ''RENAME \\USHOSEDS132-A\PIV_Transfer\SQLServerBackups\'' + @OldName + '' '' + @NewName
exec xp_cmdshell @strSQL

M
\\usclscs101\mirapps\Delivery_Manager\Tasks

N
\\usrrscsc004\proj\PMO\R2\SAP_Extracts

--Cleanup previous day SAP extract file 
declare @strSQL as varchar(1000)
--set @strSQL = 'del m:\usclscs101\mirapps\Delivery_Manager\Tasks\SapData.xls'
set @strSQL = 'del m:\usclscs101\mirapps\Delivery_Manager\Tasks\SapData.xls'
exec master..xp_cmdshell @strSQL

exec master.dbo.xp_cmdshell 'del /Q M:\usclscs101\mirapps\Delivery_Manager\Tasks\SapData.xls'

SET @SQL='EXEC master.dbo.xp_cmdshell ''del /Q G:\MSSQLSERVER\ReportServerTempDB\DIFFERENTIAL\Diff_*'+convert(VARCHAR(10), getdate()-@RETENTION,112) +'*.bak'''  
EXEC (@SQL)  

exec master.dbo.xp_cmdshell 'del /Q \\144.10.8.120\mirapps\Delivery_Manager\Tasks\SapData.xls'

set @SQLCommand = 
'EXEC master..xp_CmdShell ' + '''' + 
'COPY \\128.1.25.12\TestDir\test.txt C:\delme.txt' + ''''
EXEC (@SQLCommand)

declare @strSQL as varchar(1000)
set @strSQL = 'copy f:\Applications\PIV_Transfer\Download\SapData.xls \\usrrscsc004\proj\Pmo\R2'
exec xp_cmdshell @strSQL

declare @strSQL as varchar(1000)
set @strSQL = 'copy f:\Applications\PIV_Transfer\Download\SapData.xls \\usclscs101\mirapps\Delivery_Manager\Tasks'
exec xp_cmdshell @strSQL

exec master..xp_cmdshell "dir \proj\PMO\R2\SAP_Extracts\SapData.xls"

\\usclscs101\mirapps\Delivery_Manager\Tasks

---------------------
EXEC master..xp_CMDShell 'F:\Applications\PIV_Transfer\Download\CopySapFile.bat' 

DECLARE @PassedVariable VARCHAR(100)
DECLARE @CMDSQL VARCHAR(1000)
SET @PassedVariable = ‘SqlAuthority.com’
SET @CMDSQL = ‘c:findword.bat’ + @PassedVariable
EXEC master..xp_CMDShell @CMDSQL