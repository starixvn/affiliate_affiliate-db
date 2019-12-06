/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Exchange_Sel]
	@Date SMALLDATETIME
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Exchange Rate - Select

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SupportedCurrencies VARCHAR(200)
	SELECT  @SupportedCurrencies = SValue
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_SupportedCurrencies'

	;WITH CTE_Exchange AS
	(
		SELECT e.ExchangeId, MAX(e.UpdatedTime) AS UpdateTime
		FROM dbo.Exchange e WITH (NOLOCK)
			CROSS APPLY (
				SELECT s.val FROM dbo.strSplit(@SupportedCurrencies, ';') s WHERE e.Currency = s.val
			) s
		WHERE e.UpdatedTime <= @Date
		GROUP BY e.ExchangeID
	)
	SELECT
		e.ExchangeId, e.Currency, e.ActualRate2 AS ActualRate, e.BuyingRate2 AS BuyingRate
	FROM CTE_Exchange c
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON c.UpdateTime = e.UpdatedTime AND c.ExchangeId = e.ExchangeId
	ORDER BY e.Currency
END
GO