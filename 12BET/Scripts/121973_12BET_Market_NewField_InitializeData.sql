USE Affiliate_12BET
GO

/*
	Created: 20200303@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new filed for language (market)
*/

ALTER TABLE dbo.Market
	ADD MarketNativeName NVARCHAR(50)
		,ShortedCode NVARCHAR(10)
		,DisplayName NVARCHAR(50)
GO

UPDATE dbo.Market WITH (ROWLOCK)
SET MarketNativeName = CASE MarketID
							WHEN N'en-GB' THEN N'English (Europe)'
							WHEN N'en-US' THEN N'English'
							WHEN N'es-ES' THEN N'Español'
							WHEN N'hi-IN' THEN N'English (India)'
							WHEN N'id-ID' THEN N'Indonesia'
							WHEN N'ja-JP' THEN N'日本'
							WHEN N'ko-KR' THEN N'한국어'
							WHEN N'th-TH' THEN N'ภาษาไทย'
							WHEN N'vi-VN' THEN N'Tiếng Việt'
							WHEN N'zh-CN' THEN N'中文简体'
							WHEN N'zh-TW' THEN N'中文繁体'
							ELSE MarketNativeName END
	,ShortedCode = CASE MarketID
							WHEN N'en-GB' THEN N'eneuro'
							WHEN N'en-US' THEN N'en'
							WHEN N'es-ES' THEN N'es'
							WHEN N'hi-IN' THEN N'hien'
							WHEN N'id-ID' THEN N'id'
							WHEN N'ja-JP' THEN N'jp'
							WHEN N'ko-KR' THEN N'ko'
							WHEN N'th-TH' THEN N'th'
							WHEN N'vi-VN' THEN N'vn'
							WHEN N'zh-CN' THEN N'cs'
							WHEN N'zh-TW' THEN N'ch'
							ELSE ShortedCode END
	,DisplayName = CASE MarketID
							WHEN N'id-ID' THEN N'Bahasa Indonesia'
							ELSE MarketName END
GO