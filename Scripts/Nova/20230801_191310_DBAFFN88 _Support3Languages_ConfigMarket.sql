/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20230801@Sally
	DB: DBAFFN88-Affiliate_N88
	Task: N88 Aff - Support 3 more languages  [RedmineID: #191310]
		- Config 3 languages into Market for Aff N88
*/
--run only DBAFFN88-Affiliate_N88
USE Affiliate_N88
GO

INSERT INTO dbo.Market (MarketId, MarketName, MarketNativeName, DisplayName, ShortedCode)
SELECT t.MarketId, t.MarketName, t.MarketNativeName, t.DisplayName, t.ShortedCode
FROM (
	SELECT N'bn-BD' AS MarketId,N'Bangladeshi' AS MarketName,N'বাংলাদেশী' AS MarketNativeName, N'Bangladeshi' AS DisplayName, N'bn' AS ShortedCode
	UNION ALL
	SELECT N'km-KH' AS MarketId,N'Cambodian' AS MarketName,N'ខ្មែរ' AS MarketNativeName, N'Cambodian' AS DisplayName, N'kh' AS ShortedCode
	UNION ALL
	SELECT N'vi-VN' AS MarketId,N'Vietnamese' AS MarketName,N'Tiếng Việt' AS MarketNativeName, N'Vietnamese' AS DisplayName, N'vn' AS ShortedCode
)t
	LEFT JOIN  dbo.Market m WITH (NOLOCK) ON m.MarketId = t.MarketId
WHERE m.MarketId IS NULL

----Verify
SELECT  MarketId, MarketName, MarketNativeName, DisplayName, ShortedCode
FROM dbo.Market WITH (NOLOCK)
WHERE ShortedCode IN ('vn','bn','kh')