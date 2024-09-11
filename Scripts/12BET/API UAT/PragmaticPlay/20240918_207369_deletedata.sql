/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240918@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Set timezone again and delete data on UAT [RedmineId : #207119]

*/
USE Affiliate_12BET
GO

UPDATE dbo.APIProductSettingsTest WITH (ROWLOCK, UPDLOCK)
SET SettingValue = '0'
WHERE ProductId = 47 AND SettingName = 'TimeZone'
GO

DELETE rt -- 1282 rows
FROM rptMemberDailyTest rt WITH (ROWLOCK, UPDLOCK)
WHERE rt.ProductId = 47 AND rt.WinlostDate >= '2024-09-01'
GO

-- 1253627 rows
WHILE 1 = 1
BEGIN
	DELETE TOP(5000) bt
	FROM bettrans_APIProductsTest bt WITH (ROWLOCK, UPDLOCK)
	WHERE bt.TpType = 29 AND bt.WinlostDate >= '2024-09-01'
	
	IF @@ROWCOUNT = 0
		BREAK

	WAITFOR DELAY '00:00:00.280'
END
GO