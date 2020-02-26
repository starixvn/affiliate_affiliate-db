/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_BaseCurrency_Sel]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Get base currency list

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SELECT ExchangeId, Code
	FROM bodb02.dbo.Exchange WITH (NOLOCK)
	WHERE ExchangeId IN (2,3,6,13,51) -- MYR,USD,EUR,CNY,VND
	ORDER BY CASE WHEN ExchangeId = 51 THEN 1 ELSE 2 END, Code
END
GO