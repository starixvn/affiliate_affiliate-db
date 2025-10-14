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
		,@FromDateTimeGMT0		DATETIME
		,@ToDateTimeGMT0		DATETIME
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
	DECLARE @WinlostDateFrom DATE, @WinlostDateTo DATE
	SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @FromDate))
	SELECT @WinlostDateTo = DATEADD(DAY, 1, CONVERT(DATE, @ToDate))


	SELECT @NoOfMonth = DATEDIFF(MONTH, @FromDate, @ToDate) + 1
	
	IF @NoOfMonth <= 0
		RETURN;

	IF @ToDate > @EndOfCurrentMonth
		SELECT @ToDate = @EndOfCurrentMonth

	-- Data on GMT+0 --> convert timezone
	SELECT @FromDateTimeGMT0	= DATEADD(HOUR, -@TimeZone, CONVERT(DATETIME, @FromDate))
		,@ToDateTimeGMT0		= DATEADD(HOUR, -@TimeZone, CONVERT(DATETIME, @ToDate))

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME)
	;WITH CTE_MonthDate AS
	(
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate) + 1, 0)) AS MonthDate
		UNION ALL
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
		FROM CTE_MonthDate
		WHERE MonthDate < @ToDate
	)
	INSERT INTO @MonthDate (MonthDate)
	SELECT MonthDate FROM CTE_MonthDate
	OPTION (MAXRECURSION 0)


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
				@AffIds				= 'all',
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
				@AffIds				= 'all',
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
			CREATE TABLE #DataMemberDaily (MonthDate SMALLDATETIME, AffId INT, Currency INT, CustId INT, ProductId INT, Bonus MONEY, Rebate MONEY, Turnover MONEY, Winloss MONEY)
			CREATE CLUSTERED INDEX IX_DataMemberDaily ON #DataMemberDaily (MonthDate, AffId)
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
			SELECT CONVERT(SMALLDATETIME,EOMONTH(r.WinlostDate)) AS MonthDate
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
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
					WHERE mr.CustId = r.custid AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
				)
			GROUP BY CONVERT(SMALLDATETIME,EOMONTH(r.WinlostDate))
				,r.AffId
				,Currency
				,CustId
				,r.ProductId

			DECLARE @AffInfo TABLE (AffId INT, AffUsername VARCHAR(50),MonthDate SMALLDATETIME, GroupId INT, QMTurnover MONEY)
			INSERT INTO @AffInfo (AffId, AffUsername, MonthDate, GroupId)
				SELECT a.AffId, a.Username, agh.MonthDate, a.GroupId
				FROM (
					SELECT DISTINCT AffId, MonthDate FROM #DataMemberDaily
				)t
					INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON t.AffId = a.AffId
					INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON a.AffId = agh.AffId AND agh.MonthDate = t.MonthDate
				WHERE (Username LIKE '%' + @Username + '%' OR @Username IS NULL)
					AND Status NOT IN ('Pending', 'Disapproved')					
			
			UPDATE a SET a.QMTurnover = ISNULL(cg.QMTurnover, 0) * e.Rate
			FROM @AffInfo a
				INNER JOIN dbo.CommGroupHistory cg WITH (NOLOCK) ON a.GroupId = cg.GroupId AND a.MonthDate = cg.MonthDate
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(a.MonthDate, @AffExchangeId, @BaseExchangeId) e

			-- Get Product List		
			DECLARE @Products TABLE (ProductId INT)
			SET @ProductIds = dbo.Aff_f_AddRelatedProducts(@ProductIds)
			INSERT INTO @Products (ProductId)
			SELECT ProductId FROM dbo.Products WITH (NOLOCK) 
			WHERE ProductId IN (SELECT CONVERT(INT,value) AS ProductID FROM STRING_SPLIT(@ProductIds, ','))

			CREATE TABLE #ProductSetting (AffId INT, AffUsername VARCHAR(50), ProductId INT, MonthDate SMALLDATETIME)
			INSERT INTO #ProductSetting (AffId, AffUsername, ProductId, MonthDate)
			SELECT DISTINCT a.AffId, a.AffUsername, dsh.ProductId, dsh.MonthDate
			FROM @AffInfo a
				INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON a.GroupId = dsh.GroupId AND a.MonthDate = dsh.MonthDate
				INNER JOIN @Products p ON dsh.ProductId = p.ProductId
			
			;WITH CTE_DataFilter AS(
				SELECT d.MonthDate
					,d.AffId
					,Currency
					,CustId
					,d.ProductId
					,Bonus
					,Rebate
					,Turnover
					,Winloss
				FROM #DataMemberDaily d
					LEFT JOIN #ProductSetting pt ON d.AffId = pt.AffId AND d.ProductId = pt.ProductId AND d.MonthDate = pt.MonthDate
				WHERE (pt.ProductId IS NOT NULL OR d.ProductId = -1)
			)
			, CTE_DataResult AS(
				SELECT  r.AffId
					,SUM(r.Bonus		* e.Rate)	AS Bonus
					,SUM(r.Rebate		* e.Rate)	AS Rebate
					,SUM(r.Turnover		* e.Rate)	AS Turnover
					,SUM(r.Winloss		* e.Rate)	AS Winloss
					,- SUM(r.Winloss	* e.Rate)	AS GrossWinloss
				FROM CTE_DataFilter r
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.MonthDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
				GROUP BY r.AffId
			)
			, CTE_QualifieldMember AS (
				SELECT r.AffId, r.MonthDate, COUNT(DISTINCT IIF(r.Turnover >= a.QMTurnover, r.CustId, NULL)) AS QualifiedMember
				FROM (
					SELECT c.AffId, c.MonthDate, c.CustId, SUM(ISNULL(c.Turnover, 0) * e.Rate) AS Turnover
					FROM CTE_DataFilter c
						LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON c.Currency = t.TpExchangeId
						CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(c.MonthDate, ISNULL(t.ExchangeId, c.Currency), @BaseExchangeId) e
					GROUP BY c.AffId, c.MonthDate, c.CustId
				)r
					INNER JOIN @AffInfo a ON a.AffId = r.AffId AND r.MonthDate = a.MonthDate
				GROUP BY r.AffId, r.MonthDate
			)
			, CTE_ActivePlayer AS (
				SELECT r.AffId, r.MonthDate, COUNT(DISTINCT IIF(r.productId > 0, r.CustId, NULL)) AS ActivePlayer
				FROM CTE_DataFilter r
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
			OUTER APPLY(
				SELECT SUM(QualifiedMember) AS QualifiedMember 
				FROM CTE_QualifieldMember q
				WHERE q.AffId = t.AffId
			)qm 
			OUTER APPLY(
				SELECT SUM(ActivePlayer) AS ActivePlayer 
				FROM CTE_ActivePlayer q
				WHERE q.AffId = t.AffId
			)ap
		DROP TABLE #ProductSetting
		DROP TABLE #DataMemberDaily 
		END
		-- Statistics
		CREATE TABLE #IP (AffId INT, TotalClick INT, IP VARCHAR (25))
		CREATE TABLE #Statistics (AffId INT, TotalClick INT, UniqueClick INT)

		DECLARE @ArchiveDate SMALLDATETIME;
		SELECT @ArchiveDate = dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics'); -- GMT-4

		SELECT @FromDate_Local = DATEADD(HOUR, -12, CAST(@FromDate AS DATETIME)) -- GMT+8 to GMT-4
			,@ToDate_Local = DATEADD(HOUR, -12, DATEADD(DAY, 1, CAST(@ToDate AS DATETIME))); -- GMT+8 to GMT-4

		IF @ToDate_Local > @ArchiveDate
		BEGIN
			SELECT @tempFromDate = CASE 
										WHEN @FromDate_Local > @ArchiveDate THEN CONVERT(DATE, @FromDate_Local) 
										ELSE DATEADD(DAY, 1, @ArchiveDate) 
								   END
				,@tempToDate = DATEADD(DAY, 1, CONVERT(DATE, @ToDate_Local))

			INSERT INTO #IP(AffId, TotalClick, IP)
			SELECT AffId,					
					COUNT(1) AS TotalClick,
					IP
			FROM dbo.ClickStatistics c WITH (NOLOCK)
			WHERE [Date] >= @tempFromDate
				AND [Date] < @tempToDate
				AND UpdatedTime >= @FromDate_Local -- GMT-4
				AND UpdatedTime < @ToDate_Local -- GMT-4
			GROUP BY
				AffId, IP
			
		END

		IF CONVERT(DATE, @FromDate_Local) <= @ArchiveDate
		BEGIN
			 SELECT @tempFromDate = CONVERT(DATE, @FromDate_Local)
				,@tempToDate = CASE 
									WHEN @ToDate_Local <= @ArchiveDate THEN DATEADD(DAY, 1, CONVERT(DATE, @ToDate_Local)) 
									ELSE DATEADD(DAY, 1, @ArchiveDate) 
							   END
			INSERT INTO #IP (AffId, TotalClick, IP)
			SELECT  AffId,					
					COUNT(1) AS TotalClick,
					IP
			FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
			WHERE [Date] >= @tempFromDate
				AND [Date] < @tempToDate
				AND UpdatedTime >= @FromDate_Local -- GMT-4
				AND UpdatedTime < @ToDate_Local -- GMT-4
			GROUP BY
				AffId, IP
		END

		INSERT INTO #Statistics (AffId, TotalClick, UniqueClick)
		SELECT AffId, SUM(TotalClick) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM #IP
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
				LEFT JOIN dbo.TpExchange te WITH (NOLOCK) ON mi.Currency = te.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(mi.FirstDepositDate, ISNULL(te.ExchangeId, mi.Currency), @BaseCurrency) ex
				OUTER APPLY (
					SELECT 
						SUM(r.Deposit) AS Deposit
					FROM dbo.rptMemberDaily r WITH (NOLOCK)
					WHERE r.CustId = mi.CustId 
					AND r.WinlostDate BETWEEN CAST(mi.FirstDepositDate AS DATE) AND EOMONTH(mi.FirstDepositDate)
				) r
			WHERE mi.FirstDepositDate >= @FromDate 
				AND mi.FirstDepositDate < DATEADD(DAY, 1, @ToDate)
				AND mi.FirstDepositDate < @CommissionBoundary  -- Historical data only (before commission boundary)
			GROUP BY mi.AffId, mi.Currency, CONVERT(DATE, EOMONTH(mi.FirstDepositDate))
		),
		CTE_FDM_Recent AS (
			-- Recent FDM total deposits (FirstDepositDate >= @CommissionBoundary) - use DepositInfo
			SELECT 
				mi.AffId,
				mi.Currency,
				CONVERT(DATE, EOMONTH(mi.FirstDepositDate)) AS MonthDate,
				SUM(ISNULL(d.ActualDeposit, 0) * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) AS FDM_TotalDeposit
			FROM dbo.MemberInfo mi WITH (NOLOCK)
				INNER JOIN bodb_12B.dbo.DepositInfo d WITH (NOLOCK) ON d.CustId = mi.CustId
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
				LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, mi.Currency) = e.ExchangeId
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

		-- AffWithdrawal, AffAdjustment
		CREATE TABLE #AffTrans (AffId INT, AffWithdrawal MONEY, AffAdjustment MONEY, BFF MONEY, CurrentBBF MONEY)
		INSERT INTO #AffTrans (AffId, AffWithdrawal, AffAdjustment, BFF, CurrentBBF)
		SELECT ata.AffId,
			SUM(ata.AffWithdrawal * ex.Rate) AS AffWithdrawal,
			SUM(ata.AffAdjustment * ex.Rate) AS AffAdjustment,
			SUM(ata.BFF * ex.Rate) AS BFF,
			SUM(ata.CurrentBBF * ex.Rate) AS CurrentBBF
		FROM (
			SELECT at.AffId, at.AffCurrency
				,CONVERT(DATE, EOMONTH(at.WinlostDate)) AS MonthDate
				,SUM(CASE WHEN at.TransType = 202 AND at.WinlostDate >= @FromDate AND at.WinlostDate < DATEADD(DAY, 1, @ToDate) THEN ABS(at.Amount) ELSE 0 END) AS AffWithdrawal
				,SUM(CASE WHEN at.TransType = 203 AND at.WinlostDate >= @FromDate AND at.WinlostDate < DATEADD(DAY, 1, @ToDate) THEN at.Amount ELSE 0 END) AS AffAdjustment
				,SUM(CASE WHEN at.WinlostDate < DATEADD(DAY, 1, @ToDate) THEN Amount ELSE 0 END) AS BFF
				,SUM(Amount) AS CurrentBBF
			FROM dbo.AffTrans at WITH (NOLOCK)
			WHERE Status IN ('Pending', 'Approved', 'Completed')
			GROUP BY at.AffId, at.AffCurrency, CONVERT(DATE, EOMONTH(at.WinlostDate))
		) ata
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON ata.AffCurrency = t.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(ata.MonthDate, ISNULL(t.ExchangeId, ata.AffCurrency), @BaseExchangeId) ex
		GROUP BY ata.AffId

		-- Total Deposit
		CREATE TABLE #TotalDeposit(AffId INT, TotalDeposit BIGINT, TotalDepositAmount MONEY, TotalWithdrawalAmount MONEY)
		;WITH CTE_DepositInfo AS ( 
		-- Get all deposit data from DepositInfo (full range) for counts and recent amounts
		SELECT mi.AffId
			,mi.Currency
			,CONVERT(DATE, EOMONTH(DATEADD(HOUR, @TimeZone, d.CreateTime))) AS MonthDate
			,COUNT(1) AS TotalDeposit
			,SUM(CASE 
				WHEN CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)) >= @CommissionBoundary 
				THEN ISNULL(d.ActualDeposit,0) * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END
				ELSE 0 
			END) AS RecentDepositAmount
			,0 AS HistoricalDepositAmount
			,0 AS WithdrawalAmount
		FROM bodb_12B.dbo.DepositInfo d WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.CustId = mi.CustId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
			LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, mi.Currency) = e.ExchangeId		
		WHERE d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index first
			AND d.Status = 3 -- Approved
			AND CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)) >= @FromDate
			AND CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)) < DATEADD(DAY, 1, @ToDate)  -- Convert GMT+0 to GMT+8
			AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
					WHERE mr.CustId = d.custid AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate
				)
		GROUP BY mi.AffId, mi.Currency, CONVERT(DATE, EOMONTH(DATEADD(HOUR, @TimeZone, d.CreateTime)))
		),
		CTE_RptMemberData AS (
		-- Get all data from rptMemberDaily (full range) for historical deposits and all withdrawals
		SELECT r.AffId
			,r.Currency
			,CONVERT(DATE, EOMONTH(r.WinlostDate)) AS MonthDate
			,0 AS TotalDeposit
			,0 AS RecentDepositAmount
			,SUM(CASE 
				WHEN r.WinlostDate < @CommissionBoundary 
				THEN ISNULL(r.Deposit, 0)
				ELSE 0 
			END) AS HistoricalDepositAmount
			,SUM(ISNULL(r.Withdrawal, 0)) AS WithdrawalAmount
		FROM dbo.rptMemberDaily r WITH (NOLOCK)
		WHERE r.WinlostDate >= @FromDate 
			AND r.WinlostDate < DATEADD(DAY, 1, @ToDate)
			AND r.ProductId < 0
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
				WHERE mr.CustId = r.custid AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
			)
		GROUP BY r.AffId, r.Currency, CONVERT(DATE, EOMONTH(r.WinlostDate))
		),
		CTE_CombinedData AS (
		-- Combine both sources with exchange rate conversion using UNION ALL
		SELECT 
			td.AffId,
			SUM(td.TotalDeposit) AS TotalDeposit,
			SUM(td.RecentDepositAmount * ex.Rate) AS RecentDepositAmount,
			SUM(td.HistoricalDepositAmount * ex.Rate) AS HistoricalDepositAmount,
			SUM(td.WithdrawalAmount * ex.Rate) AS WithdrawalAmount
		FROM (
			SELECT AffId, Currency, MonthDate, TotalDeposit, RecentDepositAmount, HistoricalDepositAmount, WithdrawalAmount FROM CTE_DepositInfo
			UNION ALL
			SELECT AffId, Currency, MonthDate, TotalDeposit, RecentDepositAmount, HistoricalDepositAmount, WithdrawalAmount FROM CTE_RptMemberData
		) td
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON td.Currency = t.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(td.MonthDate, ISNULL(t.ExchangeId, td.Currency), @BaseExchangeId) ex
		GROUP BY td.AffId
		)
		INSERT INTO #TotalDeposit(AffId, TotalDeposit, TotalDepositAmount, TotalWithdrawalAmount)
		SELECT AffId
			,TotalDeposit
			,RecentDepositAmount + HistoricalDepositAmount AS TotalDepositAmount
			,WithdrawalAmount AS TotalWithdrawalAmount
		FROM CTE_CombinedData
	END

	-- Return data
	BEGIN
        CREATE TABLE #Result
		(
			AffId				INT,
			Username			NVARCHAR(30),
			CommGroupName       NVARCHAR(100),
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
			QualifiedMember 	INT,
			NoOfSubAff			INT,
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
			CommissionRate		MONEY,
			IsMultiGroupProduct BIT,
			Earning				MONEY,
			P2PEarning			MONEY,
			SubAffEarning		MONEY,
			AffWithdrawal		MONEY,
			AffAdjustment		MONEY,
			BFF					MONEY,
			CurrentBFF			MONEY,
			TotalDeposit		BIGINT,
			RowIdx				INT
		)
        ;WITH CTE_AffInfo AS(
            SELECT
                ai.AffId,
                ai.Username,
				cg.GroupName AS CommGroupName,
                ad.PreferredLanguage,
                ad.Player_CurrencyCode AS PaymentCurrency,
                ISNULL(a.NoOfSubAff, 0)	AS NoOfSubAff,
                CASE WHEN ai.IsRejected = 1 THEN 'Suspended' ELSE 'Approved' END [Status]
            FROM dbo.AffInfo ai WITH (NOLOCK)
				INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupId = cg.GroupId
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
                AND ai.Username LIKE '%' + @Username + '%'
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
                    )
                )
                AND ai.ApprovedDate < DATEADD(DAY, 1, @ToDate)
                AND ((ISNULL(c.IsTest, 0) = 0 AND ai.AffCategoryId <> 2) OR @IsExcludeAFFTest = 0) -- exclude AFF marketing account
        )
		INSERT INTO #Result
		(
			AffId,
			Username,
			CommGroupName,
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
			NoOfSubAff,
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
			CommissionRate,
			IsMultiGroupProduct,
			Earning,
			P2PEarning,
			SubAffEarning,
			AffWithdrawal,
			AffAdjustment,
			BFF,
			CurrentBFF,
			TotalDeposit,
			RowIdx
		)
        SELECT
			ai.AffId,
			ai.Username,
			ai.CommGroupName,
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
			ISNULL(tc.QualifiedMember, 0)		AS QualifiedMember,
			ai.NoOfSubAff,
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
			ISNULL(tc.CommissionRate, 0)		AS CommissionRate,
			ISNULL(tc.IsMultiGroupProduct, 0)   AS IsMultiGroupProduct,
			ISNULL(tc.Commission, 0)			AS Earning,
			ISNULL(tc.StraightCommission, 0)	AS P2PEarning,
			ISNULL(tc.SubAffCommission, 0)		AS SubAffEarning,
			ISNULL(at.AffWithdrawal, 0)			AS AffWithdrawal,
			ISNULL(at.AffAdjustment, 0)			AS AffAdjustment,
			ISNULL(at.BFF, 0)					AS BFF,
			ISNULL(at.CurrentBBF, 0)			AS CurrentBBF,
			ISNULL(td.TotalDeposit, 0)			AS TotalDeposit,
			ROW_NUMBER() OVER(ORDER BY
				CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN ai.Username END ASC,
				CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN ai.Username END DESC,
				CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN ISNULL(tc.Turnover, 0) END ASC,
				CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN ISNULL(tc.Turnover, 0) END DESC,
				CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN ISNULL(tc.GGR, 0) END ASC,
				CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN ISNULL(tc.GGR, 0) END DESC,
				CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN ISNULL(tc.Commission, 0) END ASC,
				CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN ISNULL(tc.Commission, 0) END DESC,
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
	SELECT AffId, Username, CommGroupName, [Status], PreferredLanguage, PaymentCurrency, TotalClick, UniqueClick, Signup, FDM, FDM_Amount, FDM_TotalDeposit, ActivePlayer, QualifiedMember, NoOfSubAff
		,Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, PlatFormFee, OperationalFee, DepositFee, WithdrawalFee
		,PlatFormFee + OperationalFee + DepositFee + WithdrawalFee AS TotalFee
		,CommissionRate, IsMultiGroupProduct, P2PEarning, Earning, SubAffEarning, AffWithdrawal, AffAdjustment, BFF, CurrentBFF, TotalDeposit
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
		,SUM(NoOfSubAff)		AS NoOfSubAff
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
		,0 AS CommissionRate
		,SUM(Earning)			AS Earning
		,SUM(P2PEarning)		AS P2PEarning
		,SUM(SubAffEarning)		AS SubAffEarning
		,SUM(AffWithdrawal)		AS AffWithdrawal
		,SUM(AffAdjustment)		AS AffAdjustment
		,SUM(BFF)				AS BFF
		,SUM(CurrentBFF)		AS CurrentBFF
		,SUM(TotalDeposit)		AS TotalDeposit
	FROM #Result

	DROP TABLE #AffTrans
	DROP TABLE #Result
	DROP TABLE #Signup
	DROP TABLE #Statistics
	DROP TABLE #IP
	DROP TABLE #TempCommission
	DROP TABLE #TotalDeposit;

END;
GO