/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20241001@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete data of BetSoft in August on UAT [RedmineId : #207119]
*/
USE Affiliate_12BET
GO

DELETE bettrans_BetsoftTest WITH (ROWLOCK, UPDLOCK) -- 84271 rows
WHERE WinlostDate >= '2024-08-01' AND WinlostDate < '2024-09-01'
GO

DELETE rptMemberDailyTest WITH (ROWLOCK, UPDLOCK) -- 381 rows
WHERE ProductId = 11 AND WinlostDate >= '2024-08-01' AND WinlostDate < '2024-09-01'
GO