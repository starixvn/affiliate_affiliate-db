USE Affiliate_N8G
GO

/*
	Created: 20200507@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Update list of supported currency
*/

UPDATE dbo.SystemSettings
SET SValue = '51:VND,20:UUS'
WHERE SName = 'AFF_SupportedCurrencies'
GO