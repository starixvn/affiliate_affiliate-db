/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_PaymentCurrency_Sel]
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Get payment account currency list

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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