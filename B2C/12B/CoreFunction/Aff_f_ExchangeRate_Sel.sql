/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_ExchangeRate_Sel]
(
	@ExchangeDate	SMALLDATETIME
	,@ExchangeId	INT
	,@BaseCurrency	INT
)
RETURNS TABLE
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core function - Get Exchange Rate

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

	Param's Explanation:
		- @BaseCurrency : Currency of maindb

*/

RETURN
	WITH CTE_ExchangeDate AS
	(
		SELECT @ExchangeId AS ExchangeId, CONVERT(SMALLDATETIME, EOMONTH(@ExchangeDate)) AS ExchangeDate
	), CTE_BaseCurrency AS
	(
		SELECT @ExchangeId AS ExchangeId, CASE WHEN @BaseCurrency = 0 THEN ISNULL(t.ExchangeId, CONVERT(INT, SValue)) ELSE @BaseCurrency END AS BaseCurrency
		FROM dbo.SystemSettings s WITH (NOLOCK)
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON CONVERT(INT, SValue) = t.TpExchangeId
		WHERE SName = 'AffCurrency'
	)
	SELECT e.ExchangeDate, e.ExchangeId, e.Code,
		CASE bc.BaseCurrency
			WHEN  2 THEN e.MYR
			WHEN  3 THEN e.USD
			WHEN  4 THEN e.THB
			WHEN  6 THEN e.EUR
			WHEN 13 THEN e.CNY
			WHEN 15 THEN e.IDR / 1000.0
			WHEN 20 THEN 1 -- cheat code for UAT testing
			WHEN 51 THEN e.VND / 1000.0
			WHEN 61 THEN e.INR
			WHEN 97 THEN e.BDT
			ELSE 0 END AS Rate
	FROM dbo.ExchangeOanda e WITH (NOLOCK)
		INNER JOIN CTE_BaseCurrency bc ON e.ExchangeId = bc.ExchangeId
		INNER JOIN CTE_ExchangeDate ed ON e.ExchangeId = ed.ExchangeId
	WHERE e.ExchangeDate = ed.ExchangeDate
GO