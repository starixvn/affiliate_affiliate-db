/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_Login_UserInfoSel]
	@UserName NVARCHAR(50)
AS

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Login - Get user info by username

	Revisions:
		- 20180601@Percy: Initiliaze SP [RedmineID: #87923]
		- 20211213@Malcolm: Add information of exclusive page [RedmineID: #165915]

	Parameter's Explanation:
		- @UserName: username or mail of user

*/

BEGIN
	SET NOCOUNT ON
	
	SELECT
		ai.AffID,
		ai.UserName,
		ai.Password,
		cg.GroupName,
		ai.AffType,
		ai.IsClosed,
		ai.Status,
		ad.PreferredLanguage,
	    CASE WHEN op.PageId IS NULL THEN 0
			 WHEN GETDATE() BETWEEN op.EffectiveFromDate AND op.EffectiveToDate THEN op.PageId  
		ELSE 0 END AS OfferPageId
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffID = ad.AffID
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupID = cg.GroupID
		LEFT JOIN dbo.OfferAffiliate ea WITH(NOLOCK) ON ea.AffId = ai.AffID
		LEFT JOIN dbo.OfferPage op WITH(NOLOCK) ON op.PageId = ea.PageId
	WHERE (ai.UserName = @UserName OR ai.Email = @UserName)
		AND cg.IsDeleted = 0
END
GO