/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateReport_Detail_Sel]
	@Username			NVARCHAR(50)
	,@FromDate			SMALLDATETIME
	,@ToDate			SMALLDATETIME
	,@IsGetAll			BIT = 0
	,@ProductIds		VARCHAR(MAX) = '0'
	,@Currencies		VARCHAR(MAX) = ''
	,@BaseCurrency		INT = 0
	,@SortType			TINYINT = 1
	,@SortDirectionType	BIT = 0
	,@EarningType		VARCHAR(50) = 'all'
	,@IsExportExcel		BIT = 0
	,@PageIndex			INT = 1
	,@PageSize			INT = 50
	,@NRows				INT = 0 OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Report - Affiliate Report - Detail Affiliate

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241225@Sally: Apply QM Turnover [RedmineID: #212201]
		- 20250326@Sally: Add new column FDAM Amount [RedmineID: #220316]
		- 20250416@Sally: Change the data retrieval method for Deposit [RedmineID: #224116]
        - 20250417@Sally: Add Revenue Group column [RedmineID: #224286]
		- 20250418@Sally: Enhance get BBF by TimeZone [RedmineID: #222352]
        - 20250421@Sally: Add FDM_TotalDeposit column [RedmineID: #224709]
		- 20250506@Sophia: Fix IP handling in UniqueClick [RedmineID: #225820] 
		- 20250516@Sally: Get correct Date for FDM's Total Deposit [RedmineID: #227685]
		- 20250723@Sophia: Implement hybrid approach using rptMemberDaily for historical data and DepositInfo for recent data based on commission date boundary [RedmineID: #239737]
		- 20251022@Sophia: Add IsExcluded = 0 condition to filter excluded clicks [RedmineID: #241768]

	Param's Explanation:
		- @SortType: 1: Month, 2: Turnover, 3: GGR, 4: Earning (Commission)
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
		- @ProductIds: list of products
		- @BaseCurrency : Currency of B2C
		- @Currencies : Currency of B2C, 72: represent for USD( currency 72, 3)
		- @EarningTypes:
			. Winloss : Earning By Winloss 
			. Turnover: Earning By Turnover
			. all	  : All
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffId INT		
		,@TimeZone				SMALLINT
		,@FromDateTimeGMT0		DATETIME
		,@ToDateTimeGMT0		DATETIME
		,@FromDate_Local		DATETIME
		,@ToDate_Local			DATETIME

	SELECT  @Username = ISNULL(TRIM(@Username), '')
	SELECT  @TimeZone = CONVERT(SMALLINT, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'TimeZone'
	SELECT  @AffId = AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE Username = @Username AND Status = 'Approved'

	IF @AffId IS NULL
		RETURN

	DECLARE @MinReportDate SMALLDATETIME, @EndOfCurrentMonth SMALLDATETIME
	SELECT  @MinReportDate		= dbo.Aff_f_GetMinReportDate(@AffId)
	SELECT  @EndOfCurrentMonth	= EOMONTH(GETDATE())

	IF @IsGetAll = 0
	BEGIN
		IF @FromDate IS NULL OR @ToDate IS NULL
			RETURN

		SELECT  @FromDate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0) -- Begin Of Month
		SELECT  @ToDate		= EOMONTH(@ToDate) -- End Of Month

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

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'
	
	-- Calculate commission date boundary for data separation (MaxCommDate + 1 day)
	DECLARE @CommissionBoundary SMALLDATETIME
	SELECT @CommissionBoundary = DATEADD(DAY, 1, @MaxCommDate)

	-- Pre-calculate DATE variables for WinlostDate index optimization
	DECLARE @WinlostDateFrom DATE, @WinlostDateTo DATE
	SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @FromDate))
	SELECT @WinlostDateTo = DATEADD(DAY, 1, CONVERT(DATE, @ToDate))


	SELECT @NRows = DATEDIFF(MONTH, @FromDate, @ToDate) + 1

	IF @NRows <= 0
		RETURN

	-- Data on GMT+0 --> convert timezone
	SELECT @FromDateTimeGMT0	= DATEADD(HOUR, -@TimeZone, CONVERT(DATETIME, @FromDate))
		,@ToDateTimeGMT0		= DATEADD(HOUR, -@TimeZone, CONVERT(DATETIME, @ToDate))	

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME, RowIdx INT, EarningBy VARCHAR(50), CommGroupName NVARCHAR(100))
	;WITH CTE_MonthDate AS
	(
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate) + 1, 0)) AS MonthDate
		UNION ALL
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
		FROM CTE_MonthDate
		WHERE MonthDate < @ToDate
	)
	INSERT INTO @MonthDate (MonthDate, EarningBy, CommGroupName)
	SELECT m.MonthDate, af.GroupTypeBy, af.GroupName
	FROM CTE_MonthDate m
		INNER JOIN dbo.Aff_f_AffGroupInfo_Sel(@FromDate, @ToDate, CONVERT(VARCHAR(20), @AffId)) af ON af.MonthDate= m.MonthDate
	WHERE (@EarningType ='all' OR GroupTypeBy = @EarningType)
	OPTION (MAXRECURSION 0)

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
			NetTurnover			MONEY,
			ActivePlayer		INT,
			QualifiedMember     INT,
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
				@ProductIds			= @ProductIds,
				@Currencies			= @Currencies,
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 0,
				@GetRowTotalOnly	= 1;
		END

		-- Statistics
		CREATE TABLE #IP (MonthDate SMALLDATETIME, TotalClick INT, IP VARCHAR(25))
		CREATE TABLE #Statistics (MonthDate SMALLDATETIME, TotalClick INT, UniqueClick INT, Signup INT, FDM INT)

		DECLARE @ArchiveDate SMALLDATETIME;
		SELECT @ArchiveDate = dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics'); -- GMT-4

		SELECT @FromDate_Local = DATEADD(HOUR, -12, CAST(@FromDate AS DATETIME)), -- GMT+8 to GMT-4
			@ToDate_Local = DATEADD(HOUR, -12, DATEADD(DAY, 1, CAST(@ToDate AS DATETIME))); -- GMT+8 to GMT-4

		IF  CONVERT(DATE, @ToDate_Local) > @ArchiveDate
		BEGIN
			SELECT @tempFromDate = CASE 
										WHEN @FromDate_Local > @ArchiveDate THEN CONVERT(DATE, @FromDate_Local) 
										ELSE DATEADD(DAY, 1, @ArchiveDate) 
								   END
				,@tempToDate = DATEADD(DAY, 1, CONVERT(DATE, @ToDate_Local))

			INSERT INTO #IP (MonthDate, TotalClick, IP)
			SELECT
				EOMONTH(DATEADD(HOUR, 12, c.UpdatedTime)) AS MonthDate, -- GMT-4 to GMT+8
				COUNT(1) AS TotalClick,
				c.IP 
			FROM dbo.ClickStatistics c WITH (NOLOCK)
			WHERE [Date] >= @tempFromDate
				AND [Date] < @tempToDate
				AND UpdatedTime >= @FromDate_Local -- GMT-4
				AND UpdatedTime < @ToDate_Local -- GMT-4
				AND AffId = @AffID
				AND c.IsExcluded = 0
			GROUP BY
				EOMONTH(DATEADD(HOUR, 12, c.UpdatedTime)), c.IP
		END

		IF CONVERT(DATE, @FromDate_Local) <= @ArchiveDate
		BEGIN
			 SELECT @tempFromDate = CONVERT(DATE, @FromDate_Local)
				,@tempToDate = CASE 
									WHEN @ToDate_Local <= @ArchiveDate THEN DATEADD(DAY, 1, CONVERT(DATE, @ToDate_Local)) 
									ELSE DATEADD(DAY, 1, @ArchiveDate) 
							   END
			
			INSERT INTO #IP (MonthDate, TotalClick, IP)
			SELECT
				EOMONTH(DATEADD(HOUR, 12, c.UpdatedTime)) AS MonthDate, -- GMT-4 to GMT+8
				COUNT(1) AS TotalClick,
				c.IP 
			FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
			WHERE [Date] >= @tempFromDate
				AND [Date] < @tempToDate
				AND UpdatedTime >= @FromDate_Local -- GMT-4
				AND UpdatedTime < @ToDate_Local -- GMT-4
				AND AffId = @AffID
				AND c.IsExcluded = 0
			GROUP BY
				EOMONTH(DATEADD(HOUR, 12, c.UpdatedTime)), c.IP
		 END	

		 INSERT INTO #Statistics (MonthDate, TotalClick, UniqueClick )
		 SELECT MonthDate, SUM(TotalClick) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		 FROM #IP
		 GROUP BY MonthDate 

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
				EOMONTH(CASE WHEN at.WinlostDate < @FromDate THEN @FromDate ELSE at.WinlostDate END) AS MonthDate,
				SUM(CASE WHEN at.TransType = 202 AND at.WinlostDate >= @FromDate AND at.WinlostDate < DATEADD(DAY, 1, @ToDate) THEN ABS(at.Amount * e.Rate) ELSE 0 END) AS AffWithdrawal,
				SUM(CASE WHEN at.TransType = 203 AND at.WinlostDate >= @FromDate AND at.WinlostDate < DATEADD(DAY, 1, @ToDate) THEN at.Amount * e.Rate ELSE 0 END) AS AffAdjustment,
				SUM(at.Amount * e.Rate) AS BFF
			FROM dbo.AffTrans at WITH (NOLOCK)
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON at.AffCurrency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(at.WinlostDate, ISNULL(t.ExchangeId, at.AffCurrency), @BaseExchangeId) e
			WHERE at.AffId = @AffId
				AND at.WinlostDate < DATEADD(DAY, 1, @ToDate)
				AND at.Status IN ('Pending', 'Approved', 'Completed')
			GROUP BY EOMONTH(CASE WHEN at.WinlostDate < @FromDate THEN @FromDate ELSE at.WinlostDate END)
		) AS at ON md.MonthDate = at.MonthDate

	UPDATE md1
	SET md1.BFF = ISNULL(md.BFF, 0)
	FROM @tblAffStatistics md1
		CROSS APPLY (SELECT SUM(md2.BFF) AS BFF FROM @tblAffStatistics md2 WHERE md2.MonthDate <= md1.MonthDate) AS md

	DECLARE @MemberStatistics TABLE (MonthDate DATETIME, Signup INT, FDM INT, FDM_Amount MONEY, FDM_TotalDeposit MONEY)
	
	-- Get Signup data
	;WITH CTE_Signup AS (
		SELECT EOMONTH(mi.RegisteredDate) AS MonthDate,
			COUNT(1) AS Signup
		FROM dbo.MemberInfo mi WITH (NOLOCK)
		WHERE mi.AffId = @AffId
			AND mi.RegisteredDate >= @FromDate 
			AND mi.RegisteredDate < DATEADD(DAY, 1, @ToDate)
		GROUP BY EOMONTH(mi.RegisteredDate)
	),
	-- Get FDM count and FirstDepositAmount with exchange rate conversion
	CTE_FDM_Basic AS (
		SELECT 
			fd.MonthDate,
			SUM(fd.FDM) AS FDM,
			SUM(fd.FDM_Amount * er.Rate) AS FDM_Amount
		FROM (
			SELECT 
				EOMONTH(mi.FirstDepositDate) AS MonthDate,
				mi.Currency,
				COUNT(DISTINCT mi.CustId) AS FDM,
				SUM(ISNULL(mi.FirstDepositAmount, 0)) AS FDM_Amount
			FROM dbo.MemberInfo mi WITH (NOLOCK)
			WHERE mi.AffId = @AffId
				AND mi.FirstDepositDate >= @FromDate 
				AND mi.FirstDepositDate < DATEADD(DAY, 1, @ToDate)
			GROUP BY EOMONTH(mi.FirstDepositDate), mi.Currency
		) fd
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON fd.Currency = t.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(fd.MonthDate, ISNULL(t.ExchangeId, fd.Currency), @BaseExchangeId) er
		GROUP BY fd.MonthDate
	),
	-- Historical deposit data (FirstDepositDate < @CommissionBoundary) - use rptMemberDaily
	CTE_FDM_Historical AS (
		SELECT 
			EOMONTH(mi.FirstDepositDate) AS MonthDate,
			mi.Currency,
			SUM(ISNULL(r.Deposit, 0)) AS FDM_TotalDeposit
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			OUTER APPLY (
				SELECT 
					SUM(r.Deposit) AS Deposit
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
				WHERE r.CustId = mi.CustId 
					AND r.WinlostDate BETWEEN CAST(mi.FirstDepositDate AS DATE) AND EOMONTH(mi.FirstDepositDate)
			) r
		WHERE mi.AffId = @AffId
			AND mi.FirstDepositDate >= @FromDate 
			AND mi.FirstDepositDate < DATEADD(DAY, 1, @ToDate)
			AND mi.FirstDepositDate < @CommissionBoundary  -- Historical data only (before commission boundary)
		GROUP BY EOMONTH(mi.FirstDepositDate), mi.Currency
	),
	-- Recent deposit data (FirstDepositDate >= @CommissionBoundary) - use DepositInfo
	CTE_FDM_Recent AS (
		SELECT 
			EOMONTH(mi.FirstDepositDate) AS MonthDate,
			mi.Currency,
			SUM(ISNULL(d.ActualDeposit,0) * 1.0 / CASE WHEN e.Code  IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) AS FDM_TotalDeposit
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			INNER JOIN bodb_12B.dbo.DepositInfo d WITH (NOLOCK) ON d.CustId = mi.CustId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
			LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, mi.Currency) = e.ExchangeId
		WHERE mi.AffId = @AffId
			AND mi.FirstDepositDate >= @FromDate 
			AND mi.FirstDepositDate < DATEADD(DAY, 1, @ToDate)
			AND mi.FirstDepositDate >= @CommissionBoundary  -- Recent data only (after commission boundary)
			AND d.Status = 3  -- Approved deposits only
			AND d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index first
			AND CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)) >= CAST(mi.FirstDepositDate AS DATE) 
			AND CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)) < DATEADD(Day, 1, EOMONTH(mi.FirstDepositDate))  -- Convert GMT+0 to GMT+8
		GROUP BY EOMONTH(mi.FirstDepositDate), mi.Currency
	),
	CTE_FDM_Combined AS (
		-- Combine deposit data with exchange rate conversion (FDM_TotalDeposit only)
		SELECT 
			MonthDate,
			SUM(FDM_TotalDeposit * er.Rate) AS FDM_TotalDeposit
		FROM (
			SELECT MonthDate, Currency, FDM_TotalDeposit FROM CTE_FDM_Historical
			UNION ALL
			SELECT MonthDate, Currency, FDM_TotalDeposit FROM CTE_FDM_Recent
		) fdep
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON fdep.Currency = t.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(fdep.MonthDate, ISNULL(t.ExchangeId, fdep.Currency), @BaseExchangeId) er
		GROUP BY MonthDate
	)
	-- Insert data into @MemberStatistics
	INSERT INTO @MemberStatistics (MonthDate, Signup, FDM, FDM_Amount, FDM_TotalDeposit)
	SELECT MonthDate, SUM(Signup) AS Signup, SUM(FDM) AS FDM, SUM(FDM_Amount) AS FDM_Amount, SUM(FDM_TotalDeposit) AS FDM_TotalDeposit
	FROM (
		SELECT MonthDate, Signup, 0 AS FDM, 0 AS FDM_Amount, 0 AS FDM_TotalDeposit
		FROM CTE_Signup
		UNION ALL
		SELECT MonthDate, 0 AS Signup, FDM, FDM_Amount, 0 AS FDM_TotalDeposit
		FROM CTE_FDM_Basic
		UNION ALL
		SELECT MonthDate, 0 AS Signup, 0 AS FDM, 0 AS FDM_Amount, FDM_TotalDeposit
		FROM CTE_FDM_Combined
	) Combined
	GROUP BY MonthDate




	DECLARE @tblSubAff TABLE (MonthDate SMALLDATETIME, NoOfSubAff INT)
	INSERT INTO @tblSubAff (MonthDate, NoOfSubAff)
	SELECT EOMONTH(ApprovedDate), COUNT(1)
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE ParentAffId = @AffId
		AND Status = 'Approved'
		AND IsClosed = 0
		AND ApprovedDate >= @FromDate AND ApprovedDate < DATEADD(DAY, 1, @ToDate)
	GROUP BY EOMONTH(ApprovedDate)

	-- Total Deposit
	DECLARE @TotalDeposit TABLE(MonthDate SMALLDATETIME, TotalDeposit BIGINT, TotalDepositAmount MONEY, TotalWithdrawalAmount MONEY)	
	;WITH CTE_DepositInfo AS (
		-- DepositInfo data (counts and recent amounts)
		SELECT CONVERT(DATE, EOMONTH(DATEADD(HOUR, 8, d.CreateTime))) AS MonthDate
			,mi.Currency
			,COUNT(1) AS TotalDeposit
			,SUM(CASE 
				WHEN DATEADD(HOUR, 8, d.CreateTime) >= @CommissionBoundary 
				THEN (ISNULL(d.ActualDeposit,0) * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END)
				ELSE 0 
			END) AS TotalDepositAmount
			,0 AS TotalWithdrawalAmount
		FROM bodb_12B.dbo.DepositInfo d WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.CustId = mi.CustId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
			LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, mi.Currency) = e.ExchangeId
		WHERE d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index first
			AND d.Status = 3 -- Approved
			AND CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)) >= @FromDate
			AND CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)) < DATEADD(DAY, 1, @ToDate)  -- Convert GMT+0 to GMT+8
			AND mi.AffId = @AffId
			AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
					WHERE mr.CustId = d.custid AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate
				)
		GROUP BY CONVERT(DATE, EOMONTH(DATEADD(HOUR, 8, d.CreateTime))), mi.Currency
	),
	CTE_HistoricalData AS (
		-- rptMemberDaily data (historical deposits and all withdrawals)
		SELECT EOMONTH(r.WinlostDate) AS MonthDate
			,r.Currency
			,0 AS TotalDeposit
			,SUM(CASE 
				WHEN r.WinlostDate < @CommissionBoundary 
				THEN ISNULL(r.Deposit, 0)
				ELSE 0 
			END) AS TotalDepositAmount
			,SUM(ISNULL(r.Withdrawal, 0)) AS TotalWithdrawalAmount
		FROM dbo.rptMemberDaily r WITH (NOLOCK)
		WHERE r.WinlostDate >= @FromDate 
			AND r.WinlostDate < DATEADD(DAY, 1, @ToDate)
			AND r.AffId = @AffId
			AND r.ProductId < 0
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
				WHERE mr.CustId = r.custid AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
			)
		GROUP BY EOMONTH(r.WinlostDate), r.Currency
	),
	CTE_CombinedData AS (
		-- Combine both sources with exchange rate conversion
		SELECT
			td.MonthDate,
			SUM(td.TotalDeposit) AS TotalDeposit,
			SUM(td.TotalDepositAmount * er.Rate) AS TotalDepositAmount,
			SUM(td.TotalWithdrawalAmount * er.Rate) AS TotalWithdrawalAmount
		FROM (
			SELECT MonthDate, Currency, TotalDeposit, TotalDepositAmount, TotalWithdrawalAmount 
			FROM CTE_DepositInfo
			UNION ALL
			SELECT MonthDate, Currency, TotalDeposit, TotalDepositAmount, TotalWithdrawalAmount 
			FROM CTE_HistoricalData
		) td
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON td.Currency = t.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(td.MonthDate, ISNULL(t.ExchangeId, td.Currency), @BaseExchangeId) er
		GROUP BY td.MonthDate
	)
	INSERT INTO @TotalDeposit(MonthDate, TotalDeposit, TotalDepositAmount, TotalWithdrawalAmount)
	SELECT MonthDate, TotalDeposit, TotalDepositAmount, TotalWithdrawalAmount
	FROM CTE_CombinedData

	-- Return detail
	SELECT
		md.MonthDate,
		md.EarningBy,
		md.CommGroupName,
		CASE
			WHEN md.MonthDate >= GETDATE() THEN 'Temporary'
			WHEN md.MonthDate > @MaxCommDate THEN 'Uncalculated'
			ELSE '' END AS Description,
		ISNULL(s.TotalClick, 0)					AS TotalClick,
		ISNULL(s.UniqueClick, 0)				AS UniqueClick,
		ISNULL(m.Signup, 0)						AS Signup,
		ISNULL(m.FDM, 0)						AS FDM,
		ISNULL(m.FDM_Amount, 0)					AS FDM_Amount,
		ISNULL(m.FDM_TotalDeposit, 0)			AS FDM_TotalDeposit,
		ISNULL(ts.NoOfSubAff, 0)				AS NoOfSubAff,
		ISNULL(tc.ActivePlayer, 0)				AS ActivePlayer,
		ISNULL(tc.QualifiedMember, 0)			AS QualifiedMember,
		ISNULL(tp.TotalDepositAmount, 0)		AS Deposit,
		ISNULL(tp.TotalWithdrawalAmount, 0)		AS Withdrawal,
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
		ISNULL(at.BFF, 0)						AS BFF,
		ISNULL(tp.TotalDeposit, 0)				AS TotalDeposit
	FROM @MonthDate md
		LEFT JOIN #TempCommission tc ON md.MonthDate = tc.MonthDate
		OUTER APPLY (
			SELECT
				SUM(ISNULL(Signup, 0)) AS Signup,
				SUM(ISNULL(FDM, 0)) AS FDM,
				SUM(ISNULL(m.FDM_Amount,0)) AS FDM_Amount,
				SUM(ISNULL(m.FDM_TotalDeposit,0)) AS FDM_TotalDeposit
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
		LEFT JOIN @TotalDeposit tp ON md.MonthDate = tp.MonthDate
	WHERE md.RowIdx BETWEEN @RowStart AND @RowEnd
	ORDER BY md.RowIdx ASC

	-- Return total
	SELECT
		SUM(ISNULL(s.TotalClick, 0))				AS TotalClick,
		SUM(ISNULL(s.UniqueClick, 0))				AS UniqueClick,
		SUM(ISNULL(m.Signup, 0))					AS Signup,
		SUM(ISNULL(m.FDM, 0))						AS FDM,
		SUM(ISNULL(m.FDM_Amount, 0))				AS FDM_Amount,
		SUM(ISNULL(m.FDM_TotalDeposit, 0))		    AS FDM_TotalDeposit,
		SUM(ISNULL(ts.NoOfSubAff, 0))				AS NoOfSubAff,
		SUM(ISNULL(tc.ActivePlayer, 0))				AS ActivePlayer,
		SUM(ISNULL(tc.QualifiedMember, 0))			AS QualifiedMember,
		SUM(ISNULL(tp.TotalDepositAmount, 0))		AS Deposit,
		SUM(ISNULL(tp.TotalWithdrawalAmount, 0))	AS Withdrawal,
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
		SUM(ISNULL(CASE WHEN md.MonthDate = @ToDate THEN at.BFF ELSE 0 END, 0)) AS BFF, -- the last month by running total
		SUM(ISNULL(tp.TotalDeposit, 0))				AS TotalDeposit
	FROM @MonthDate md
		LEFT JOIN #TempCommission tc ON md.MonthDate = tc.MonthDate
		OUTER APPLY (
			SELECT
				SUM(ISNULL(Signup, 0)) AS Signup,
				SUM(ISNULL(FDM, 0)) AS FDM,
				SUM(ISNULL(m.FDM_Amount,0)) AS FDM_Amount,
				SUM(ISNULL(m.FDM_TotalDeposit,0)) AS FDM_TotalDeposit
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
		LEFT JOIN @TotalDeposit tp ON md.MonthDate = tp.MonthDate

	DROP TABLE #TempCommission
	DROP TABLE #Statistics
END
GO