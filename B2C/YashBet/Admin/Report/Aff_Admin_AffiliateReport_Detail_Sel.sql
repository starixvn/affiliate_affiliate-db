/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateReport_Detail_Sel]
	@Username			NVARCHAR(50)
	,@FromDate			SMALLDATETIME
	,@ToDate			SMALLDATETIME
	,@IsGetAll			BIT = 0
	,@ProductIds		VARCHAR(MAX) = '0'
	,@Currencies		VARCHAR(MAX) = ''
	,@BaseCurrency		INT = 0
	,@SortType			TINYINT = 1
	,@SortDirectionType	BIT = 0
	,@IsExportExcel		BIT = 0
	,@PageIndex			INT = 1
	,@PageSize			INT = 50
	,@NRows				INT = 0 OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin site - Report - Affiliate Report - Detail Affiliate

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

	Param's Explanation:
		- @SortType: 1: Month, 2: Turnover, 3: GGR, 4: Earning (Commission)
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
		- @ProductIds: list of products
		- @BaseCurrency : Currency of B2C
		- @Currencies : Currency of B2C, 72: represent for USD( currency 72, 3)

*/

BEGIN
	SET NOCOUNT ON

	SELECT  @Username = ISNULL(LTRIM(RTRIM(@Username)), '')

	DECLARE @AffId INT
	SELECT  @AffId = AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE Username = @Username AND Status = 'Approved'

	IF @AffId IS NULL
		RETURN

	DECLARE @MinReportDate SMALLDATETIME, @EndOfCurrentMonth SMALLDATETIME
	SELECT  @MinReportDate		= dbo.Aff_f_GetMinReportDate(@AffId)
	SELECT  @EndOfCurrentMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

	IF @IsGetAll = 0
	BEGIN
		IF @FromDate IS NULL OR @ToDate IS NULL
			RETURN

		SELECT  @FromDate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0) -- Begin Of Month
		SELECT  @ToDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0)) -- End Of Month

		IF @FromDate < @MinReportDate
			SELECT @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MinReportDate), 0)

		IF @ToDate > @EndOfCurrentMonth
			SELECT @ToDate = @EndOfCurrentMonth
	END
	ELSE
	BEGIN
		SELECT  @FromDate	= @MinReportDate
		SELECT  @ToDate		= @EndOfCurrentMonth
	END

	SELECT @NRows = DATEDIFF(MONTH, @FromDate, @ToDate) + 1
	
	IF @NRows <= 0
		RETURN

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME, RowIdx INT)
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

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	/*
		===== Get data =====
	*/
	BEGIN
		DECLARE @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

		CREATE TABLE #TempCommission
		(
			MonthDate			SMALLDATETIME,
			AffId				INT,
			GroupId				INT,
			ProductId			INT,
			Deposit				MONEY,
			Withdrawal			MONEY,
			Bonus				MONEY,
			Rebate				MONEY,
			Turnover			MONEY,
			Winloss				MONEY,
			Revenue				MONEY,
			-- Fees
			P2PFee				MONEY,
			PlatFormFee			MONEY,
			OperationalFee		MONEY,
			DepositFee			MONEY,
			WithdrawalFee		MONEY,
			-- Calculation
			GrossWinloss		MONEY,
			NetWinloss			MONEY,
			ActivePlayer		INT,
			CommissionRate		FLOAT,
			Commission			MONEY,
			StraightCommission	MONEY,
			SubAffCommission	MONEY,
			IsMultiGroupProduct BIT
		)

		IF @FromDate <= @MaxCommDate
		BEGIN
			SELECT @tempFromDate	= @FromDate
			SELECT @tempToDate		= CASE WHEN @ToDate > @MaxCommDate THEN @MaxCommDate ELSE @ToDate END

			INSERT INTO #TempCommission
			(
				MonthDate,
				AffId,
				GroupId,
				ProductId,
				Deposit,
				Withdrawal,
				Bonus,
				Rebate,
				Turnover,
				Winloss,
				Revenue,
				P2PFee,
				PlatFormFee,
				OperationalFee,
				DepositFee,
				WithdrawalFee,
				GrossWinloss,
				NetWinloss,
				ActivePlayer,
				CommissionRate,
				Commission,
				StraightCommission,
				SubAffCommission,
				IsMultiGroupProduct
			)
			EXEC dbo.Aff_Commission_Calc
				@AffIds				= @AffIds,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= @ProductIds,
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 0,
				@GetRowTotalOnly	= 1
		END

		IF @ToDate > @MaxCommDate
		BEGIN
			SELECT @tempFromDate	= CASE WHEN @FromDate <= @MaxCommDate THEN DATEADD(DAY, 1, @MaxCommDate) ELSE @FromDate END
			SELECT @tempToDate		= @ToDate
			
			INSERT INTO #TempCommission
			(
				MonthDate,
				AffId,
				GroupId,
				ProductId,
				Deposit,
				Withdrawal,
				Bonus,
				Rebate,
				Turnover,
				Winloss,
				Revenue,
				P2PFee,
				PlatFormFee,
				OperationalFee,
				DepositFee,
				WithdrawalFee,
				GrossWinloss,
				NetWinloss,
				ActivePlayer,
				CommissionRate,
				Commission,
				StraightCommission,
				SubAffCommission,
				IsMultiGroupProduct
			)
			EXEC dbo.Aff_Commission_UnCalc
				@AffIds				= @AffIds,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= @ProductIds,
				@Currencies			= @Currencies,
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 0,
				@GetRowTotalOnly	= 1
		END

		-- Statistics
		CREATE TABLE #Statistics (MonthDate SMALLDATETIME, TotalClick INT, UniqueClick INT, Signup INT, FDM INT)

		DECLARE @ArchiveDate SMALLDATETIME
		SELECT	@ArchiveDate = MAX(Date) FROM dbo.ClickStatisticsSum (NOLOCK)
		SELECT  @ArchiveDate = ISNULL(@ArchiveDate, DATEADD(DAY, -1, @FromDate))

		IF @ToDate > @ArchiveDate
		BEGIN
			SELECT @tempFromDate = CASE WHEN @FromDate <= @ArchiveDate THEN DATEADD(DAY, 1, @ArchiveDate) ELSE @FromDate END
			SELECT @tempToDate	= DATEADD(DAY, 1, @ToDate)

			INSERT INTO #Statistics (MonthDate, TotalClick, UniqueClick)
			SELECT
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0)) AS MonthDate,
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT c.IP) AS UniqueClick
			FROM dbo.ClickStatistics c WITH (NOLOCK)
			WHERE c.AffId = @AffId
				AND c.Date >= @tempFromDate AND c.Date < @tempToDate
				AND c.Date > @ArchiveDate
			GROUP BY
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0))
		END

		IF @FromDate <= @ArchiveDate
		BEGIN
			SELECT @tempFromDate = @FromDate
			SELECT @tempToDate	= CASE WHEN @ToDate > @ArchiveDate THEN @ArchiveDate ELSE @ToDate END

			SELECT @tempToDate = DATEADD(DAY, 1, @tempToDate)
			
			INSERT INTO #Statistics (MonthDate, TotalClick, UniqueClick)
			SELECT MonthDate, SUM(TotalClick), COUNT(1) AS UniqueClick
			FROM
			(
				SELECT
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0)) AS MonthDate,
					c.IP,
					COUNT(1) AS TotalClick
				FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
				WHERE c.AffId = @AffId
					AND c.Date >= @tempFromDate AND c.Date < @tempToDate
					AND c.Date <= @ArchiveDate
				GROUP BY
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0)),
					c.IP
			) AS c
			GROUP BY MonthDate
		END
	END
	
	/*
		===== Paging ====
	*/
	BEGIN
		DECLARE @RowStart INT, @RowEnd INT

		IF @IsExportExcel = 0
		BEGIN
			SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1,
					@RowEnd = @RowStart + @PageSize - 1
		END
		ELSE
		BEGIN
			SELECT  @RowStart = 1,
					@RowEnd = @NRows
		END

		;WITH CTE_RowNum AS
		(
			SELECT md.MonthDate, ROW_NUMBER() OVER(ORDER BY
							CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN md.MonthDate END ASC,
							CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN md.MonthDate END DESC,
							CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN ISNULL(tc.Turnover, 0) END ASC,
							CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN ISNULL(tc.Turnover, 0) END DESC,
							CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN ISNULL(-tc.Winloss + tc.Revenue, 0) END ASC,
							CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN ISNULL(-tc.Winloss + tc.Revenue, 0) END DESC,
							CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN ISNULL(tc.Commission, 0) END ASC,
							CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN ISNULL(tc.Commission, 0) END DESC) AS RowIdx
			FROM @MonthDate md
				LEFT JOIN #TempCommission tc ON md.MonthDate = tc.MonthDate
		)
		UPDATE md
		SET md.RowIdx = rn.RowIdx
		FROM @MonthDate md
			INNER JOIN CTE_RowNum rn ON md.MonthDate = rn.MonthDate
	END

	DECLARE @tblAffStatistics TABLE (MonthDate SMALLDATETIME, AffWithdrawal MONEY, AffAdjustment MONEY, BFF MONEY)
	INSERT INTO @tblAffStatistics (MonthDate, AffWithdrawal, AffAdjustment, BFF)
	SELECT md.MonthDate, ISNULL(at.AffWithdrawal, 0), ISNULL(at.AffAdjustment, 0), ISNULL(at.BFF, 0)
	FROM @MonthDate md
		LEFT JOIN (
			SELECT
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, CASE WHEN at.TransDate < @FromDate THEN @FromDate ELSE at.TransDate END) + 1, 0)) AS MonthDate,
				SUM(CASE WHEN at.TransType = 202 AND at.TransDate >= @FromDate THEN ABS(at.Amount * e.Rate) ELSE 0 END) AS AffWithdrawal,
				SUM(CASE WHEN at.TransType = 203 AND at.TransDate >= @FromDate THEN at.Amount * e.Rate ELSE 0 END) AS AffAdjustment,
				SUM(at.Amount * e.Rate) AS BFF
			FROM dbo.AffTrans at WITH (NOLOCK)
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON at.AffCurrency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(at.TransDate, ISNULL(t.ExchangeId, at.AffCurrency), @BaseExchangeId) e
			WHERE at.AffId = @AffId
				AND at.TransDate < DATEADD(DAY, 1, @ToDate)
				AND at.Status IN ('Pending', 'Approved', 'Completed')
			GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, CASE WHEN at.TransDate < @FromDate THEN @FromDate ELSE at.TransDate END) + 1, 0))
		) AS at ON md.MonthDate = at.MonthDate

	UPDATE md1
	SET md1.BFF = ISNULL(md.BFF, 0)
	FROM @tblAffStatistics md1
		CROSS APPLY (SELECT SUM(md2.BFF) AS BFF FROM @tblAffStatistics md2 WHERE md2.MonthDate <= md1.MonthDate) AS md

	DECLARE @MemberStatistics TABLE (MonthDate DATETIME, Signup INT, FDM INT)
	
	INSERT INTO @MemberStatistics (MonthDate, Signup)
	SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, RegisteredDate) + 1, 0)), COUNT(1)
	FROM dbo.MemberInfo mi WITH (NOLOCK)
	WHERE mi.AffId = @AffId
		AND mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < DATEADD(DAY, 1, @ToDate)
	GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, RegisteredDate) + 1, 0))

	INSERT INTO @MemberStatistics (MonthDate, FDM)
	SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, FirstDepositDate) + 1, 0)), COUNT(1)
	FROM dbo.MemberInfo mi WITH (NOLOCK)
	WHERE mi.AffId = @AffId
		AND mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < DATEADD(DAY, 1, @ToDate)
	GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, FirstDepositDate) + 1, 0))

	DECLARE @tblSubAff TABLE (MonthDate SMALLDATETIME, NoOfSubAff INT)
	INSERT INTO @tblSubAff (MonthDate, NoOfSubAff)
	SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, ApprovedDate) + 1, 0)), COUNT(1)
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE ParentAffId = @AffId
		AND Status = 'Approved'
		AND IsClosed = 0
		AND ApprovedDate >= @FromDate AND ApprovedDate < DATEADD(DAY, 1, @ToDate)
	GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, ApprovedDate) + 1, 0))

	-- Return detail
	SELECT
		md.MonthDate,
		CASE
			WHEN md.MonthDate >= GETDATE() THEN 'Temporary'
			WHEN md.MonthDate > @MaxCommDate THEN 'Uncalculated'
			ELSE '' END AS Description,
		ISNULL(s.TotalClick, 0)					AS TotalClick,
		ISNULL(s.UniqueClick, 0)				AS UniqueClick,
		ISNULL(m.Signup, 0)						AS Signup,
		ISNULL(m.FDM, 0)						AS FDM,
		ISNULL(ts.NoOfSubAff, 0)				AS NoOfSubAff,
		ISNULL(tc.ActivePlayer, 0)				AS ActivePlayer,
		ISNULL(tc.Deposit, 0)					AS Deposit,
		ISNULL(tc.Withdrawal, 0)				AS Withdrawal,
		ISNULL(tc.Turnover, 0)					AS Turnover,
		ISNULL(-tc.Winloss + tc.Revenue, 0)		AS GGR,
		ISNULL(tc.Bonus, 0)						AS Bonus,
		ISNULL(tc.Rebate, 0)					AS Rebate,
		ISNULL(tc.PlatFormFee + tc.P2PFee, 0)	AS PlatFormFee,
		ISNULL(tc.OperationalFee, 0)			AS OperationalFee,
		ISNULL(tc.DepositFee, 0)				AS DepositFee,
		ISNULL(tc.WithdrawalFee, 0)				AS WithdrawalFee,
		ISNULL(tc.PlatFormFee + tc.P2PFee + tc.OperationalFee + tc.DepositFee + tc.WithdrawalFee, 0) AS TotalFee,
		ISNULL(tc.CommissionRate, 0)			AS CommissionRate,
		ISNULL(tc.IsMultiGroupProduct, 0)       AS IsMultiGroupProduct,
		ISNULL(tc.Commission, 0)				AS Earning,
		ISNULL(tc.StraightCommission, 0)		AS P2PEarning,
		ISNULL(tc.SubAffCommission, 0)			AS SubAffEarning,
		ISNULL(at.AffWithdrawal, 0)				AS AffWithdrawal,
		ISNULL(at.AffAdjustment, 0)				AS AffAdjustment,
		ISNULL(at.BFF, 0)						AS BFF
	FROM @MonthDate md
		LEFT JOIN #TempCommission tc ON md.MonthDate = tc.MonthDate
		OUTER APPLY (
			SELECT
				SUM(ISNULL(Signup, 0)) AS Signup,
				SUM(ISNULL(FDM, 0)) AS FDM
			FROM @MemberStatistics m
			WHERE md.MonthDate = m.MonthDate
		) m
		LEFT JOIN @tblSubAff ts ON md.MonthDate = ts.MonthDate
		CROSS APPLY (
			SELECT
				SUM(ISNULL(TotalClick, 0)) AS TotalClick,
				SUM(ISNULL(UniqueClick, 0)) AS UniqueClick
			FROM #Statistics s
			WHERE md.MonthDate = s.MonthDate
		) s
		CROSS APPLY (
			SELECT AffWithdrawal, AffAdjustment, BFF
			FROM @tblAffStatistics at
			WHERE md.MonthDate = at.MonthDate
		) at
	WHERE md.RowIdx BETWEEN @RowStart AND @RowEnd
	ORDER BY md.RowIdx

	-- Return total
	SELECT
		SUM(ISNULL(s.TotalClick, 0))				AS TotalClick,
		SUM(ISNULL(s.UniqueClick, 0))				AS UniqueClick,
		SUM(ISNULL(m.Signup, 0))					AS Signup,
		SUM(ISNULL(m.FDM, 0))						AS FDM,
		SUM(ISNULL(ts.NoOfSubAff, 0))				AS NoOfSubAff,
		SUM(ISNULL(tc.ActivePlayer, 0))				AS ActivePlayer,
		SUM(ISNULL(tc.Deposit, 0))					AS Deposit,
		SUM(ISNULL(tc.Withdrawal, 0))				AS Withdrawal,
		SUM(ISNULL(tc.Turnover, 0))					AS Turnover,
		SUM(ISNULL(-tc.Winloss + tc.Revenue, 0))	AS GGR,
		SUM(ISNULL(tc.Bonus, 0))					AS Bonus,
		SUM(ISNULL(tc.Rebate, 0))					AS Rebate,
		SUM(ISNULL(tc.PlatFormFee, 0) + ISNULL(tc.P2PFee, 0))	AS PlatFormFee,
		SUM(ISNULL(tc.OperationalFee, 0))			AS OperationalFee,
		SUM(ISNULL(tc.DepositFee, 0))				AS DepositFee,
		SUM(ISNULL(tc.WithdrawalFee, 0))			AS WithdrawalFee,
		SUM(ISNULL(tc.PlatFormFee, 0) + ISNULL(tc.P2PFee, 0) + ISNULL(tc.OperationalFee, 0) + ISNULL(tc.DepositFee, 0) + ISNULL(tc.WithdrawalFee, 0)) AS TotalFee,
		0											AS CommissionRate,
		CONVERT(BIT, MAX(CONVERT(TINYINT, ISNULL(tc.IsMultiGroupProduct, 0)))) AS IsMultiGroupProduct,
		SUM(ISNULL(tc.Commission, 0))				AS Earning,
		SUM(ISNULL(tc.StraightCommission, 0))		AS P2PEarning,
		SUM(ISNULL(tc.SubAffCommission, 0))			AS SubAffEarning,
		SUM(ISNULL(at.AffWithdrawal, 0))			AS AffWithdrawal,
		SUM(ISNULL(at.AffAdjustment, 0))			AS AffAdjustment,
		SUM(ISNULL(CASE WHEN md.MonthDate = @ToDate THEN at.BFF ELSE 0 END, 0)) AS BFF -- the last month by running total
	FROM @MonthDate md
		LEFT JOIN #TempCommission tc ON md.MonthDate = tc.MonthDate
		OUTER APPLY (
			SELECT
				SUM(ISNULL(Signup, 0)) AS Signup,
				SUM(ISNULL(FDM, 0)) AS FDM
			FROM @MemberStatistics m
			WHERE md.MonthDate = m.MonthDate
		) m
		LEFT JOIN @tblSubAff ts ON md.MonthDate = ts.MonthDate
		CROSS APPLY (
			SELECT
				SUM(ISNULL(TotalClick, 0)) AS TotalClick,
				SUM(ISNULL(UniqueClick, 0)) AS UniqueClick
			FROM #Statistics s
			WHERE md.MonthDate = s.MonthDate
		) s
		CROSS APPLY (
			SELECT AffWithdrawal, AffAdjustment, BFF
			FROM @tblAffStatistics at
			WHERE md.MonthDate = at.MonthDate
		) at

	DROP TABLE #TempCommission
	DROP TABLE #Statistics
END
GO