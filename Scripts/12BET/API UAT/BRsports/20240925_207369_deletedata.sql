/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240925@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Set timezone again and delete data on UAT [RedmineId : #207119]

*/
USE Affiliate_12BET
GO

UPDATE dbo.APIProductSettingsTest WITH (ROWLOCK, UPDLOCK)
SET SettingValue = '8'
WHERE ProductId = 49 AND SettingName = 'TimeZone'
GO

DELETE rt -- 296 rows
FROM rptMemberDailyTest rt WITH (ROWLOCK, UPDLOCK)
WHERE rt.ProductId = 49 AND rt.WinlostDate >= '2024-09-01'
GO

DELETE bt -- 1854 rows
FROM bettrans_APIProductsTest bt WITH (ROWLOCK, UPDLOCK)
WHERE bt.TpType = 28 AND bt.WinlostDate >= '2024-09-01'
GO