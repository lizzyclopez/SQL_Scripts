exec master..xp_sendmail
    @recipients = 'lizzy.lopez@hp.com', @message = 'This is a test', @subject = 'TEST'

USE master
EXEC sp_configure 'show advanced option', '1'
RECONFIGURE
EXEC sp_configure

EXEC sp_configure 'user instances enabled', 1;RECONFIGURE;


EXEC xp_sendmail @email@removed', @message&H3D'This is a test'

DECLARE @test VARCHAR(8000)
SET @test = 'This is a test'
EXEC master.dbo.xp_sendmail @recipients = 'lizzy.lopez@hp.com', @subject = 'test', @message = @test

		-- Send email with attachment.
 		EXEC master..xp_sendmail @recipients = 'Shirly.Hanlon-Blanco@hp.com', 
   			@message = 'The attached file containining Mesage Type U from ACAR_MESSAGE table.', 			@copy_recipients = 'lizzy.lopez@hp.com',
  			@subject = ' >>>  ACARS MESSAGE TYPE U <<<',
		    @attachments = 'd:\ACARS_Type_U.zip'
