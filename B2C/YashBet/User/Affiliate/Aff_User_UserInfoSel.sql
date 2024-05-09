/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_UserInfoSel]
	@AffId INT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User - My Account - Select user info

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffCurrency INT, @AffCurrencyCode VARCHAR(5)
	SELECT  @AffCurrency = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffCurrency'

	-- Get affcurrency mapping
	DECLARE @AffExchangeId INT = @AffCurrency
	SELECT  @AffExchangeId = tp.ExchangeId
	FROM dbo.TpExchange tp WITH (NOLOCK)
	WHERE tp.TpExchangeId = @AffCurrency

	SELECT  @AffCurrencyCode = Code FROM dbo.Exchange WITH (NOLOCK) WHERE ExchangeId = @AffExchangeId

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