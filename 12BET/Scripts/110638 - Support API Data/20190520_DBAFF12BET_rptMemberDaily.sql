USE [Affiliate_12BET]
GO

/*
	Created: 20190520@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Re-run job update data after update raw data
*/

-- EBet - ProductId = 10
DECLARE @ProductId INT, @WinlostDate SMALLDATETIME, @message VARCHAR(1000)
SELECT @ProductId = 10, @WinlostDate = '2019-03-01'

BEGIN
	SET @message = '@WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT
	
	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END
GO

-- Betsoft - ProductId = 11
DECLARE @ProductId INT, @WinlostDate SMALLDATETIME, @message VARCHAR(1000)
SELECT @ProductId = 11, @WinlostDate = '2019-03-01'

BEGIN
	SET @message = '@WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT
	
	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END
GO

-- GPI - ProductId = 12
DECLARE @ProductId INT, @WinlostDate SMALLDATETIME, @message VARCHAR(1000)
SELECT @ProductId = 12, @WinlostDate = '2019-03-01'

BEGIN
	SET @message = '@WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT
	
	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END
GO

-- isoftbet - ProductId = 13
DECLARE @ProductId INT, @WinlostDate SMALLDATETIME, @message VARCHAR(1000)
SELECT @ProductId = 13, @WinlostDate = '2019-03-01'

BEGIN
	SET @message = '@WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT
	
	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate
END
GO

-- OPUS - ProductId = 14
DECLARE @ProductId INT, @WinlostDate SMALLDATETIME, @message VARCHAR(1000)
SELECT @ProductId = 14, @WinlostDate = '2019-03-01'

WHILE @WinlostDate < = CONVERT(DATE, GETDATE())
BEGIN
	SET @message = '@WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT
	
	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END
GO