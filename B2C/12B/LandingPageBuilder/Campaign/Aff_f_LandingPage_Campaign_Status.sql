/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet,wsv_afinetv" isFunction="1" isNested="0"></info>*/
CREATE FUNCTION [dbo].[Aff_f_LandingPage_Campaign_Status]()
RETURNS TABLE
/*
	Created: 20250903@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Table-valued function for Campaign Status
	Revisions:
		- 20250903@Eddie: Initial version [RedmineID: #236797]
*/
AS
RETURN
(
	SELECT StatusId, Status
	FROM (
		VALUES (0, 'Draft')
			  ,(1, 'Active')
			  ,(2, 'Paused')
			  ,(3, 'Inactive')
	) AS StatusTable(StatusId, Status)
)
GO
