/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_PaymentCurrency_Sel]
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Get payment account currency list

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/

BEGIN
	DECLARE @PaymentCurrencies XML
	SELECT  @PaymentCurrencies = REPLACE(N'<root><r ID="' + REPLACE(SValue, ',', '" /><r ID="') + '" /></root>', ':', '" Name="')
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_PaymentCurrencies'

	SELECT ExchangeId, Code
	FROM (
		SELECT
			t.c.value('@ID', 'INT') AS ExchangeId,
			t.c.value('@Name', 'VARCHAR(5)') AS Code,
			ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS OrderBy
		FROM @PaymentCurrencies.nodes('/root/r') AS t(c)
	) c
	ORDER BY OrderBy
	OPTION (OPTIMIZE FOR (@PaymentCurrencies = NULL))
END
GO