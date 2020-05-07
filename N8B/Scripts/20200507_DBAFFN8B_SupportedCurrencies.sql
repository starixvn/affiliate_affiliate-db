USE Affiliate_N8B
GO

/*
	Created: 20200507@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Update list of supported currency
*/

UPDATE dbo.SystemSettings
SET SValue = '51:VND,20:UUS'
WHERE SName = 'AFF_SupportedCurrencies'
GO