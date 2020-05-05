/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Currency_Sel]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Get currency list

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SELECT e.ExchangeId, CASE WHEN e.ExchangeId = 20 THEN 'UUS' ELSE e.Code END AS Code
	FROM dbo.SystemSettings ss WITH (NOLOCK)
		CROSS APPLY dbo.Aff_f_StringSplit(ss.SValue, ',') f
		INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON e.currency = f.val
	WHERE ss.SName = 'AFF_SupportedCurrencies'
	ORDER BY CASE WHEN ExchangeId = 51 THEN 1 ELSE 2 END, Code
END
GO