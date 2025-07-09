/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Market_Sel]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core SP - Get market (PreferredLanguage)

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20230801@Sally: Support 3 more Languages Cambodian, Bangladeshi and Vietnamese [RedmineId: #191310]
		- 20230801@Eddie: Support English (Philippines) language [RedmineId: #232327]
*/

BEGIN
	SET NOCOUNT ON
	
	;WITH CTE_Market AS (
		SELECT MarketId, MarketName, MarketNativeName, DisplayName, ShortedCode
			,CASE MarketId WHEN 'en-US' THEN 1
						   WHEN 'en-PH' THEN 3
						   ELSE 2 END AS SortTypeId
		FROM dbo.Market WITH (NOLOCK)
	)
	SELECT MarketId, MarketName, MarketNativeName, DisplayName, ShortedCode
	FROM CTE_Market
	ORDER BY SortTypeId, MarketId

END
GO