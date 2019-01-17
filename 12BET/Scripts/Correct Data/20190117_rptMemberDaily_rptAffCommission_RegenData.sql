USE Affiliate_12BET
GO

/*
	Created: 20190117@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Regen data for Dec 2018

	Step
		1. Betsoft		ProductId = 11	01 Dec 2018 --> 31 Dec 2018
		2. AG Casino	ProductId = 9	28 Dec 2018 --> 31 Dec 2018
		3. Run commission job
*/


DECLARE @WinlostDate SMALLDATETIME, @ToDate SMALLDATETIME

-- Betsoft
BEGIN
	SELECT @WinlostDate = '2018-12-01', @ToDate = '2018-12-31'

	WHILE @WinlostDate <= @ToDate
	BEGIN
		EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = 11, @WinlostDate = @WinlostDate

		SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END
END

-- AG Casino
BEGIN
	SELECT @WinlostDate = '2018-12-28', @ToDate = '2018-12-31'

	WHILE @WinlostDate <= @ToDate
	BEGIN
		EXEC dbo.Task_Aff_ImportData_AGCasino @WinlostDate = @WinlostDate

		SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END
END

-- Commission job
BEGIN
	EXEC dbo.Task_Aff_Monthly_Commission @MonthDate = '2018-12-01', @IsForceUpdate = 1
END