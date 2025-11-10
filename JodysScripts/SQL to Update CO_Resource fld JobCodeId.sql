/* *****************
1. Before running this SQl you will need to manually add the following fields to the CO_Resource table.
	Add them after Billing_CodeId and before LastName.

	[JobCodeId] [int] NULL,
	[Resource_OrgId] [int] NULL,
*/

/* *****************
2. Run this SQL to build the FK relationship between the new Job Code field and the new lkEDSJobCode table

	USE [PIV_Reports]
	GO
	ALTER TABLE [dbo].[CO_Resource]  WITH NOCHECK ADD  CONSTRAINT [fk_EDSJobCode_Res] FOREIGN KEY([JobCodeId])
	REFERENCES [dbo].[lkEDSJobCode] ([JobCodeId])
	GO
	ALTER TABLE [dbo].[CO_Resource] CHECK CONSTRAINT [fk_EDSJobCode_Res]
	GO

-- Before running the following you need to manually make sure that Resource_Org_Id is defined as the primary key of lkResourceOrg
	ALTER TABLE [dbo].[CO_Resource]  WITH NOCHECK ADD  CONSTRAINT [fk_ResourceOrg_Res] FOREIGN KEY([Resource_OrgId])
	REFERENCES [dbo].[lkResourceOrg] ([Resource_OrgId])
	GO
	ALTER TABLE [dbo].[CO_Resource] CHECK CONSTRAINT [fk_ResourceOrg_Res]
	GO
*/

/* *****************
3. Run this SQL to populate the new JobCodeId field on the CO_Resource table
	Use PIV_Reports
	
	Select PIV.ResourceNumber, EJC.JobCodeId
	Into #Temp
	From tblResource PIV
	Join CO_Resource CO 
		On PIV.ResourceNumber = CO.ResourceNumber
	Join lkEDSJobCode EJC
		On EJC.JobCodeDesc = PIV.EDSJobCode
	Where CO.ResourceNumber = PIV.ResourceNumber

--	Select * from #Temp

	Update CO_Resource 
	Set JobCodeId = (select #Temp.JobCodeId from #Temp where #Temp.ResourceNumber = CO_Resource.ResourceNumber)

-- The following is used for verification
--	select	co.ResourceNumber, co.JobCodeId, t.*
--	Select co.*
--	From CO_Resource co
--	Left Outer Join #Temp t On co.ResourceNumber = t.ResourceNumber
--	where co.JobCodeId is null
--	order by co.LastName
 */


/* *****************
3. Run this SQL to populate the new Resource_OrgId field on the CO_Resource table
	Use PIV_Reports

	select	r.ResourceNumber, ro.Resource_OrgId
	Into #Temp2
	from tblResource r
	Join lkResourceOrg ro
	on r.ResourceOrg = ro.Description
	order by r.ResourceOrg

--	Select * from #Temp2

	Update CO_Resource 
	Set Resource_OrgId = (select #Temp2.Resource_OrgId from #Temp2 where #Temp2.ResourceNumber = CO_Resource.ResourceNumber)

-- The following is used for verification
--	Select co.*
--	From CO_Resource co
--	where co.Resource_OrgId is null
--	order by co.LastName

 */

