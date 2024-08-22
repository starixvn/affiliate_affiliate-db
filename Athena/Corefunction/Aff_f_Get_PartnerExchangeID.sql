/*<info serverAlias="DBAFF-Affiliate_Athena000" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_Get_PartnerExchangeID]
(
	@Currencies		VARCHAR(MAX),
	@CurrencyType	TINYINT = 1
)
RETURNS @tbData TABLE
(
	CurrencyID			INT,
	PartnerExchangeID	INT
)
AS

/*
	Task: Remove linked server to DBCust
	DB: DBAFF-Affiliate_Athena000
	
	Revisions:
		- 20240806@Sally: Initialize Function [RedmineID: #206891]

	Param's Explanation:
		- @CurrencyType : 
			+ 1: CurrencyCode
			+ 0: CurrencyId
		- @Currencies: Currency of Aff
			+ @Currencies =  'MYR,CNY,EUR,USD,UUS,AUD,KRW,VND'
			+ @Currencies =  '13,15,51'
*/

BEGIN

	DECLARE @PartnerExchangeIDs VARCHAR(MAX)
	DECLARE @Currency TABLE (CurrencyID SMALLINT)

	IF @CurrencyType = 0
	BEGIN
		INSERT INTO @Currency (CurrencyID)
		SELECT CONVERT(INT, c.value) AS CurrencyCode
		FROM STRING_SPLIT(@Currencies, ',')c
	END
	ELSE IF @CurrencyType =1 
	BEGIN
		INSERT INTO @Currency (CurrencyID)
		SELECT c.CurrencyID
		FROM dbo.Currency c WITH (NOLOCK)
		INNER JOIN (
			SELECT CONVERT(VARCHAR(5), c.value) AS CurrencyCode
			FROM STRING_SPLIT(@Currencies, ',')c
		)t ON t.CurrencyCode = c.CurrencyCode
	END

	INSERT INTO @tbData (CurrencyID, PartnerExchangeID)
	SELECT  t.CurrencyID, cc.PartnerExchangeID
	FROM @Currency t 
		LEFT JOIN dbo.CurrencyConverter cc WITH (NOLOCK) ON t.CurrencyID = cc.ExchangeID

	RETURN
END
