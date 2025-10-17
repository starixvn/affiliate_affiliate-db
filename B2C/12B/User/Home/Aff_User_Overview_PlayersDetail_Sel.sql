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

	-- date range for get data whole month of @MonthDate
	DECLARE @BeginOfMonth SMALLDATETIME, @EndOfMonth SMALLDATETIME
	SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @EndOfMonth		= DATEADD(DAY, -1, DATEADD(MONTH, 1, @BeginOfMonth))

	-- Pre-calculate DATE variables for WinlostDate index optimization
	DECLARE @WinlostDateFrom DATE, @WinlostDateTo DATE
	SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @BeginOfMonth))
	SELECT @WinlostDateTo = DATEADD(DAY, 1, CONVERT(DATE, DATEADD(DAY, 1, @EndOfMonth)))

	-- Calculate commission date boundary for data separation (commission date + 1 day)
	DECLARE @CommissionBoundary SMALLDATETIME
	SELECT @CommissionBoundary = DATEADD(DAY, 1, CONVERT(SMALLDATETIME, SValue)) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	CREATE TABLE #tmpData (CustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, GGR MONEY, Bonus MONEY, Rebate MONEY)

	DECLARE @Products TABLE (ProductId INT, IsStraightSetting BIT)
		
	INSERT INTO @Products (ProductId, IsStraightSetting)
	SELECT DISTINCT dsh.ProductId, 0
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId AND agh.MonthDate = dsh.MonthDate
	WHERE dsh.ProductId > 0
		AND agh.MonthDate = @EndOfMonth
		AND agh.AffID = @AffId

	INSERT INTO @Products (ProductId, IsStraightSetting)
	SELECT DISTINCT ssh.ProductId, 1
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.StraightSettingHistory ssh WITH (NOLOCK) ON agh.GroupId = ssh.GroupId AND agh.MonthDate = ssh.MonthDate
	WHERE ssh.ProductId > 0
		AND agh.MonthDate = @EndOfMonth
		AND agh.AffID = @AffId

	-- Get data using conditional hybrid approach
	BEGIN
		-- Check if @BeginOfMonth is before commission boundary
		IF @BeginOfMonth < @CommissionBoundary
		BEGIN
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
					LEFT JOIN @Products p ON r.ProductId = p.ProductId
				WHERE r.WinlostDate BETWEEN @BeginOfMonth AND @EndOfMonth
					AND r.AffId = @AffId
					AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY r.CustId, r.Currency, CONVERT(DATE, EOMONTH(r.WinlostDate))
			)
			INSERT INTO #tmpData (CustId, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate)
			SELECT 
				c.CustId,
				SUM(c.Deposit * e.Rate) AS Deposit,
				SUM(c.Withdrawal * e.Rate) AS Withdrawal,
				SUM(c.Turnover * e.Rate) AS Turnover,
				SUM(c.GGR * e.Rate) AS GGR,
				SUM(c.Bonus * e.Rate) AS Bonus,
				SUM(c.Rebate * e.Rate) AS Rebate
			FROM CTE_CombinedDeposit c
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON c.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(c.MonthDate, ISNULL(t.ExchangeId, c.Currency), @BaseExchangeId) e
			GROUP BY c.CustId
		END
		ELSE
		BEGIN
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
					LEFT JOIN @Products p ON r.ProductId = p.ProductId
				WHERE r.WinlostDate BETWEEN @BeginOfMonth AND @EndOfMonth
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
					AND di.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index
					AND CAST(DATEADD(HOUR, 8, di.CreateTime) AS DATE) BETWEEN @BeginOfMonth AND @EndOfMonth  -- Convert GMT+0 to GMT+8
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
					SUM(Rebate * e.Rate) AS Rebate
				FROM (
					SELECT CustId, Currency, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, MonthDate FROM CTE_HistoricalDeposit
					UNION ALL
					SELECT CustId, Currency, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, MonthDate FROM CTE_RecentDeposit
				) b
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON b.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(b.MonthDate, ISNULL(t.ExchangeId, b.Currency), @BaseExchangeId) e
				GROUP BY b.CustId
			)
			INSERT INTO #tmpData (CustId, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate)
			SELECT 
				CustId,
				Deposit,
				Withdrawal,
				Turnover,
				GGR,
				Bonus,
				Rebate
			FROM CTE_CombinedDeposit
		END

		SELECT @NRows = COUNT(1) FROM #tmpData
	END

	-- Get Banking Fee
	DECLARE @DepositRate DECIMAL(9, 8) = 0, @DepositAmount MONEY = 0
			,@WithdrawalRate DECIMAL(9, 8) = 0, @WithdrawalAmount MONEY = 0
	
	SELECT  @DepositRate = CASE WHEN DeductionID = 13 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE @DepositRate END
			,@DepositAmount = CASE WHEN DeductionID = 13 THEN ISNULL(dsh.DeductedAmount, 0) ELSE @DepositAmount END
			,@WithdrawalRate = CASE WHEN DeductionID = 14 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE @WithdrawalRate END
			,@WithdrawalAmount = CASE WHEN DeductionID = 14 THEN ISNULL(dsh.DeductedAmount, 0) ELSE @WithdrawalAmount END
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupID = dsh.GroupID AND agh.MonthDate = dsh.MonthDate
	WHERE dsh.DeductionID IN (13, 14)
		AND agh.MonthDate = @EndOfMonth
		AND agh.AffID = @AffId

	SELECT @DepositRate = ISNULL(@DepositRate, 0), @DepositAmount = ISNULL(@DepositAmount, 0)
			,@WithdrawalRate = ISNULL(@WithdrawalRate, 0), @WithdrawalAmount = ISNULL(@WithdrawalAmount, 0)

	IF @BaseCurrency <> 0
	BEGIN
		DECLARE @AffCurrency INT, @Rate FLOAT
		SELECT  @AffCurrency = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffCurrency'		
		-- Get affcurrency mapping
		DECLARE @AffExchangeId INT = @AffCurrency
		SELECT  @AffExchangeId = tp.ExchangeId
		FROM dbo.TpExchange tp WITH (NOLOCK)
		WHERE tp.TpExchangeId = @AffCurrency

		SELECT  @Rate = Rate FROM dbo.Aff_f_ExchangeRate_Sel(@EndOfMonth, @AffExchangeId, @BaseExchangeId)

		SELECT  @DepositAmount = @DepositAmount * @Rate
				,@WithdrawalAmount = @WithdrawalAmount * @Rate
	END

	-- Paging
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	SELECT CustId, UserName, RegisteredDate, FirstDepositDate, FirstDepositAmount, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, DepositFee, WithdrawalFee
	FROM
	(
		SELECT
			m.CustId
			,m.UserName
			,m.RegisteredDate
			,m.FirstDepositDate
			,ISNULL(m.FirstDepositAmount, 0) * e.Rate AS FirstDepositAmount
			,d.Deposit
			,d.Withdrawal
			,d.Turnover
			,d.GGR
			,d.Bonus
			,d.Rebate
			,d.Deposit * @DepositRate + @DepositAmount AS DepositFee
			,d.Withdrawal * @WithdrawalRate + @WithdrawalAmount AS WithdrawalFee
			,ROW_NUMBER() OVER(ORDER BY
				 (CASE WHEN @IsSortAsc = 1 AND @SortById =  1 THEN m.UserName			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  2 THEN m.RegisteredDate		END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  3 THEN d.Deposit			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  4 THEN d.Withdrawal			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  5 THEN d.Turnover			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  6 THEN d.GGR				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  7 THEN d.Bonus				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  8 THEN d.Rebate				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  9 THEN d.Deposit			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 10 THEN d.Withdrawal			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 11 THEN m.FirstDepositDate	END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 12 THEN ISNULL(m.FirstDepositAmount, 0) * e.Rate END) ASC

				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  1 THEN m.UserName			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  2 THEN m.RegisteredDate		END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  3 THEN d.Deposit			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  4 THEN d.Withdrawal			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  5 THEN d.Turnover			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  6 THEN d.GGR				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  7 THEN d.Bonus				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  8 THEN d.Rebate				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  9 THEN d.Deposit			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 10 THEN d.Withdrawal			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 11 THEN m.FirstDepositDate	END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 12 THEN ISNULL(m.FirstDepositAmount, 0) * e.Rate END) DESC
			) AS RN
		FROM #tmpData d
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.CustId = m.CustId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON m.Currency = t.TpExchangeId
			OUTER APPLY dbo.Aff_f_ExchangeRate_Sel (m.FirstDepositDate, ISNULL(t.ExchangeId, m.Currency), @BaseExchangeId) e
	) r
	WHERE r.RN BETWEEN @RowStart AND @RowEnd
	ORDER BY r.RN ASC

	DROP TABLE #tmpData
END
GO