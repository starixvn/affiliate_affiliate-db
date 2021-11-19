/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_UserInfoSel]
	@AffId INT
AS

/*
	Creator: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User - My Account - Select user info
	
	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #87923]
		- 20201026@Percy: Add AffCode [RedmineID: #143852]
		- 20211005@Percy: Support Transfer Balance For Player [RedmineID: #153227]
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
		ad.TransferLimit,
		ad.Player_CustId AS PlayerCustId,
		ad.Player_Username AS PlayerUsername,
		ad.Player_Currency AS PlayerCurrencyId,
		ad.Player_CurrencyCode AS PlayerCurrency,
		@AffCurrencyCode AS AffCurrency,
		ai.DefaultCurrency AS DefaultBaseCurrency,
		ai.AffCode
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId = @AffId
END
GO