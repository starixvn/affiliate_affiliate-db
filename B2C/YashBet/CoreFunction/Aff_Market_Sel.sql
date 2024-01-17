/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Market_Sel]
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Core SP - Get market (PreferredLanguage)

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON
	
	;WITH CTE_Market AS (
		SELECT MarketId, MarketName, MarketNativeName, DisplayName, ShortedCode
			,CASE WHEN MarketId = 'en-US' THEN 1 ELSE 2 END AS SortTypeId
		FROM dbo.Market WITH (NOLOCK)
	)
	SELECT MarketId, MarketName, MarketNativeName, DisplayName, ShortedCode
	FROM CTE_Market
	ORDER BY SortTypeId, MarketId 

END
GO