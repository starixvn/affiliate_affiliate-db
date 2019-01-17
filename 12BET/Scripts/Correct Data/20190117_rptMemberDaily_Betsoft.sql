USE Affiliate_12BET
GO

/*
	Created: 20190117@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Regen data for Betsoft - ProductId = 11
*/

DECLARE @WinlostDate SMALLDATETIME, @ToDate SMALLDATETIME

SELECT  @WinlostDate = '2019-01-01', @ToDate = '2019-01-17'

WHILE @WinlostDate <= @ToDate
BEGIN
	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = 11, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END