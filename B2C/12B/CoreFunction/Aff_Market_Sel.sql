/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Market_Sel]
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core SP - Get market (PreferredLanguage)

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/

BEGIN
	SET NOCOUNT ON
	
	;WITH CTE_Market AS (
		SELECT MarketId, MarketName, MarketNativeName, DisplayName, ShortedCode
			,CASE MarketId WHEN 'en-US' THEN 1
						   WHEN 'bn-BD' THEN 2
						   WHEN 'en-GB' THEN 3
						   WHEN 'en-IN' THEN 4
						   WHEN 'hi-IN' THEN 5
						   WHEN 'te-IN' THEN 6
			 ELSE 7 END AS SortTypeId
		FROM dbo.Market WITH (NOLOCK)
		WHERE MarketId <> 'hi-IN'
	)
	SELECT MarketId, MarketName, MarketNativeName, DisplayName, ShortedCode
	FROM CTE_Market
	ORDER BY SortTypeId, MarketId ASC

END
GO