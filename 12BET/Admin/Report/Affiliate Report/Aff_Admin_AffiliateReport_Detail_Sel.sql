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
		SELECT @FromDate = dbo.Aff_f_GetMinReportDate(@AffId), @ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))
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
		Winloss			MONEY
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
	IF @FromDate <= @CutOffDate
	BEGIN
		SELECT @tmpFromDate = @FromDate
		SELECT @tmpToDate = CASE WHEN @ToDate > @CutOffDate THEN @CutOffDate ELSE @ToDate END

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
	IF @ToDate > @CutOffDate
	BEGIN
		SELECT @tmpFromDate = CASE WHEN @FromDate <= @CutOffDate THEN DATEADD(DAY, 1, @CutOffDate) ELSE @FromDate END
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
	END

	-- Calculate data
	BEGIN
		CREATE TABLE #Result
		(
			WinlostDate		SMALLDATETIME,
			MonthDate		SMALLDATETIME,
			ProductId		INT,
			Currency		INT,
			AffExRate		FLOAT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Bonus			MONEY,
			Turnover		MONEY,
			Winloss			MONEY,
			PlatFormFee		MONEY,
			OperationalFee	MONEY,
			BankingFee		MONEY,
			NetWinloss		MONEY
		)

		-- By Product
		INSERT INTO #Result
		(
			WinlostDate,
			MonthDate,
			ProductId,
			Currency,
			AffExRate,
			Turnover,
			Winloss
		)
		SELECT
			WinlostDate,
			MonthDate,
			ProductId,
			Currency,
			AffExRate,
			SUM(ISNULL(Turnover, 0)) AS Turnover,
			SUM(ISNULL(Winloss, 0)) AS Winloss
		FROM #AffData
		WHERE ProductId > 0
		GROUP BY
			WinlostDate,
			MonthDate,
			ProductId,
			Currency,
			AffExRate

		-- Total
		INSERT INTO #Result
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
			WinlostDate,
			MonthDate,
			0 AS ProductId,
			Currency,
			AffExRate,
			SUM(ISNULL(Deposit, 0))		AS Deposit,
			SUM(ISNULL(Withdrawal, 0))	AS Withdrawal,
			SUM(ISNULL(Bonus, 0))		AS Bonus,
			SUM(ISNULL(Turnover, 0))	AS Turnover,
			SUM(ISNULL(Winloss, 0))		AS Winloss
		FROM #AffData
		GROUP BY
			WinlostDate,
			MonthDate,
			Currency,
			AffExRate

		DROP TABLE #AffData

		-- Calculate Fees
		UPDATE r
		SET r.PlatFormFee		= ABS(ISNULL(r.Winloss, 0)) * s.PlatFormFee,
			r.OperationalFee	= ABS(ISNULL(r.Winloss, 0)) * s.OperationalFee,
			r.BankingFee		= (ISNULL(r.Deposit, 0) + ISNULL(r.Withdrawal, 0)) * s.BankingFee
		FROM #Result r
			INNER JOIN #Setting s ON r.MonthDate = s.MonthDate AND r.ProductId = s.ProductId

		UPDATE r
		SET r.PlatFormFee = pf.PlatFormFee
		FROM #Result r
			CROSS APPLY (
				SELECT SUM(r1.PlatFormFee) AS PlatFormFee
				FROM #Result r1
				WHERE r.WinlostDate = r1.WinlostDate AND r.Currency = r1.Currency AND r1.ProductId > 0
			) AS pf
		WHERE r.ProductId = 0

		-- Net Winloss
		UPDATE #Result
		SET NetWinloss = - Winloss - (PlatFormFee + OperationalFee + BankingFee)
		WHERE ProductId = 0

		DROP TABLE #Setting
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

		-- Uncalculated Months
		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @AffIds VARCHAR(MAX)
		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME
		
		IF @ToDate > @MaxCommDate
		BEGIN
			SELECT	@tempFromDate	= CASE WHEN @FromDate <= @MaxCommDate THEN DATEADD(DAY, 1, @MaxCommDate) ELSE @FromDate END,
					@tempToDate		= @ToDate

			SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

			CREATE TABLE #TempCommission
			(
				MonthDate		SMALLDATETIME,
				AffId			INT,
				GroupId			INT,
				ProductId		INT,
				Deposit			MONEY,
				Withdrawal		MONEY,
				Bonus			MONEY,
				Turnover		MONEY,
				Winloss			MONEY,
				-- Fees
				PlatFormFee		MONEY,
				OperationalFee	MONEY,
				BankingFee		MONEY,
				-- Calculation
				NetWinloss		MONEY,
				ActivePlayer	INT,
				QualifiedMember INT,
				QMTurnover		MONEY,
				CommissionRate	DECIMAL(9,8),
				Commission		MONEY
			)
		
			INSERT INTO #TempCommission
			(
				MonthDate,
				AffId,
				GroupId,
				ProductId,
				Deposit,
				Withdrawal,
				Bonus,
				Turnover,
				Winloss,
				PlatFormFee,
				OperationalFee,
				BankingFee,
				NetWinloss,
				ActivePlayer,
				QualifiedMember,
				QMTurnOver,
				CommissionRate,
				Commission
			)
			EXEC dbo.Aff_Commission_UnCalc @AffIds = @AffIds, @FromMonthDate = @tempFromDate, @ToMonthDate = @tempToDate

			INSERT INTO #CommRate
			(
				MonthDate,
				CommRate
			)
			SELECT
				MonthDate,
				CommissionRate AS CommRate
			FROM #TempCommission
			WHERE ProductId = 0

			DROP TABLE #TempCommission
		END
	END
	
	-- Return data
	SELECT
		Winlostdate,
		AffExRate,
		e.Currency,
		SUM(ISNULL(Deposit, 0))			AS Deposit,
		SUM(ISNULL(Withdrawal, 0))		AS Withdrawal,
		SUM(ISNULL(Turnover, 0))		AS Turnover,
		SUM(ISNULL(Winloss, 0))			AS Winlost,
		SUM(ISNULL(Bonus, 0))			AS Bonus,
		SUM(ISNULL(BankingFee, 0))		AS PSP, -- BankingFee
		0								AS Adjustment, -- will remove later
		SUM(ISNULL(AffAdjustment, 0))	AS AffAdjustment,
		SUM(ISNULL(AffWithdrawal, 0))	AS AffWithdrawal,
		SUM(ISNULL(AffBF, 0))			AS AffBF
	FROM
	(
		SELECT
			r.Winlostdate,
			r.AffExRate,
			r.Currency,
			SUM(ISNULL(r.Deposit, 0))		AS Deposit,
			SUM(ISNULL(r.Withdrawal, 0))	AS Withdrawal,
			SUM(ISNULL(r.Turnover, 0))		AS Turnover,
			SUM(ISNULL(r.Winloss, 0))		AS Winloss,
			SUM(ISNULL(r.Bonus, 0))			AS Bonus,
			SUM(ISNULL(r.BankingFee, 0))	AS BankingFee,
			0								AS AffAdjustment,
			0								AS AffWithdrawal,
			SUM((ISNULL(r.NetWinloss, 0) - ISNULL(r.Bonus, 0)) * ISNULL(c.CommRate, 0)) AS AffBF
		FROM #Result r
			LEFT JOIN #CommRate c ON r.MonthDate = c.MonthDate
		GROUP BY
			r.Winlostdate,
			r.AffExRate,
			r.Currency

		-- Aff Payment, Adjustment
		UNION ALL
		SELECT
			CONVERT(DATE, at.TransDate) AS WinlostDate,
			1 AS AffExRate,
			at.Currency,
			0 AS Deposit,
			0 AS Withdrawal,
			0 AS Turnover,
			0 AS Winloss,
			0 AS Bonus,
			0 AS BankingFee,
			SUM(CASE WHEN at.TransType = 203 THEN at.Amount ELSE 0 END) AS AffAdjustment,
			SUM(CASE WHEN at.TransType = 202 THEN -at.Amount ELSE 0 END) AS AffWithdrawal,
			SUM(at.Amount) AS AffBF
		FROM dbo.AffTrans at WITH (NOLOCK)
			CROSS APPLY @MonthDate md
		WHERE at.AffId = @AffId
			AND at.TransDate >= @FromDate AND at.TransDate < DATEADD(DAY, 1, @ToDate)
			AND at.TransType IN (202, 203)
			AND at.Status IN ('Pending', 'Approved', 'Completed')
		GROUP BY
			CONVERT(DATE, at.TransDate),
			at.Currency
	) AS A
		INNER JOIN dbo.Exchange_Current e WITH (NOLOCK) ON A.Currency = e.ExchangeId
	GROUP BY
		Winlostdate,
		AffExRate,
		e.Currency
	ORDER BY WinlostDate

	DROP TABLE #CommRate
	DROP TABLE #Result
END
GO