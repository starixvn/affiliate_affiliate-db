/*<info serverAlias="DBAFFN8B-Affiliate_N8B" selecters="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_ExchangeRate_Sel]
(
	@ExchangeDate	SMALLDATETIME
	,@ExchangeId	INT
	,@BaseCurrency	INT
)
RETURNS TABLE
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Core function - Get Exchange Rate

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

RETURN
	WITH CTE_Exchange AS
	(
		SELECT MAX(ExchangeDate) AS ExchangeDate
		FROM dbo.ExchangeOanda WITH (NOLOCK)
		WHERE ExchangeDate <= @ExchangeDate
			AND ExchangeId = @ExchangeId
	), CTE_BaseCurrency AS
	(
		SELECT @ExchangeId AS ExchangeId, CASE WHEN @BaseCurrency = 0 THEN CONVERT(INT, SValue) ELSE @BaseCurrency END AS BaseCurrency
		FROM dbo.SystemSettings WITH (NOLOCK)
		WHERE SName = 'AffCurrency'
	)
	SELECT
		e.ExchangeDate
		,e.ExchangeId
		,e.Code
		,CASE bc.BaseCurrency
							WHEN 2 THEN e.MYR
							WHEN 3 THEN e.USD
							WHEN 6 THEN e.EUR
							WHEN 13 THEN e.CNY
							WHEN 20 THEN 1 -- cheat code for UAT testing
							WHEN 34 THEN e.IDR / 1000.0
							WHEN 43 THEN e.THB
							WHEN 51 THEN e.VND / 1000.0
							ELSE 0 END AS Rate
	FROM dbo.ExchangeOanda e WITH (NOLOCK)
		INNER JOIN CTE_Exchange c ON e.ExchangeDate = c.ExchangeDate
		INNER JOIN CTE_BaseCurrency bc ON e.ExchangeId = bc.ExchangeId
	WHERE e.ExchangeId = @ExchangeId
GO