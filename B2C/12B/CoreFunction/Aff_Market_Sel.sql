/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Market_Sel]
	@TargetCountryCode VARCHAR(5) = ''
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

*/

BEGIN
	SET NOCOUNT ON
	
	;WITH CTE_Market AS (
		SELECT tc.CountryCode,tc.MarketId, tc.MarketName, m.MarketNativeName, m.DisplayName, tc.ShortedCode
			,tc.OrderNo
		FROM dbo.Market m WITH (NOLOCK)
			INNER JOIN TargetCountry tc WITH (NOLOCK) ON m.MarketId = tc.MarketId
		WHERE m.IsDeleted = 0 
			AND (@TargetCountryCode = '' OR tc.CountryCode = @TargetCountryCode)
	)
	SELECT CountryCode AS [TargetCountryCode], MarketId, MarketName, MarketNativeName, DisplayName, ShortedCode
	FROM CTE_Market
	ORDER BY CASE WHEN OrderNo IS NULL THEN 1 ELSE 0 END, OrderNo;

END
GO