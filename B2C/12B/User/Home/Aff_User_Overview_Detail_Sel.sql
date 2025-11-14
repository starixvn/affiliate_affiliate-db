/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Overview_Detail_Sel]
	@AffId			INT
	,@FromDate		SMALLDATETIME
	,@ToDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
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

	-- Date range handling based on @IsGetMonthly parameter
	DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME

	-- Calculate commission date boundary for data separation (commission date + 1 day)
	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	-- For monthly mode, get end of month for group settings
	DECLARE @EndOfMonth TABLE (MonthDate DATE);

	;WITH MonthCTE AS 
	(
		SELECT EOMONTH(@FromDate) AS MonthDate
		UNION ALL
		SELECT EOMONTH(DATEADD(MONTH, 1, MonthDate))
		FROM MonthCTE
		WHERE DATEADD(MONTH, 1, MonthDate) <= @ToDate
	)
	INSERT INTO @EndOfMonth (MonthDate)
	SELECT MonthDate
	FROM MonthCTE
	OPTION (MAXRECURSION 0);

	
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
			AND RegisteredDate >= @FDate AND RegisteredDate < DATEADD(DAY, 1, @TDate)
		GROUP BY CONVERT(DATE, RegisteredDate)

		INSERT INTO @Signups (WinlostDate, DepositedMembers)
		SELECT CONVERT(DATE, FirstDepositDate) AS WinlostDate, COUNT(1) AS DepositedMembers
		FROM dbo.MemberInfo WITH (NOLOCK)
		WHERE AffId = @AffId
			AND FirstDepositDate >= @FDate AND FirstDepositDate < DATEADD(DAY, 1, @TDate)
		GROUP BY CONVERT(DATE, FirstDepositDate)
	END

	-- Turnover, Winloss, Deposit, Withdrawl, Qualified Active Members
	BEGIN
		CREATE TABLE #Data (WinlostDate SMALLDATETIME, CustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, GGR MONEY, IsActive TINYINT
							, MonthDate DATETIME)
		
		DECLARE @QualifiedMemberCPA TABLE (WinlostDate SMALLDATETIME, QualifiedMemberCPA INT)

		-- Deposit Amount + QualifiedMemberCPA
		-- Check if date range is before commission boundary
		IF @FromDate <= @MaxCommDate
		BEGIN

			SELECT @FDate = @FromDate
				   ,@TDate = IIF(@ToDate > @MaxCommDate, @MaxCommDate, @ToDate)

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
				WHERE r.WinlostDate >= @FDate AND r.WinlostDate <= @TDate
					AND r.AffId = @AffId
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY r.WinlostDate, r.CustId, r.Currency, CONVERT(DATE, EOMONTH(r.WinlostDate))
			)
			INSERT INTO #Data (WinlostDate, CustId, Deposit, Withdrawal, Turnover, GGR, IsActive, MonthDate)
			SELECT rd.WinlostDate, rd.CustId
				,SUM(rd.Deposit * e.Rate) AS Deposit
				,SUM(rd.Withdrawal * e.Rate) AS Withdrawal
				,SUM(rd.Turnover * e.Rate) AS Turnover
				,SUM(rd.GGR * e.Rate) AS GGR
				,MAX(rd.IsActive) AS IsActive
				, rd.MonthDate
			FROM CTE_RawData rd
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON rd.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(rd.MonthDate, ISNULL(t.ExchangeId, rd.Currency), @BaseExchangeId) e
			GROUP BY rd.WinlostDate, rd.CustId, rd.MonthDate

			--QualifiedMemberCPA --pastmonth
			INSERT INTO @QualifiedMemberCPA(WinlostDate, QualifiedMemberCPA)
			SELECT mc.CPADate, COUNT(mc.CustId) AS QualifiedMemberCPA
			FROM dbo.MemberCPA mc WITH (NOLOCK)
			WHERE mc.StatusId = 3
				AND mc.CPADate BETWEEN @FDate AND @TDate
				AND mc.AffId = @AffId
			GROUP BY mc.CPADate
		END
		
		IF @ToDate > @MaxCommDate
		BEGIN
			--GMT8
			SELECT @FDate = IIF(@FromDate <= @MaxCommDate, DATEADD(DAY, 1, @MaxCommDate), @FromDate)
				   ,@TDate = DATEADD(DAY, 1, @ToDate)

			-- Use hybrid approach for data spanning commission boundary
			-- GMT8
			;WITH CTE_HistoricalData AS (
				-- Historical data from rptMemberDaily (before commission boundary)
				SELECT r.WinlostDate, r.CustId, r.Currency
					,0 AS Deposit
					,SUM(r.Withdrawal) AS Withdrawal
					,SUM(r.Turnover) AS Turnover
					,SUM(-(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0)) AS GGR
					,MAX(CASE WHEN r.ProductId > 0 THEN 1 ELSE 0 END) AS IsActive
					,CONVERT(DATE, EOMONTH(r.WinlostDate)) AS MonthDate
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
				WHERE r.WinlostDate >= @FDate
					AND r.WinlostDate < @TDate
					AND r.AffId = @AffId
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY r.WinlostDate, r.CustId, r.Currency, CONVERT(DATE, EOMONTH(r.WinlostDate))
			), 
			--GMT0
			CTE_RecentDeposit AS (
				-- Recent deposit data from DepositInfo (after commission boundary)
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
					AND d.WinlostDate >= @FDate 
					AND d.WinlostDate < @TDate  -- Use WinlostDate index with pre-calculated DATE variables
					AND d.CreateTime >= DATEADD(HOUR, -8, @FDate)  -- GMT0
					AND d.CreateTime < DATEADD(HOUR, -8, @TDate)  -- GMT0
					AND mi.AffId = @AffId
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
						WHERE mr.CustId = d.CustId AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)), d.CustId, mi.Currency, CONVERT(DATE, EOMONTH(DATEADD(HOUR, 8, d.CreateTime)))
			),
			CTE_CombinedData AS (
				-- Combine all data sources with exchange rate conversion
				SELECT 
					WinlostDate,
					CustId,
					SUM(Deposit * e.Rate) AS Deposit,
					SUM(Withdrawal * e.Rate) AS Withdrawal,
					SUM(Turnover * e.Rate) AS Turnover,
					SUM(GGR * e.Rate) AS GGR,
					MAX(IsActive) AS IsActive,
					b.MonthDate
				FROM (
					SELECT WinlostDate, CustId, Currency, Deposit, Withdrawal, Turnover, GGR, IsActive, MonthDate FROM CTE_HistoricalData
					UNION ALL
					SELECT WinlostDate, CustId, Currency, Deposit, Withdrawal, Turnover, GGR, IsActive, MonthDate FROM CTE_RecentDeposit
				) b
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON b.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(b.MonthDate, ISNULL(t.ExchangeId, b.Currency), @BaseExchangeId) e
				GROUP BY b.WinlostDate, b.CustId, b.MonthDate
			)
			INSERT INTO #Data (WinlostDate, CustId, Deposit, Withdrawal, Turnover, GGR, IsActive, MonthDate)
			SELECT 
				WinlostDate,
				CustId,
				Deposit,
				Withdrawal,
				Turnover,
				GGR,
				IsActive,
				MonthDate
			FROM CTE_CombinedData

			--QualifiedMemberCPA --currentmonth
			INSERT INTO @QualifiedMemberCPA(WinlostDate, QualifiedMemberCPA)
			SELECT WinlostDate, QualifiedMemberCPA
			FROM (
					SELECT mc.CPADate AS WinlostDate, COUNT(mc.CustId) AS QualifiedMemberCPA
					FROM dbo.MemberCPA mc WITH (NOLOCK)
					WHERE mc.StatusId = 3 --settled
						AND mc.CPADate BETWEEN @FDate AND @TDate
						AND mc.AffId = @AffId
					GROUP BY mc.CPADate
					UNION ALL
					SELECT mc.HoldingQualifiedDate, COUNT(mc.CustId) AS QualifiedMemberCPA
					FROM dbo.MemberCPA mc WITH (NOLOCK)
					WHERE mc.StatusId = 2 --Eligibled
						AND mc.HoldingQualifiedDate BETWEEN @FDate AND @TDate
						AND mc.AffId = @AffId
					GROUP BY mc.HoldingQualifiedDate
				) t
		END

		CREATE CLUSTERED INDEX CIX_IBCCustId_WinlostDate ON #Data (CustId, WinlostDate)

		SELECT @FDate = @FromDate
			,@TDate = @ToDate

		UPDATE d
		SET d.IsActive = 0
		FROM #Data d
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.CustId = m.CustId
		WHERE d.IsActive = 1
			AND (
				m.FirstDepositDate IS NULL
				OR m.FirstDepositDate > DATEADD(DAY, 1, @TDate)
			)

		-- Active Members + Qualified Members
		DECLARE @ActiveMembers TABLE (WinlostDate SMALLDATETIME, CustId INT)
		DECLARE @QualifiedActiveMembers TABLE (WinlostDate SMALLDATETIME, CustId INT, Turnover MONEY)

		DECLARE @QMTurnover TABLE (MonthDate DATETIME, QMTurnover MONEY)

		INSERT INTO @QMTurnOver (MonthDate, QMTurnover)
		SELECT cgh.MonthDate, cgh.QMTurnover
		FROM dbo.CommGroupHistory cgh WITH (NOLOCK)
			INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON cgh.GroupID = agh.GroupID AND cgh.MonthDate = agh.MonthDate
		WHERE EXISTS (SELECT TOP 1 1 FROM @EndOfMonth a WHERE cgh.MonthDate = a.MonthDate)
			AND agh.AffID = @AffId

		DECLARE @tmpWinlostDate SMALLDATETIME
		SELECT  @tmpWinlostDate = @FDate

		WHILE @tmpWinlostDate <= @TDate
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
				SELECT 
					x.WinlostDate,
					x.CustId,
					x.TotalTurnover
				FROM (
					SELECT  
						@tmpWinlostDate AS WinlostDate,
						d.CustId,
						SUM(d.Turnover) AS TotalTurnover,
						q.QMTurnover
					FROM #Data d
						INNER JOIN @QMTurnOver q ON q.MonthDate = d.MonthDate
					WHERE d.WinlostDate <= @tmpWinlostDate
						AND NOT EXISTS (SELECT 1 FROM @QualifiedActiveMembers qa WHERE d.CustId = qa.CustId)
					GROUP BY d.CustId, q.QMTurnover
				) x
				WHERE x.TotalTurnover >= x.QMTurnover
			END

			SELECT @tmpWinlostDate = DATEADD(DAY, 1, @tmpWinlostDate)
		END
	END
	
	-- ===============================
	-- CPA INFO
	-- ===============================
	DECLARE @TimeZone INT
	SELECT @TimeZone = CAST(SValue AS INT) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'TimeZone'

	DECLARE @GroupTypeName NVARCHAR(200) = 'Hybrid CPA/Revenue Share'
			,@CurrentDate DATETIME = DATEADD(HOUR, @TimeZone, GETUTCDATE())
	
	-- @GroupTypeName
	IF NOT EXISTS (
					SELECT TOP 1 1
					FROM dbo.AffGroupHistory agh WITH (NOLOCK)
						INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON cg.IsDeleted = 0 AND agh.GroupId = cg.GroupId
					WHERE agh.AffId = @AffId
						AND agh.FromDate <= @ToDate
						AND agh.ToDate >= @FromDate
						AND cg.GroupTypeId <> 3
					)
	BEGIN 
		SET @GroupTypeName = 'CPA'
	END

	IF NOT EXISTS (
					SELECT TOP 1 1
					FROM dbo.AffGroupHistory agh WITH (NOLOCK)
						INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON cg.IsDeleted = 0 AND agh.GroupId = cg.GroupId
					WHERE agh.AffId = @AffId
						AND agh.FromDate <= @ToDate
						AND agh.ToDate >= @FromDate
						AND cg.GroupTypeId <> 1
					)
	BEGIN 
		SET @GroupTypeName = 'Revenue Share'
	END


	-- Return result
	BEGIN
		SELECT @GroupTypeName AS GroupTypeName

		;WITH CTE_WinlostDate AS (
			SELECT @FDate AS WinlostDate
			UNION ALL
			SELECT DATEADD(DAY, 1, WinlostDate)
			FROM CTE_WinlostDate
			WHERE WinlostDate < @TDate
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
			,ISNULL(mc.QualifiedMemberCPA, 0) AS QualifiedMemberCPA
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
			OUTER APPLY (
				SELECT SUM(QualifiedMemberCPA) AS QualifiedMemberCPA
				FROM  @QualifiedMemberCPA mc
				WHERE wld.WinlostDate = mc.WinlostDate
			) mc
		ORDER BY wld.WinlostDate DESC
	END

	DROP TABLE #Data
END
GO