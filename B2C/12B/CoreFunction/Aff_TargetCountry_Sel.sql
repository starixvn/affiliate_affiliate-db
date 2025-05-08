/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_TargetCountry_Sel]
	@TargetCountryCode VARCHAR(5) = ''
AS

/*
	Created: 20250418@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Core SP - Get TargetCountry (Preference TargetCountry)

	Revisions:
		- 20250417@Lewis: Initialize SP [RedmineID: #223644]

*/

BEGIN
	SET NOCOUNT ON
	
	;WITH CTE_Market AS (
		SELECT tc.CountryCode, tc.CountryName, tc.MarketId, tc.MarketName, tc.OrderNo
		FROM TargetCountry tc WITH (NOLOCK)
		WHERE EXISTS (SELECT 1 FROM dbo.Market m WITH (NOLOCK) WHERE m.MarketId = tc.MarketId AND m.IsDeleted = 0 )
			AND tc.OrderNo IS NOT NULL
			AND (@TargetCountryCode = '' OR tc.CountryCode = @TargetCountryCode)
	)
	SELECT OrderNo, CountryCode AS [TargetCountryCode], CountryName AS [TargetCountryName], MarketId AS [DefaultLanguageCode]
	FROM CTE_Market
	ORDER BY OrderNo;

END
GO