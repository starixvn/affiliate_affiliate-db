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
	,@PaymentCurrencies	VARCHAR(MAX) = ''
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
	SET NOCOUNT ON

	DECLARE @IsExcludeAFFTest	BIT = 1
		,@EndOfCurrentMonth		SMALLDATETIME
		,@NoOfMonth				INT
		,@TimeZone				SMALLINT
		,@FromDateTimeGMT0		DATETIME
		,@ToDateTimeGMT0		DATETIME
		,@LastDayOfToDate		SMALLDATETIME
		,@StartDayOfFromDate	SMALLDATETIME
		,@FromDateLocalTime		SMALLDATETIME
		,@ToDateLocalTime		SMALLDATETIME

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
		RETURN

	SELECT  @Username		 = ISNULL(TRIM(@Username), ''), @PreferredLanguage = ISNULL(@PreferredLanguage, ''), @GroupIds = ISNULL(@GroupIds, '')
		,@EndOfCurrentMonth	 = EOMONTH(GETDATE())	
		,@StartDayOfFromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0)
		,@LastDayOfToDate	 = EOMONTH(@ToDate)

	IF (@IsGetMonthly = 1)
	BEGIN
		SELECT  @FromDate	= @StartDayOfFromDate -- Begin Of Month
		SELECT  @ToDate		= @LastDayOfToDate  -- End Of Month
	END

	SELECT @NoOfMonth = DATEDIFF(MONTH, @FromDate, @ToDate) + 1
	
	IF @NoOfMonth <= 0
		RETURN

	IF @ToDate > @EndOfCurrentMonth
		SELECT @ToDate = @EndOfCurrentMonth

	-- Data on GMT+0 --> convert timezone
	SELECT @FromDateTimeGMT0	= DATEADD(HOUR, -@TimeZone, CONVERT(DATETIME, @FromDate))
		,@ToDateTimeGMT0		= DATEADD(HOUR, -@TimeZone, CONVERT(DATETIME, @ToDate))

	-- Convert datetime to localtime
	SELECT @FromDateLocalTime = DATEADD(HOUR, -4 - @TimeZone, @FromDate)
	SELECT @ToDateLocalTime   = DATEADD(HOUR, -4 - @TimeZone, @ToDate)

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

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

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
	DECLARE @ListPaymentCurrencies	VARCHAR(MAX) = ''
	SELECT @ListPaymentCurrencies = COALESCE(@ListPaymentCurrencies + ',', '') + CONVERT(VARCHAR(20), t.TpExchangeId)
	FROM STRING_SPLIT(@PaymentCurrencies, ',') f
		CROSS APPLY(
			SELECT TpExchangeId
			FROM dbo.Aff_f_TpExchange_Sel(f.value)
		)t

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
				@GetRowTotalOnly	= 1
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
		CREATE TABLE #Statistics (AffId INT, TotalClick INT, UniqueClick INT, Signup INT, FDM INT)

		DECLARE @ArchiveDate SMALLDATETIME
		SELECT  @ArchiveDate = MAX(Date) FROM dbo.ClickStatistics_bk WITH (NOLOCK)
		
		SELECT @ArchiveDate = ISNULL(@ArchiveDate, '2025-02-01') -- Will remove after Mar 01, 2025

		IF @ToDate > @ArchiveDate
		BEGIN
			SELECT @tempFromDate = CASE WHEN @FromDate <= @ArchiveDate THEN DATEADD(DAY, 1, @ArchiveDate) ELSE @FromDate END
			SELECT @tempToDate	= @ToDate

			INSERT INTO #Statistics (AffId, TotalClick, UniqueClick)
			SELECT AffId, SUM(TotalClick), SUM(UniqueClick)
			FROM 
			(
				SELECT
					AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)) AS MonthDate,
					COUNT(1) AS TotalClick,
					COUNT(DISTINCT IP) AS UniqueClick
				FROM dbo.ClickStatistics WITH (NOLOCK)
				WHERE Date BETWEEN @tempFromDate AND @tempToDate
				GROUP BY
					AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0))
			) AS c
			GROUP BY AffId
		END

		IF @FromDate <= @ArchiveDate
		BEGIN
			SELECT @tempFromDate = @FromDate
			SELECT @tempToDate	= CASE WHEN @ToDate > @ArchiveDate THEN @ArchiveDate ELSE @ToDate END
			
			INSERT INTO #Statistics (AffId, TotalClick, UniqueClick)
			SELECT AffId, SUM(TotalClick), SUM(UniqueClick)
			FROM
			(
				SELECT
					AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)) AS MonthDate,
					COUNT(1) AS TotalClick,
					COUNT(DISTINCT IP) AS UniqueClick
				FROM dbo.ClickStatistics_bk WITH (NOLOCK)
				WHERE Date BETWEEN @tempFromDate AND @tempToDate
				GROUP BY
					AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)) 					 
			) AS c
			GROUP BY AffId
		END

		-- Signup, FDM
		CREATE TABLE #Signup (AffId INT, Signup INT, FDM INT, FDM_Amount MONEY)

		;WITH CTE_MemberInfoData AS(
		SELECT mi.AffId
			,COUNT(1) AS Signup
			,0 AS FDM
			,0 AS FDM_Amount
		FROM dbo.MemberInfo mi WITH (NOLOCK)
		WHERE mi.RegisteredDate >= @FromDate 
			AND mi.RegisteredDate < DATEADD(DAY, 1, @ToDate)
		GROUP BY mi.AffId
		UNION ALL
		SELECT mi.AffId
			,0 AS Signup
			,COUNT(1) AS FDM
			,SUM(ISNULL(mi.FirstDepositAmount, 0) * e.Rate) AS FDM_Amount
		FROM dbo.MemberInfo mi WITH (NOLOCK)
        	LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(mi.FirstDepositDate, ISNULL(t.ExchangeId, mi.Currency), @BaseExchangeId) e
		WHERE mi.FirstDepositDate >= @FromDate 
			AND mi.FirstDepositDate < DATEADD(DAY, 1, @ToDate)
		GROUP BY mi.AffId
		)
		INSERT INTO #Signup (AffId, Signup, FDM, FDM_Amount)
		SELECT mi.AffId
			,SUM(Signup) AS Signup
			,SUM(FDM) AS FDM
			,SUM(FDM_Amount) AS FDM_Amount
		FROM CTE_MemberInfoData mi
		GROUP BY mi.AffId

		-- AffWithdrawal, AffAdjustment
		CREATE TABLE #AffTrans (AffId INT, AffWithdrawal MONEY, AffAdjustment MONEY, BFF MONEY, CurrentBBF MONEY)
		;WITH CTE_AffTransData AS(
			SELECT at.AffId,
				at.AffCurrency,
				EOMONTH(DATEADD(HOUR, 4 + @TimeZone,at.TransDate)) MonthDate,
				SUM((CASE WHEN at.TransType = 202 AND at.TransDate >= @FromDateLocalTime AND at.TransDate < DATEADD(DAY, 1, @ToDateLocalTime) THEN ABS(at.Amount) ELSE 0 END)) AS AffWithdrawal,
				SUM((CASE WHEN at.TransType = 203 AND at.TransDate >= @FromDateLocalTime THEN at.Amount ELSE 0 END) ) AS AffAdjustment,
				SUM(CASE WHEN TransDate < DATEADD(DAY, 1, @ToDateLocalTime) THEN Amount ELSE NULL END) AS BFF,
				SUM(Amount) AS CurrentBBF		
			FROM dbo.AffTrans at WITH (NOLOCK)
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON at.AffCurrency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(at.TransDate, ISNULL(t.ExchangeId, at.AffCurrency), @BaseExchangeId) e
			WHERE Status IN ('Pending', 'Approved', 'Completed')
			GROUP BY AffId, EOMONTH(DATEADD(HOUR, 4 + @TimeZone,at.TransDate)), at.AffCurrency
		)
		INSERT INTO #AffTrans (AffId, AffWithdrawal, AffAdjustment, BFF, CurrentBBF)
		SELECT at.AffId
			,SUM(at.AffWithdrawal * e.Rate) AS AffWithdrawal
			,SUM(at.AffAdjustment * e.Rate) AS AffAdjustment
			,SUM(at.BFF * e.Rate)			AS BFF
			,SUM(at.CurrentBBF * e.Rate)	AS CurrentBBF
		FROM CTE_AffTransData at WITH (NOLOCK)
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON at.AffCurrency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(at.MonthDate, ISNULL(t.ExchangeId, at.AffCurrency), @BaseExchangeId) e
		GROUP BY AffId

		-- Total Deposit
		CREATE TABLE #TotalDeposit(AffId INT, TotalDeposit BIGINT, TotalDepositAmount MONEY, TotalWithdrawalAmount MONEY)
		;WITH CTE_DataDeposit AS (
		SELECT mi.AffId
			,COUNT(1) AS TotalDeposit
		FROM bodb_12B.dbo.DepositInfo d WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.CustId = mi.CustId
		WHERE d.WinlostDate BETWEEN DATEADD(DAY, -1, @FromDate) AND DATEADD(DAY, 1, @ToDate)
			AND d.Status = 3 -- Approved
			AND d.CreateTime >= @FromDateTimeGMT0 
			AND d.CreateTime < DATEADD(DAY, 1, @ToDateTimeGMT0)
		GROUP BY mi.AffId
		),
		CTE_DataDepositAmount AS (
			SELECT r.AffId
				,SUM(ISNULL(Deposit, 0) * e.Rate)	    AS Deposit
				,SUM(ISNULL(r.Withdrawal, 0) * e.Rate)	AS Withdrawal
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.WinlostDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
			WHERE r.WinlostDate >= @FromDate 
				AND r.WinlostDate < DATEADD(DAY, 1, @ToDate)
				AND r.ProductId < 0
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
					WHERE mr.CustId = r.custid AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
				)
			GROUP BY r.AffId
		)	
		INSERT INTO #TotalDeposit(AffId, TotalDeposit, TotalDepositAmount, TotalWithdrawalAmount)
		SELECT t.AffId
			,SUM(TotalDeposit)          AS TotalDeposit
			,SUM(TotalDepositAmount)    AS TotalDepositAmount
			,SUM(TotalWithdrawalAmount) AS TotalWithdrawalAmount
		FROM (
			SELECT mi.AffId
				,mi.TotalDeposit
				,0 AS TotalDepositAmount
				,0 AS TotalWithdrawalAmount
			FROM CTE_DataDeposit mi
			UNION ALL
			SELECT mi.AffId
				,0 TotalDeposit
				,Deposit	AS TotalDepositAmount
				,Withdrawal	AS TotalWithdrawalAmount
			FROM CTE_DataDepositAmount mi
		)t
		GROUP BY t.AffId
	END

	-- Return data
	BEGIN
        CREATE TABLE #Result
		(
			AffId				INT,
			Username			NVARCHAR(30),
			[Status]			VARCHAR(30),
			PreferredLanguage	VARCHAR(11),	
			PaymentCurrency		VARCHAR(5),
			TotalClick			INT,
			UniqueClick			INT,
			Signup				INT,
			FDM					INT,
			FDM_Amount			MONEY,
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
                ad.PreferredLanguage,
                ad.Player_CurrencyCode AS PaymentCurrency,
                ISNULL(a.NoOfSubAff, 0)	AS NoOfSubAff,
                CASE WHEN ai.IsRejected = 1 THEN 'Suspended' ELSE 'Approved' END [Status]
            FROM dbo.AffInfo ai WITH (NOLOCK)
                INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
                INNER JOIN bodb_12B.dbo.Customer c WITH(NOLOCK) ON ad.Player_CustId = c.CustId
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
                AND ',' + @ListPaymentCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(20), ad.Player_Currency) + ',%'
                AND (
                    @GroupIds = 'all'
                    OR EXISTS (
                        SELECT 1 FROM dbo.AffGroupHistory agh WITH (NOLOCK)
                        WHERE agh.AffId = ai.AffId AND agh.MonthDate BETWEEN @StartDayOfFromDate AND @LastDayOfToDate
                                AND ',' + @GroupIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), agh.GroupId) + ',%'
                    )
                )
                AND ai.ApprovedDate < DATEADD(DAY, 1, @ToDate)
                AND (c.IsTest = 0 OR @IsExcludeAFFTest = 0)
        )
		INSERT INTO #Result
		(
			AffId,
			Username,
			[Status],
			PreferredLanguage,
			PaymentCurrency,
			TotalClick,
			UniqueClick,
			Signup,
			FDM,
			FDM_Amount,
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
			ai.[Status],
			ai.PreferredLanguage,
			ai.PaymentCurrency,
			ISNULL(s.TotalClick, 0)				AS TotalClick,
			ISNULL(s.UniqueClick, 0)			AS UniqueClick,
			ISNULL(su.Signup, 0)				AS Signup,
			ISNULL(su.FDM, 0)					AS FDM,
			ISNULL(su.FDM_Amount, 0)			AS FDM_Amount,
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
	SELECT AffId, Username, [Status], PreferredLanguage, PaymentCurrency, TotalClick, UniqueClick, Signup, FDM, FDM_Amount, ActivePlayer, QualifiedMember, NoOfSubAff
		,Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, PlatFormFee, OperationalFee, DepositFee, WithdrawalFee
		,PlatFormFee + OperationalFee + DepositFee + WithdrawalFee AS TotalFee
		,CommissionRate, IsMultiGroupProduct, P2PEarning, Earning, SubAffEarning, AffWithdrawal, AffAdjustment, BFF, CurrentBFF, TotalDeposit
	FROM #Result
	WHERE RowIdx BETWEEN @RowStart AND @RowEnd
	ORDER BY RowIdx

	-- Return total
    SELECT
		SUM(TotalClick)			AS TotalClick
		,SUM(UniqueClick)		AS UniqueClick
		,SUM(Signup)			AS Signup
		,SUM(FDM)				AS FDM
		,SUM(FDM_Amount)		AS FDM_Amount
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
	DROP TABLE #TempCommission
	DROP TABLE #TotalDeposit

END
GO