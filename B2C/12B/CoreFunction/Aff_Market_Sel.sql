/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Market_Sel]
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core SP - Get market (PreferredLanguage)

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250318@Lewis: Use col IsDeleted [RedmineID: #219810]
		- 20250417@Lewis: Add TargetCountry [RedmineID: #223644]
		- 20250515@Lewis: Get ShortedCode by table TargetCountry [RedmineID: #227338]
        - 20250825@Sally: Support en-US for all TargetCountry [RedmineID: #234155]

*/

BEGIN
	SET NOCOUNT ON
	
	;WITH CTE_Market AS (
		SELECT m.MarketId, m.MarketName, m.MarketNativeName, m.DisplayName, m.ShortedCode
			,CASE WHEN MarketId = 'en-US' THEN 1 ELSE 2 END AS SortTypeId
		FROM dbo.Market m WITH (NOLOCK)
		WHERE m.IsDeleted = 0 
	)
	SELECT MarketId, MarketName, MarketNativeName, DisplayName, ShortedCode
	FROM CTE_Market
	ORDER BY SortTypeId, MarketId 

END
GO