/*
USE [PIV_Reports]
GO
*/
/****** Object:  Table [dbo].[lkResourceOrg]    Script Date: 10/08/2008 16:26:32 ******/
/*
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[lkResourceOrg](
	[Resource_OrgId] [int] IDENTITY(3000,1) NOT NULL,
	[Description] [varchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StatusCode] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LastUpdateDate] [datetime] NULL CONSTRAINT [DF_lkResourceOrg_LastUpdateDate]  DEFAULT (getdate())
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
*/

-- Seed the table
INSERT INTO dbo.lkResourceOrg
	(Description, StatusCode, LastUpdateDate)

	SELECT distinct 
		ResourceOrg as Description,
		'A' as StatusCode,
		GetDate() as LastUpdateDate

	FROM tblResource
	WHERE ResourceOrg IS NOT NULL AND ResourceOrg <> ''

	UNION

	SELECT DISTINCT 
		'GCR - ' + ResourceOrg as Description,
		'A' as StatusCode,
		GetDate() as LastUpdateDate
	FROM tblResource
	WHERE ResourceOrg IS NOT NULL AND ResourceOrg <> ''
	AND Keyword = 'CESC GCR'
	
	ORDER BY 2
