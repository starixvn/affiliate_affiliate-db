/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20221117@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete data on APIProduct_ImportQueue

*/

DECLARE @QueueId INT

SELECT @QueueId = MAX(QueueId)
FROM dbo.APIProduct_ImportQueue WITH(NOLOCK)
WHERE CheckInTime <= DATEADD(MONTH, -2, GETDATE())

WHILE 1 = 1
BEGIN
	DELETE TOP(2000) dbo.APIProduct_ImportQueue WITH(ROWLOCK, UPDLOCK)
	WHERE QueueId < @QueueId

	IF @@ROWCOUNT < 2000
		BREAK

	WAITFOR DELAY '00:00:00.280'

END