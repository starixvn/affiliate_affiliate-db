/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_UserInfoSel]
	@AffId INT
AS

/*
	Creator: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: User - My Account - Select user info
	
	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #87923]
		- 20201026@Percy: Add AffCode [RedmineID: #143852]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffCurrency INT, @AffCurrencyCode VARCHAR(5)
	SELECT  @AffCurrency = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffCurrency'

	SELECT  @AffCurrencyCode = Code FROM dbo.Exchange WITH (NOLOCK) WHERE ExchangeId = @AffCurrency

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
		ad.Player_Username AS PlayerUsername,
		@AffCurrencyCode AS AffCurrency,
		ai.DefaultCurrency AS DefaultBaseCurrency,
		ai.AffCode
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId=@AffID
END
GO