/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250822@Sally	
	Task: Customize Target country/Language list, English for all target country
	DB: DBAFF12B-Affiliate_12B
	
	Revisions:
		- 20250822@Sally: Created [RedmineID: #234155]

	Description:
		- Inactivate en-IN, en-PH market in Market table
		- Update TargetCountry table market from en-IN, en-PH to en-US
			MarketID ==> en-US
			MarketName ==> English
*/

USE Affiliate_12B
GO

UPDATE m SET 
	m.IsDeleted 		= 1, 
	m.MarketName 		= 'English', 
	m.MarketNativeName 	= 'English', 
	m.DisplayName 		= 'English'
FROM Market m WITH (ROWLOCK, UPDLOCK)
WHERE MarketId IN ( 'en-IN')
GO

 UPDATE c SET MarketID = 'en-US', c.MarketName = 'English'
 FROM dbo.TargetCountry c WITH(ROWLOCK, UPDLOCK )
 WHERE MarketID IN ( 'en-IN')
GO


-- Insert English market for the remaining target countries if not exists 
;WITH NewData AS (
	SELECT 'en-US' AS MarketID, 'English' AS MarketName, 'BD' AS CountryCode, 'Bangladesh' AS CountryName, NULL AS OrderNo, 'bnen' AS ShortedCode UNION ALL
	SELECT 'en-US', 'English', 'ID', 'Indonesia', NULL, 'iden' UNION ALL
	SELECT 'en-US', 'English', 'JP', 'Japan', NULL, 'jpen' UNION ALL
	SELECT 'en-US', 'English', 'KR', 'South Korea', NULL, 'kren' UNION ALL
	SELECT 'en-US', 'English', 'TH', 'Thailand', NULL, 'then' UNION ALL
	SELECT 'en-US', 'English', 'VN', 'Vietnam', NULL, 'vnen' UNION ALL
	SELECT 'en-US', 'English', 'CN', 'China', NULL, 'csen'
)
INSERT INTO targetCountry (MarketID, MarketName, CountryCode, CountryName, OrderNo, ShortedCode)
SELECT n.MarketID, n.MarketName, n.CountryCode, n.CountryName, n.OrderNo, n.ShortedCode
FROM NewData n
LEFT JOIN targetCountry t WITH (NOLOCK) ON n.MarketID = t.MarketID AND n.CountryCode = t.CountryCode
WHERE t.MarketID IS NULL;