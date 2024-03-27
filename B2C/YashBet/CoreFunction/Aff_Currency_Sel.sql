/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Currency_Sel]
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Get currency list

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	DECLARE @Currencies XML
	SELECT  @Currencies = REPLACE(N'<root><r ID="' + REPLACE(SValue, ',', '" /><r ID="') + '" /></root>', ':', '" Name="')
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_SupportedCurrencies'

	SELECT
		t.c.value('@ID', 'INT') AS ExchangeId,
		t.c.value('@Name', 'VARCHAR(5)') AS Code
	FROM @Currencies.nodes('/root/r') AS t(c)
END
GO