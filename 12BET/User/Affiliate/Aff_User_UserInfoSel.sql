/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_UserInfoSel]
	@AffId INT
AS

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User - My Account - Select user info
	
	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		ai.AffId,
		ai.username,
		ISNULL(ad.gender, 0) AS gender,
		ad.address,
		ad.city,
		ad.State,
		ad.postal,
		ad.country,
		ai.email,
		ad.phone,
		ad.ContactApps,
		ad.SiteUrl,
		ad.MoreSiteURLs,
		ad.NoSiteDesc,
		ad.PreferredLanguage,
		ad.PreferredPayment,
		ad.Player_Username AS PlayerUsername
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId=@AffID
END
GO