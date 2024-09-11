/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240911@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete data on UAT for 12Topaz [RedmineId : #207119]

*/
USE Affiliate_12BET
GO

WHILE 1 = 1
BEGIN
	DELETE TOP(5000) tes WITH (ROWLOCK, UPDLOCK)
	FROM bettrans_APIProductsTest tes 
		LEFT JOIN bettrans_APIProducts bt WITH (NOLOCK) ON bt.TransactionId = tes.TransactionId
	WHERE tes.TpType = 18 AND tes.WinlostDate >= '2024-08-01' AND bt.TransactionId IS NULL
	
	IF @@ROWCOUNT = 0
		BREAK

	WAITFOR DELAY '00:00:00.280'
END
GO