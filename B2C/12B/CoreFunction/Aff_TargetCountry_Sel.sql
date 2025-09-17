/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_TargetCountry_Sel]
	@TargetCountryCode VARCHAR(5) = '',
    @IsDefault BIT = 1
AS

/*
	Created: 20250418@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Core SP - Get TargetCountry (Preference TargetCountry)

	Revisions:
		- 20250417@Lewis: Initialize SP [RedmineID: #223644]
        - 20250825@Sally: Support en-US for all TargetCountry [RedmineID: #234155]
		- 20250917@Sally: Support get TargetLanguageCode [RedmineID: #238480]

*/

BEGIN
	SET NOCOUNT ON
	
	;WITH CTE_Market AS (
		SELECT tc.CountryCode, tc.CountryName, tc.MarketId, tc.MarketName, m.MarketNativeName, tc.ShortedCode
			,ISNULL(tl.TargetLanguageCode, m.ShortedCode) AS TargetLanguageCode
			,CASE WHEN tc.OrderNo IS NULL THEN tc1.OrderNo ELSE tc.OrderNo END AS OrderNo
			,CASE WHEN tc.OrderNo IS NOT NULL THEN 1 ELSE 0 END AS IsDefault
		FROM TargetCountry tc WITH (NOLOCK)
			LEFT JOIN dbo.TargetCountry tc1 WITH (NOLOCK) ON tc1.CountryCode = tc.CountryCode
			INNER JOIN dbo.Market m WITH (NOLOCK) ON m.MarketId = tc.MarketId
			LEFT JOIN dbo.Aff_f_GetTargetLanguageCode() tl ON m.ShortedCode = tl.ShortedCode
		WHERE m.IsDeleted = 0
			AND tc1.OrderNo IS NOT NULL
			AND (
				(tc.OrderNo IS NOT NULL AND @IsDefault = 1) 
				OR @IsDefault = 0
			)
			AND (@TargetCountryCode = '' OR tc.CountryCode = @TargetCountryCode)
	)
	SELECT OrderNo, CountryCode AS [TargetCountryCode], CountryName AS [TargetCountryName], MarketId, MarketName, MarketNativeName, ShortedCode, TargetLanguageCode
	FROM CTE_Market
	ORDER BY OrderNo, IsDefault DESC;

END
GO