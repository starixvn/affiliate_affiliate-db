/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20231024@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new table TargetCountry and insert data into TargetCountry [RedmineId : #181590]
*/
-- Note: only use for function target country, not affect to country or market separately
CREATE TABLE [dbo].[TargetCountry](
	[MarketID]		[NVARCHAR](10) 	NOT NULL
	,[MarketName]	[NVARCHAR](50) 	NOT NULL
	,[CountryCode] 	[VARCHAR](2)   	NOT NULL
	,[CountryName] 	[NVARCHAR](100) NOT NULL
	,CONSTRAINT [PK_TargetCountry] PRIMARY KEY CLUSTERED 
	(
		[MarketID] 		ASC
		,[CountryCode] 	ASC
	) ON [Data]
) ON [Data]
GO


INSERT INTO [dbo].[TargetCountry](MarketName, MarketID, CountryCode, CountryName)
VALUES ('English', 				'en-US', 'MY', 'Malaysia')
	  ,('English (Bangladesh)', 'bn-BD', 'BD', 'Bangladesh')
	  ,('English (Europe)', 	'en-GB', 'MY', 'Malaysia')
	  ,('English (India)', 		'hi-IN', 'IN', 'India')
	  ,('Indonesian', 			'id-ID', 'ID', 'Indonesia')
	  ,('Japanese', 			'ja-JP', 'JP', 'Japan')
	  ,('Cambodian', 			'km-KH', 'KH', 'Cambodia')
	  ,('Korean', 				'ko-KR', 'KR', 'South Korea')
	  ,('Thai', 				'th-TH', 'TH', 'Thailand')
	  ,('Vietnamese', 			'vi-VN', 'VN', 'Vietnam')
	  ,('Chinese Simplified', 	'zh-CN', 'CN', 'China')
	  ,('Chinese Traditional', 	'zh-TW', 'MY', 'Malaysia')
GO