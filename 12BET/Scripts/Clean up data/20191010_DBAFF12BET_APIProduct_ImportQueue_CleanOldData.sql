/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Clean old data (keep 3 months) [RedmineID: #121795]
*/

USE Affiliate_12BET
GO

WHILE 1 = 1
BEGIN
	DELETE TOP (2000) FROM APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
	WHERE QueueId < 1259926 -- 2019-07-10

	IF @@ROWCOUNT < 2000
		BREAK

	WAITFOR DELAY '00:00:00.280'
END
GO