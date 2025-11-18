/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Overview_PlayersDetail_Sel]
	@AffId			INT
	,@FromDate		SMALLDATETIME
	,@ToDate		SMALLDATETIME
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

	-- Calculate commission date boundary for data separation (commission date + 1 day)
	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	-- Get list of months within date range (end of month dates)
	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME)
	
	;WITH CTE_MonthDate AS (
		SELECT EOMONTH (@FromDate) AS MonthDate
		UNION ALL
		SELECT EOMONTH(DATEADD(MONTH, 1, MonthDate))
		FROM CTE_MonthDate
		WHERE MonthDate <= EOMONTH(DATEADD(MONTH, -1, @ToDate))
	)
	INSERT INTO @MonthDate (MonthDate)
	SELECT md.MonthDate
	FROM CTE_MonthDate md
	OPTION (MAXRECURSION 0)

	-- GroupTypeId
	DECLARE @GroupTypeId INT

	-- @GroupTypeId
	SELECT @GroupTypeId = SUM(DISTINCT cg.GroupTypeId)
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON agh.GroupId = cg.GroupId
	WHERE agh.AffId = @AffId
		AND agh.FromDate <= @ToDate
		AND agh.ToDate >= @FromDate
  
	SET @GroupTypeId = ISNULL(IIF(@GroupTypeId > 4, 4, @GroupTypeId),1)

	-- Create temporary table to store intermediate data
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
	CREATE TABLE #tmpDeductionSettings (
		MonthDate SMALLDATETIME,
		Dep_IsDeductedPercent TINYINT,
		DepositRate FLOAT,
		DepositAmount MONEY,
		WithdrawalRate FLOAT,
		WithdrawalAmount MONEY,
		Wit_IsDeductedPercent TINYINT
	)
	IF(@GroupTypeId <> 3)  -- Not CPA Only
	BEGIN
	-- Create temporary table to store deduction settings for each month in date range
		;WITH CTE_DeductionSettings AS (
			SELECT 
				ml.MonthDate,
				IIF(dsh.DeductionID = 13 AND dsh.IsDeductedPercent = 1, 1, 0) AS Dep_IsDeductedPercent,
				IIF(dsh.DeductionID = 14 AND dsh.IsDeductedPercent = 1, 1, 0) AS Wit_IsDeductedPercent,
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
					,IIF(dsh.DeductionID = 13 AND dsh.IsDeductedPercent = 1, 1, 0)
					,IIF(dsh.DeductionID = 14 AND dsh.IsDeductedPercent = 1, 1, 0)
		)
		INSERT INTO #tmpDeductionSettings (
			MonthDate,
			Dep_IsDeductedPercent,
			DepositRate,
			DepositAmount,
			WithdrawalRate,
			WithdrawalAmount,
			Wit_IsDeductedPercent
		)
		SELECT 
			ds.MonthDate,
			ds.Dep_IsDeductedPercent,
			ds.DepositRate,
			ds.DepositAmount * er.Rate AS DepositAmount,
			ds.WithdrawalRate,
			ds.WithdrawalAmount * er.Rate AS WithdrawalAmount,
			ds.Wit_IsDeductedPercent
		FROM CTE_DeductionSettings ds
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(ds.MonthDate, @AffExchangeId, @BaseExchangeId) er
		
		DECLARE @Dep_IsDeductedPercent BIT, @Wit_IsDeductedPercent BIT
		SELECT @Dep_IsDeductedPercent = IIF(MAX(Dep_IsDeductedPercent) = 1, 1, 0)
				,@Wit_IsDeductedPercent = IIF(MAX(Wit_IsDeductedPercent) = 1, 1, 0)
		FROM #tmpDeductionSettings d

	END
	-- Create #DataByMonth table to store monthly aggregated data
	CREATE TABLE #DataByMonth (
		MonthDate SMALLDATETIME,
		CustId INT,
		Currency INT,
		Deposit MONEY DEFAULT(0),
		Withdrawal MONEY DEFAULT(0),
		Bonus MONEY DEFAULT(0),
		Rebate MONEY DEFAULT(0),
		Turnover MONEY DEFAULT(0),
		GGR MONEY DEFAULT(0)
	)
	INSERT INTO #DataByMonth (
		MonthDate,
		CustId,
		Currency,
		Withdrawal,
		Bonus,
		Rebate,
		Turnover,
		GGR,
		Deposit
	)
	SELECT 
		EOMONTH(r.winlostDate) AS MonthDate
		,r.CustId
		,r.Currency
		,SUM(ISNULL(r.Withdrawal, 0))	AS Withdrawal
		,SUM(ISNULL(r.Bonus, 0))		AS Bonus
		,SUM(ISNULL(r.Rebate, 0))		AS Rebate
		,SUM(ISNULL(r.Turnover, 0)) 	AS Turnover
		,SUM(ISNULL(-(r.Winloss - ISNULL(ProgressiveWin, 0)) - ISNULL(ProgressiveBet, 0), 0)) AS GGR
		,SUM(CASE WHEN r.ProductId = -1 AND r.WinlostDate <= @MaxCommDate THEN ISNULL(r.Deposit, 0) ELSE 0 END) AS Deposit -- only get Deposit data  <= @MaxCommDate
	FROM dbo.rptMemberDaily r WITH (NOLOCK)
		INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON r.CustId = m.CustId
	WHERE r.WinlostDate BETWEEN @FromDate AND @ToDate
		AND r.AffId = @AffId
		AND NOT EXISTS (
			SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
			WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
		)
	GROUP BY EOMONTH(r.winlostDate), r.CustId, r.Currency

	IF (@ToDate > @MaxCommDate)
	BEGIN
			-- Prepare date range for DepositInfo filtering
			DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME
				,@FDateGMT0 SMALLDATETIME, @TDateGMT0 SMALLDATETIME
				,@WinlostDateFrom DATE, @WinlostDateTo DATE
				
			SELECT @FDate	= CASE WHEN @FromDate <= @MaxCommDate THEN DATEADD(DAY, 1, @MaxCommDate) ELSE @FromDate END
			SELECT @TDate	= @ToDate

			-- Pre-calculate DATE variables for WinlostDate index optimization
			SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @FDate))
			SELECT @WinlostDateTo = DATEADD(DAY, 1, CONVERT(DATE, @TDate))

			--GMT0 date range for DepositInfo filtering
			SELECT @FDateGMT0 = DATEADD(HOUR, -8, @FDate)
			SELECT @TDateGMT0 = DATEADD(HOUR, -8, DATEADD(DAY, 1, @TDate))  -- +1 day to make it < next day

			INSERT INTO #DataByMonth (MonthDate, CustId, Currency, Deposit)
			SELECT 
				EOMONTH(DATEADD(HOUR, 8, d.CreateTime)) AS MonthDate  -- Convert GMT+0 to GMT+8
				,mi.CustId
				,mi.Currency
				,SUM(d.ActualDeposit * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) AS Deposit
			FROM bodb_12B.dbo.DepositInfo d WITH(NOLOCK)
				INNER JOIN dbo.MemberInfo mi WITH(NOLOCK) ON d.CustId = mi.CustId
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
				LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, mi.Currency) = e.ExchangeId
			WHERE mi.AffId = @AffId
				AND d.Status = 3  -- Approved deposits only
				AND d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index first
				AND d.CreateTime >= @FDateGMT0
				AND d.CreateTime < @TDateGMT0
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
					WHERE mr.CustId = d.CustId 
					AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate  -- Convert to GMT+8 for comparison
				)
			GROUP BY EOMONTH(DATEADD(HOUR, 8, d.CreateTime)), mi.CustId, mi.Currency

	END
	-- Aggregate data from #DataByMonth into #tmpData with currency conversion and fee calculations
	BEGIN
		;WITH CTE_SumData AS(
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
			FROM #DataByMonth
			GROUP BY MonthDate, CustId, Currency
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
		FROM CTE_SumData r
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.MonthDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
			LEFT JOIN #tmpDeductionSettings ds ON ds.MonthDate = r.MonthDate
		GROUP BY r.CustId;

		DELETE #tmpData WHERE Deposit = 0 AND Withdrawal = 0 AND Bonus = 0 AND Rebate = 0 AND Turnover = 0 AND GGR = 0;

		SELECT @NRows = COUNT(1) FROM #tmpData;
	END

	-- Paging
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1
	
	-- Return GroupTypeId flag
	SELECT @GroupTypeId AS GroupTypeId,
			@Dep_IsDeductedPercent AS Dep_IsDeductedPercent,
			@Wit_IsDeductedPercent AS Wit_IsDeductedPercent;

	SELECT CustId, UserName, RegisteredDate, FirstDepositDate, FirstDepositAmount, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, DepositFee, WithdrawalFee
	FROM(
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
		FROM #tmpData r
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON r.CustId = m.CustId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON m.Currency = t.TpExchangeId
			OUTER APPLY dbo.Aff_f_ExchangeRate_Sel (m.FirstDepositDate, ISNULL(t.ExchangeId, m.Currency), @BaseExchangeId) e
	) AS r
	WHERE r.RN BETWEEN @RowStart AND @RowEnd
	ORDER BY r.RN ASC

	DROP TABLE #tmpData;
	DROP TABLE #tmpDeductionSettings;
	DROP TABLE #DataByMonth;
END
GO