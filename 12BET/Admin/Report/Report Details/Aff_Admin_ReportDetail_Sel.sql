/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_ReportDetail_Sel]
	@AffId		INT = 0,
	@FromDate	SMALLDATETIME,
	@ToDate		SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task:
		Admin site - Report - Report Detail (all Affs - AffId = 0)
		Admin site - Customer - Left menu - Report Detail (by Aff)

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = dbo.Aff_f_GetMoveBetsDay()

	DECLARE @CutOffDate SMALLDATETIME
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME)

	DECLARE @tmpFromDate SMALLDATETIME, @tmpToDate SMALLDATETIME

	;WITH CTE_MonthDate AS
	(
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate) + 1, 0)) AS MonthDate
		UNION ALL
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
		FROM CTE_MonthDate
		WHERE MonthDate < @ToDate
	)
	INSERT INTO @MonthDate (MonthDate)
	SELECT MonthDate FROM CTE_MonthDate
	OPTION (MAXRECURSION 0)

	-- Data
	BEGIN
		DECLARE @tmpDate SMALLDATETIME

		CREATE TABLE #Data
		(
			MonthDate		SMALLDATETIME,
			WinlostDate		SMALLDATETIME,
			AffId			INT,
			ProductId		INT,
			Currency		INT,
			ActualRate		FLOAT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Bonus			MONEY,
			Turnover		MONEY,
			Winloss			MONEY
		)
		CREATE CLUSTERED INDEX CIX_MonthDate_AffId ON #Data (MonthDate, AffId)

		IF @AffId = 0
		BEGIN
			-- MemberDaily
			IF @FromDate < @CutOffDate
			BEGIN
				SELECT @tmpFromDate = @FromDate
				SELECT @tmpToDate = CASE WHEN @ToDate >= @CutOffDate THEN @CutOffDate ELSE @ToDate END

				-- Deposit, Withdrawal, Bonus
				INSERT INTO #Data
				(
					MonthDate,
					WinlostDate,
					AffId,
					ProductId,
					Currency,
					ActualRate,
					Deposit,
					Withdrawal,
					Bonus,
					Turnover,
					Winloss
				)
				SELECT
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate,
					md.WinlostDate,
					md.AffId,
					-1 AS ProductId,
					md.Currency,
					md.AffExRate,
					SUM(ISNULL(md.Deposit, 0)),
					SUM(ISNULL(md.Withdrawal, 0)),
					SUM(ISNULL(md.Bonus, 0)),
					0 AS Turnover,
					0 AS Winloss
				FROM dbo.MemberDaily md WITH (NOLOCK)
				WHERE md.WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
					AND NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.IBCCustId = md.IBCCustId
								AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
						)
				GROUP BY
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
					md.WinlostDate,
					md.AffId,
					md.Currency,
					md.AffExRate

				-- Turnover, Winloss
				INSERT INTO #Data
				(
					MonthDate,
					WinlostDate,
					AffId,
					ProductId,
					Currency,
					ActualRate,
					Deposit,
					Withdrawal,
					Bonus,
					Turnover,
					Winloss
				)
				SELECT
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate,
					md.WinlostDate,
					md.AffId,
					md.SportType AS ProductId,
					md.Currency,
					md.AffExRate,
					0 AS Deposit,
					0 AS Withdrawal,
					0 AS Bonus,
					SUM(ISNULL(md.Turnover, 0)),
					SUM(ISNULL(md.Winlost, 0))
				FROM dbo.MemberDaily md WITH (NOLOCK)
				WHERE md.WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
					AND NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.IBCCustId = md.IBCCustId
								AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
						)
				GROUP BY
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
					md.WinlostDate,
					md.AffId,
					md.SportType,
					md.Currency,
					md.AffExRate
			END

			-- rptMemberDaily
			IF @ToDate >= @CutOffDate
			BEGIN
				SELECT @tmpFromDate = CASE WHEN @FromDate < @CutOffDate THEN @CutOffDate ELSE @FromDate END
				SELECT @tmpToDate = @ToDate

				INSERT INTO #Data
				(
					MonthDate,
					WinlostDate,
					AffId,
					ProductId,
					Currency,
					ActualRate,
					Deposit,
					Withdrawal,
					Bonus,
					Turnover,
					Winloss
				)
				SELECT
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate,
					md.WinlostDate,
					md.AffId,
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
				WHERE md.WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
					AND NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.IBCCustId = md.IBCCustId
								AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
						)
				GROUP BY
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
					md.WinlostDate,
					md.AffId,
					md.ProductId,
					md.Currency,
					md.AffExRate
			END

			-- bettrans
			IF @ToDate > @MoveBetsDay
			BEGIN
				SELECT @tmpDate = CASE WHEN @FromDate <= @MoveBetsDay THEN DATEADD(DAY, 1, @MoveBetsDay) ELSE @FromDate END

				INSERT INTO #Data
				(
					MonthDate,
					WinlostDate,
					AffId,
					ProductId,
					Currency,
					ActualRate,
					Deposit,
					Withdrawal,
					Bonus,
					Turnover,
					Winloss
				)
				SELECT
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate,
					md.WinlostDate,
					mi.AffId,
					md.ProductId,
					md.Currency,
					e.ActualRate2,
					SUM(ISNULL(md.Deposit, 0)),
					SUM(ISNULL(md.Withdrawal, 0)),
					SUM(ISNULL(md.Bonus, 0)),
					SUM(ISNULL(md.Turnover, 0)),
					SUM(ISNULL(md.Winloss, 0))
				FROM OPENQUERY(DBEXT, 'SELECT WinlostDate,IBCCustId,currency,ProductId,Deposit,Withdrawal,Bonus,Turnover,Winloss
										FROM bodb02.dbo.Aff_f_Bettrans_Sel()') md
					INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON md.IBCCustId = mi.IBCCustId
					CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(md.Currency, md.WinlostDate) e
					CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 1, md.WinlostDate, @MoveBetsDay) f
				WHERE md.WinlostDate BETWEEN @tmpDate AND @ToDate
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.IBCCustId = mi.IBCCustId
							AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
					)
				GROUP BY
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
					md.WinlostDate,
					mi.AffId,
					md.ProductId,
					md.Currency,
					e.ActualRate2
			END
		END
		ELSE
		BEGIN
			-- MemberDaily
			IF @FromDate < @CutOffDate
			BEGIN
				SELECT @tmpFromDate = @FromDate
				SELECT @tmpToDate = CASE WHEN @ToDate >= @CutOffDate THEN @CutOffDate ELSE @ToDate END

				-- Deposit, Withdrawal, Bonus
				INSERT INTO #Data
				(
					MonthDate,
					WinlostDate,
					AffId,
					ProductId,
					Currency,
					ActualRate,
					Deposit,
					Withdrawal,
					Bonus,
					Turnover,
					Winloss
				)
				SELECT
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate,
					md.WinlostDate,
					@AffId,
					-1 AS ProductId,
					md.Currency,
					md.AffExRate,
					SUM(ISNULL(md.Deposit, 0)),
					SUM(ISNULL(md.Withdrawal, 0)),
					SUM(ISNULL(md.Bonus, 0)),
					0 AS Turnover,
					0 AS Winloss
				FROM dbo.MemberDaily md WITH (NOLOCK)
				WHERE md.WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
					AND md.AffId = @AffId
					AND NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.IBCCustId = md.IBCCustId
								AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
						)
				GROUP BY
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
					md.WinlostDate,
					md.Currency,
					md.AffExRate

				-- Turnover, Winloss
				INSERT INTO #Data
				(
					MonthDate,
					WinlostDate,
					AffId,
					ProductId,
					Currency,
					ActualRate,
					Deposit,
					Withdrawal,
					Bonus,
					Turnover,
					Winloss
				)
				SELECT
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate,
					md.WinlostDate,
					@AffId,
					md.SportType AS ProductId,
					md.Currency,
					md.AffExRate,
					0 AS Deposit,
					0 AS Withdrawal,
					0 AS Bonus,
					SUM(ISNULL(md.Turnover, 0)),
					SUM(ISNULL(md.Winlost, 0))
				FROM dbo.MemberDaily md WITH (NOLOCK)
				WHERE md.WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
					AND md.AffId = @AffId
					AND NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.IBCCustId = md.IBCCustId
								AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
						)
				GROUP BY
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
					md.WinlostDate,
					md.SportType,
					md.Currency,
					md.AffExRate
			END

			-- rptMemberDaily
			IF @ToDate >= @CutOffDate
			BEGIN
				SELECT @tmpFromDate = CASE WHEN @FromDate < @CutOffDate THEN @CutOffDate ELSE @FromDate END
				SELECT @tmpToDate = @ToDate
			
				INSERT INTO #Data
				(
					MonthDate,
					WinlostDate,
					AffId,
					ProductId,
					Currency,
					ActualRate,
					Deposit,
					Withdrawal,
					Bonus,
					Turnover,
					Winloss
				)
				SELECT
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate,
					md.WinlostDate,
					@AffId,
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
				WHERE md.WinlostDate BETWEEN @FromDate AND @ToDate
					AND NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.IBCCustId = md.IBCCustId
								AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
						)
					AND md.AffId = @AffId
				GROUP BY
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
					md.WinlostDate,
					md.ProductId,
					md.Currency,
					md.AffExRate
			END

			-- bettrans
			IF @ToDate > @MoveBetsDay
			BEGIN
				SELECT @tmpDate = CASE WHEN @FromDate <= @MoveBetsDay THEN DATEADD(DAY, 1, @MoveBetsDay) ELSE @FromDate END

				INSERT INTO #Data
				(
					MonthDate,
					WinlostDate,
					AffId,
					ProductId,
					Currency,
					ActualRate,
					Deposit,
					Withdrawal,
					Bonus,
					Turnover,
					Winloss
				)
				SELECT
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate,
					md.WinlostDate,
					@AffId,
					md.ProductId,
					md.Currency,
					e.ActualRate2,
					SUM(ISNULL(md.Deposit, 0)),
					SUM(ISNULL(md.Withdrawal, 0)),
					SUM(ISNULL(md.Bonus, 0)),
					SUM(ISNULL(md.Turnover, 0)),
					SUM(ISNULL(md.Winloss, 0))
				FROM OPENQUERY(DBEXT, 'SELECT WinlostDate,IBCCustId,currency,ProductId,Deposit,Withdrawal,Bonus,Turnover,Winloss
										FROM bodb02.dbo.Aff_f_Bettrans_Sel()') md
					INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON md.IBCCustId = mi.IBCCustId
					CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(md.Currency, md.WinlostDate) e
					CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 1, md.WinlostDate, @MoveBetsDay) f
				WHERE md.WinlostDate BETWEEN @tmpDate AND @ToDate
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.IBCCustId = mi.IBCCustId
							AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
					)
					AND mi.AffId = @AffId
				GROUP BY
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
					md.WinlostDate,
					md.ProductId,
					md.Currency,
					e.ActualRate2
			END
		END
	END

	-- Setting
	BEGIN
		CREATE TABLE #Setting
		(
			MonthDate		SMALLDATETIME,
			AffId			INT,
			ProductId		INT,
			PlatFormFee		DECIMAL(9,8),
			OperationalFee	DECIMAL(9,8),
			BankingFee		DECIMAL(9,8)
		)
		CREATE CLUSTERED INDEX CIX_MonthDate_AffId ON #Setting (MonthDate, AffId)

		IF @AffId = 0
		BEGIN
			INSERT INTO #Setting
			(
				MonthDate,
				AffId,
				ProductId,
				PlatFormFee,
				OperationalFee,
				BankingFee
			)
			SELECT
				agh.MonthDate,
				agh.AffId,
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
		END
		ELSE
		BEGIN
			INSERT INTO #Setting
			(
				MonthDate,
				AffId,
				ProductId,
				PlatFormFee,
				OperationalFee,
				BankingFee
			)
			SELECT
				agh.MonthDate,
				agh.AffId,
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

		UPDATE s
		SET s.OperationalFee	= s1.OperationalFee,
			s.BankingFee		= s1.BankingFee
		FROM #Setting s
			INNER JOIN #Setting s1 ON s.MonthDate = s1.MonthDate AND s.AffId = s1.AffId
		WHERE s.ProductId <> 0 AND s1.ProductId = 0

		UPDATE #Setting
		SET ProductId = -1
		WHERE ProductId = 0
	END

	-- Commission Rate
	BEGIN
		CREATE TABLE #CommRate
		(
			MonthDate	SMALLDATETIME,
			AffId		INT,
			CommRate	DECIMAL(9,8)
		)
		CREATE CLUSTERED INDEX CIX_MonthDate_AffId ON #CommRate (MonthDate, AffId)

		IF @AffId = 0
		BEGIN
			INSERT INTO #CommRate
			(
				MonthDate,
				AffId,
				CommRate
			)
			SELECT
				ac.MonthDate,
				ac.AffId,
				ac.CommissionRate
			FROM @MonthDate md
				INNER JOIN dbo.rptAffCommission ac WITH (NOLOCK) ON md.MonthDate = ac.MonthDate
			WHERE ac.ProductId = 0
		END
		ELSE
		BEGIN
			INSERT INTO #CommRate
			(
				MonthDate,
				AffId,
				CommRate
			)
			SELECT
				ac.MonthDate,
				@AffId,
				ac.CommissionRate
			FROM @MonthDate md
				INNER JOIN dbo.rptAffCommission ac WITH (NOLOCK) ON md.MonthDate = ac.MonthDate
			WHERE ac.ProductId = 0
				AND ac.AffId = @AffId
		END

		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @AffIds VARCHAR(MAX)
		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME
		
		-- Uncalculated Months
		IF DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate) + 1, 0)) > @MaxCommDate
		BEGIN
			SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
					@tempToDate		= @ToDate

			SELECT @AffIds = CASE WHEN @AffId = 0 THEN 'all' ELSE CONVERT(VARCHAR(20), @AffId) END

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
				AffId,
				CommRate
			)
			SELECT
				MonthDate,
				AffId,
				CommissionRate AS CommRate
			FROM #TempCommission
			WHERE ProductId = 0

			DROP TABLE #TempCommission
		END
	END
	
	-- Return data
	SELECT
		dt.WinlostDate,
		ec.Currency,
		dt.ActualRate,
		SUM(dt.Deposit)		AS Deposit,
		SUM(dt.Bonus)		AS Bonus,
		SUM(dt.Turnover)	AS Turnover,
		SUM(dt.Winloss)		AS MemberWinLost,
		SUM(-dt.Winloss * ISNULL(c.CommRate, 0))		AS AffiliateWinLost,
		SUM(-dt.Winloss * (1 - ISNULL(c.CommRate, 0)))	AS HouseWinLost,
		SUM((-dt.Winloss
			- ABS(dt.Winloss * s.PlatFormFee)
			- ABS(dt.Winloss * s.OperationalFee)
			- (dt.Deposit + dt.Withdrawal) * s.BankingFee
			) * ISNULL(c.CommRate, 0)) AS AffiliateNetWinLost,
		SUM((-dt.Winloss
			- ABS(dt.Winloss * s.PlatFormFee)
			- ABS(dt.Winloss * s.OperationalFee)
			- (dt.Deposit + dt.Withdrawal) * s.BankingFee
			) * (1 - ISNULL(c.CommRate, 0))) AS HouseNetWinLost
	FROM #Data dt
		INNER JOIN #Setting s ON dt.MonthDate = s.MonthDate AND dt.AffId = s.AffId AND dt.ProductId = s.ProductId
		LEFT JOIN #CommRate c ON dt.MonthDate = c.MonthDate AND dt.AffId = c.AffId
		LEFT JOIN dbo.Exchange_Current ec WITH (NOLOCK) ON dt.Currency = ec.ExchangeId
	GROUP BY
		dt.WinlostDate,
		ec.Currency,
		dt.ActualRate
	ORDER BY
		dt.WinlostDate

	DROP TABLE #Data
	DROP TABLE #Setting
	DROP TABLE #CommRate
END
GO