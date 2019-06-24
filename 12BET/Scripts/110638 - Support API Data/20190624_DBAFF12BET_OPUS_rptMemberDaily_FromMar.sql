USE [Affiliate_12BET]
GO

/*
	Created: 20190624@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: OPUS - Re-run job update data after update raw data
*/

DECLARE @FromDate SMALLDATETIME
SELECT  @FromDate = '2019-03-01'

DECLARE @ProductId INT, @WinlostDate SMALLDATETIME, @message VARCHAR(1000)

-- OPUS - ProductId = 14
SELECT @ProductId = 14, @WinlostDate = @FromDate

WHILE @WinlostDate <= CONVERT(DATE, CURRENT_TIMESTAMP)
BEGIN
	SET @message = 'OPUS: @WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT
	
	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END