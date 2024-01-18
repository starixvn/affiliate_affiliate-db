/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240116@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete or update data language Spanish [RedmineId : #181590]
*/
DELETE FROM RoleMarket
WHERE RoleId = 6 AND MarketId = 'es-ES'
GO

DELETE FROM UserMarket
WHERE CustId IN (10000000, 10000001, 10000006, 10000022, 10000027) AND MarketId = 'es-ES'
GO

DELETE FROM AffDomainControl
WHERE ID IN (64, 65, 237, 239)
GO

UPDATE AffDomainControl WITH (ROWLOCK, UPDLOCK)
SET MarketId = 'en-US'
WHERE ID IN (3, 238)
GO

UPDATE ClickStatistics1 WITH (ROWLOCK, UPDLOCK) -- 10 lines
SET LanguageCode = 'en'
WHERE LanguageCode = 'es'
GO

UPDATE ClickStatistics1_bk WITH (ROWLOCK, UPDLOCK) -- 4855 lines
SET LanguageCode = 'en'
WHERE LanguageCode = 'es'
GO

DELETE FROM Market
WHERE MarketID = 'es-ES'
GO