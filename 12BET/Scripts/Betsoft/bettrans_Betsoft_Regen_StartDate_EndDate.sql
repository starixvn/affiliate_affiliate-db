USE [Affiliate_12BET]
GO

/*
	Created: 20190128@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Regen data for 2 new columns: StartDate, EndDate
*/

DECLARE @QueueId BIGINT, @LatestQueueId BIGINT = 0

DECLARE @ErrCode INT = 0, @ErrMsg NVARCHAR(4000) = ''

DECLARE @i INT = 0

WHILE 1 = 1
BEGIN
	SELECT TOP 1 @QueueId = QueueId FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
	WHERE ProductId = 11 AND JobType = 0 AND CheckInTime >= '2018-12-01' AND QueueId > @LatestQueueId

	IF @@ROWCOUNT = 0
		BREAK;

	SELECT @LatestQueueId = @QueueId

	EXEC dbo.Task_APIProduct_ImportQueue_Process @ProductId = 11, @QueueIdInput = @QueueId, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
	BEGIN
		SELECT 'QueueId = ' + CONVERT(VARCHAR(20), @QueueId) + ': ' + @ErrMsg

		RETURN
	END

	SELECT @i = @i + 1

	IF @i%50 = 0
		WAITFOR DELAY '00:00:05.000'

END