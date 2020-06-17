/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_BaseCurrency_Sel]
	@AffId INT = 0
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

	DECLARE @tblBaseCurrencies TABLE (ExchangeId INT, Code VARCHAR(5), OrderBy INT)

	INSERT INTO @tblBaseCurrencies (ExchangeId, Code, OrderBy)
	SELECT
		t.c.value('@ID', 'INT'),
		t.c.value('@Name', 'VARCHAR(5)'),
		ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
	FROM @BaseCurrencies.nodes('/root/r') AS t(c)

	IF @AffId <> 0
	BEGIN
		UPDATE t
		SET t.OrderBy = 0
		FROM @tblBaseCurrencies t
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON t.ExchangeId = ai.DefaultCurrency
		WHERE ai.AffId = @AffId
	END

	SELECT ExchangeId, Code
	FROM @tblBaseCurrencies
	ORDER BY OrderBy
END
GO