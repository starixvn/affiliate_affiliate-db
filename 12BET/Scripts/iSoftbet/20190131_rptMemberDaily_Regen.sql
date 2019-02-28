USE [Affiliate_12BET]
GO

/*
	Created: 20190131@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Regen iSoftbet's data from Dec 2018 - rptMemberDaily
*/

DECLARE @WinlostDate SMALLDATETIME = '2019-01-01'

WHILE @WinlostDate <= '2019-01-31'
BEGIN
	EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = 13, @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END
