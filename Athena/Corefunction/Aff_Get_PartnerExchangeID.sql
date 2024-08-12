/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Get_PartnerExchangeID]
	@CurrencyIds VARCHAR(MAX)
AS

/*
	Task: Remove linked server to DBCust
	DB: DBAFF-Affiliate_Athena000
	
	Revisions:
		- 20240806@Sally: Initialize SP  [RedmineID: #206891]

	Param's Explanation:
		@CurrencyIds: CurrencyID of Aff
		@CurrencyIds =  '9,41,13,6'
*/

BEGIN

	SET NOCOUNT ON;
	DECLARE @PartnerExchangeIDs VARCHAR(MAX)

	SELECT @PartnerExchangeIDs = COALESCE(@PartnerExchangeIDs + ', ', '') + CONVERT(VARCHAR(10), cv.PartnerExchangeID)
	FROM dbo.CurrencyConverter cv WITH (NOLOCK)
		INNER JOIN (
			SELECT CONVERT(INT, c.value) AS CurrencyID
			FROM STRING_SPLIT(@CurrencyIds, ',')c
		)t ON t.CurrencyID = cv.ExchangeID
	
	SELECT @PartnerExchangeIDs AS PartnerExchangeIDs

END


