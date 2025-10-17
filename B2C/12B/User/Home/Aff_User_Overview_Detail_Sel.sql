/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Overview_Detail_Sel]
	@AffId			INT
	,@FromDate		SMALLDATETIME
	,@ToDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
	,@IsGetMonthly  BIT = 1
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Account Overview - Detail

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250310@Lewis: Add column Qualified Members [RedmineID: #219495]
		- 20250723@Sophia: Optimize Deposit/Withdrawal using commission date boundary approach [RedmineID: #239737]
		- 20251021@Lewis: Remove redundant @Products table logic and Enhance query performance [RedmineID: #242297]
		- 20250918@Lewis: Get CPAAmount data [RedmineID: #238519]

	Param's Explanation:
		. @BaseCurrency : Currency of B2C
	NOT:
	- Data separation: rptMemberDaily for historical data (before commission boundary), DepositInfo for recent data (after commission boundary)
	- Commission boundary = @CommissionBoundary = AFF_CommissionDate + 1 day

*/

BEGIN
	SET NOCOUNT ON

	-- date range for get data whole month of @MonthDate
	DECLARE @FromBeginMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	SELECT  @FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @ToNextMonth	= DATEADD(MONTH, 1, @FromBeginMonth)

	-- Pre-calculate DATE variables for WinlostDate index optimization
	DECLARE @WinlostDateFrom DATE, @WinlostDateTo DATE
	SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @FromBeginMonth))
	SELECT @WinlostDateTo =  @ToNextMonth 

	-- Calculate commission date boundary for data separation (commission date + 1 day)
	DECLARE @CommissionBoundary SMALLDATETIME
	SELECT @CommissionBoundary = DATEADD(DAY, 1, CONVERT(SMALLDATETIME, SValue)) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	DECLARE @EndOfMonth SMALLDATETIME
	SELECT  @EndOfMonth = DATEADD(DAY, -1, @ToNextMonth)

	DECLARE @TimeZone INT
	SELECT  @TimeZone = CONVERT(SMALLINT, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'TimeZone'

	IF @ToNextMonth > DATEADD(DAY, 1, CONVERT(DATE, DATEADD(HOUR, 4 + @TimeZone, GETDATE())))
		SELECT @ToNextMonth = DATEADD(DAY, 1, CONVERT(DATE, DATEADD(HOUR, 4 + @TimeZone, GETDATE())))

	IF @ToNextMonth < DATEADD(DAY, 1, @FromBeginMonth)
		RETURN
	
	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	-- Signups, Deposited Members
	BEGIN
		DECLARE @Signups TABLE (WinlostDate SMALLDATETIME, Signups INT DEFAULT(0), DepositedMembers INT DEFAULT(0))

		INSERT INTO @Signups (WinlostDate, Signups)
		SELECT CONVERT(DATE, RegisteredDate) AS WinlostDate, COUNT(1) AS Signups
		FROM dbo.MemberInfo WITH (NOLOCK)
		WHERE AffId = @AffId
			AND RegisteredDate >= @FromBeginMonth AND RegisteredDate < @ToNextMonth
		GROUP BY CONVERT(DATE, RegisteredDate)

		INSERT INTO @Signups (WinlostDate, DepositedMembers)
		SELECT CONVERT(DATE, FirstDepositDate) AS WinlostDate, COUNT(1) AS DepositedMembers
		FROM dbo.MemberInfo WITH (NOLOCK)
		WHERE AffId = @AffId
			AND FirstDepositDate >= @FromBeginMonth AND FirstDepositDate < @ToNextMonth
		GROUP BY CONVERT(DATE, FirstDepositDate)
	END

	-- Turnover, Winloss, Deposit, Withdrawl, Qualified Active Members
	BEGIN
		CREATE TABLE #Data (WinlostDate SMALLDATETIME, CustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, GGR MONEY, IsActive TINYINT)
		
		-- Deposit Amount
		-- Check if @FromBeginMonth is before commission boundary
		IF @FromBeginMonth < @CommissionBoundary
		BEGIN
			-- Use rptMemberDaily only for all data with currency grouping optimization
			;WITH CTE_RawData AS (
				SELECT r.WinlostDate, r.CustId, r.Currency
					,SUM(r.Deposit) AS Deposit
					,SUM(r.Withdrawal) AS Withdrawal
					,SUM(r.Turnover) AS Turnover
					,SUM(-(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0)) AS GGR
					,MAX(CASE WHEN r.ProductId > 0 THEN 1 ELSE 0 END) AS IsActive
					,CONVERT(DATE, EOMONTH(r.WinlostDate)) AS MonthDate
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
				WHERE r.WinlostDate >= @FromBeginMonth AND r.WinlostDate < @ToNextMonth
					AND r.AffId = @AffId
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY r.WinlostDate, r.CustId, r.Currency, CONVERT(DATE, EOMONTH(r.WinlostDate))
			)
			INSERT INTO #Data (WinlostDate, CustId, Deposit, Withdrawal, Turnover, GGR, IsActive)
			SELECT rd.WinlostDate, rd.CustId
				,SUM(rd.Deposit * e.Rate) AS Deposit
				,SUM(rd.Withdrawal * e.Rate) AS Withdrawal
				,SUM(rd.Turnover * e.Rate) AS Turnover
				,SUM(rd.GGR * e.Rate) AS GGR
				,MAX(rd.IsActive) AS IsActive
			FROM CTE_RawData rd
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON rd.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(rd.MonthDate, ISNULL(t.ExchangeId, rd.Currency), @BaseExchangeId) e
			GROUP BY rd.WinlostDate, rd.CustId
		END
		ELSE
		BEGIN
			-- Use hybrid approach: rptMemberDaily for all data except deposits + DepositInfo for recent deposits
			;WITH CTE_HistoricalDeposit AS (
				-- Non-deposit data from rptMemberDaily (all metrics except deposits)
				SELECT r.WinlostDate, r.CustId, r.Currency
					,0 AS Deposit  -- Deposit will come from CTE_RecentDeposit
					,SUM(r.Withdrawal) AS Withdrawal
					,SUM(r.Turnover) AS Turnover
					,SUM(-(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0)) AS GGR
					,MAX(CASE WHEN r.ProductId > 0 THEN 1 ELSE 0 END) AS IsActive
					,CONVERT(DATE, EOMONTH(r.WinlostDate)) AS MonthDate
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
				WHERE r.WinlostDate >= @FromBeginMonth
					AND r.WinlostDate < @ToNextMonth
					AND r.AffId = @AffId
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY r.WinlostDate, r.CustId, r.Currency, CONVERT(DATE, EOMONTH(r.WinlostDate))
			),
			CTE_RecentDeposit AS (
				-- Deposit data from DepositInfo
				SELECT CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)) AS WinlostDate, d.CustId, mi.Currency
					,SUM(d.ActualDeposit * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) AS Deposit
					,0 AS Withdrawal
					,0 AS Turnover
					,0 AS GGR
					,0 AS IsActive
					,CONVERT(DATE, EOMONTH(DATEADD(HOUR, 8, d.CreateTime))) AS MonthDate
				FROM bodb_12B.dbo.DepositInfo d WITH (NOLOCK)
					INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.CustId = mi.CustId
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
					LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, mi.Currency) = e.ExchangeId
				WHERE d.Status = 3 -- Approved
					AND d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index
					AND DATEADD(HOUR, 8, d.CreateTime) >= @FromBeginMonth
					AND DATEADD(HOUR, 8, d.CreateTime) < @ToNextMonth
					AND mi.AffId = @AffId
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
						WHERE mr.CustId = d.CustId AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)), d.CustId, mi.Currency, CONVERT(DATE, EOMONTH(DATEADD(HOUR, 8, d.CreateTime)))
			),
			CTE_CombinedDeposit AS (
				-- Combine historical and recent data with exchange rate conversion
				SELECT 
					WinlostDate,
					CustId,
					SUM(Deposit * e.Rate) AS Deposit,
					SUM(Withdrawal * e.Rate) AS Withdrawal,
					SUM(Turnover * e.Rate) AS Turnover,
					SUM(GGR * e.Rate) AS GGR,
					MAX(IsActive) AS IsActive
				FROM (
					SELECT WinlostDate, CustId, Currency, Deposit, Withdrawal, Turnover, GGR, IsActive, MonthDate FROM CTE_HistoricalDeposit
					UNION ALL
					SELECT WinlostDate, CustId, Currency, Deposit, Withdrawal, Turnover, GGR, IsActive, MonthDate FROM CTE_RecentDeposit
				) b
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON b.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(b.MonthDate, ISNULL(t.ExchangeId, b.Currency), @BaseExchangeId) e
				GROUP BY b.WinlostDate, b.CustId
			)
			INSERT INTO #Data (WinlostDate, CustId, Deposit, Withdrawal, Turnover, GGR, IsActive)
			SELECT 
				WinlostDate,
				CustId,
				Deposit,
				Withdrawal,
				Turnover,
				GGR,
				IsActive
			FROM CTE_CombinedDeposit
		END

		CREATE CLUSTERED INDEX CIX_IBCCustId_WinlostDate ON #Data (CustId, WinlostDate)

		UPDATE d
		SET d.IsActive = 0
		FROM #Data d
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.CustId = m.CustId
		WHERE d.IsActive = 1
			AND (
				m.FirstDepositDate IS NULL
				OR m.FirstDepositDate >= DATEADD(DAY, 1, @EndOfMonth)
			)

		-- Active Members + Qualified Members
		DECLARE @ActiveMembers TABLE (WinlostDate SMALLDATETIME, CustId INT)
		DECLARE @QualifiedActiveMembers TABLE (WinlostDate SMALLDATETIME, CustId INT, Turnover MONEY)

		DECLARE @QMTurnover MONEY

		SELECT  @QMTurnover = QMTurnover
		FROM dbo.CommGroupHistory cgh WITH (NOLOCK)
			INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON cgh.GroupID = agh.GroupID AND cgh.MonthDate = agh.MonthDate
		WHERE cgh.MonthDate = @EndOfMonth
			AND agh.AffID = @AffId

		DECLARE @tmpWinlostDate SMALLDATETIME
		SELECT  @tmpWinlostDate = @FromBeginMonth

		WHILE @tmpWinlostDate < @ToNextMonth
		BEGIN
			IF EXISTS (SELECT 1 FROM #Data WHERE WinlostDate = @tmpWinlostDate)
			BEGIN
				INSERT INTO @ActiveMembers (WinlostDate, CustId)
				SELECT WinlostDate, CustId
				FROM #Data d
				WHERE WinlostDate = @tmpWinlostDate
					AND IsActive = 1
					AND NOT EXISTS (SELECT 1 FROM @ActiveMembers a WHERE d.CustId = a.CustId)

				INSERT INTO @QualifiedActiveMembers (WinlostDate, CustId, Turnover)
				SELECT @tmpWinlostDate AS WinlostDate, CustId, SUM(Turnover) AS Turnover
				FROM #Data d
				WHERE WinlostDate <= @tmpWinlostDate
					AND NOT EXISTS (SELECT 1 FROM @QualifiedActiveMembers q WHERE d.CustId = q.CustId)
				GROUP BY CustId
				HAVING SUM(Turnover) >= @QMTurnover
			END

			SELECT @tmpWinlostDate = DATEADD(DAY, 1, @tmpWinlostDate)
		END
	END
	
	-- Return result
	BEGIN
		WITH CTE_WinlostDate AS (
			SELECT @FromBeginMonth AS WinlostDate
			UNION ALL
			SELECT DATEADD(DAY, 1, WinlostDate)
			FROM CTE_WinlostDate
			WHERE WinlostDate < DATEADD(DAY, -1, @ToNextMonth)
		)
		SELECT
			wld.WinlostDate
			,ISNULL(s.Signups, 0)			AS Signups
			,ISNULL(s.DepositedMembers, 0)	AS DepositedMembers
			,ISNULL(d.Deposit, 0)			AS Deposit
			,ISNULL(d.Withdrawal, 0)		AS Withdrawal
			,ISNULL(d.Turnover, 0)			AS Turnover
			,ISNULL(d.GGR, 0)				AS GGR
			,ISNULL(a.ActiveMembers, 0)		AS ActiveMembers
			,ISNULL(q.QualifiedActiveMembers, 0)	AS QualifiedActiveMembers
		FROM CTE_WinlostDate wld
			OUTER APPLY (
				SELECT SUM(s.Signups) AS Signups, SUM(s.DepositedMembers) AS DepositedMembers
				FROM @Signups s
				WHERE wld.WinlostDate = s.WinlostDate
			) s
			OUTER APPLY (
				SELECT SUM(d.Deposit) AS Deposit, SUM(d.Withdrawal) AS Withdrawal, SUM(d.Turnover) AS Turnover, SUM(d.GGR) AS GGR
				FROM #Data d
				WHERE wld.WinlostDate = d.WinlostDate
			) d
			OUTER APPLY (
				SELECT COUNT(DISTINCT a.CustId) AS ActiveMembers
				FROM @ActiveMembers a
				WHERE wld.WinlostDate = a.WinlostDate
			) a
			OUTER APPLY (
				SELECT COUNT(DISTINCT q.CustId) AS QualifiedActiveMembers
				FROM @QualifiedActiveMembers q
				WHERE wld.WinlostDate = q.WinlostDate
			) q
		ORDER BY wld.WinlostDate DESC
	END

	DROP TABLE #Data
END
GO