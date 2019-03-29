USE [Affiliate_12BET]
GO

/*
	Created: 20190329@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Betsoft - Re-run job update data after update raw data
*/

DECLARE @FromDate SMALLDATETIME
SELECT  @FromDate = '2019-03-01'

DECLARE @ProductId INT, @WinlostDate SMALLDATETIME, @message VARCHAR(1000)

-- Betsoft - ProductId = 11
SELECT @ProductId = 11, @WinlostDate = @FromDate

WHILE @WinlostDate <= CONVERT(DATE, CURRENT_TIMESTAMP)
BEGIN
	SET @message = 'Betsoft: @WinlostDate: ' + CONVERT(VARCHAR(50), @WinlostDate, 121) + ', currentDate: ' + CONVERT(VARCHAR(50), GETDATE(), 121)
	RAISERROR (@message, 0, 1) WITH NOWAIT
	
	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END
