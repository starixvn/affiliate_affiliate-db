USE [Affiliate_12BET]
GO

/*
	Created: 20190322@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Re-run job update data after update raw data
*/

DECLARE @FromDate SMALLDATETIME
SELECT  @FromDate = '2019-03-01'

DECLARE @ProductId INT, @WinlostDate SMALLDATETIME, @message VARCHAR(10)

-- Betsoft - ProductId = 11
SELECT @ProductId = 11, @WinlostDate = @FromDate

WHILE @WinlostDate <= CONVERT(DATE, CURRENT_TIMESTAMP)
BEGIN
	SET @message = 'Betsoft: @WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT
	
	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END

-- Ebet - ProductId = 10
SELECT @ProductId = 10, @WinlostDate = @FromDate

WHILE @WinlostDate <= CONVERT(DATE, CURRENT_TIMESTAMP)
BEGIN
	SET @message = 'Ebet: @WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT

	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END

-- Crystal - ProductId = 12
SELECT @ProductId = 12, @WinlostDate = @FromDate

WHILE @WinlostDate <= CONVERT(DATE, CURRENT_TIMESTAMP)
BEGIN
	SET @message = 'Crystal: @WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT

	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END

-- iSoftbet - ProductId = 13
SELECT @ProductId = 13, @WinlostDate = @FromDate

WHILE @WinlostDate <= CONVERT(DATE, CURRENT_TIMESTAMP)
BEGIN
	SET @message = 'iSoftbet: @WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT

	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END

-- OPUS - ProductId = 14
SELECT @ProductId = 14, @WinlostDate = @FromDate

WHILE @WinlostDate <= CONVERT(DATE, CURRENT_TIMESTAMP)
BEGIN
	SET @message = 'OPUS: @WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT

	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END