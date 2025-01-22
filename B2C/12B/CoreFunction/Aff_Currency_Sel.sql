/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Currency_Sel]
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Get currency list

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
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