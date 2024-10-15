/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Get_PartnerExchangeID]
	@Currencies		VARCHAR(MAX),
	@CurrencyType	TINYINT = 1
AS

/*
	Task: Remove linked server to DBCust
	DB: DBAFF-Affiliate_Athena000
	
	Revisions:
		- 20240806@Sally: Initialize SP [RedmineID: #206891]

	Param's Explanation:
		- @CurrencyType : 
			+ 1: CurrencyCode
			+ 0: CurrencyId
		- @Currencies: Currency of Aff
			+ @Currencies =  'MYR,CNY,EUR,USD,UUS,AUD,KRW,VND'
			+ @Currencies =  '13,15,51'
*/

BEGIN

	SET NOCOUNT ON;

	DECLARE @PartnerExchangeIDs VARCHAR(MAX)

	SELECT @PartnerExchangeIDs = COALESCE(@PartnerExchangeIDs + ', ', '') + CONVERT(VARCHAR(10), t.PartnerExchangeID)
	FROM dbo.Aff_f_Get_PartnerExchangeID (@Currencies, @CurrencyType) t

	SELECT @PartnerExchangeIDs AS PartnerExchangeIDs

END
