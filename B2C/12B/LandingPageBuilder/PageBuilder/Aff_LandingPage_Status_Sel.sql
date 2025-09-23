/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Status_Sel]
AS
/*
	Created: 20250826@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Select Landing Page Status List
	Revisions:
		- 20250826@Sophia: Initial version [RedmineID: #236797]
		- 20250826@Copilot: Refactored to use fn_LandingPage_Status
*/
BEGIN
	SET NOCOUNT ON;

	SELECT StatusId, Status
	FROM dbo.Aff_f_LandingPage_Status()
	ORDER BY StatusId ASC;
END;
GO
