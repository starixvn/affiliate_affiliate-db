/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateReport_Sel]
	@Username			NVARCHAR(50) = NULL
	,@GroupIds 			VARCHAR(MAX) = ''
	,@FromDate			SMALLDATETIME
	,@ToDate			SMALLDATETIME
	,@PreferredLanguage	VARCHAR(11) = NULL
	,@Statuses			VARCHAR(MAX)	= 'Approved'
	,@ProductIds		VARCHAR(MAX) = '0'
	,@Currencies		VARCHAR(MAX) = ''
	,@PaymentCurrencies	VARCHAR(MAX) = 'all'
	,@BaseCurrency		INT = 0
	,@SortType			TINYINT = 1
	,@SortDirectionType	BIT = 0
	,@IsExcludeNegvBBF			BIT = 0
	,@IsExcludeNegvCurrentBBF	BIT = 0
	,@IsExportExcel		BIT = 0
	,@IsGetMonthly      BIT = 1
	,@PageIndex			INT = 1
	,@PageSize			INT = 50
	,@NRows				INT = 0 OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Report - Affiliate Report

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241225@Sally: Apply QM Turnover [RedmineID: #212201]
		- 20250218@Eddie: Enhance SP [RedmineID: #218047]
		- 20250314@Sally: Display Qualified Players if using Date Picker [RedmineID: #220322]
		- 20250314@Sally: Add an additional Language column [RedmineID: #220316]
        - 20250326@Sally: Add new column FDAM Amount, Status [RedmineID: #220316]
		- 20250327@Sally: Change get AFFWithdrawal [RedmineID: #222217]
		- 20250331@Sally: Add Sort by Signup, FDM, FDM Amt, Active players and Qualified active players [RedmineID: #221783]
		- 20250402@Sophia: Fix Unique Click count IP by range from - to [RedmineID: #222777]
		- 20250415@Sally: Change the data retrieval method for Deposit [RedmineID: #224116]
        - 20250417@Sally: Add Revenue Group column [RedmineID: #224286]
		- 20250418@Sally: Enhance get BBF by TimeZone [RedmineID: #222352]
        - 20250420@Sally: Add FDM_TotalDeposit column [RedmineID: #224709]
		- 20250506@Sophia: Fix IP handling in UniqueClick [RedmineID: #225820] 
		- 20250516@Sally: Get correct Date for FDM's Total Deposit [RedmineID: #227685]
		- 20250516@Sally: Fix Get BBF [RedmineID: #227716]
		- 20250812@Sally: Enhance conditions to view data of marketing affiliate accounts [RedmineID: #235773]
		- 20251002@Sophia: Implement hybrid approach using rptMemberDaily for historical data and DepositInfo for recent data based on commission date boundary [RedmineID: #239737]
		- 20251022@Sophia: Add IsExcluded = 0 condition to filter excluded clicks [RedmineID: #241768]
		- 20250825@Lewis: Enhance report - add column related to CPA [RedmineID: #236665]

	Param's Explanation:
		- @SortType: 
			1: Affiliate username
			2: Turnover
			3: GGR
			4: Earning (Commission)
			5: SignUp
			6: FDM
			7: FDM Amount
			8: Active Players
			9: Qualified Members
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
		- @ProductIds: list of products
		- @BaseCurrency : Currency of B2C
		- @Currencies : Currency of B2C, 72: represent for USD( currency 72, 3)
		- @PaymentCurrencies : Currency of B2C, 72: represent for USD( currency 72, 3)
        - @Statuses : Approved, Suspended

*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @IsExcludeAFFTest	BIT = 1
		,@EndOfCurrentMonth		SMALLDATETIME
		,@NoOfMonth				INT
		,@TimeZone				SMALLINT
		,@LastDayOfToDate		SMALLDATETIME
		,@StartDayOfFromDate	SMALLDATETIME
		,@FromDate_Local		DATETIME
		,@ToDate_Local			DATETIME
	
    DECLARE @Status TABLE ([Status] VARCHAR(30))
	INSERT INTO @Status ([Status]) 
	SELECT TRIM(CONVERT(VARCHAR(30), value)) AS [Status]
	FROM STRING_SPLIT(@Statuses, ',') 

	SELECT  @TimeZone = CONVERT(SMALLINT, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'TimeZone'
		
	IF (@IsExcludeNegvBBF = 0 AND @IsExcludeNegvCurrentBBF = 0)
	BEGIN
		SET @IsExcludeAFFTest = 0
	END

	IF @FromDate IS NULL OR @ToDate IS NULL
		RETURN;

	SELECT  @Username		 = ISNULL(TRIM(@Username), ''), @PreferredLanguage = ISNULL(@PreferredLanguage, ''), @GroupIds = ISNULL(@GroupIds, '')
		,@EndOfCurrentMonth	 = EOMONTH(GETDATE())	
		,@StartDayOfFromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0)
		,@LastDayOfToDate	 = EOMONTH(@ToDate)

	IF (@IsGetMonthly = 1)
	BEGIN
		SELECT  @FromDate	= @StartDayOfFromDate -- Begin Of Month
		SELECT  @ToDate		= @LastDayOfToDate  -- End Of Month
	END

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'


	-- Calculate last month start for hybrid approach (convert server GMT-4 to GMT+8)
	-- Calculate commission date boundary for data separation (MaxCommDate + 1 day)
	DECLARE @CommissionBoundary SMALLDATETIME
	SELECT @CommissionBoundary = DATEADD(DAY, 1, @MaxCommDate)

	-- Pre-calculate DATE variables for WinlostDate index optimization
	DECLARE @WinlostDateFrom DATE, @WinlostDateTo DATE,  @FDateGMT0 SMALLDATETIME, @TDateGMT0 SMALLDATETIME

	IF(@ToDate >= @CommissionBoundary)
	BEGIN
		DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME
		SELECT @FDate	= CASE WHEN @FromDate <= @MaxCommDate THEN DATEADD(DAY, 1, @MaxCommDate) ELSE @FromDate END
		SELECT @TDate	= @ToDate

		-- Pre-calculate DATE variables for WinlostDate index optimization
		SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @FDate))
		SELECT @WinlostDateTo = DATEADD(DAY, 1, CONVERT(DATE, @TDate))

		--GMT0 date range for DepositInfo filtering		
		SELECT @FDateGMT0 = DATEADD(HOUR, -@TimeZone, @FDate)
		SELECT @TDateGMT0 = DATEADD(HOUR, -@TimeZone, DATEADD(DAY, 1, @TDate))  -- +1 day to make it < next day

	END

	SELECT @NoOfMonth = DATEDIFF(MONTH, @FromDate, @ToDate) + 1
	
	IF @NoOfMonth <= 0
		RETURN;

	IF @ToDate > @EndOfCurrentMonth
		SELECT @ToDate = @EndOfCurrentMonth

	DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

	-- AffCurrency
	DECLARE @AffCurrency INT
	SELECT  @AffCurrency = dbo.Aff_f_GetSetting('AffCurrency')

	-- Get affcurrency mapping
	DECLARE @AffExchangeId INT = @AffCurrency
	SELECT  @AffExchangeId = tp.ExchangeId
	FROM dbo.TpExchange tp WITH (NOLOCK)
	WHERE tp.TpExchangeId = @AffCurrency

	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	--Get list payment currency mapping TpExchange
	DECLARE @ListPaymentCurrencies	VARCHAR(MAX) = @PaymentCurrencies
	IF (@ListPaymentCurrencies <> 'all')
	BEGIN
		SELECT @ListPaymentCurrencies = COALESCE(@ListPaymentCurrencies + ',', '') + CONVERT(VARCHAR(20), t.TpExchangeId)
		FROM STRING_SPLIT(@PaymentCurrencies, ',') f
			CROSS APPLY(
				SELECT TpExchangeId
				FROM dbo.Aff_f_TpExchange_Sel(f.value)
		)t
	END

	/*
		===== Get Filter Affiliate =====
	*/
	DECLARE @Aff TABLE(AffId INT PRIMARY KEY);
	DECLARE @AffIds VARCHAR(MAX) = 'all'
	IF (ISNULL(@Username,'') <> '')
	BEGIN
		INSERT INTO @Aff(AffId)
		SELECT a.AffId
		FROM dbo.AffInfo a WITH (NOLOCK) 
		WHERE (Username LIKE '%' + @Username + '%' OR @Username IS NULL)
			AND Status NOT IN ('Pending', 'Disapproved')

		SELECT @AffIds = COALESCE(@AffIds + ',', '') + CONVERT(VARCHAR(20), AffId)
		FROM @Aff	
	END
	/*
		===== Get data =====
	*/
	BEGIN
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
		CREATE NONCLUSTERED INDEX IX_TempCommission_Aff ON #TempCommission (AffId)

		IF (@FromDate <= @MaxCommDate) AND (@IsGetMonthly = 1)
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
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END

		IF (@ToDate > @MaxCommDate) AND (@IsGetMonthly = 1)
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
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1;
		END

		IF(@IsGetMonthly = 0)
		BEGIN
				-- Get Product List		
			DECLARE @Products TABLE (ProductId INT)
			SET @ProductIds = dbo.Aff_f_AddRelatedProducts(@ProductIds)
			INSERT INTO @Products (ProductId)
			SELECT ProductId FROM dbo.Products WITH (NOLOCK) 
			WHERE ProductId IN (SELECT CONVERT(INT,value) AS ProductID FROM STRING_SPLIT(@ProductIds, ','))

			CREATE TABLE #DataMemberDaily (MonthDate SMALLDATETIME, AffId INT, Currency INT, CustId INT, ProductId INT, Bonus MONEY, Rebate MONEY, Turnover MONEY, Winloss MONEY)
			CREATE CLUSTERED INDEX IX_DataMemberDaily ON #DataMemberDaily (AffId, MonthDate)
			;WITH CTE_rptMemberDailyData AS(
				SELECT CONVERT(DATE, EOMONTH(r.WinlostDate)) AS MonthDate
					,r.AffId
					,Currency
					,CustId
					,r.ProductId
					,SUM(ISNULL(Bonus, 0))		AS Bonus
					,SUM(ISNULL(Rebate, 0))		AS Rebate
					,SUM(ISNULL(Turnover, 0))	AS Turnover
					,SUM(ISNULL(Winloss, 0) - ISNULL(ProgressiveWin, 0) + ISNULL(ProgressiveBet, 0)) AS Winloss				
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
				WHERE r.WinlostDate >= @FromDate 
					AND r.WinlostDate < DATEADD(DAY, 1, @ToDate)
					AND (@AffIds='all' OR EXISTS (SELECT 1 FROM @Aff a WHERE a.AffId = r.AffId))
					AND NOT EXISTS (
						SELECT TOP 1 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
						WHERE mr.CustId = r.custid AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)			
				GROUP BY CONVERT(DATE, EOMONTH(r.WinlostDate))
					,r.AffId
					,Currency
					,CustId
					,r.ProductId
			)
			INSERT INTO #DataMemberDaily
			(
				MonthDate,
				AffId,
				Currency,
				CustId,
				ProductId,
				Bonus,
				Rebate,
				Turnover,
				Winloss
			)

			SELECT d.MonthDate
				,d.AffId
				,Currency
				,CustId
				,d.ProductId
				,Bonus * e.Rate AS Bonus
				,Rebate * e.Rate AS Rebate
				,Turnover * e.Rate AS Turnover
				,Winloss * e.Rate AS Winloss
			FROM CTE_rptMemberDailyData d					
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON d.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(d.MonthDate, ISNULL(t.ExchangeId, d.Currency), @BaseExchangeId) e
			WHERE EXISTS (SELECT TOP 1 1 FROM @Products p WHERE d.ProductId = p.ProductId)
				OR d.ProductId = -1

			-- Get QM Turnover for Affiliates
			CREATE TABLE #temp_AffInfo (AffId INT,MonthDate SMALLDATETIME, GroupId INT, QMTurnover MONEY)
			CREATE CLUSTERED INDEX IX_temp_AffInfo_AffId_MonthDate ON #temp_AffInfo (AffId, MonthDate)

			INSERT INTO #temp_AffInfo (AffId, MonthDate, GroupId, QMTurnover)
				SELECT a.AffId, agh.MonthDate, agh.GroupId, ISNULL(cg.QMTurnover, 0) * e.Rate AS QMTurnover
				FROM (
					SELECT DISTINCT AffId, MonthDate FROM #DataMemberDaily
				)a
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON a.AffId = agh.AffId AND agh.MonthDate = a.MonthDate				
				INNER JOIN dbo.CommGroupHistory cg WITH (NOLOCK) ON agh.GroupId = cg.GroupId AND agh.MonthDate = cg.MonthDate
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(a.MonthDate, @AffExchangeId, @BaseExchangeId) e
				
			;WITH CTE_DataResult AS(
				SELECT  r.AffId
					,SUM(r.Bonus) AS Bonus
					,SUM(r.Rebate) AS Rebate
					,SUM(r.Turnover) AS Turnover
					,SUM(r.Winloss)	AS Winloss
					,- SUM(r.Winloss) AS GrossWinloss
				FROM #DataMemberDaily r					
				GROUP BY r.AffId
			)
			, CTE_QualifieldMember AS (
				SELECT r.AffId, r.MonthDate, COUNT(DISTINCT IIF(r.Turnover >= a.QMTurnover, r.CustId, NULL)) AS QualifiedMember
				FROM (
					SELECT c.AffId, c.MonthDate, c.CustId, SUM(c.Turnover) AS Turnover
					FROM #DataMemberDaily c
					GROUP BY c.AffId, c.MonthDate, c.CustId
				)r
					INNER JOIN #temp_AffInfo a ON a.AffId = r.AffId AND r.MonthDate = a.MonthDate
				GROUP BY r.AffId, r.MonthDate
			)
			, CTE_ActivePlayer AS (
				SELECT r.AffId, r.MonthDate, COUNT(DISTINCT IIF(r.productId > 0, r.CustId, NULL)) AS ActivePlayer
				FROM #DataMemberDaily r
				GROUP BY r.AffId, r.MonthDate
			)
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
			SELECT @FromDate
					,t.AffId
					,0 AS GroupId
					,0 AS ProductId
					,0 AS Deposit
					,0 AS Withdrawal
					,t.Bonus
					,t.Rebate
					,t.Turnover
					,t.Winloss
					,0 AS Revenue
					,0 AS P2PFee
					,0 AS PlatFormFee
					,0 AS OperationalFee
					,0 AS DepositFee
					,0 AS WithdrawalFee
					,t.GrossWinloss
					,0 AS NetWinloss
					,0 AS NetTurnover
					,ISNULL(ap.ActivePlayer, 0) AS ActivePlayer
					,ISNULL(qm.QualifiedMember, 0) AS QualifiedMember
					,0 AS CommissionRate
					,0 AS Commission
					,0 AS StraightCommission
					,0 AS SubAffCommission
					,0 AS IsMultiGroupProduct 
			FROM CTE_DataResult t		
				LEFT JOIN(
					SELECT AffId, SUM(QualifiedMember) AS QualifiedMember 
					FROM CTE_QualifieldMember q
					GROUP BY AffId
				)qm ON qm.AffId = t.AffId
				LEFT JOIN (
					SELECT AffId, SUM(ActivePlayer) AS ActivePlayer
					FROM CTE_ActivePlayer 
					GROUP BY AffId
				) ap ON ap.AffId = t.AffId

				DROP TABLE #DataMemberDaily
				DROP TABLE #temp_AffInfo
		END

		-- Statistics
		CREATE TABLE #Statistics (AffId INT, TotalClick INT, UniqueClick INT)
		CREATE NONCLUSTERED INDEX IX_Statistics_Aff ON #Statistics (AffId) 

		-- Get Click data
		SELECT @FromDate_Local = DATEADD(HOUR, -12, CAST(@FromDate AS DATETIME)) -- GMT+8 to GMT-4
			,@ToDate_Local = DATEADD(HOUR, -12, DATEADD(DAY, 1, CAST(@ToDate AS DATETIME))); -- GMT+8 to GMT-4

		SELECT @tempFromDate = CONVERT(SMALLDATETIME, CAST(@FromDate_Local AS DATE))
			,@tempToDate 	 = CONVERT(SMALLDATETIME, DATEADD(DAY, 1, CONVERT(DATE, @ToDate_Local)))

		;WITH CTE_Clickstatisc AS(
			SELECT AffId,                   
				COUNT(1) AS TotalClick,
				IP
			FROM dbo.ClickStatistics c WITH (NOLOCK)
			WHERE [Date] >= @tempFromDate
				AND [Date] < @tempToDate
				AND UpdatedTime >= @FromDate_Local -- GMT-4
				AND UpdatedTime < @ToDate_Local -- GMT-4
				AND c.IsExcluded = 0
			GROUP BY AffId, IP							
		),
		CTE_Clickstatisc_bk AS(
			SELECT  AffId,                  
				COUNT(1) AS TotalClick,
				IP
			FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
			WHERE [Date] >= @tempFromDate
				AND [Date] < @tempToDate
				AND UpdatedTime >= @FromDate_Local -- GMT-4
				AND UpdatedTime < @ToDate_Local -- GMT-4
				AND c.IsExcluded = 0
			GROUP BY AffId, IP
		)
        INSERT INTO #Statistics (AffId, TotalClick, UniqueClick)
        SELECT AffId, SUM(t.TotalClick) AS TotalClick, COUNT(DISTINCT t.IP) AS UniqueClick
        FROM (
			SELECT AffId, TotalClick, IP
			FROM CTE_Clickstatisc
			UNION ALL
			SELECT AffId, TotalClick, IP
			FROM CTE_Clickstatisc_bk
        )t
        GROUP BY AffId

		-- Signup, FDM
		CREATE TABLE #Signup (AffId INT, Signup INT, FDM INT, FDM_Amount MONEY, FDM_TotalDeposit MONEY)
		-- Get Signup data
        ;WITH CTE_Signup AS (
            SELECT mi.AffId,
                COUNT(1) AS Signup
            FROM dbo.MemberInfo mi WITH (NOLOCK)
            WHERE mi.RegisteredDate >= @FromDate 
                AND mi.RegisteredDate < DATEADD(DAY, 1, @ToDate)
            GROUP BY mi.AffId
        ),
        CTE_FDM_Basic AS (
            -- Recent FDM count and FirstDepositAmount (FirstDepositDate >= @CommissionBoundary)
            SELECT 
                mi.AffId,
                COUNT(DISTINCT mi.CustId) AS FDM,
                SUM(ISNULL(mi.FirstDepositAmount, 0) * ex.Rate) AS FDM_Amount
            FROM dbo.MemberInfo mi WITH (NOLOCK)
				LEFT JOIN dbo.TpExchange te WITH (NOLOCK) ON mi.Currency = te.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(mi.FirstDepositDate, ISNULL(te.ExchangeId, mi.Currency), @BaseCurrency) ex
            WHERE mi.FirstDepositDate >= @FromDate 
                AND mi.FirstDepositDate < DATEADD(DAY, 1, @ToDate)              
            GROUP BY mi.AffId
        ),
        -- Calculate FDM, FDM_Amount, and FDM_TotalDeposit using hybrid approach
        CTE_FDM_Historical AS (
			-- Historical FDM data (FirstDepositDate < @CommissionBoundary) - use rptMemberDaily
			SELECT 
				mi.AffId,
				mi.Currency,
				CONVERT(DATE, EOMONTH(mi.FirstDepositDate)) AS MonthDate,
				SUM(ISNULL(r.Deposit, 0)) AS FDM_TotalDeposit
			FROM dbo.MemberInfo mi WITH (NOLOCK)
				INNER JOIN dbo.rptMemberDaily r WITH (NOLOCK)ON r.CustId = mi.CustId 
			WHERE mi.FirstDepositDate >= @FromDate 
				AND mi.FirstDepositDate < DATEADD(DAY, 1, @ToDate)
				AND mi.FirstDepositDate < @CommissionBoundary  -- Historical data only (before commission boundary)
                AND r.WinlostDate BETWEEN CAST(mi.FirstDepositDate AS DATE) AND EOMONTH(mi.FirstDepositDate)
			GROUP BY mi.AffId, mi.Currency, CONVERT(DATE, EOMONTH(mi.FirstDepositDate))
        ),
        CTE_FDM_Recent AS (
            -- Recent FDM total deposits (FirstDepositDate >= @CommissionBoundary) - use DepositInfo
            SELECT 
                mi.AffId,
                mi.Currency,
                CONVERT(DATE, EOMONTH(mi.FirstDepositDate)) AS MonthDate,          
                SUM(ISNULL(d.ActualDeposit, 0) * 1.0 / CASE WHEN mi.Currency IN (51, 15) THEN 1000.0 ELSE 1.0 END) AS FDM_TotalDeposit
            FROM dbo.MemberInfo mi WITH (NOLOCK)
                INNER JOIN bodb_12B.dbo.DepositInfo d WITH (NOLOCK) ON d.CustId = mi.CustId
            WHERE mi.FirstDepositDate >= @FromDate 
                AND mi.FirstDepositDate < DATEADD(DAY, 1, @ToDate)
                AND mi.FirstDepositDate >= @CommissionBoundary  -- Recent data only (after commission boundary)
                AND d.Status = 3  -- Approved deposits only
                AND d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index first
                AND CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)) >= CAST(mi.FirstDepositDate AS DATE) 
                AND CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)) < DATEADD(Day, 1, EOMONTH(mi.FirstDepositDate))  -- Convert GMT+0 to GMT+8
            GROUP BY mi.AffId, mi.Currency, CONVERT(DATE, EOMONTH(mi.FirstDepositDate))
        ),
        CTE_FDM_Combined AS (
            -- Combine historical and recent FDM data with exchange rate conversion
            SELECT 
                c.AffId,
                SUM(c.FDM_TotalDeposit * ex.Rate) AS FDM_TotalDeposit
            FROM (
                SELECT AffId, Currency, MonthDate, FDM_TotalDeposit FROM CTE_FDM_Historical
                UNION ALL
                SELECT AffId, Currency, MonthDate, FDM_TotalDeposit FROM CTE_FDM_Recent
            ) c
			LEFT JOIN dbo.TpExchange te WITH (NOLOCK) ON c.Currency = te.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(c.MonthDate, ISNULL(te.ExchangeId, c.Currency), @BaseCurrency) ex
            GROUP BY c.AffId
        )
        -- Insert data into #Signup
        INSERT INTO #Signup (AffId, Signup, FDM, FDM_Amount, FDM_TotalDeposit)
        SELECT AffId, SUM(Signup) AS Signup, SUM(FDM) AS FDM, SUM(FDM_Amount) AS FDM_Amount, SUM(FDM_TotalDeposit) AS FDM_TotalDeposit
        FROM (
            SELECT AffId, Signup, 0 AS FDM, 0 AS FDM_Amount, 0 AS FDM_TotalDeposit
            FROM CTE_Signup
            UNION ALL
            SELECT AffId, 0 AS Signup, FDM, FDM_Amount, 0 AS FDM_TotalDeposit
            FROM CTE_FDM_Basic
            UNION ALL
            SELECT AffId, 0 AS Signup, 0 AS FDM, 0 AS FDM_Amount, FDM_TotalDeposit
            FROM CTE_FDM_Combined
        ) Combined
        GROUP BY AffId

		-- Total Deposit
		CREATE TABLE #TotalDeposit(AffId INT, TotalDeposit BIGINT, TotalDepositAmount MONEY, TotalWithdrawalAmount MONEY)
		;WITH CTE_RptMemberData AS(
			SELECT r.AffId
				,r.Currency
				,CONVERT(DATE, EOMONTH(r.WinlostDate)) AS MonthDate
				,SUM(CASE WHEN r.winlostDate <= @MaxCommDate THEN ISNULL(r.DepositCount, 0) ELSE 0 END) AS TotalDeposit
				,SUM(CASE WHEN r.winlostDate <= @MaxCommDate THEN ISNULL(r.Deposit, 0) ELSE 0 END) AS DepositAmount
				,SUM(ISNULL(r.Withdrawal, 0)) AS WithdrawalAmount
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
			WHERE r.WinlostDate >= @FromDate 
				AND r.WinlostDate < DATEADD(DAY, 1, @ToDate)
				AND r.ProductId < 0
				AND NOT EXISTS (
					SELECT TOP 1 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
					WHERE mr.CustId = r.custid AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
				)
			GROUP BY r.AffId, r.Currency, CONVERT(DATE, EOMONTH(r.WinlostDate))
		),
		-- Recent Deposit data (after commission boundary)
		CTE_DepositRecent AS (
				SELECT mi.AffId
					,mi.Currency
					,EOMONTH(DATEADD(HOUR, @TimeZone, d.CreateTime)) AS MonthDate
					,COUNT(1) AS TotalDeposit
					,SUM(ISNULL(d.ActualDeposit,0) * 1.0 / CASE WHEN mi.Currency IN (51, 15) THEN 1000.0 ELSE 1.0 END) AS DepositAmount
				FROM dbo.MemberInfo mi WITH (NOLOCK)  
					INNER JOIN bodb_12B.dbo.DepositInfo d WITH (NOLOCK) ON d.CustId = mi.CustId
				WHERE d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index first					
					AND d.Status = 3 -- Approved
					AND d.CreateTime >= @FDateGMT0
					AND d.CreateTime < @TDateGMT0  -- Convert GMT+0 to GMT+8
					AND NOT EXISTS (
							SELECT TOP 1 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
							WHERE mr.CustId = d.custid AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate
						)
				GROUP BY mi.AffId, mi.Currency, EOMONTH(DATEADD(HOUR, @TimeZone, d.CreateTime))
			)
		INSERT INTO #TotalDeposit(AffId, TotalDeposit, TotalDepositAmount, TotalWithdrawalAmount)
		-- Combine both sources with exchange rate conversion using UNION ALL
		SELECT 
			td.AffId,
			SUM(td.TotalDeposit) AS TotalDeposit,
			SUM(td.DepositAmount * ex.Rate) AS TotalDepositAmount,
			SUM(td.WithdrawalAmount * ex.Rate) AS TotalWithdrawalAmount
		FROM (
			SELECT AffId, Currency, MonthDate, TotalDeposit, DepositAmount, 0 AS WithdrawalAmount FROM CTE_DepositRecent
			UNION ALL
			SELECT AffId, Currency, MonthDate, TotalDeposit, DepositAmount, WithdrawalAmount FROM CTE_RptMemberData
		) td
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON td.Currency = t.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(td.MonthDate, ISNULL(t.ExchangeId, td.Currency), @BaseExchangeId) ex
		GROUP BY td.AffId

		-- AffWithdrawal, AffAdjustment, Approved CPA Amount , Adjusted CPA Amount
		BEGIN
			DECLARE @CurrentDate DATE = DATEADD(HOUR, @TimeZone, GETUTCDATE())
			CREATE TABLE #AffTrans (AffId INT, AffWithdrawal MONEY, AffAdjustment MONEY, BFF MONEY, CurrentBBF MONEY, ApprovedCPAAmount MONEY, AdjustedCPAAmount MONEY)
			INSERT INTO #AffTrans (AffId, AffWithdrawal, AffAdjustment, ApprovedCPAAmount, AdjustedCPAAmount, BFF, CurrentBBF)
            SELECT ata.AffId,
                SUM(ata.AffWithdrawal * ex.Rate) AS AffWithdrawal,
                SUM(ata.AffAdjustment * ex.Rate) AS AffAdjustment,
                SUM(ata.ApprovedCPAAmount * ex.Rate) AS ApprovedCPAAmount,
                SUM(ata.AdjustedCPAAmount * ex.Rate) AS AdjustedCPAAmount,
                SUM(ata.BFF * ex.Rate) AS BFF,
                SUM(ata.CurrentBBF * ex.Rate) AS CurrentBBF
            FROM (
                SELECT at.AffId, at.AffCurrency
                    ,CONVERT(DATE, EOMONTH(at.WinlostDate)) AS MonthDate
                    ,SUM(CASE WHEN at.TransType = 202 AND at.WinlostDate BETWEEN @FromDate AND @ToDate THEN ABS(at.Amount) ELSE 0 END) AS AffWithdrawal
                    ,SUM(CASE WHEN at.TransType = 203 AND at.WinlostDate BETWEEN @FromDate AND @ToDate THEN at.Amount ELSE 0 END) AS AffAdjustment
                    ,SUM(CASE WHEN at.Transtype = 206 AND at.WinlostDate BETWEEN @FromDate AND @ToDate THEN at.Amount ELSE 0 END) AS ApprovedCPAAmount
                    ,SUM(CASE WHEN at.Transtype = 208 AND at.WinlostDate BETWEEN @FromDate AND @ToDate THEN at.Amount ELSE 0 END) AS AdjustedCPAAmount
                    ,SUM(CASE WHEN at.WinlostDate < DATEADD(DAY, 1, @ToDate) THEN Amount ELSE 0 END) AS BFF
                    ,SUM(Amount) AS CurrentBBF
                FROM dbo.AffTrans at WITH (NOLOCK)
                WHERE Status IN ('Pending', 'Approved', 'Completed')
                GROUP BY at.AffId, at.AffCurrency, CONVERT(DATE, EOMONTH(at.WinlostDate))
            )AS ata
            LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON ata.AffCurrency = t.TpExchangeId
            CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(ata.MonthDate, ISNULL(t.ExchangeId, ata.AffCurrency), @BaseExchangeId) ex
            GROUP BY ata.AffId
		END
		-- ======================
		-- CPA
		-- ======================	
		-- Qualified Player CPA
		-- Qualified Players = Settled Players + Min(Up to Now Remaining Quota, Eligible Players)
		CREATE TABLE #CPA (AffId INT, QualifiedCPAPlayer INT)
		;WITH CTE_Settled AS (
			SELECT AffId
				, COUNT(CustId) AS SettledPlayer
			FROM dbo.MemberCPA mc WITH (NOLOCK)
			WHERE mc.CPADate BETWEEN @FromDate AND @ToDate
				AND mc.StatusId = 3
			GROUP BY AffId
		)
		,CTE_Eligible AS (
			SELECT mc.AffId
				, COUNT(mc.CustId) AS EligibledPlayer
			FROM dbo.MemberCPA mc WITH (NOLOCK)
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON mc.AffId = agh.AffId AND mc.GroupId = agh.GroupId AND agh.ToDate = '9999-12-31'
			WHERE mc.HoldingQualifiedDate <= @ToDate
				AND MONTH(@ToDate) = MONTH(@CurrentDate) --current month
				AND mc.StatusId = 2
			GROUP BY mc.AffId
		)
		,CTE_Remaining AS (
			SELECT mc.AffId
				, IIF(cpg.Quota = 0, NULL, cpg.Quota - COUNT(mc.CustId)) AS Remaining -- NULL is unlimitedQuota
			FROM dbo.MemberCPA mc WITH (NOLOCK)
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON mc.AffId = agh.AffId AND mc.GroupId = agh.GroupId AND agh.ToDate = '9999-12-31' -- get current groupid of AFF to get quota
				INNER JOIN dbo.CPAGroupSetting cpg WITH (NOLOCK) ON mc.GroupId = cpg.GroupId AND cpg.ToDate = '9999-12-31'
			WHERE mc.StatusId = 3
			GROUP BY mc.AffId, cpg.Quota
		)
		,CTE_AffIds AS(
			SELECT AffId FROM CTE_Settled
			UNION
			SELECT AffId FROM CTE_Eligible
			UNION
			SELECT AffId FROM CTE_Remaining
		),
		CTE_QualifiedPlayerCPA AS(
			SELECT COALESCE(s.AffId, e.AffId, r.AffId) AS AffId
				,ISNULL(s.SettledPlayer, 0) + IIF(r.Remaining IS NULL, ISNULL(e.EligibledPlayer, 0), IIF(ISNULL(e.EligibledPlayer, 0) <= r.Remaining, ISNULL(e.EligibledPlayer, 0), r.Remaining)) AS QualifiedCPAPlayer
			FROM CTE_Settled s
				FULL OUTER JOIN CTE_Eligible e ON s.AffId = e.AffId
				FULL OUTER JOIN CTE_Remaining r ON ISNULL(s.AffId, e.AffId) = r.AffId
		)	
		-- #CPA
		INSERT INTO #CPA (AffId, QualifiedCPAPlayer)
		SELECT t.AffId, SUM(t.QualifiedCPAPlayer)
		FROM CTE_QualifiedPlayerCPA t
		GROUP BY t.AffId
	END

	-- Return data
	BEGIN
        CREATE TABLE #Result
		(
			AffId				INT,
			Username			NVARCHAR(30),
			GroupId				INT,
			GroupTypeId			INT,
			CommGroupName       NVARCHAR(100),
			ScheduleName		VARCHAR(400),
			[Status]			VARCHAR(30),
			PreferredLanguage	VARCHAR(11),	
			PaymentCurrency		VARCHAR(5),

			TotalClick			INT,
			UniqueClick			INT,
			Signup				INT,
			FDM					INT,
			FDM_Amount			MONEY,
			FDM_TotalDeposit	MONEY,
			ActivePlayer 		INT,
			QualifiedMember 	INT, --revenue
			QualifiedCPAMember 	INT, --CPA
			NoOfSubAff			INT,
			TotalDeposit		BIGINT,
			--Player Statistics
			Deposit				MONEY,
			Withdrawal			MONEY,
			Turnover			MONEY,
			GGR					MONEY,
			Bonus				MONEY,
			Rebate				MONEY,
			PlatFormFee			MONEY,
			OperationalFee		MONEY,
			DepositFee			MONEY,
			WithdrawalFee		MONEY,
			--Aff Statistics
			--Main
			CommissionRate		MONEY,
			IsMultiGroupProduct BIT,
			Earning				MONEY,
			P2PEarning			MONEY,
			ApprovedCPAAmount	MONEY,
			AdjustedCPAAmount	MONEY, 
			--Sub
			SubAffEarning		MONEY,
			AffWithdrawal		MONEY,
			AffAdjustment		MONEY,
			BFF					MONEY,
			CurrentBFF			MONEY,

			RowIdx				INT
		)
        ;WITH CTE_AffInfo AS(
            SELECT
                ai.AffId,
                ai.Username,
				ai.GroupId,
				cg.GroupName AS CommGroupName,
				cg.GroupTypeId,
				s.ScheduleName,
                ad.PreferredLanguage,
                ad.Player_CurrencyCode AS PaymentCurrency,
                ISNULL(a.NoOfSubAff, 0)	AS NoOfSubAff,
                CASE WHEN ai.IsRejected = 1 THEN 'Suspended' ELSE 'Approved' END [Status]
            FROM dbo.AffInfo ai WITH (NOLOCK)
				INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupId = cg.GroupId
				LEFT JOIN dbo.Schedule s WITH (NOLOCK) ON cg.ScheduleId = s.ScheduleId
                INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
                LEFT JOIN bodb_12B.dbo.Customer c WITH(NOLOCK) ON ad.Player_CustId = c.CustId
                LEFT JOIN (
                    SELECT ParentAffId, COUNT(1) AS NoOfSubAff
                    FROM dbo.AffInfo WITH (NOLOCK)
                    WHERE Status = 'Approved'
                        AND ApprovedDate >= @FromDate AND ApprovedDate < DATEADD(DAY, 1, @ToDate)
                    GROUP BY ParentAffId
                ) a ON ai.AffId = a.ParentAffId
            WHERE ai.Status = 'Approved'
                AND (@AffIds='all' OR EXISTS (SELECT 1 FROM @Aff a WHERE a.AffId = ai.AffId))
                AND (@PreferredLanguage = '' OR ad.PreferredLanguage = @PreferredLanguage)
                AND (@ListPaymentCurrencies = 'all' 
					OR ',' + @ListPaymentCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(20), ad.Player_Currency) + ',%' 
				)
                AND (
                    @GroupIds = 'all'
                    OR EXISTS (
                        SELECT 1 FROM dbo.AffGroupHistory agh WITH (NOLOCK)
                        WHERE agh.AffId = ai.AffId AND agh.MonthDate BETWEEN @StartDayOfFromDate AND @LastDayOfToDate
                                AND ',' + @GroupIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), agh.GroupId) + ',%'
								AND agh.MonthDate = EOMONTH(agh.MonthDate)
                    )
                )
                AND ai.ApprovedDate < DATEADD(DAY, 1, @ToDate)
                AND ((ISNULL(c.IsTest, 0) = 0 AND ai.AffCategoryId <> 2) OR @IsExcludeAFFTest = 0) -- exclude AFF marketing account
        )
		INSERT INTO #Result
		(
			AffId,
			Username,
			GroupId,
			GroupTypeId,
			CommGroupName,
			ScheduleName,
			[Status],
			PreferredLanguage,
			PaymentCurrency,

			TotalClick,
			UniqueClick,
			Signup,
			FDM,
			FDM_Amount,
			FDM_TotalDeposit,
			ActivePlayer,
			QualifiedMember,
			QualifiedCPAMember,
			NoOfSubAff,
			TotalDeposit,
			--Player Statistics
			Deposit,
			Withdrawal,
			Turnover,
			GGR,
			Bonus,
			Rebate,
			PlatFormFee,
			OperationalFee,
			DepositFee,
			WithdrawalFee,
			--Aff Statistics
			--main
			CommissionRate,
			IsMultiGroupProduct,
			Earning,
			P2PEarning,
			ApprovedCPAAmount,
			AdjustedCPAAmount,
			--sub
			SubAffEarning,
			AffWithdrawal,
			AffAdjustment,
			BFF,
			CurrentBFF,
			RowIdx
		)
        SELECT
			ai.AffId,
			ai.Username,
			ai.GroupId,
			ai.GroupTypeId,
			ai.CommGroupName,
			CASE 
				WHEN ai.GroupTypeId = 1 THEN 'Monthly'
				WHEN ai.GroupTypeId = 4 THEN 'Revenue Share: Monthly - CPA: ' + ai.ScheduleName -- '-' => '\r\n'
				ELSE ai.ScheduleName 
			END AS ScheduleName,
			ai.[Status],
			ai.PreferredLanguage,
			ai.PaymentCurrency,
			ISNULL(s.TotalClick, 0)				AS TotalClick,
			ISNULL(s.UniqueClick, 0)			AS UniqueClick,
			ISNULL(su.Signup, 0)				AS Signup,
			ISNULL(su.FDM, 0)					AS FDM,
			ISNULL(su.FDM_Amount, 0)			AS FDM_Amount,
			ISNULL(su.FDM_TotalDeposit, 0)		AS FDM_TotalDeposit,
			ISNULL(tc.ActivePlayer, 0)			AS ActivePlayer,
			ISNULL(tc.QualifiedMember, 0)		AS QualifiedMember, -- revenue
			ISNULL(cpa.QualifiedCPAPlayer, 0)	AS QualifiedCPAPlayer, -- cpa
			ai.NoOfSubAff,
			ISNULL(td.TotalDeposit, 0)			AS TotalDeposit,
			--Player Statistics
			ISNULL(td.TotalDepositAmount, 0)	AS Deposit,
			ISNULL(td.TotalWithdrawalAmount, 0)	AS Withdrawal,
			ISNULL(tc.Turnover, 0)				AS Turnover,
			ISNULL(tc.GGR, 0)					AS GGR,
			ISNULL(tc.Bonus, 0)					AS Bonus,
			ISNULL(tc.Rebate, 0)				AS Rebate,
			ISNULL(tc.PlatFormFee, 0)			AS PlatFormFee,
			ISNULL(tc.OperationalFee, 0)		AS OperationalFee,
			ISNULL(tc.DepositFee, 0)			AS DepositFee,
			ISNULL(tc.WithdrawalFee, 0)			AS WithdrawalFee,
			--Aff Statistics
			--main
			ISNULL(tc.CommissionRate, 0)		AS CommissionRate,
			ISNULL(tc.IsMultiGroupProduct, 0)   AS IsMultiGroupProduct,
			ISNULL(tc.Commission, 0)			AS Earning,
			ISNULL(tc.StraightCommission, 0)	AS P2PEarning,
			ISNULL(at.ApprovedCPAAmount, 0)		AS ApprovedCPAAmount,
			ISNULL(at.AdjustedCPAAmount, 0)		AS AdjustedCPAAmount,
			--sub
			ISNULL(tc.SubAffCommission, 0)		AS SubAffEarning,
			ISNULL(at.AffWithdrawal, 0)			AS AffWithdrawal,
			ISNULL(at.AffAdjustment, 0)			AS AffAdjustment,
			ISNULL(at.BFF, 0)					AS BFF,
			ISNULL(at.CurrentBBF, 0)			AS CurrentBBF,
			ROW_NUMBER() OVER(ORDER BY
				CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN ai.Username END ASC,
				CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN ai.Username END DESC,
				CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN ISNULL(tc.Turnover, 0) END ASC,
				CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN ISNULL(tc.Turnover, 0) END DESC,
				CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN ISNULL(tc.GGR, 0) END ASC,
				CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN ISNULL(tc.GGR, 0) END DESC,
				CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN ISNULL(tc.Commission, 0) + ISNULL(at.ApprovedCPAAmount, 0) + ISNULL(at.AdjustedCPAAmount, 0) + ISNULL(tc.SubAffCommission, 0) END ASC,
				CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN ISNULL(tc.Commission, 0) + ISNULL(at.ApprovedCPAAmount, 0) + ISNULL(at.AdjustedCPAAmount, 0) + ISNULL(tc.SubAffCommission, 0) END DESC,
				CASE WHEN @SortType = 5 AND @SortDirectionType = 0 THEN ISNULL(su.Signup, 0) END ASC,
				CASE WHEN @SortType = 5 AND @SortDirectionType = 1 THEN ISNULL(su.Signup, 0) END DESC,
				CASE WHEN @SortType = 6 AND @SortDirectionType = 0 THEN ISNULL(su.FDM, 0) END ASC,
				CASE WHEN @SortType = 6 AND @SortDirectionType = 1 THEN ISNULL(su.FDM, 0) END DESC,
				CASE WHEN @SortType = 7 AND @SortDirectionType = 0 THEN ISNULL(su.FDM_Amount, 0) END ASC,
				CASE WHEN @SortType = 7 AND @SortDirectionType = 1 THEN ISNULL(su.FDM_Amount, 0) END DESC,
				CASE WHEN @SortType = 8 AND @SortDirectionType = 0 THEN ISNULL(tc.ActivePlayer, 0) END ASC,
				CASE WHEN @SortType = 8 AND @SortDirectionType = 1 THEN ISNULL(tc.ActivePlayer, 0) END DESC,
				CASE WHEN @SortType = 9 AND @SortDirectionType = 0 THEN ISNULL(tc.QualifiedMember, 0) END ASC,
				CASE WHEN @SortType = 9 AND @SortDirectionType = 1 THEN ISNULL(tc.QualifiedMember, 0) END DESC
				) AS RowIdx
		FROM CTE_AffInfo ai
			LEFT JOIN #Signup su ON ai.AffId = su.AffId
			LEFT JOIN #AffTrans at ON ai.AffId = at.AffId
			LEFT JOIN (
				SELECT AffId, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
				FROM #Statistics
				GROUP BY AffId
			) s ON ai.AffId = s.AffId
			LEFT JOIN (
				SELECT AffId,
					SUM(ActivePlayer)				AS ActivePlayer,
					SUM(QualifiedMember)			AS QualifiedMember,
					SUM(Deposit)					AS Deposit,
					SUM(Withdrawal)					AS Withdrawal,
					SUM(Turnover)					AS Turnover,
					SUM(-Winloss + Revenue)			AS GGR,
					SUM(Bonus)						AS Bonus,
					SUM(Rebate)						AS Rebate,
					SUM(PlatFormFee + P2PFee)		AS PlatFormFee, -- include P2P Fee
					SUM(OperationalFee)				AS OperationalFee,
					SUM(DepositFee)					AS DepositFee,
					SUM(WithdrawalFee)				AS WithdrawalFee,
					SUM(NetWinloss)					AS NetWinloss,
					MAX(CommissionRate)				AS CommissionRate,
					CONVERT(BIT, MAX(CONVERT(TINYINT, IsMultiGroupProduct))) AS IsMultiGroupProduct,
					SUM(Commission)					AS Commission,
					SUM(StraightCommission)			AS StraightCommission,
					SUM(SubAffCommission)			AS SubAffCommission
				FROM #TempCommission
				GROUP BY AffId
			) tc ON ai.AffId = tc.AffId
			LEFT JOIN #TotalDeposit td ON td.AffId = ai.AffId
			LEFT JOIN #CPA cpa ON cpa.AffId = ai.AffId
		WHERE EXISTS (
                SELECT 1 
                FROM @Status st 
                WHERE st.[Status] = ai.[Status]
            )
            AND 1 = (CASE
						WHEN @IsExcludeNegvBBF = 0 AND @IsExcludeNegvCurrentBBF = 0 THEN 1
						WHEN @IsExcludeNegvBBF = 1 AND @IsExcludeNegvCurrentBBF = 0 AND ISNULL(at.BFF,0) >= 0 THEN 1
						WHEN @IsExcludeNegvBBF = 0 AND @IsExcludeNegvCurrentBBF = 1 AND ISNULL(at.CurrentBBF,0) >= 0 THEN 1
						WHEN @IsExcludeNegvBBF = 1 AND @IsExcludeNegvCurrentBBF = 1 AND ISNULL(at.BFF,0) >= 0 AND ISNULL(at.CurrentBBF,0) >= 0 THEN 1
					ELSE 0 END
				)
	END

	SELECT @NRows = COUNT(1) FROM #Result
	IF @NRows = 0
		RETURN
		
	DECLARE @RowStart INT, @RowEnd INT

	IF @IsExportExcel = 0
		SELECT @RowStart = (@PageIndex - 1) * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1
	ELSE
		SELECT @RowStart = 1, @RowEnd = @NRows

	-- Return detail
	SELECT AffId
		, Username
		, GroupId
		, GroupTypeId
		, CommGroupName
		, ScheduleName AS PaymentFrequency
		, [Status]
		, PreferredLanguage
		, PaymentCurrency
	
		, TotalClick
		, UniqueClick
		, Signup
		, FDM --FTD Count
		, FDM_Amount --FTD Amount
		, FDM_TotalDeposit
		, ActivePlayer
		, QualifiedMember
		, QualifiedCPAMember
		, NoOfSubAff
		, TotalDeposit --Total Deposit Count

		--Player Statistics
		, Deposit --Total Deposit Amount
		, Withdrawal
		, Turnover
		, GGR
		, Bonus
		, Rebate
		, PlatFormFee --Royalty Fee
		, OperationalFee
		, DepositFee
		, WithdrawalFee
		, PlatFormFee + OperationalFee + DepositFee + WithdrawalFee AS TotalFee

		--Aff Statistics
		--main
		, CommissionRate --Rev Share%
		, IsMultiGroupProduct
		, P2PEarning -- not use
		, Earning
		, ApprovedCPAAmount
		, AdjustedCPAAmount
		--sub
		, SubAffEarning
		, Earning + ApprovedCPAAmount + SubAffEarning + AdjustedCPAAmount AS TotalEarning

		, AffWithdrawal
		, AffAdjustment
		, BFF
		, CurrentBFF
		
	FROM #Result
	WHERE RowIdx BETWEEN @RowStart AND @RowEnd
	ORDER BY RowIdx ASC

	-- Return total
    SELECT
		SUM(TotalClick)			AS TotalClick
		,SUM(UniqueClick)		AS UniqueClick
		,SUM(Signup)			AS Signup
		,SUM(FDM)				AS FDM
		,SUM(FDM_Amount)		AS FDM_Amount
		,SUM(FDM_TotalDeposit)	AS FDM_TotalDeposit
		,SUM(ActivePlayer)		AS ActivePlayer
		,SUM(QualifiedMember)	AS QualifiedMember
		,SUM(QualifiedCPAMember)	AS QualifiedCPAMember
		,SUM(NoOfSubAff)		AS NoOfSubAff
		,SUM(TotalDeposit)		AS TotalDeposit
		--Player Statistics
		,SUM(Deposit)			AS Deposit
		,SUM(Withdrawal)		AS Withdrawal
		,SUM(Turnover)			AS Turnover
		,SUM(GGR)				AS GGR
		,SUM(Bonus)				AS Bonus
		,SUM(Rebate)			AS Rebate
		,SUM(PlatFormFee)		AS PlatFormFee
		,SUM(OperationalFee)	AS OperationalFee
		,SUM(DepositFee)		AS DepositFee
		,SUM(WithdrawalFee)		AS WithdrawalFee
		,SUM(PlatFormFee + OperationalFee + DepositFee + WithdrawalFee) AS TotalFee
		--Aff Statistics
		--main
		,0 AS CommissionRate
		,SUM(Earning)			AS Earning
		,SUM(P2PEarning)		AS P2PEarning
		,SUM(ApprovedCPAAmount)			AS ApprovedCPAAmount
		,SUM(AdjustedCPAAmount)			AS AdjustedCPAAmount
		--Sub
		,SUM(SubAffEarning)		AS SubAffEarning
		,SUM(Earning + ApprovedCPAAmount + AdjustedCPAAmount + SubAffEarning) AS TotalEarning

		,SUM(AffWithdrawal)		AS AffWithdrawal
		,SUM(AffAdjustment)		AS AffAdjustment
		,SUM(BFF)				AS BFF
		,SUM(CurrentBFF)		AS CurrentBFF
	FROM #Result

	DROP TABLE #AffTrans
	DROP TABLE #Result
	DROP TABLE #Signup
	DROP TABLE #Statistics
	DROP TABLE #TempCommission
	DROP TABLE #TotalDeposit;
	DROP TABLE #CPA
END;
GO