/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_PlayersDetail_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@FromDate		SMALLDATETIME
	,@ToDate		SMALLDATETIME
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
		- 20250815@Sally: Add date picker functionality [RedmineID: #236120]
		- 20251002@Sophia: Implement hybrid approach using rptMemberDaily for historical data and DepositInfo for recent data based on commission date boundary [RedmineID: #239737]
		
	Param's Explanation:
		- @FromDate:	Start date of the range
		- @ToDate:		End date of the range
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
	  - rptMemberDaily.WinlostDate is in GMT+8
	  - bodb_12B.dbo.DepositInfo.CreateTime is in GMT+0
	  - bodb_12B.dbo.DepositInfo.WinlostDate is indexed (Date of CreateTime)
	  - Data separation: rptMemberDaily for historical data (before commission boundary), DepositInfo for recent data (after commission boundary)
	  - Commission boundary = @CommissionBoundary = AFF_CommissionDate + 1 day

	Example:
		EXEC dbo.Aff_Admin_PlayersDetail_Sel 
			@AffId = 123, 
			@FromDate = '2025-07-15', 
			@ToDate = '2025-08-15',
			@ProductId = 0,
			@PageIndex = 1,
			@PageSize = 20;
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffCurrency INT, @Rate FLOAT
	SELECT  @AffCurrency = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffCurrency'

	--Get AffCurrency mapping
	DECLARE @AffExchangeId INT = @AffCurrency
	SELECT @AffExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @AffCurrency

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

	-- Calculate commission date boundary for data separation
	DECLARE @CommissionBoundary SMALLDATETIME
	SELECT @CommissionBoundary = DATEADD(DAY, 1, CONVERT(SMALLDATETIME, SValue)) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'
	
	-- Pre-calculate DATE variables for WinlostDate index optimization
	DECLARE @WinlostDateFrom DATE, @WinlostDateTo DATE
	SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @FromDate))
	SELECT @WinlostDateTo = DATEADD(DAY, 1, CONVERT(DATE, @ToDate))
	
	CREATE TABLE #tmpData (
		CustId INT, 
		Deposit MONEY, 
		Withdrawal MONEY, 
		Turnover MONEY, 
		GGR MONEY, 
		Bonus MONEY, 
		Rebate MONEY,
		DepositFee MONEY,
		WithdrawalFee MONEY
	)

	-- Get list of months within date range (end of month dates)
	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME)
	
	;WITH CTE_MonthDate AS (
		SELECT EOMONTH (@FromDate) AS MonthDate
		UNION ALL
		SELECT EOMONTH(DATEADD(MONTH,1, MonthDate))
		FROM CTE_MonthDate
		WHERE MonthDate <= EOMONTH(DATEADD(MONTH,-1, @ToDate))
	)
	INSERT INTO @MonthDate (MonthDate)
	SELECT md.MonthDate
	FROM CTE_MonthDate md
	OPTION (MAXRECURSION 0)

	-- Create temporary table to store deduction settings for each month in date range
	;WITH CTE_DeductionSettings AS (
		SELECT 
			ml.MonthDate,
			SUM(CASE WHEN dsh.DeductionID = 13 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE 0 END) AS DepositRate,
			SUM(CASE WHEN dsh.DeductionID = 13 THEN ISNULL(dsh.DeductedAmount, 0) ELSE 0 END) AS DepositAmount,
			SUM(CASE WHEN dsh.DeductionID = 14 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE 0 END) AS WithdrawalRate,
			SUM(CASE WHEN dsh.DeductionID = 14 THEN ISNULL(dsh.DeductedAmount, 0) ELSE 0 END) AS WithdrawalAmount
		FROM @MonthDate ml
			INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON agh.MonthDate = ml.MonthDate AND agh.AffID = @AffId
			INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId 
																		AND agh.MonthDate = dsh.MonthDate
																		AND dsh.DeductionID IN (13, 14)
		GROUP BY ml.MonthDate
	)
	SELECT 
		ds.MonthDate,
		ds.DepositRate,
		ds.DepositAmount * er.Rate AS DepositAmount,
		ds.WithdrawalRate,
		ds.WithdrawalAmount * er.Rate AS WithdrawalAmount
	INTO #tmpDeductionSettings
	FROM CTE_DeductionSettings ds
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(ds.MonthDate, @AffExchangeId, @BaseExchangeId) er						

	DECLARE @Products TABLE (ProductId INT)
	
	-- Get products based on the months in date range
	INSERT INTO @Products (ProductId)
	SELECT p.ProductId
	FROM dbo.Products p WITH (NOLOCK)

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
	
	-- Get data player detail using hybrid approach: 2 CTE blocks for Deposit (historical + recent), rptMemberDaily for other columns
	BEGIN
		-- Get all other metrics from rptMemberDaily (Withdrawal, Bonus, Rebate, Turnover, GGR)
		;WITH CTE_RptMemberData AS (
			SELECT 
				EOMONTH(r.winlostDate) AS MonthDate
				,r.CustId
				,r.Currency
				,0 AS Deposit  -- No deposits from rptMemberDaily in hybrid approach
				,SUM(ISNULL(r.Withdrawal, 0))	AS Withdrawal
				,SUM(ISNULL(r.Bonus, 0))		AS Bonus
				,SUM(ISNULL(r.Rebate, 0))		AS Rebate
				,SUM(ISNULL(r.Turnover, 0)) 	AS Turnover
				,SUM(ISNULL(-(r.Winloss - ISNULL(ProgressiveWin, 0)) - ISNULL(ProgressiveBet, 0), 0)) AS GGR
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
				INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON r.CustId = m.CustId
				LEFT JOIN @Products p ON r.ProductId = p.ProductId
			WHERE r.WinlostDate BETWEEN @FromDate AND @ToDate
				AND r.AffId = @AffId
				AND (m.IsRemoved = 0 OR @IsIncludeRemovedPlayer = 1)
				AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
				AND (@ListCurrencies = '' OR ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%')
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
					WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
				)
			GROUP BY EOMONTH(r.winlostDate), r.CustId, r.Currency
		),
		CTE_HistoricalDeposit AS (
			-- Historical deposit data from rptMemberDaily (before commission boundary)
			SELECT 
				EOMONTH(r.winlostDate) AS MonthDate
				,r.CustId
				,r.Currency
				,SUM(ISNULL(r.Deposit, 0)) AS Deposit
				,0 AS Withdrawal
				,0 AS Bonus
				,0 AS Rebate
				,0 AS Turnover
				,0 AS GGR
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
				INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON r.CustId = m.CustId
				LEFT JOIN @Products p ON r.ProductId = p.ProductId
			WHERE r.WinlostDate BETWEEN @FromDate AND @ToDate
				AND r.WinlostDate < @CommissionBoundary  -- Historical data only (before commission boundary)
				AND r.AffId = @AffId
				AND (m.IsRemoved = 0 OR @IsIncludeRemovedPlayer = 1)
				AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
				AND (@ListCurrencies = '' OR ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%')
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
					WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
				)
			GROUP BY EOMONTH(r.winlostDate), r.CustId, r.Currency
		),
		CTE_RecentDeposit AS (
			-- Recent deposit data from live DepositInfo (after commission boundary)
			SELECT 
				EOMONTH(DATEADD(HOUR, 8, d.CreateTime)) AS MonthDate  -- Convert GMT+0 to GMT+8
				,mi.CustId
				,mi.Currency
				,SUM(d.ActualDeposit * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) AS Deposit
				,0 AS Withdrawal
				,0 AS Bonus
				,0 AS Rebate
				,0 AS Turnover
				,0 AS GGR
			FROM bodb_12B.dbo.DepositInfo d WITH(NOLOCK)
				INNER JOIN dbo.MemberInfo mi WITH(NOLOCK) ON d.CustId = mi.CustId
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
				LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, mi.Currency) = e.ExchangeId
			WHERE mi.AffId = @AffId
				AND d.Status = 3  -- Approved deposits only
				AND d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index first
				AND DATEADD(HOUR, 8, d.CreateTime) >= @FromDate 
				AND DATEADD(HOUR, 8, d.CreateTime) < DATEADD(DAY, 1, @ToDate)  -- Convert GMT+0 to GMT+8
				AND DATEADD(HOUR, 8, d.CreateTime) >= @CommissionBoundary  -- After commission boundary data
				AND (mi.IsRemoved = 0 OR @IsIncludeRemovedPlayer = 1)
				AND (@ListCurrencies = '' OR ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), mi.Currency) + ',%')
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
					WHERE mr.CustId = d.CustId 
					AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate  -- Convert to GMT+8 for comparison
				)
			GROUP BY EOMONTH(DATEADD(HOUR, 8, d.CreateTime)), mi.CustId, mi.Currency
		),
		CTE_CombinedData AS (
			-- Combine all data using UNION ALL and aggregate
			SELECT 
				MonthDate,
				CustId,
				Currency,
				SUM(Deposit) AS Deposit,
				SUM(Withdrawal) AS Withdrawal,
				SUM(Bonus) AS Bonus,
				SUM(Rebate) AS Rebate,
				SUM(Turnover) AS Turnover,
				SUM(GGR) AS GGR
			FROM (
				SELECT MonthDate, CustId, Currency, Deposit, Withdrawal, Bonus, Rebate, Turnover, GGR FROM CTE_RptMemberData
				UNION ALL
				SELECT MonthDate, CustId, Currency, Deposit, Withdrawal, Bonus, Rebate, Turnover, GGR FROM CTE_HistoricalDeposit
				UNION ALL
				SELECT MonthDate, CustId, Currency, Deposit, Withdrawal, Bonus, Rebate, Turnover, GGR FROM CTE_RecentDeposit
			) combined
			GROUP BY MonthDate, CustId, Currency
			HAVING SUM(Deposit) > 0 OR SUM(Withdrawal) > 0 OR SUM(Bonus) > 0 OR SUM(Rebate) > 0 OR SUM(Turnover) > 0 OR SUM(GGR) > 0
		)
		INSERT INTO #tmpData
		(
			CustId
			,Deposit
			,Withdrawal
			,Bonus
			,Rebate
			,Turnover
			,GGR
			,DepositFee
			,WithdrawalFee
		)
		SELECT 
			r.CustId
			,SUM(r.Deposit * e.Rate) AS Deposit
			,SUM(r.Withdrawal * e.Rate) AS Withdrawal
			,SUM(r.Bonus * e.Rate) AS Bonus
			,SUM(r.Rebate * e.Rate) AS Rebate
			,SUM(r.Turnover * e.Rate) AS Turnover
			,SUM(r.GGR * e.Rate) AS GGR
			,SUM(r.Deposit 		* e.Rate * ISNULL(ds.DepositRate, 0) 	+ ISNULL(ds.DepositAmount, 0)) 	  AS DepositFee
			,SUM(r.Withdrawal 	* e.Rate * ISNULL(ds.WithdrawalRate, 0) + ISNULL(ds.WithdrawalAmount, 0)) AS WithdrawalFee
		FROM CTE_CombinedData r
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.MonthDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
			LEFT JOIN #tmpDeductionSettings ds ON ds.MonthDate = r.MonthDate
		GROUP BY r.CustId;

		DELETE #tmpData WHERE Deposit = 0 AND Withdrawal = 0 AND Bonus = 0 AND Rebate = 0 AND Turnover = 0 AND GGR = 0;

		SELECT @NRows = COUNT(1) FROM #tmpData;
	END

	-- Paging
	DECLARE @RowStart INT, @RowEnd INT;

	IF @IsExportExcel = 0
		SELECT @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1;
	ELSE
		SELECT @RowStart =  1, @RowEnd = @NRows;

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
			,d.DepositFee
			,d.WithdrawalFee
			,ROW_NUMBER() OVER(ORDER BY
				 (CASE WHEN @IsSortAsc = 1 AND @SortById =  1 THEN m.UserName			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  2 THEN m.RegisteredDate		END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  3 THEN d.Deposit			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  4 THEN d.Withdrawal			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  5 THEN d.Turnover			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  6 THEN d.GGR				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  7 THEN d.Bonus				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  8 THEN d.Rebate				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  9 THEN d.DepositFee			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 10 THEN d.WithdrawalFee			END) ASC
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
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  9 THEN d.DepositFee			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 10 THEN d.WithdrawalFee			END) DESC
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
	ORDER BY r.RN ASC;

	DROP TABLE #tmpData;
	DROP TABLE #tmpDeductionSettings;
END
GO