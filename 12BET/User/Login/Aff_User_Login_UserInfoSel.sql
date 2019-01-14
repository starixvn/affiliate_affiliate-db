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

	Parameter's Explanation:
		- @UserName: username or mail of user

*/

BEGIN
	SET NOCOUNT ON
	
	SELECT
		ai.AffID,
		ai.UserName,
		ai.Password,
		ai.Currency AS CurrencyId,
		ai.GroupID,
		cg.GroupName,
		ai.AffType,
		ai.IsClosed,
		ai.Status,
		ad.PreferredLanguage,
		ai.IsLocked
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffID = ad.AffID
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupID = cg.GroupID
	WHERE (ai.UserName = @UserName OR ai.Email = @UserName)
		AND cg.IsDeleted = 0
END
GO