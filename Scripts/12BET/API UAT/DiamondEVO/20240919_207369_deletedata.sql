/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240919@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Set timezone again and delete data on UAT [RedmineId : #207119]

*/
USE Affiliate_12BET
GO

UPDATE dbo.APIProductSettingsTest WITH (ROWLOCK, UPDLOCK)
SET SettingValue = '0'
WHERE ProductId IN (48, 49) AND SettingName = 'TimeZone'
GO

DELETE rt -- 572 rows
FROM rptMemberDailyTest rt WITH (ROWLOCK, UPDLOCK)
WHERE rt.ProductId IN (48, 49) AND rt.WinlostDate >= '2024-09-01'
GO

DELETE bt -- 89602 rows
FROM bettrans_APIProductsTest bt WITH (ROWLOCK, UPDLOCK)
WHERE bt.TpType IN (27, 28) AND bt.WinlostDate >= '2024-09-01'
GO