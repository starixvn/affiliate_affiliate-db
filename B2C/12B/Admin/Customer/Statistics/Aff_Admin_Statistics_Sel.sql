/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Statistics_Sel] 
	@AffId		INT,
	@MonthDate	SMALLDATETIME
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Customer - Statistics

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241225@Sally: Apply QM Turnover [RedmineID: #212201]
		- 20250402@Sophia: Fix Unique Click count IP by range from - to [RedmineID: #222777]
		- 20250415@Sally: Change the data retrieval method for Deposit [RedmineID: #224116]
		- 20250416@Sophia: Get report by timezone [RedmineID: #222352]
		- 20250421@Sally: Add FDM_TotalDepositByMonth column [RedmineID: #224709]
		- 20250516@Sally: Get correct Date for FDM's Total Deposit [RedmineID: #227685]
		- 20250722@Sophia: Implement hybrid approach using rptMemberDaily for historical data (up to month before last month) and live DepositInfo for last month and current month [RedmineID: #233096]
		
	Notes:
	  - ClickStatistics.Date contains Date only, in GMT-4
	  - ClickStatistics.UpdatedTime is DateTime in GMT-4
	  - MemberInfo dates are DateTime in GMT+8
	  - rptMemberDaily.WinlostDate is in GMT+8
	  - bodb_12B.dbo.DepositInfo.CreateTime is in GMT+0
	  - bodb_12B.dbo.DepositInfo.WinlostDate is indexed (Date of CreateTime)	 
	  - Hybrid approach: rptMemberDaily for historical data (up to month before last month), DepositInfo for last month and current month
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SignupsByMonth				INT,
			@SignupsTotal				INT,
			@FDMByMonth					INT,
			@FDMTotal					INT,
			@ActivePlayersByMonth		INT,
			@QualifiedMembersByMonth	INT,
			@DepositByMonth				MONEY,
			@DepositTotal				MONEY,
			@TurnoverByMonth			MONEY,
			@TurnoverTotal				MONEY,
			@GGRByMonth					MONEY,
			@GGRTotal					MONEY,
			@UniqueClickPCByMonth		INT,
			@TotalClickPCByMonth		INT,
			@UniqueClickMobileByMonth	INT,
			@TotalClickMobileByMonth	INT,
			@NoOfSubAffByMonth			INT,
			@NoOfSubAffTotal			INT,
			@TotalFDMAmountByMonth		MONEY,
			@TotalFDMAmount				MONEY,
			@FDM_TotalDepositByMonth	MONEY

	DECLARE @FromBeginMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME, @CurrentDate SMALLDATETIME
	SELECT	@FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT	@ToNextMonth	= DATEADD(MONTH, 1, @FromBeginMonth)
	SELECT  @CurrentDate    = CONVERT(DATE, DATEADD(HOUR, 12, GETDATE())) -- GMT-4 TO GMT+8
	SELECT  @MonthDate      = EOMONTH(@MonthDate)

	-- Calculate last month start for hybrid approach (convert server GMT-4 to GMT+8)
	DECLARE @LastMonthStart SMALLDATETIME
	SELECT @LastMonthStart = DATEADD(MONTH, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(HOUR, 12, GETDATE())), 0))  -- Start of last month

	-- Pre-calculate DATE variables for WinlostDate index optimization
	DECLARE @WinlostDateFrom DATE, @WinlostDateTo DATE
	SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @FromBeginMonth))
	SELECT @WinlostDateTo = DATEADD(DAY, 1, CONVERT(DATE, @ToNextMonth))
	
	-- member statistics
	BEGIN
		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @IsSumAll BIT, @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(MAX), @AffId)

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

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
			NetTurnover			MONEY,
			ActivePlayer		INT,
			QualifiedMember		INT,
			CommissionRate		FLOAT,
			Commission			MONEY,
			StraightCommission	MONEY,
			SubAffCommission	MONEY,
			IsMultiGroupProduct BIT
		)

		-- Uncalculated Months
		BEGIN
			SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
					@tempToDate		= @CurrentDate

			SELECT  @IsSumAll = CASE WHEN @MonthDate >= @tempFromDate THEN 0 ELSE 1 END

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
				NetTurnover,
				ActivePlayer,
				QualifiedMember,
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
				@ProductIds			= '0',
				@IsSumAll			= @IsSumAll,
				@GetRowTotalOnly	= 1
		END

		-- Calculated Months
		BEGIN
			SELECT	@tempFromDate	= dbo.Aff_f_GetMinReportDate(@AffId),
					@tempToDate		= @MaxCommDate

			SELECT  @IsSumAll = CASE WHEN @MonthDate <= @tempToDate THEN 0 ELSE 1 END

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
				NetTurnover,
				ActivePlayer,
				QualifiedMember,
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
				@ProductIds			= '0',
				@IsSumAll			= @IsSumAll,
				@GetRowTotalOnly	= 1
		END
	END

	SELECT
		@ActivePlayersByMonth		= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(ActivePlayer, 0) ELSE 0 END),
		@QualifiedMembersByMonth	= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(QualifiedMember, 0) ELSE 0 END),
		@TurnoverByMonth			= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(Turnover, 0) ELSE 0 END),
		@GGRByMonth					= SUM(CASE WHEN MonthDate = @MonthDate THEN -ISNULL(Winloss, 0) + ISNULL(Revenue, 0) ELSE 0 END),
		@TurnoverTotal				= SUM(ISNULL(Turnover, 0)),
		@GGRTotal					= SUM(-ISNULL(Winloss, 0) + ISNULL(Revenue, 0))
	FROM #TempCommission

	DROP TABLE #TempCommission

	-- Hybrid approach: Use rptMemberDaily for historical data (up to month before last month) and DepositInfo for last month and current month
	;WITH CTE_HistoricalDeposit AS(
		-- Historical data from rptMemberDaily (up to month before last month)
		SELECT m.AffId
			,m.Currency
			,EOMONTH(m.WinlostDate) AS MonthDate
			,SUM(ISNULL(m.Deposit, 0)) AS Deposit
		FROM dbo.rptMemberDaily m WITH(NOLOCK)
		WHERE m.AffId = @AffId
			AND m.WinlostDate < @LastMonthStart  -- Historical data only (before last month)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
				WHERE mr.CustId = m.custid AND m.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
			)
		GROUP BY m.AffId, m.Currency, EOMONTH(m.WinlostDate)
	),
	CTE_RecentDeposit AS(
		-- Recent data from live DepositInfo (last month and current month)
		SELECT mi.AffId
			,mi.Currency
			,EOMONTH(DATEADD(HOUR, 8, d.CreateTime)) AS MonthDate  -- Convert GMT+0 to GMT+8
			,SUM(d.Amount) AS Deposit
		FROM bodb_12B.dbo.DepositInfo d WITH(NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH(NOLOCK) ON d.CustId = mi.CustId
		WHERE mi.AffId = @AffId
			AND d.Status = 3  -- Approved deposits only
			AND d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index first (covers full date range)
			AND DATEADD(HOUR, 8, d.CreateTime) >= @LastMonthStart  -- Last month and current month data (GMT+8)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
				WHERE mr.CustId = d.CustId 
				AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate  -- Convert to GMT+8 for comparison
			)
		GROUP BY mi.AffId, mi.Currency, EOMONTH(DATEADD(HOUR, 8, d.CreateTime))  -- Convert GMT+0 to GMT+8
	),
	CTE_CombinedDeposit AS(
		-- Combine historical and recent data
		SELECT AffId, Currency, MonthDate, Deposit FROM CTE_HistoricalDeposit
		UNION ALL
		SELECT AffId, Currency, MonthDate, Deposit FROM CTE_RecentDeposit
	)
	SELECT @DepositByMonth = SUM(CASE WHEN MonthDate = @MonthDate THEN r.Deposit * e.Rate ELSE 0 END)
		,@DepositTotal = SUM(r.Deposit * e.Rate)
	FROM CTE_CombinedDeposit r				
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.MonthDate, ISNULL(t.ExchangeId, r.Currency), 0) e

	SELECT
		@SignupsTotal	= COUNT(1),
		@FDMTotal		= COUNT(FirstDepositDate),
		@SignupsByMonth = COUNT(CASE WHEN RegisteredDate >= @FromBeginMonth AND RegisteredDate < @ToNextMonth THEN 1 ELSE NULL END),		
		@TotalFDMAmount	= SUM(ISNULL(FirstDepositAmount, 0) * ISNULL(e.Rate, 0))
	FROM dbo.MemberInfo r WITH (NOLOCK)
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
		OUTER APPLY dbo.Aff_f_ExchangeRate_Sel(@FromBeginMonth, ISNULL(t.ExchangeId, r.Currency), 0) e
	WHERE AffId = @AffId

	-- Calculate FDM_TotalDepositByMonth using hybrid approach
	SELECT 
		@FDMByMonth	 			 = COUNT(DISTINCT mi.CustId),
		@TotalFDMAmountByMonth 	 = SUM(ISNULL(FirstDepositAmount, 0) * ISNULL(ex.Rate, 0))
	FROM dbo.MemberInfo mi WITH (NOLOCK)
		LEFT JOIN dbo.TpExchange te WITH (NOLOCK) ON mi.Currency = te.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@FromBeginMonth, ISNULL(te.ExchangeId, mi.Currency), 0) ex
	WHERE mi.AffId = @AffId
		AND mi.FirstDepositDate >= @FromBeginMonth 
		AND mi.FirstDepositDate < @ToNextMonth

	-- Calculate @FDM_TotalDepositByMonth using conditional approach based on month comparison
	IF @FromBeginMonth < @LastMonthStart
	BEGIN
		-- Historical data from rptMemberDaily (for months before last month)
		SELECT @FDM_TotalDepositByMonth = SUM(ISNULL(r.Deposit, 0) * ex.Rate)
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			INNER JOIN dbo.rptMemberDaily r WITH (NOLOCK) ON r.CustId = mi.CustId
			LEFT JOIN dbo.TpExchange te WITH (NOLOCK) ON mi.Currency = te.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@FromBeginMonth, ISNULL(te.ExchangeId, mi.Currency), 0) ex
		WHERE mi.AffId = @AffId
			AND mi.FirstDepositDate >= @FromBeginMonth 
			AND mi.FirstDepositDate < @ToNextMonth
			AND mi.FirstDepositDate < @LastMonthStart  -- Only FDM from before last month
			AND r.WinlostDate BETWEEN CAST(mi.FirstDepositDate AS DATE) AND EOMONTH(mi.FirstDepositDate)
	END
	ELSE
	BEGIN
		-- Recent data from live DepositInfo (for last month and current month)
		SELECT @FDM_TotalDepositByMonth = SUM(ISNULL(d.Amount, 0) * ex.Rate)
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			INNER JOIN bodb_12B.dbo.DepositInfo d WITH(NOLOCK) ON d.CustId = mi.CustId
			LEFT JOIN dbo.TpExchange te WITH (NOLOCK) ON mi.Currency = te.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@FromBeginMonth, ISNULL(te.ExchangeId, mi.Currency), 0) ex
		WHERE mi.AffId = @AffId
			AND mi.FirstDepositDate >= @FromBeginMonth 
			AND mi.FirstDepositDate < @ToNextMonth
			AND mi.FirstDepositDate >= @LastMonthStart  -- Only FDM from last month onwards
			AND d.Status = 3  -- Approved deposits only
			AND d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index first (covers full date range)
			AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN CAST(mi.FirstDepositDate AS DATE) AND EOMONTH(mi.FirstDepositDate)
	END

	DECLARE @ArchiveDate SMALLDATETIME
	SELECT @ArchiveDate = dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics') -- GMT-4, Date only
	
	-- Convert month range from GMT+8 to GMT-4 for Click statistics date comparison
	DECLARE @FromBeginMonth_GMT4 DATETIME, @ToNextMonth_GMT4 DATETIME
	SELECT @FromBeginMonth_GMT4 = DATEADD(HOUR, -12, CAST(@FromBeginMonth AS DATETIME)), -- GMT+8 to GMT-4
	       @ToNextMonth_GMT4 = DATEADD(HOUR, -12, CAST(@ToNextMonth AS DATETIME)) -- GMT+8 to GMT-4

	-- Initialize click counters
	SELECT @TotalClickPCByMonth = 0, @UniqueClickPCByMonth = 0,
	       @TotalClickMobileByMonth = 0, @UniqueClickMobileByMonth = 0
	
	-- Declare temp variables outside the conditional blocks
	DECLARE @TmpFromDate DATE, @TmpToDate DATE

	-- Get clicks from current table if applicable
	IF CONVERT(DATE, @ToNextMonth_GMT4) > @ArchiveDate
	BEGIN 
		SELECT @TmpFromDate = CASE WHEN CONVERT(DATE, @FromBeginMonth_GMT4) > @ArchiveDate 
		                         THEN CONVERT(DATE, @FromBeginMonth_GMT4)
		                         ELSE DATEADD(Day, 1, @ArchiveDate) END,
		       @TmpToDate = DATEADD(Day, 1, CONVERT(DATE, @ToNextMonth_GMT4))

		;WITH CTE_Device AS (
			SELECT 
				ISNULL(DeviceType, 0) AS DeviceType,
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT IP) AS UniqueClick
			FROM dbo.ClickStatistics WITH (NOLOCK)
			WHERE AffId = @AffId
				AND [Date] >= @TmpFromDate AND [Date] < @TmpToDate
				AND UpdatedTime >= @FromBeginMonth_GMT4 AND UpdatedTime < @ToNextMonth_GMT4
			GROUP BY ISNULL(DeviceType, 0)
		)
		SELECT
			@TotalClickPCByMonth = @TotalClickPCByMonth + ISNULL(SUM(CASE WHEN DeviceType = 0 THEN TotalClick ELSE 0 END), 0),
			@UniqueClickPCByMonth = @UniqueClickPCByMonth + ISNULL(SUM(CASE WHEN DeviceType = 0 THEN UniqueClick ELSE 0 END), 0),
			@TotalClickMobileByMonth = @TotalClickMobileByMonth + ISNULL(SUM(CASE WHEN DeviceType = 1 THEN TotalClick ELSE 0 END), 0),
			@UniqueClickMobileByMonth = @UniqueClickMobileByMonth + ISNULL(SUM(CASE WHEN DeviceType = 1 THEN UniqueClick ELSE 0 END), 0)
		FROM CTE_Device
	END
	
	-- Get clicks from archived table if applicable
	IF CONVERT(DATE, @FromBeginMonth_GMT4) <= @ArchiveDate		
	BEGIN
		SELECT @TmpFromDate = CONVERT(DATE, @FromBeginMonth_GMT4), 
		       @TmpToDate = CASE WHEN CONVERT(DATE, @ToNextMonth_GMT4) > @ArchiveDate 
		                       THEN DATEADD(Day, 1, @ArchiveDate)
		                       ELSE DATEADD(DAY, 1, CONVERT(DATE, @ToNextMonth_GMT4)) END

		;WITH CTE_Device AS (
			SELECT 
				ISNULL(DeviceType, 0) AS DeviceType,
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT IP) AS UniqueClick
			FROM dbo.ClickStatistics_bk WITH (NOLOCK)
			WHERE AffId = @AffId
				AND [Date] >= @TmpFromDate AND [Date] < @TmpToDate
				AND UpdatedTime >= @FromBeginMonth_GMT4 AND UpdatedTime < @ToNextMonth_GMT4
			GROUP BY ISNULL(DeviceType, 0)
		)
		SELECT
			@TotalClickPCByMonth = @TotalClickPCByMonth + ISNULL(SUM(CASE WHEN DeviceType = 0 THEN TotalClick ELSE 0 END), 0),
			@UniqueClickPCByMonth = @UniqueClickPCByMonth + ISNULL(SUM(CASE WHEN DeviceType = 0 THEN UniqueClick ELSE 0 END), 0),
			@TotalClickMobileByMonth = @TotalClickMobileByMonth + ISNULL(SUM(CASE WHEN DeviceType = 1 THEN TotalClick ELSE 0 END), 0),
			@UniqueClickMobileByMonth = @UniqueClickMobileByMonth + ISNULL(SUM(CASE WHEN DeviceType = 1 THEN UniqueClick ELSE 0 END), 0)
		FROM CTE_Device
	END
	
	SELECT
		@NoOfSubAffTotal	= COUNT(1),
		@NoOfSubAffByMonth	= COUNT(CASE WHEN ApprovedDate >= @FromBeginMonth AND ApprovedDate < @ToNextMonth THEN 1 ELSE NULL END)
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE ParentAffId = @AffId
		AND Status = 'Approved'
		AND IsClosed = 0

	-- Return data
	SELECT
		ISNULL(@SignupsByMonth, 0)				AS SignupsByMonth,
		ISNULL(@SignupsTotal, 0)				AS SignupsTotal,
		ISNULL(@FDMByMonth, 0)					AS FDMByMonth,
		ISNULL(@FDMTotal, 0)					AS FDMTotal,
		ISNULL(@ActivePlayersByMonth, 0)		AS ActivePlayersByMonth,
		ISNULL(@QualifiedMembersByMonth, 0)		AS QualifiedMembersByMonth,
		ISNULL(@DepositByMonth, 0)				AS DepositByMonth,
		ISNULL(@DepositTotal, 0)				AS DepositTotal,
		ISNULL(@TurnoverByMonth, 0)				AS TurnoverByMonth,
		ISNULL(@TurnoverTotal, 0)				AS TurnoverTotal,
		ISNULL(@GGRByMonth, 0)					AS GGRByMonth,
		ISNULL(@GGRTotal, 0)					AS GGRTotal,
		ISNULL(@UniqueClickPCByMonth, 0)		AS UniqueClickPCByMonth,
		ISNULL(@TotalClickPCByMonth, 0)			AS TotalClickPCByMonth,
		ISNULL(@TotalClickMobileByMonth, 0)		AS TotalClickMobileByMonth,
		ISNULL(@UniqueClickMobileByMonth, 0)	AS UniqueClickMobileByMonth,
		ISNULL(@NoOfSubAffByMonth, 0)			AS NoOfSubAffByMonth,
		ISNULL(@NoOfSubAffTotal, 0)				AS NoOfSubAffTotal,
		ISNULL(@TotalFDMAmount, 0)				AS TotalFDMAmount,
		ISNULL(@TotalFDMAmountByMonth, 0)		AS TotalFDMAmountByMonth,
		ISNULL(@FDM_TotalDepositByMonth, 0)		AS FDM_TotalDepositByMonth
END
GO