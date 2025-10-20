/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Overview_PlayersDetail_Sel]
	@AffId			INT
	,@FromDate		SMALLDATETIME
	,@ToDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
	,@SortById		TINYINT = 5 -- default
	,@IsSortAsc		BIT = 0 -- default
	,@PageIndex		INT = 1
	,@PageSize		INT = 20
	,@NRows			INT = 0 OUTPUT
	,@IsGetMonthly  BIT = 1
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Account Overview - Detail

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250425@Sally: Get FDMAmount [RedmineID: #225616]
		- 20250627@Sally: Sort by FDMAmount [RedmineID: #231702]
		- 20251002@Sophia: Implement hybrid approach using rptMemberDaily for historical data and DepositInfo for recent data based on commission date boundary [RedmineID: #239737]
		- 20250918@Lewis: Get CPAAmount data [RedmineID: #238519]

	Notes:
	  - rptMemberDaily.WinlostDate is in GMT+8
	  - bodb_12B.dbo.DepositInfo.CreateTime is in GMT+0
	  - bodb_12B.dbo.DepositInfo.WinlostDate is indexed (Date of CreateTime)
	  - Data separation: rptMemberDaily for historical data (before commission boundary), DepositInfo for recent data (after commission boundary)
	  - Commission boundary = @CommissionBoundary = AFF_CommissionDate + 1 day

	Param's Explanation:
		- @SortById:	1 = Username
						2 = Registered Date
						3 = Deposit
						4 = Withdrawal
						5 = Turnover
						6 = GGR
						7 = Bonus
						8 = Rebate
						9 = Deposit Fee
					   10 = Withdrawal Fee
					   11 = First Deposit Date
					   12 = First Deposit Amount
		- @IsSortAsc:	0 = DESC
						1 = ASC
		- @BaseCurrency : Currency of B2C
*/

BEGIN
	SET NOCOUNT ON
	
	-- Date range handling based on @IsGetMonthly parameter
	DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME

	-- Calculate commission date boundary for data separation (commission date + 1 day)
	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	-- For monthly mode, get end of month for group settings
	DECLARE @EndOfMonth TABLE (MonthDate DATETIME)
	INSERT INTO @EndOfMonth (MonthDate)
	SELECT EOMONTH(@FromDate,0)
	UNION --Distinct EOMONTH
	SELECT EOMONTH(@ToDate,0)

	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	CREATE TABLE #tmpData (CustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, GGR MONEY, Bonus MONEY, Rebate MONEY, MonthDate DATETIME)

	DECLARE @Products TABLE (ProductId INT, IsStraightSetting BIT, MonthDate DATETIME)
		
	INSERT INTO @Products (ProductId, IsStraightSetting, MonthDate)
	SELECT DISTINCT dsh.ProductId, 0, agh.MonthDate
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId AND agh.MonthDate = dsh.MonthDate
	WHERE dsh.ProductId > 0
		AND EXISTS (SELECT TOP 1 1 FROM @EndOfMonth a WHERE agh.MonthDate = a.MonthDate)
		AND agh.AffID = @AffId

	INSERT INTO @Products (ProductId, IsStraightSetting, MonthDate)
	SELECT DISTINCT ssh.ProductId, 1, agh.MonthDate
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.StraightSettingHistory ssh WITH (NOLOCK) ON agh.GroupId = ssh.GroupId AND agh.MonthDate = ssh.MonthDate
	WHERE ssh.ProductId > 0
		AND EXISTS (SELECT TOP 1 1 FROM @EndOfMonth a WHERE agh.MonthDate = a.MonthDate)
		AND agh.AffID = @AffId

	-- Get data using conditional hybrid approach
	BEGIN
		-- Check if @BeginOfMonth is before commission boundary
		IF @FromDate <= @MaxCommDate
		BEGIN

			SELECT @FDate = @FromDate
				   ,@TDate = IIF(@ToDate > @MaxCommDate, @MaxCommDate, @ToDate)

			-- Use rptMemberDaily only for historical data with currency grouping optimization
			;WITH CTE_CombinedDeposit AS (
				SELECT r.CustId, r.Currency
					,SUM(r.Deposit) AS Deposit
					,SUM(r.Withdrawal) AS Withdrawal
					,SUM(CASE WHEN p.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END) AS Turnover
					,SUM(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
							ELSE -(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0) END) AS GGR
					,SUM(r.Bonus) AS Bonus
					,SUM(r.Rebate) AS Rebate
					,CONVERT(DATE, EOMONTH(r.WinlostDate)) AS MonthDate
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
					LEFT JOIN @Products p ON r.ProductId = p.ProductId AND CONVERT(DATE, EOMONTH(r.WinlostDate)) = p.MonthDate
				WHERE r.WinlostDate >= @FDate AND r.WinlostDate <= @TDate
					AND r.AffId = @AffId
					AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY r.CustId, r.Currency, CONVERT(DATE, EOMONTH(r.WinlostDate))
			)
			INSERT INTO #tmpData (CustId, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, MonthDate)
			SELECT 
				c.CustId,
				SUM(c.Deposit * e.Rate) AS Deposit,
				SUM(c.Withdrawal * e.Rate) AS Withdrawal,
				SUM(c.Turnover * e.Rate) AS Turnover,
				SUM(c.GGR * e.Rate) AS GGR,
				SUM(c.Bonus * e.Rate) AS Bonus,
				SUM(c.Rebate * e.Rate) AS Rebate
				, c.MonthDate
			FROM CTE_CombinedDeposit c
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON c.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(c.MonthDate, ISNULL(t.ExchangeId, c.Currency), @BaseExchangeId) e
			GROUP BY c.CustId, c.MonthDate
		END
		
		IF @ToDate > @MaxCommDate
		BEGIN
			
			--GMT8
			SELECT @FDate = IIF(@FromDate <= @MaxCommDate, DATEADD(DAY, 1, @MaxCommDate), @FromDate)
				   ,@TDate = DATEADD(DAY, 1, @ToDate)

			-- Use hybrid approach: DepositInfo for deposits, rptMemberDaily for other metrics
			;WITH CTE_HistoricalDeposit AS (
				-- Other metrics from rptMemberDaily
				SELECT r.CustId, r.Currency,
					0 AS Deposit,
					SUM(r.Withdrawal) AS Withdrawal,
					SUM(CASE WHEN p.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END) AS Turnover,
					SUM(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
							ELSE -(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0) END) AS GGR,
					SUM(r.Bonus) AS Bonus,
					SUM(r.Rebate) AS Rebate,
					CONVERT(DATE, EOMONTH(r.WinlostDate)) AS MonthDate
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
					LEFT JOIN @Products p ON r.ProductId = p.ProductId AND CONVERT(DATE, EOMONTH(r.WinlostDate)) = p.MonthDate
				WHERE r.WinlostDate >= @FDate
					AND r.WinlostDate < @TDate
					AND r.AffId = @AffId
					AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY r.CustId, r.Currency, CONVERT(DATE, EOMONTH(r.WinlostDate))
			),
			CTE_RecentDeposit AS (
				-- Deposit data from DepositInfo
				SELECT 
					mi.CustId,
					mi.Currency,
					SUM(di.ActualDeposit * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) AS Deposit,
					0 AS Withdrawal,
					0 AS Turnover,
					0 AS GGR,
					0 AS Bonus,
					0 AS Rebate,
					CONVERT(DATE, EOMONTH(DATEADD(HOUR, 8, di.CreateTime))) AS MonthDate
				FROM bodb_12B.dbo.DepositInfo di WITH(NOLOCK)
					INNER JOIN dbo.MemberInfo mi WITH(NOLOCK) ON di.CustId = mi.CustId
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
					LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, mi.Currency) = e.ExchangeId
				WHERE mi.AffId = @AffId
					AND di.Status = 3  -- Approved deposits only
					AND di.WinlostDate >= @FDate 
					AND di.WinlostDate < @TDate  -- Use WinlostDate index with pre-calculated DATE variables
					AND di.CreateTime >= DATEADD(HOUR, -8, @FDate)  -- GMT0
					AND di.CreateTime < DATEADD(HOUR, -8, @TDate)  -- GMT0
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
						WHERE mr.CustId = di.CustId 
						AND CAST(DATEADD(HOUR, 8, di.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY mi.CustId, mi.Currency, CONVERT(DATE, EOMONTH(DATEADD(HOUR, 8, di.CreateTime)))
			),
			CTE_CombinedDeposit AS (
				-- Combine historical and recent data with exchange rate conversion
				SELECT 
					CustId,
					SUM(Deposit * e.Rate) AS Deposit,
					SUM(Withdrawal * e.Rate) AS Withdrawal,
					SUM(Turnover * e.Rate) AS Turnover,
					SUM(GGR * e.Rate) AS GGR,
					SUM(Bonus * e.Rate) AS Bonus,
					SUM(Rebate * e.Rate) AS Rebate,
					b.MonthDate
				FROM (
					SELECT CustId, Currency, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, MonthDate FROM CTE_HistoricalDeposit
					UNION ALL
					SELECT CustId, Currency, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, MonthDate FROM CTE_RecentDeposit
				) b
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON b.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(b.MonthDate, ISNULL(t.ExchangeId, b.Currency), @BaseExchangeId) e
				GROUP BY b.CustId, b.MonthDate
			)
			INSERT INTO #tmpData (CustId, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, MonthDate)
			SELECT 
				CustId,
				Deposit,
				Withdrawal,
				Turnover,
				GGR,
				Bonus,
				Rebate,
				MonthDate
			FROM CTE_CombinedDeposit
		END

		SELECT @NRows = COUNT(1) FROM #tmpData
	END

	-- Get Banking Fee
	DECLARE @BankingFee TABLE (MonthDate DATETIME, DepositRate DECIMAL(9, 8), DepositAmount MONEY, WithdrawalRate DECIMAL(9, 8), WithdrawalAmount MONEY) 
	INSERT INTO @BankingFee (MonthDate, DepositRate, DepositAmount, WithdrawalRate, WithdrawalAmount)
	SELECT  
			agh.MonthDate
			,CASE WHEN dsh.DeductionID = 13 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE 0 END AS DepositRate
			,CASE WHEN dsh.DeductionID = 13 THEN ISNULL(dsh.DeductedAmount, 0) ELSE 0 END AS DepositAmount
			,CASE WHEN dsh.DeductionID = 14 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE 0 END AS WithdrawalRate
			,CASE WHEN dsh.DeductionID = 14 THEN ISNULL(dsh.DeductedAmount, 0) ELSE 0 END AS WithdrawalAmount
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupID = dsh.GroupID AND agh.MonthDate = dsh.MonthDate
	WHERE dsh.DeductionID IN (13, 14)
		AND EXISTS (SELECT TOP 1 1 FROM @EndOfMonth a WHERE agh.MonthDate = a.MonthDate)
		AND agh.AffID = @AffId

	-- Paging
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	SELECT 
		r.CustId
		, m.Username
		, m.RegisteredDate
		, m.FirstDepositDate
		, ISNULL(m.FirstDepositAmount, 0) * e.Rate AS FirstDepositAmount
		, r.Deposit
		, r.Withdrawal
		, r.Turnover
		, r.GGR
		, r.Bonus
		, r.Rebate
		, r.DepositFee
		, r.WithdrawalFee
		,ROW_NUMBER() OVER(ORDER BY
				 (CASE WHEN @IsSortAsc = 1 AND @SortById =  1 THEN m.UserName			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  2 THEN m.RegisteredDate		END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  3 THEN r.Deposit			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  4 THEN r.Withdrawal			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  5 THEN r.Turnover			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  6 THEN r.GGR				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  7 THEN r.Bonus				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  8 THEN r.Rebate				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  9 THEN r.Deposit			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 10 THEN r.Withdrawal			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 11 THEN m.FirstDepositDate	END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 12 THEN ISNULL(m.FirstDepositAmount, 0) * e.Rate END) ASC

				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  1 THEN m.UserName			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  2 THEN m.RegisteredDate		END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  3 THEN r.Deposit			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  4 THEN r.Withdrawal			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  5 THEN r.Turnover			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  6 THEN r.GGR				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  7 THEN r.Bonus				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  8 THEN r.Rebate				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  9 THEN r.Deposit			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 10 THEN r.Withdrawal			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 11 THEN m.FirstDepositDate	END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 12 THEN ISNULL(m.FirstDepositAmount, 0) * e.Rate END) DESC
			) AS RN
	FROM
		(
			SELECT
				d.CustId
				,SUM(d.Deposit) AS Deposit
				,SUM(d.Withdrawal) AS Withdrawal
				,SUM(d.Turnover) AS Turnover
				,SUM(d.GGR) AS GGR
				,SUM(d.Bonus) AS Bonus
				,SUM(d.Rebate) AS Rebate
				,SUM(d.Deposit * bf.DepositRate + bf.DepositAmount) AS DepositFee
				,SUM(d.Withdrawal * bf.WithdrawalRate + bf.WithdrawalAmount) AS WithdrawalFee
			FROM #tmpData d
				INNER JOIN @BankingFee bf ON d.MonthDate = bf.MonthDate
			GROUP BY d.CustId
		) r
		INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON r.CustId = m.CustId
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON m.Currency = t.TpExchangeId
		OUTER APPLY dbo.Aff_f_ExchangeRate_Sel (m.FirstDepositDate, ISNULL(t.ExchangeId, m.Currency), @BaseExchangeId) e
	WHERE r.RN BETWEEN @RowStart AND @RowEnd
	ORDER BY r.RN ASC

	DROP TABLE #tmpData
END
GO