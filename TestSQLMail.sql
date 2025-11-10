
EXEC master.dbo.xp_stopmail

EXEC master.dbo.xp_startmail


--Send mail
EXEC msdb.dbo.sp_send_dbmail
    @recipients=N'lizzy.lopez@hpe.com',
    @body= 'Test Email Body',
    @subject = 'Test Email Subject',
    @profile_name = 'SQL_DBMail'

--EXEC master.dbo.xp_sendmail 
--   @recipients=N'lizzy.lopez@eds.com',
--    @message=N'Testing2' ;

