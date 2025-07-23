/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_PlayersDetail_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@MonthDate		SMALLDATETIME
	,@Currencies	VARCHAR(MAX) = ''
	,@BaseCurrency	INT = 0
	,@SortById		TINYINT = 5 -- default
	,@IsSortAsc		BIT = 0 -- default
	,@IsExportExcel	BIT = 0
	,@PageIndex		INT = 1
	,@PageSize		INT = 20
	,@NRows			INT = 0 OUTPUT
	,@IsIncludeRemovedPlayer BIT = 0
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task:
		Admin site - Customer - Players Detail
		Admin site - Customer - Statistics - Click amount of Total Active Players

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250506@Sally: Enhance Removed Player logic [RedmineID: #225717]
		- 20250722@Sophia: Implement hybrid approach using rptMemberDaily for historical data and DepositInfo for last month and current month [RedmineID: #233096]

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
					   11 = IBCUsername
					   12 = First Deposit Date
					   13 = First Deposit Amount
		- @IsSortAsc:	0 = DESC
						1 = ASC
		- @BaseCurrency : Currency of B2C
		- @Currencies : Currency of B2C, 72: represent for USD( currency 72, 3)
		
	Notes:
	  - MemberInfo dates are DateTime in GMT+8
	  - rptMemberDaily.WinlostDate is in GMT+8
	  - bodb_12B.dbo.DepositInfo.CreateTime is in GMT+0
	  - bodb_12B.dbo.DepositInfo.WinlostDate is indexed (Date of CreateTime)
	  - Hybrid approach: rptMemberDaily for historical data (up to month before last month), DepositInfo for Deposit data in last month and current month
*/

BEGIN
	SET NOCOUNT ON

	-- date range for get data whole month of @MonthDate
	DECLARE @BeginOfMonth SMALLDATETIME, @EndOfMonth SMALLDATETIME
	SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @EndOfMonth		= DATEADD(DAY, -1, DATEADD(MONTH, 1, @BeginOfMonth))

	-- Calculate last month start for hybrid approach (convert server GMT-4 to GMT+8)
	DECLARE @LastMonthStart SMALLDATETIME
	SELECT @LastMonthStart = DATEADD(MONTH, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(HOUR, 12, GETDATE())), 0))  -- Start of last month

	-- Pre-calculate DATE variables for WinlostDate index optimization
	DECLARE @WinlostDateFrom DATE, @WinlostDateTo DATE
	SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @BeginOfMonth))
	SELECT @WinlostDateTo = DATEADD(DAY, 1, CONVERT(DATE, DATEADD(MONTH, 1, @BeginOfMonth)))

	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	--Get list currencies maping
	DECLARE @ListCurrencies	VARCHAR(MAX) = ''
	SELECT @ListCurrencies = COALESCE(@ListCurrencies + ',', '') + CONVERT(VARCHAR(20), t.TpExchangeId)
	FROM STRING_SPLIT(@Currencies, ',') f
		CROSS APPLY(
			SELECT TpExchangeId
			FROM dbo.Aff_f_TpExchange_Sel(f.value)
		)t
	
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
		
	IF @ProductId <> 0
	BEGIN
		;WITH CTE_GProducts AS(
			SELECT CONVERT(INT,f.Value) AS ProductId
			FROM STRING_SPLIT(dbo.Aff_f_AddRelatedProducts(CONVERT(VARCHAR(10),@ProductId)), ',')f
		)
		DELETE p
		FROM @Products p
			LEFT JOIN CTE_GProducts gp ON gp.ProductId = p.ProductId
		WHERE gp.ProductId IS NULL
	END
	
	-- Get data using conditional hybrid approach
	BEGIN
		-- Conditional approach: Use rptMemberDaily for historical data (before last month) or hybrid for recent months
		IF @BeginOfMonth < @LastMonthStart
		BEGIN
			-- Historical data only from rptMemberDaily (for months before last month)
			INSERT INTO #tmpData
			(
				CustId
				,Deposit
				,Withdrawal
				,Bonus
				,Rebate
				,Turnover
				,GGR
			)
			SELECT r.CustId
				,SUM(ISNULL(r.Deposit * e.Rate, 0))		AS Deposit
				,SUM(ISNULL(r.Withdrawal * e.Rate, 0))	AS Withdrawal
				,SUM(ISNULL(r.Bonus * e.Rate, 0))		AS Bonus
				,SUM(ISNULL(r.Rebate * e.Rate, 0))		AS Rebate
				,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END * e.Rate, 0)) AS Turnover
				,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
								ELSE -(r.Winloss - ISNULL(ProgressiveWin, 0)) - ISNULL(ProgressiveBet, 0) END * e.Rate, 0)) AS GGR
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
				INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON r.CustId = m.CustId
				LEFT JOIN @Products p ON r.ProductId = p.ProductId
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@BeginOfMonth, ISNULL(T.ExchangeId,r.Currency), @BaseExchangeId) e
			WHERE r.WinlostDate BETWEEN @BeginOfMonth AND @EndOfMonth
				AND r.AffId = @AffId
				AND (m.IsRemoved = 0 OR @IsIncludeRemovedPlayer = 1)
				AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
					WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate 
				)
				AND (@ListCurrencies = '' OR ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%')
			GROUP BY r.CustId
		END
		ELSE
		BEGIN
			-- Hybrid approach: Use DepositInfo for Deposit only (ProductId <= 0), and rptMemberDaily for other data
			;WITH CTE_RptData AS(
				-- Data from rptMemberDaily (set Deposit to 0, include other data normally)
				SELECT r.CustId
					,SUM(ISNULL(r.Withdrawal * e.Rate, 0)) AS Withdrawal  -- Include all withdrawals
					,SUM(ISNULL(r.Bonus * e.Rate, 0)) AS Bonus
					,SUM(ISNULL(r.Rebate * e.Rate, 0)) AS Rebate
					,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END * e.Rate, 0)) AS Turnover
					,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
									ELSE -(r.Winloss - ISNULL(ProgressiveWin, 0)) - ISNULL(ProgressiveBet, 0) END * e.Rate, 0)) AS GGR
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON r.CustId = m.CustId
					LEFT JOIN @Products p ON r.ProductId = p.ProductId
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@BeginOfMonth, ISNULL(T.ExchangeId,r.Currency), @BaseExchangeId) e
				WHERE r.WinlostDate BETWEEN @BeginOfMonth AND @EndOfMonth
					AND r.AffId = @AffId
					AND (m.IsRemoved = 0 OR @IsIncludeRemovedPlayer = 1)
					AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
						WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate 
					)
					AND (@ListCurrencies = '' OR ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%')
				GROUP BY r.CustId
			),
			CTE_DepositData AS(
				-- Deposit data from live DepositInfo only
				SELECT mi.CustId
					,SUM(d.Amount * er.Rate) AS Deposit
				FROM bodb_12B.dbo.DepositInfo d WITH(NOLOCK)
					INNER JOIN dbo.MemberInfo mi WITH(NOLOCK) ON d.CustId = mi.CustId
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@BeginOfMonth, ISNULL(t.ExchangeId, mi.Currency), @BaseExchangeId) er
				WHERE mi.AffId = @AffId
					AND d.Status = 3  -- Approved deposits only
					AND d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index first
					AND DATEADD(HOUR, 8, d.CreateTime) BETWEEN @BeginOfMonth AND DATEADD(DAY, 1, @EndOfMonth)  -- Convert GMT+0 to GMT+8
					AND (mi.IsRemoved = 0 OR @IsIncludeRemovedPlayer = 1)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
						WHERE mr.CustId = d.CustId 
						AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate  -- Convert to GMT+8 for comparison
					)
					AND (@ListCurrencies = '' OR ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), mi.Currency) + ',%')
				GROUP BY mi.CustId
			)
			INSERT INTO #tmpData (CustId, Deposit, Withdrawal, Bonus, Rebate, Turnover, GGR)
			SELECT 
				COALESCE(r.CustId, d.CustId) AS CustId
				,ISNULL(d.Deposit, 0) AS Deposit  -- Only deposits from DepositInfo
				,ISNULL(r.Withdrawal, 0) AS Withdrawal
				,ISNULL(r.Bonus, 0) AS Bonus
				,ISNULL(r.Rebate, 0) AS Rebate
				,ISNULL(r.Turnover, 0) AS Turnover
				,ISNULL(r.GGR, 0) AS GGR
			FROM CTE_RptData r
				FULL OUTER JOIN CTE_DepositData d ON r.CustId = d.CustId
		END

		DELETE #tmpData WHERE Deposit = 0 AND Withdrawal = 0 AND Bonus = 0 AND Rebate = 0 AND Turnover = 0 AND GGR = 0

		SELECT @NRows = COUNT(1) FROM #tmpData

		-- Banking Fee
		DECLARE @DepositRate DECIMAL(9, 8) = 0, @DepositAmount MONEY = 0
			,@WithdrawalRate DECIMAL(9, 8) = 0, @WithdrawalAmount MONEY = 0
		
		IF EXISTS (SELECT 1 FROM #tmpData WHERE Deposit + Withdrawal > 0)
		BEGIN
			SELECT
				@DepositRate = CASE WHEN DeductionID = 13 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE @DepositRate END
				,@DepositAmount = CASE WHEN DeductionID = 13 THEN ISNULL(dsh.DeductedAmount, 0) ELSE @DepositAmount END
				,@WithdrawalRate = CASE WHEN DeductionID = 14 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE @WithdrawalRate END
				,@WithdrawalAmount = CASE WHEN DeductionID = 14 THEN ISNULL(dsh.DeductedAmount, 0) ELSE @WithdrawalAmount END
			FROM dbo.AffGroupHistory agh WITH (NOLOCK)
				INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId AND agh.MonthDate = dsh.MonthDate
			WHERE dsh.DeductionID IN (13, 14)
				AND agh.MonthDate = @EndOfMonth
				AND agh.AffID = @AffId

			SELECT @DepositRate = ISNULL(@DepositRate, 0), @DepositAmount = ISNULL(@DepositAmount, 0)
				,@WithdrawalRate = ISNULL(@WithdrawalRate, 0), @WithdrawalAmount = ISNULL(@WithdrawalAmount, 0)

			IF @BaseCurrency <> 0
			BEGIN
				DECLARE @AffCurrency INT, @Rate FLOAT
				SELECT  @AffCurrency = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffCurrency'

				--Get AffCurrency mapping
				DECLARE @AffExchangeId INT = @AffCurrency
				SELECT @AffExchangeId = t.ExchangeId
				FROM dbo.TpExchange t WITH (NOLOCK)
				WHERE t.TpExchangeId = @AffCurrency

				SELECT  @Rate = Rate FROM dbo.Aff_f_ExchangeRate_Sel(@EndOfMonth, @AffExchangeId, @BaseExchangeId)
			
				SELECT  @DepositAmount = @DepositAmount * @Rate
						,@WithdrawalAmount = @WithdrawalAmount * @Rate
			END
		END
	END

	-- Paging
	DECLARE @RowStart INT, @RowEnd INT

	IF @IsExportExcel = 0
		SELECT @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1
	ELSE
		SELECT @RowStart =  1, @RowEnd = @NRows

	SELECT CustId, UserName, IBCUserName, RegisteredDate, FirstDepositDate, FirstDepositAmount, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, DepositFee, WithdrawalFee
	FROM
	(
		SELECT
			m.CustId
			,m.UserName
			,m.IBCUserName
			,m.RegisteredDate
			,m.FirstDepositDate
			,CONVERT(MONEY, m.FirstDepositAmount * ISNULL(e.Rate, 0)) AS FirstDepositAmount
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
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 11 THEN m.IBCUserName		END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 12 THEN m.FirstDepositDate	END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 13 THEN m.FirstDepositAmount * ISNULL(e.Rate, 0)	END) ASC
				
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
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 11 THEN m.IBCUserName		END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 12 THEN m.FirstDepositDate	END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 13 THEN m.FirstDepositAmount * ISNULL(e.Rate, 0)	END) DESC
			) AS RN
		FROM #tmpData d
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.CustId = m.CustId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON m.currency = t.TpExchangeId
			OUTER APPLY dbo.Aff_f_ExchangeRate_Sel(m.FirstDepositDate, ISNULL(t.ExchangeId, m.currency), @BaseExchangeId) e
	) r
	WHERE r.RN BETWEEN @RowStart AND @RowEnd
	ORDER BY r.RN

	DROP TABLE #tmpData
END
GO