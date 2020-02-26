/*<info serverAlias="DBAFFN8G-Affiliate_N8G" selecters="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
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
	DB: DBAFFN8G-Affiliate_N8G
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
	)
	SELECT
		e.ExchangeDate
		,e.ExchangeId
		,CASE @BaseCurrency
							WHEN 0 THEN e.VND / CASE WHEN @ExchangeId = 51 THEN 1000.0 ELSE 1.0 END -- default is INH
							WHEN 2 THEN e.MYR
							WHEN 3 THEN e.USD
							WHEN 6 THEN e.EUR
							WHEN 13 THEN e.CNY
							WHEN 51 THEN e.VND / CASE WHEN @ExchangeId = 51 THEN 1000.0 ELSE 1.0 END
							ELSE 0 END AS Rate
	FROM dbo.ExchangeOanda e WITH (NOLOCK)
		INNER JOIN CTE_Exchange c ON e.ExchangeDate = c.ExchangeDate
	WHERE e.ExchangeId = @ExchangeId
GO