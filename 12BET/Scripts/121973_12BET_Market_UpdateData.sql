USE Affiliate_12BET
GO

/*
	Created: 20200303@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new filed for language (market)
*/

UPDATE dbo.Market WITH (ROWLOCK)
SET MarketNativeName = N'中文繁体', ShortedCode = 'ch'
WHERE MarketID = N'zh-TW'
