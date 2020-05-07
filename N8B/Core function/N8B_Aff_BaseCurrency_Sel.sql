/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_BaseCurrency_Sel]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Get base currency list

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	DECLARE @BaseCurrencies XML
	SELECT  @BaseCurrencies = REPLACE(N'<root><r ID="' + REPLACE(SValue, ',', '" /><r ID="') + '" /></root>', ':', '" Name="')
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_BaseCurrencies'

	SELECT
		t.c.value('@ID', 'INT') AS ExchangeId,
		t.c.value('@Name', 'VARCHAR(5)') AS Code
	FROM @BaseCurrencies.nodes('/root/r') AS t(c)
END
GO