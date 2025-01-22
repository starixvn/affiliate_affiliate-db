/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_MediaCurrency_Sel]
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Media Gallery - Get Currency

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
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