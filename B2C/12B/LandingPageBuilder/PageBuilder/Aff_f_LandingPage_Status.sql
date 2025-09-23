/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet,wsv_afinetv" isFunction="1" isNested="0"></info>*/
CREATE FUNCTION [dbo].[Aff_f_LandingPage_Status]()
RETURNS TABLE
/*
	Created: 20250826@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Table-valued function for Landing Page Status
	Revisions:
		- 20250826@Sophia: Initial version [RedmineID: #236797]
*/

AS
RETURN
(
	SELECT StatusId, Status FROM (
		VALUES
			(0, 'Draft'),
			(1, 'Active'),
			(2, 'Inactive')
	) AS StatusTable(StatusId, Status)
);
GO
