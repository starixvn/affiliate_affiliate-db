/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_LandingPage_Campaign_Status_Sel]
AS
/*
	Created: 20250903@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: List of Campaign Status
	Revisions:
		- 20250903@Eddie: Initial version [RedmineID: #236797]
*/
BEGIN
	SET NOCOUNT ON;

	SELECT StatusId, Status
	FROM dbo.Aff_f_LandingPage_Campaign_Status()
	ORDER BY StatusId ASC;
END
GO
