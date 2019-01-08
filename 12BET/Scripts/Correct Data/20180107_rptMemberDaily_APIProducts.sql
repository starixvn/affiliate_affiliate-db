USE [Affiliate_12BET]
GO

/*
	Created: Percy
	Date: 2019-01-08
	DB: DBAFF12BET - Affiliate_12BET
	Task: Manually correct data
		- AG Casino on 2018-12-14
		- PTCS from 2018-12-01
		- Other API Products from LaunchDate

		SELECT ProductId, CONVERT(DATETIME, SettingValue)
		FROM dbo.APIProductSettings WITH (NOLOCK)
		WHERE ProductId IN (10,11,12,13,14)
			AND SettingName = 'LaunchDate'

*/

-- 1. AG Casino
BEGIN
	EXEC dbo.Task_Aff_ImportData_AGCasino @WinlostDate = '2018-12-14'
END

-- 2. PTCS
BEGIN
	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME
	SELECT  @FromDate = '2018-12-01', @ToDate = '2019-01-07'

	DECLARE @CasinoId INT = 3

	DECLARE @tblWinlostdate TABLE (WinlostDate SMALLDATETIME PRIMARY KEY)

	;WITH CTE_WinlostDate AS
	(
		SELECT @FromDate AS WinlostDate
		UNION ALL
		SELECT DATEADD(DAY, 1, WinlostDate)
		FROM CTE_WinlostDate
		WHERE WinlostDate < @ToDate
	)
	INSERT INTO @tblWinlostdate (WinlostDate)
	SELECT WinlostDate FROM CTE_WinlostDate
	--OPTION (MAXRECURSION 0)

	MERGE dbo.rptMemberDaily AS TARGET
	USING
	(
		SELECT
			md.WinlostDate,
			md.IBCCustID,
			md.AffId,
			@CasinoId AS ProductId,
			md.Currency,
			md.AffExRate,
			md.MemberExRate AS ExRate,
			0 AS Bonus,
			SUM(md.Turnover) AS Turnover,
			SUM(md.Winlost) AS Winloss
		FROM dbo.MemberDaily md WITH (NOLOCK)
			INNER JOIN @tblWinlostdate wld ON md.WinlostDate = wld.WinlostDate
		WHERE md.Sporttype = @CasinoId
		GROUP BY
			md.WinlostDate,
			md.IBCCustID,
			md.AffId,
			md.Currency,
			md.AffExRate,
			md.MemberExRate

		UNION ALL
		SELECT
			md.WinlostDate,
			md.IBCCustID,
			md.AffId,
			-3 AS ProductId,
			md.Currency,
			md.AffExRate,
			md.MemberExRate AS ExRate,
			SUM(md.Bonus) AS Bonus,
			0 AS Turnover,
			0 AS Winloss
		FROM dbo.MemberDaily md WITH (NOLOCK)
			INNER JOIN @tblWinlostdate wld ON md.WinlostDate = wld.WinlostDate
		WHERE md.Sporttype = @CasinoId
		GROUP BY
			md.WinlostDate,
			md.IBCCustID,
			md.AffId,
			md.Currency,
			md.AffExRate,
			md.MemberExRate
	) AS SOURCE
		ON		TARGET.WinlostDate	= SOURCE.WinlostDate
			AND TARGET.IBCCustId	= SOURCE.IBCCustId
			AND TARGET.ProductId	= SOURCE.ProductId
	WHEN MATCHED THEN
		UPDATE SET
			TARGET.Currency		= SOURCE.Currency,
			TARGET.AffId		= SOURCE.AffId,
			TARGET.Deposit		= 0,
			TARGET.Withdrawal	= 0,
			TARGET.Bonus		= SOURCE.Bonus,
			TARGET.Adjustment	= 0,
			TARGET.Turnover		= SOURCE.Turnover,
			TARGET.Winloss		= SOURCE.Winloss,
			TARGET.AffExRate	= SOURCE.AffExRate,
			TARGET.ExRate		= SOURCE.ExRate
	WHEN NOT MATCHED BY TARGET THEN
		INSERT
		(
			WinlostDate,IBCCustId,Currency,AffId,ProductId,
			Deposit,Withdrawal,Bonus,Adjustment,
			Turnover,Winloss,AffExRate,ExRate
		)
		VALUES
		(
			SOURCE.WinlostDate,SOURCE.IBCCustId,SOURCE.Currency,SOURCE.AffId,SOURCE.ProductId,
			0,0,SOURCE.Bonus,0,
			SOURCE.Turnover,SOURCE.Winloss,SOURCE.AffExRate,SOURCE.ExRate
		)
	WHEN NOT MATCHED BY SOURCE
			AND TARGET.WinlostDate IN (SELECT WinlostDate FROM @tblWinlostdate)
			AND TARGET.ProductId = @CasinoId
		THEN DELETE;
END

-- 3. Other API Products
BEGIN
	DECLARE @ProductId INT, @WinlostDate SMALLDATETIME, @Id INT
	DECLARE @Yesterday SMALLDATETIME = DATEADD(DAY, -1, CONVERT(DATE, GETDATE()))

	DECLARE @Products TABLE (Id INT IDENTITY(1,1), ProductId INT, FromDate SMALLDATETIME)
	INSERT INTO @Products (ProductId, FromDate)
	SELECT ProductId, CONVERT(DATETIME, SettingValue)
	FROM dbo.APIProductSettings WITH (NOLOCK)
	WHERE ProductId IN (10,11,12,13,14)
		AND SettingName = 'LaunchDate'

	SELECT @Id = 1

	SELECT @ProductId = ProductId, @WinlostDate = FromDate FROM @Products WHERE Id = @Id

	WHILE @ProductId IS NOT NULL
	BEGIN
		WHILE @WinlostDate <= @Yesterday
		BEGIN
			EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate

			SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
		END


		SELECT @ProductId = NULL, @WinlostDate = NULL
		SELECT @Id = @Id + 1
		SELECT @ProductId = ProductId, @WinlostDate = FromDate FROM @Products WHERE Id = @Id
	END
END