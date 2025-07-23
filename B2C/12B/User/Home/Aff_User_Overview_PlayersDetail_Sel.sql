/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Overview_PlayersDetail_Sel]
	@AffId			INT
	,@MonthDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
	,@SortById		TINYINT = 5 -- default
	,@IsSortAsc		BIT = 0 -- default
	,@PageIndex		INT = 1
	,@PageSize		INT = 20
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Account Overview - Detail

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250425@Sally: Get FDMAmount [RedmineID: #225616]
		- 20250627@Sally: Sort by FDMAmount [RedmineID: #231702]
		- 20250723@Sophia: Optimize Deposit/Withdrawal using conditional hybrid approach - if @BeginOfMonth < last month use rptMemberDaily only, else use hybrid with DepositInfo/WithdrawalInfo for recent months [RedmineID: #233096]

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
	DECLARE @BeginOfMonth SMALLDATETIME, @EndOfMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @ToNextMonth = DATEADD(MONTH, 1, @BeginOfMonth)
	SELECT  @EndOfMonth = DATEADD(DAY, -1, @ToNextMonth)

	-- Pre-calculate DATE variables for WinlostDate index optimization
	DECLARE @WinlostDateFrom DATE, @WinlostDateTo DATE
	SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @BeginOfMonth))
	SELECT @WinlostDateTo = DATEADD(DAY, 1, CONVERT(DATE, @ToNextMonth))

	-- Hybrid approach: calculate last month start for deposit/withdrawal logic
	DECLARE @LastMonthStart SMALLDATETIME
	SELECT @LastMonthStart = DATEADD(MONTH, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))
	

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

	-- Get data
	BEGIN
		-- Check if @BeginOfMonth is before last month
		IF @BeginOfMonth < @LastMonthStart
		BEGIN
			-- Use rptMemberDaily only for all data
			INSERT INTO #tmpData (CustId, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate)
			SELECT r.CustId
				,SUM(r.Deposit * e.Rate) AS Deposit
				,SUM(r.Withdrawal * e.Rate) AS Withdrawal
				,SUM(CASE WHEN p.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END * e.Rate) AS Turnover
				,SUM(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
						ELSE -(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0) END * e.Rate) AS GGR
				,SUM(r.Bonus * e.Rate)
				,SUM(r.Rebate * e.Rate)
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
				LEFT JOIN @Products p ON r.ProductId = p.ProductId
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel (@BeginOfMonth, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
			WHERE r.WinlostDate >= @BeginOfMonth 
			    AND r.WinlostDate < @ToNextMonth
				AND r.AffId = @AffId
				AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
				)
			GROUP BY r.CustId
		END
		ELSE
		BEGIN
			-- Use hybrid approach: rptMemberDaily for all data except deposits + DepositInfo for recent deposits
			;WITH CTE_Historical AS (
				SELECT r.CustId
					,0 AS Deposit  -- Deposit will come from CTE_RecentDeposit
					,SUM(r.Withdrawal * e.Rate) AS Withdrawal  -- Include all withdrawals from rptMemberDaily
					,SUM(CASE WHEN p.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END * e.Rate) AS Turnover
					,SUM(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
							ELSE -(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0) END * e.Rate) AS GGR
					,SUM(r.Bonus * e.Rate) AS Bonus
					,SUM(r.Rebate * e.Rate) AS Rebate
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
					LEFT JOIN @Products p ON r.ProductId = p.ProductId
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel (@BeginOfMonth, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
				WHERE r.WinlostDate >= @BeginOfMonth
					AND r.WinlostDate < @ToNextMonth
					AND r.AffId = @AffId
					AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY r.CustId
			),
			CTE_RecentDeposit AS (
				SELECT d.CustId
					,SUM(d.Amount * e.Rate) AS Deposit
					,0 AS Withdrawal
					,0 AS Turnover
					,0 AS GGR
					,0 AS Bonus
					,0 AS Rebate
				FROM bodb_12B.dbo.DepositInfo d WITH (NOLOCK)
					INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.CustId = mi.CustId
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@BeginOfMonth, ISNULL(t.ExchangeId, mi.Currency), @BaseExchangeId) e
				WHERE d.Status = 3 -- Approved
					AND d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index with pre-calculated DATE variables
					AND DATEADD(HOUR, 8, d.CreateTime) >= @BeginOfMonth
					AND DATEADD(HOUR, 8, d.CreateTime) < @ToNextMonth
					AND mi.AffId = @AffId
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
						WHERE mr.CustId = d.CustId AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY d.CustId
			)
			INSERT INTO #tmpData (CustId, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate)
			SELECT 
				COALESCE(h.CustId, d.CustId) AS CustId
				,ISNULL(d.Deposit, 0) AS Deposit  -- Only deposits from DepositInfo
				,ISNULL(h.Withdrawal, 0) AS Withdrawal
				,ISNULL(h.Turnover, 0) AS Turnover
				,ISNULL(h.GGR, 0) AS GGR
				,ISNULL(h.Bonus, 0) AS Bonus
				,ISNULL(h.Rebate, 0) AS Rebate
			FROM CTE_Historical h
				FULL OUTER JOIN CTE_RecentDeposit d ON h.CustId = d.CustId
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
	ORDER BY r.RN

	DROP TABLE #tmpData
END
GO