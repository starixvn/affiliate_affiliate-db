/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_LandingPage_Campaign_Dashboard_Sel]
AS
/*
	Created: 20250905@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Marketing tools - All Campaign - Campaign Dashboard
	Revisions:
		- 20250905@Eddie: Initial version [RedmineID: #236797]
*/
BEGIN
	SET NOCOUNT ON;

	SELECT COUNT(*) AS TotalCampaigns
          ,SUM(CASE WHEN StatusId = 0 THEN 1 ELSE 0 END) AS DraftCampaigns
          ,SUM(CASE WHEN StatusId = 1 THEN 1 ELSE 0 END) AS ActiveCampaigns
          ,SUM(CASE WHEN StatusId = 2 THEN 1 ELSE 0 END) AS PausedCampaigns
          ,SUM(CASE WHEN StatusId = 3 THEN 1 ELSE 0 END) AS InactiveCampaigns
	FROM dbo.LandingPage_Campaign WITH (NOLOCK);

END
GO
