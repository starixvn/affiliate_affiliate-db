/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap,wsv_alp,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaCurrency_Sel]
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Media Gallery - Get Currency

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Currencies XML
	SELECT  @Currencies = REPLACE(N'<root><r ID="' + REPLACE(SValue, ',', '" /><r ID="') + '" /></root>', ':', '" Name="')
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_SupportedCurrencies'

	SELECT CurrencyId, Currency
	FROM (
		SELECT
			t.c.value('@ID', 'INT') AS CurrencyId,
			t.c.value('@Name', 'VARCHAR(5)') AS Currency
		FROM @Currencies.nodes('/root/r') AS t(c)
	) e
	ORDER BY Currency
END
GO