/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Language_Sel]
	@UserId	INT = 0
	, @TargetCountryCode VARCHAR(2) = ''
AS
/*
	Created: 20231025@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Core SP - Get Affiliate Account Language (Preference Affiliate Account Language)

	Revisions:
		- 20231025@Eddie: Initialize SP [RedmineID: #181590]
*/
BEGIN
	SET NOCOUNT ON
	
	SET @UserId = ISNULL(@UserId, 0)
	SET @TargetCountryCode = ISNULL(@TargetCountryCode, '')
	
	IF @UserId <> 0
	BEGIN
		;WITH CTE_Language AS(
			SELECT DISTINCT tc.CountryCode, tc.MarketID, tc.MarketName, m.MarketNativeName, m.ShortedCode, m.DisplayName
				,CASE WHEN tc.MarketID = 'en-US' THEN 1 ELSE 2 END AS OrderID
			FROM dbo.TargetCountry tc WITH (NOLOCK)
				INNER JOIN dbo.Market  m WITH (NOLOCK) ON m.MarketID = tc.MarketID
			WHERE (tc.CountryCode = @TargetCountryCode) OR (@TargetCountryCode = '')
		)
		SELECT al.CountryCode AS [TargetCountryCode], al.MarketID AS [LanguageCode], al.MarketName AS [LanguageName], al.MarketNativeName AS [NativeLanguage], al.ShortedCode, al.DisplayName
		FROM dbo.Users u WITH (NOLOCK)
			INNER JOIN dbo.UserMarket um WITH (NOLOCK) ON um.CustId = u.CustId
			INNER JOIN CTE_Language al WITH (NOLOCK) ON al.MarketID = um.MarketId
		WHERE u.CustId = @UserId
		ORDER BY al.OrderID , al.MarketID ASC
	END
	ELSE
	BEGIN
		;WITH CTE_Language AS(
			SELECT DISTINCT tc.CountryCode, tc.MarketID, tc.MarketName, m.MarketNativeName, m.ShortedCode, m.DisplayName
				,CASE WHEN tc.MarketID = 'en-US' THEN 1 ELSE 2 END AS OrderID
			FROM dbo.TargetCountry tc WITH (NOLOCK)
				INNER JOIN dbo.Market  m WITH (NOLOCK) ON m.MarketID = tc.MarketID
			WHERE (tc.CountryCode = @TargetCountryCode) OR (@TargetCountryCode = '')
		)
		SELECT CountryCode AS [TargetCountryCode], MarketID AS [LanguageCode], MarketName AS [LanguageName], MarketNativeName AS [NativeLanguage], ShortedCode, DisplayName
		FROM CTE_Language
		ORDER BY OrderID , MarketID ASC
	END
END
GO