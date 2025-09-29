/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_TargetCountry_Sel]
	@TargetCountryCode VARCHAR(5) = ''
   ,@IsDefault BIT = 1
AS

/*
	Created: 20250801@Eddie
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core SP - Get TargetCountry (Preference TargetCountry)

	Revisions:
		- 20250801@Eddie: Initialize SP [RedmineID: #227560]

	Param's Explanation:
		@IsDefault:
			0 : get all info
			1 : get with default language with each Target Country
*/

BEGIN
	SET NOCOUNT ON
	
	IF ISNULL(@IsDefault, 0) = 0
	BEGIN
		;WITH CTE_Market AS (
			SELECT tc.CountryCode, tc.CountryName, tc.MarketId, tc.MarketName, m.MarketNativeName, tc.ShortedCode
			, CASE WHEN tc.OrderNo IS NULL THEN tc1.OrderNo ELSE tc.OrderNo END AS OrderNo
			, CASE WHEN tc.OrderNo IS NOT NULL THEN 1 ELSE 0 END AS IsDefault
			FROM dbo.TargetCountry tc WITH (NOLOCK)
				LEFT JOIN dbo.TargetCountry tc1 WITH (NOLOCK) ON tc1.CountryCode = tc.CountryCode
				INNER JOIN dbo.Market m WITH (NOLOCK) ON m.MarketId = tc.MarketId
			WHERE m.IsDeleted = 0
			  AND tc1.OrderNo IS NOT NULL
			  AND (@TargetCountryCode = '' OR tc.CountryCode = @TargetCountryCode)
		)
		SELECT OrderNo, CountryCode AS [TargetCountryCode], CountryName AS [TargetCountryName], MarketId, MarketName, MarketNativeName, ShortedCode
		FROM CTE_Market
		ORDER BY OrderNo, IsDefault DESC
	END
	ELSE
	BEGIN
		;WITH CTE_Market AS (
			SELECT tc.CountryCode, tc.CountryName, tc.MarketId, tc.MarketName, m.MarketNativeName, tc.ShortedCode, tc.OrderNo
			FROM dbo.TargetCountry tc WITH (NOLOCK)
				INNER JOIN dbo.Market m WITH (NOLOCK) ON m.MarketId = tc.MarketId
			WHERE m.IsDeleted = 0
			  AND tc.OrderNo IS NOT NULL
			  AND (@TargetCountryCode = '' OR tc.CountryCode = @TargetCountryCode)
		)
		SELECT OrderNo, CountryCode AS [TargetCountryCode], CountryName AS [TargetCountryName], MarketId, MarketName, MarketNativeName, ShortedCode
		FROM CTE_Market
		ORDER BY OrderNo
	END
END
GO