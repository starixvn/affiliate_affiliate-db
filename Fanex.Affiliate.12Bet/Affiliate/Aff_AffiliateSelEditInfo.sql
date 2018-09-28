/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_AffiliateSelEditInfo]
	@AffId INT,
	@AFF_MinWire			MONEY = 0 OUTPUT,
	@Aff_MinNeteller		MONEY = 0 OUTPUT,
	@AFF_MinCheque			MONEY = 0 OUTPUT,
	@AFF_MinMoneybookers	MONEY = 0 OUTPUT,
	@AFF_MinPlayer			MONEY = 0 OUTPUT
AS

/*
	Created:
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin Site - Customer - Edit tab - Select aff's info

	Revisions:
		- 20180601@Percy: Return ContactApps [RedmineID: #87923]
*/

BEGIN

SET NOCOUNT ON
	DECLARE @currencyName VARCHAR(5)

	SELECT @currencyName = e.Currency
	FROM dbo.Exchange_Current e WITH (NOLOCK)
		INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON a.Currency = e.ExchangeId
	WHERE a.AffId = @AffId

	SELECT
		@AFF_MinWire		 = CASE WHEN SName = 'AFF_MinWire'			+ @currencyName THEN SValue ELSE @AFF_MinWire END,
		@Aff_MinNeteller	 = CASE WHEN SName = 'AFF_MinNeteller'		+ @currencyName THEN SValue ELSE @Aff_MinNeteller END,
		@AFF_MinCheque		 = CASE WHEN SName = 'AFF_MinCheque'		+ @currencyName THEN SValue ELSE @AFF_MinCheque END,
		@AFF_MinMoneybookers = CASE WHEN SName = 'AFF_MinMoneybookers'	+ @currencyName THEN SValue ELSE @AFF_MinMoneybookers END,
		@AFF_MinPlayer		 = CASE WHEN SName = 'AFF_MinPlayer'		+ @currencyName THEN SValue ELSE @AFF_MinPlayer END
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName LIKE 'AFF_Min%'

	SELECT 	
		ai.AffId,
		ai.username,
		ad.gender,
		ai.firstname,
		ai.lastname,
		ai.Status,
		ai.email,
		ad.phone,
		ad.ContactApps,
		ad.address,
		ad.city,
		ad.state,
		ad.postal,
		ad.country,	
		ad.SiteURL ,
		ad.MoreSiteURLs,
		ad.NoSiteDesc,
		ad.PreferredPayment, --Player, Neteller, Moneybookers, Wire, Cheque
		ad.PreferredLanguage,
		ad.Player_Username,
		ad.Neteller_AccountID,
		ad.Moneybookers_Email,
		ad.Wire_BankName,
		ad.Wire_BankAddress,
		ad.Wire_SwiftCode,
		ad.Wire_AccountName,	
		ad.Wire_AccountNo,
		ad.Cheque_FullName,
		ad.Cheque_Address,
		ad.Cheque_City,
		ad.Cheque_State,
		ad.Cheque_Postal,
		ad.Cheque_Country,
		ad.question,
		ad.answer,
		ad.mailoption		
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE  ai.AffId = @AffID
END
GO