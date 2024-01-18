/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_TargetCountry_Sel]
	@UserId	INT = 0
AS
/*
	Created: 20231024@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Core SP - Get TargetCountry (Preference TargetCountry)

	Revisions:
		- 20231024@Eddie: Initialize SP [RedmineID: #181590]
	Note: Language default for target country and English for Malaysia
*/
BEGIN
	SET NOCOUNT ON
	
	SET @UserId = ISNULL(@UserId, 0)

	IF @UserId <> 0
	BEGIN
		
		;WITH CTE_TargetCountry AS(
			SELECT MarketID, MarketName, CountryCode, CountryName
				  ,CASE WHEN CountryCode = 'MY' AND MarketID = 'en-US' THEN 1
						WHEN CountryCode = 'BD' THEN 2
						WHEN CountryCode = 'IN' THEN 3
						WHEN CountryCode = 'ID' THEN 4
						WHEN CountryCode = 'JP' THEN 5
						WHEN CountryCode = 'KH' THEN 6
						WHEN CountryCode = 'KR' THEN 7
						WHEN CountryCode = 'TH' THEN 8
						WHEN CountryCode = 'VN' THEN 9
						WHEN CountryCode = 'CN' THEN 10
				   END AS OrderID
			FROM dbo.TargetCountry WITH (NOLOCK)
		)
		SELECT tc.OrderID, CountryCode AS TargetCountryCode, tc.CountryName AS TargetCountryName, tc.MarketID AS DefaultLanguageCode
		INTO #Tmp_TargetCountry
		FROM dbo.Users u WITH (NOLOCK)
			INNER JOIN dbo.UserMarket um WITH (NOLOCK) ON um.CustId = u.CustId
			INNER JOIN CTE_TargetCountry tc ON tc.MarketID = um.MarketId
		WHERE u.CustId = @UserId
		ORDER BY tc.OrderID ASC

		-- If admin user has permission for 'English' or 'Chinese Traditional' only, they will see the 'Malaysia' target country
		IF EXISTS (SELECT 1 FROM #Tmp_TargetCountry WHERE DefaultLanguageCode = 'en-US') 
		BEGIN
			SELECT OrderID, TargetCountryCode, TargetCountryName, DefaultLanguageCode
			FROM #Tmp_TargetCountry
			WHERE OrderID IS NOT NULL
			ORDER BY OrderID ASC
		END
		ELSE IF EXISTS (SELECT 1 FROM #Tmp_TargetCountry WHERE DefaultLanguageCode <> 'en-US' AND DefaultLanguageCode = 'en-GB') 
		BEGIN
			UPDATE #Tmp_TargetCountry
			SET OrderID = 1
			WHERE OrderID IS NULL AND DefaultLanguageCode = 'en-GB'

			SELECT OrderID, TargetCountryCode, TargetCountryName, DefaultLanguageCode
			FROM #Tmp_TargetCountry
			WHERE OrderID IS NOT NULL
			ORDER BY OrderID ASC
		END
		ELSE IF EXISTS (SELECT 1 FROM #Tmp_TargetCountry WHERE DefaultLanguageCode NOT IN ('en-US', 'en-GB') AND DefaultLanguageCode = 'zh-TW') 
		BEGIN
			UPDATE #Tmp_TargetCountry
			SET OrderID = 1
			WHERE OrderID IS NULL AND DefaultLanguageCode = 'zh-TW'

			SELECT OrderID, TargetCountryCode, TargetCountryName, DefaultLanguageCode
			FROM #Tmp_TargetCountry
			ORDER BY OrderID ASC
		END
		ELSE
		BEGIN
			SELECT OrderID, TargetCountryCode, TargetCountryName, DefaultLanguageCode
			FROM #Tmp_TargetCountry
			ORDER BY OrderID ASC
		END

		DROP TABLE #Tmp_TargetCountry

	END
	ELSE
	BEGIN

		;WITH CTE_TargetCountry AS(
			SELECT MarketID, MarketName, CountryCode, CountryName
				  ,CASE WHEN CountryCode = 'MY' AND MarketID = 'en-US' THEN 1
						WHEN CountryCode = 'BD' THEN 2
						WHEN CountryCode = 'IN' THEN 3
						WHEN CountryCode = 'ID' THEN 4
						WHEN CountryCode = 'JP' THEN 5
						WHEN CountryCode = 'KH' THEN 6
						WHEN CountryCode = 'KR' THEN 7
						WHEN CountryCode = 'TH' THEN 8
						WHEN CountryCode = 'VN' THEN 9
						WHEN CountryCode = 'CN' THEN 10
				   END AS OrderID
			FROM dbo.TargetCountry WITH (NOLOCK)
		)
		SELECT OrderID, CountryCode AS TargetCountryCode, CountryName AS TargetCountryName, MarketID AS DefaultLanguageCode
		FROM CTE_TargetCountry
		WHERE OrderID IS NOT NULL
		ORDER BY OrderID ASC

	END
END
GO