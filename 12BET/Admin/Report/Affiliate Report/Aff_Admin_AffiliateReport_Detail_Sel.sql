/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateReport_Detail_Sel]
	@AffUsername	NVARCHAR(50),
	@AffId			INT = 0 OUTPUT,
	@FromDate		SMALLDATETIME,
	@ToDate			SMALLDATETIME,
	@IsGetAll		BIT = 0,
	@SportId		INT = NULL
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin site - Report - Affiliate Report - Detail

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @AffId = AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE Username = @AffUsername

	IF @AffId = 0
		RETURN

	DECLARE @ProductId INT
	SELECT  @ProductId = ISNULL(@SportId, 0)

	SELECT	@FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0), -- Begin Month of @FromDate
			@ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0)) -- End Month of @ToDate

	IF @IsGetAll = 1
	BEGIN
		SELECT @FromDate = DATEADD(DAY, 1, CONVERT(DATE, SValue))
		FROM dbo.SystemSettings WITH (NOLOCK)
		WHERE SName = 'AFF_OldReportDate'

		SELECT @ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))
	END

	CREATE TABLE #AffData
	(
		WinlostDate		SMALLDATETIME,
		MonthDate		SMALLDATETIME,
		ProductId		INT,
		Currency		INT,
		AffExRate		FLOAT,
		Deposit			MONEY,
		Withdrawal		MONEY,
		BankingFee		MONEY,
		Bonus			MONEY,
		Turnover		MONEY,
		Winloss			MONEY,
		AffCommission	MONEY,
		AffWithdrawal	MONEY,
		AffAdjustment	MONEY,
		BFF				MONEY
	)

	-- Get data
	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = dbo.Aff_f_GetMoveBetsDay()

	DECLARE @CutOffDate SMALLDATETIME
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

	DECLARE @tmpFromDate SMALLDATETIME, @tmpToDate SMALLDATETIME

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME)

	;WITH CTE_MonthDate AS
	(
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, @FromDate)) AS MonthDate -- last day of month
		UNION ALL
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
		FROM CTE_MonthDate
		WHERE MonthDate < @ToDate
	)
	INSERT INTO @MonthDate (MonthDate)
	SELECT MonthDate FROM CTE_MonthDate
	OPTION (MAXRECURSION 0)

	-- MemberDaily
	IF @FromDate < @CutOffDate
	BEGIN
		SELECT @tmpFromDate = @FromDate
		SELECT @tmpToDate = CASE WHEN @ToDate >= @CutOffDate THEN @CutOffDate ELSE @ToDate END

		-- Deposit, Withdrawal, Bonus
		INSERT INTO #AffData
		(
			WinlostDate,
			MonthDate,
			ProductId,
			Currency,
			AffExRate,
			Deposit,
			Withdrawal,
			Bonus,
			Turnover,
			Winloss
		)
		SELECT
			md.WinlostDate,
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
			-1 AS ProductId,
			md.Currency,
			md.AffExRate,
			SUM(ISNULL(md.Deposit, 0)),
			SUM(ISNULL(md.Withdrawal, 0)),
			SUM(ISNULL(md.Bonus, 0)),
			0 AS Turnover,
			0 AS Winloss
		FROM dbo.MemberDaily md WITH (NOLOCK)
		WHERE md.AffId = @AffId
			AND md.WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
		GROUP BY
			md.WinlostDate,
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
			md.Currency,
			md.AffExRate

		-- Turnover, Winloss
		IF ISNULL(@ProductId, 0) IN (0,1,3)
		BEGIN
			INSERT INTO #AffData
			(
				WinlostDate,
				MonthDate,
				ProductId,
				Currency,
				AffExRate,
				Deposit,
				Withdrawal,
				Bonus,
				Turnover,
				Winloss
			)
			SELECT
				md.WinlostDate,
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
				md.SportType AS ProductId,
				md.Currency,
				md.AffExRate,
				0 AS Deposit,
				0 AS Withdrawal,
				0 AS Bonus,
				SUM(ISNULL(md.Turnover, 0)),
				SUM(ISNULL(md.Winlost, 0))
			FROM dbo.MemberDaily md WITH (NOLOCK)
			WHERE md.AffId = @AffId
				AND md.WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
				AND (ISNULL(@ProductId, 0) = 0 OR md.SportType = @ProductId)
			GROUP BY
				md.WinlostDate,
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
				md.SportType,
				md.Currency,
				md.AffExRate
		END
	END
	
	-- rptMemberDaily
	IF @ToDate >= @CutOffDate
	BEGIN
		SELECT @tmpFromDate = CASE WHEN @FromDate < @CutOffDate THEN @CutOffDate ELSE @FromDate END
		SELECT @tmpToDate = @ToDate
	
		INSERT INTO #AffData
		(
			WinlostDate,
			MonthDate,
			ProductId,
			Currency,
			AffExRate,
			Deposit,
			Withdrawal,
			Bonus,
			Turnover,
			Winloss
		)
		SELECT
			md.WinlostDate,
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
			md.ProductId,
			md.Currency,
			md.AffExRate,
			SUM(ISNULL(md.Deposit, 0)),
			SUM(ISNULL(md.Withdrawal, 0)),
			SUM(ISNULL(md.Bonus, 0)),
			SUM(ISNULL(md.Turnover, 0)),
			SUM(ISNULL(md.Winloss, 0))
		FROM dbo.rptMemberDaily md WITH (NOLOCK)
			CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 0, md.WinlostDate, @MoveBetsDay) f
		WHERE md.AffId = @AffId
			AND md.WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
			AND (@ProductId = 0 OR md.ProductId = @ProductId OR md.ProductId < 0)
		GROUP BY
			md.WinlostDate,
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
			md.ProductId,
			md.Currency,
			md.AffExRate
	END

	-- Bettrans
	IF @ToDate > @MoveBetsDay
	BEGIN
		DECLARE @tmpDate SMALLDATETIME
		SELECT  @tmpDate = CASE WHEN @FromDate <= @MoveBetsDay THEN DATEADD(DAY, 1, @MoveBetsDay) ELSE @FromDate END
	
		INSERT INTO #AffData
		(
			WinlostDate,
			MonthDate,
			ProductId,
			Currency,
			AffExRate,
			Deposit,
			Withdrawal,
			Bonus,
			Turnover,
			Winloss
		)
		SELECT
			md.WinlostDate,
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
			md.ProductId,
			md.Currency,
			e.ActualRate2 AS AffExRate,
			SUM(md.Deposit),
			SUM(md.Withdrawal),
			SUM(md.Bonus),
			SUM(md.Turnover),
			SUM(md.Winloss)
		FROM OPENQUERY(DBEXT, 'SELECT WinlostDate,IBCCustId,ProductId,Currency,Deposit,Withdrawal,Bonus,Turnover,Winloss
										FROM bodb02.dbo.Aff_f_Bettrans_Sel()') md
			CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(md.Currency, md.WinlostDate) e
			CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 1, md.WinlostDate, @MoveBetsDay) f
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON md.IBCCustId = mi.IBCCustId AND mi.AffId = @AffId
		WHERE (@ProductId = 0 OR md.ProductId = @ProductId OR md.ProductId < 0)
			AND md.WinlostDate BETWEEN @tmpDate AND @ToDate
		GROUP BY
			md.WinlostDate,
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
			md.ProductId,
			md.Currency,
			e.ActualRate2
	END

	-- Setting
	BEGIN
		CREATE TABLE #Setting
		(
			MonthDate		SMALLDATETIME,
			ProductId		INT,
			PlatFormFee		DECIMAL(9,8),
			OperationalFee	DECIMAL(9,8),
			BankingFee		DECIMAL(9,8)
		)
		CREATE CLUSTERED INDEX CIX_MonthDate_AffId ON #Setting (MonthDate)

		INSERT INTO #Setting
		(
			MonthDate,
			ProductId,
			PlatFormFee,
			OperationalFee,
			BankingFee
		)
		SELECT
			agh.MonthDate,
			cg.ProductId,
			cg.PlatFormFee,
			cg.OperationalFee,
			cg.BankingFee
		FROM @MonthDate md
			INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON md.MonthDate = agh.MonthDate
			CROSS APPLY (
				SELECT
					cgh.ProductId,
					SUM(CASE WHEN cgh.DeductionId = 10 THEN cgh.DeductedPercentage ELSE 0 END) AS PlatFormFee,
					SUM(CASE WHEN cgh.DeductionId = 11 THEN cgh.DeductedPercentage ELSE 0 END) AS OperationalFee,
					SUM(CASE WHEN cgh.DeductionId = 12 THEN cgh.DeductedPercentage ELSE 0 END) AS BankingFee
				FROM dbo.DeductionSettingHistory cgh WITH (NOLOCK)
				WHERE cgh.MonthDate = agh.MonthDate AND cgh.GroupId = agh.GroupId
				GROUP BY
					cgh.ProductId
			) cg
		WHERE agh.AffId = @AffId

		UPDATE s
		SET s.OperationalFee	= s1.OperationalFee,
			s.BankingFee		= s1.BankingFee
		FROM #Setting s
			INNER JOIN #Setting s1 ON s.MonthDate = s1.MonthDate
		WHERE s.ProductId <> 0 AND s1.ProductId = 0

		UPDATE #Setting
		SET ProductId = -1
		WHERE ProductId = 0
	END

	-- Commission Rate
	BEGIN
		CREATE TABLE #CommRate
		(
			MonthDate	SMALLDATETIME PRIMARY KEY,
			CommRate	DECIMAL(9,8)
		)

		INSERT INTO #CommRate
		(
			MonthDate,
			CommRate
		)
		SELECT
			ac.MonthDate,
			ac.CommissionRate
		FROM @MonthDate md
			INNER JOIN dbo.rptAffCommission ac WITH (NOLOCK) ON md.MonthDate = ac.MonthDate
		WHERE ac.ProductId = 0
			AND ac.AffId = @AffId
	END

	-- Aff Commission, Payment, Adjustment, BFF
	INSERT INTO #AffData
	(
		WinlostDate,
		MonthDate,
		Currency,
		AffExRate,
		AffCommission,
		BFF
	)
	SELECT
		CONVERT(DATE, at.TransDate) AS WinlostDate,
		DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, at.TransDate) + 1, 0)) AS MonthDate,
		at.Currency,
		1 AS AffExRate,
		SUM(at.Amount) AS Commission,
		SUM(at.Amount) AS BFF
	FROM dbo.AffTrans at WITH (NOLOCK)
		CROSS APPLY @MonthDate md
	WHERE at.AffId = @AffId AND at.TransDate = md.MonthDate
		AND at.TransType = 201
	GROUP BY
		CONVERT(DATE, at.TransDate),
		DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, at.TransDate) + 1, 0)),
		at.Currency

	INSERT INTO #AffData
	(
		WinlostDate,
		MonthDate,
		Currency,
		AffExRate,
		AffWithdrawal,
		AffAdjustment,
		BFF
	)
	SELECT
		CONVERT(DATE, at.TransDate) AS WinlostDate,
		DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, at.TransDate) + 1, 0)) AS MonthDate,
		at.Currency,
		1 AS AffExRate,
		SUM(CASE WHEN at.TransType = 202 THEN -at.Amount ELSE 0 END) AS Payment,
		SUM(CASE WHEN at.TransType = 203 THEN at.Amount ELSE 0 END) AS Adjustment,
		SUM(at.Amount) AS BFF
	FROM dbo.AffTrans at WITH (NOLOCK)
		CROSS APPLY @MonthDate md
	WHERE at.AffId = @AffId
		AND at.TransDate >= @FromDate AND at.TransDate < DATEADD(DAY, 1, @ToDate)
		AND at.TransType IN (202, 203)
		AND at.Status IN ('Pending', 'Approved', 'Completed')
	GROUP BY
		CONVERT(DATE, at.TransDate),
		DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, at.TransDate) + 1, 0)),
		at.Currency
	
	-- Return data
	SELECT
		ad.Winlostdate,
		ad.AffExRate,
		e.Currency,
		SUM(ISNULL(ad.Deposit, 0)) AS Deposit,
		SUM(ISNULL(ad.Withdrawal, 0)) AS Withdrawal,
		SUM(ISNULL(ad.Turnover, 0)) AS Turnover,
		SUM(ISNULL(ad.Winloss, 0)) AS Winlost,
		SUM(ISNULL(ad.Bonus, 0)) AS Bonus,
		SUM((ISNULL(ad.Deposit, 0) + ISNULL(ad.Withdrawal, 0)) * s.BankingFee) AS PSP, -- BankingFee
		0 AS Adjustment, -- will remove later
		SUM(ISNULL(ad.AffAdjustment, 0)) AS AffAdjustment,
		SUM(ISNULL(ad.AffWithdrawal, 0)) AS AffWithdrawal,
		SUM(ISNULL(ad.BFF, 0)
			+
			(ISNULL(-ad.Winloss, 0)
			- ABS(ISNULL(ad.Winloss, 0) * s.PlatFormFee)
			- ABS(ISNULL(ad.Winloss, 0) * s.OperationalFee)
			- (ISNULL(ad.Deposit, 0) + ISNULL(ad.Withdrawal, 0)) * s.BankingFee
			) * ISNULL(c.CommRate, 0)) AS AffBF
	FROM #AffData ad
		INNER JOIN #Setting s ON ad.MonthDate = s.MonthDate AND ad.ProductId = s.ProductId
		LEFT JOIN #CommRate c ON ad.MonthDate = c.MonthDate
		INNER JOIN dbo.Exchange_Current e WITH (NOLOCK) ON ad.Currency = e.ExchangeId
	GROUP BY
		ad.Winlostdate,
		ad.AffExRate,
		e.Currency
	ORDER BY
		ad.WinlostDate

	DROP TABLE #AffData
	DROP TABLE #CommRate
	DROP TABLE #Setting
END
GO