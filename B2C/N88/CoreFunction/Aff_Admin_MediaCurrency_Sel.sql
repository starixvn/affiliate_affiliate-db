/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaCurrency_Sel]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin - Media Gallery - Get Currency

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
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