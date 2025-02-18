/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateReport_Sel]
	@Username			NVARCHAR(50) = NULL
	,@GroupIds 			VARCHAR(MAX) = ''
	,@FromDate			SMALLDATETIME
	,@ToDate			SMALLDATETIME
	,@PreferredLanguage	VARCHAR(11) = NULL
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

	Param's Explanation:
		- @SortType: 1: Affiliate username, 2: Turnover, 3: GGR, 4: Earning (Commission)
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
		- @ProductIds: list of products
		- @BaseCurrency : Currency of B2C
		- @Currencies : Currency of B2C, 72: represent for USD( currency 72, 3)
		- @PaymentCurrencies : Currency of B2C, 72: represent for USD( currency 72, 3)
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

			DECLARE @AffInfo TABLE (AffId INT, AffUsername VARCHAR(50),MonthDate SMALLDATETIME, GroupId INT)
				INSERT INTO @AffInfo (AffId, AffUsername, MonthDate, GroupId)
				SELECT a.AffId, a.Username, agh.MonthDate, a.GroupId
				FROM dbo.AffInfo a WITH (NOLOCK)
					INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON a.AffId = agh.AffId AND agh.MonthDate BETWEEN @StartDayOfFromDate AND @LastDayOfToDate													
				WHERE (Username LIKE '%' + @Username + '%' OR @Username IS NULL)
					AND Status NOT IN ('Pending', 'Disapproved')					
			
			-- Get Product List		
			DECLARE @Products TABLE (ProductId INT)
			SET @ProductIds = dbo.Aff_f_AddRelatedProducts(@ProductIds)
			INSERT INTO @Products (ProductId)
			SELECT ProductId FROM dbo.Products WITH (NOLOCK) 
			WHERE ProductId IN (SELECT CONVERT(INT,value) AS ProductID FROM STRING_SPLIT(@ProductIds, ','))

			CREATE TABLE #ProductSetting (AffId INT, AffUsername VARCHAR(50), ProductId INT, FromDate SMALLDATETIME, ToDate SMALLDATETIME, IsStraightSetting BIT)
			INSERT INTO #ProductSetting (AffId, AffUsername, ProductId, FromDate, ToDate, IsStraightSetting)
			SELECT DISTINCT a.AffId, a.AffUsername, dsh.ProductId, DATEADD(MONTH, DATEDIFF(MONTH, 0, dsh.MonthDate), 0), dsh.MonthDate, 0
			FROM @AffInfo a
				INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON a.GroupId = dsh.GroupId AND a.MonthDate = dsh.MonthDate
				INNER JOIN @Products p ON dsh.ProductId = p.ProductId
			
			INSERT INTO #ProductSetting (AffId, AffUsername, ProductId, FromDate, ToDate, IsStraightSetting)
			SELECT DISTINCT a.AffId, a.AffUsername, dsh.ProductId, DATEADD(MONTH, DATEDIFF(MONTH, 0, dsh.MonthDate), 0), dsh.MonthDate, 1
			FROM @AffInfo a
				INNER JOIN dbo.StraightSettingHistory dsh WITH (NOLOCK) ON a.GroupId = dsh.GroupId AND a.MonthDate = dsh.MonthDate
				INNER JOIN @Products p ON dsh.ProductId = p.ProductId

			;WITH CTE_Data AS(
				SELECT CONVERT(SMALLDATETIME,EOMONTH(r.WinlostDate)) AS MonthDate
					,r.AffId
					,Currency
					,SUM(ISNULL(Deposit, 0))	AS Deposit
					,SUM(ISNULL(Withdrawal, 0))	AS Withdrawal
					,SUM(ISNULL(Bonus, 0))		AS Bonus
					,SUM(ISNULL(Rebate, 0))		AS Rebate
					,SUM(CASE WHEN a.IsStraightSetting = 0 THEN ISNULL(Turnover, 0) ELSE 0 END)	AS Turnover
					,SUM(CASE WHEN a.IsStraightSetting = 0 THEN ISNULL(Winloss, 0) - ISNULL(ProgressiveWin, 0) + ISNULL(ProgressiveBet, 0) ELSE 0 END) AS Winloss
					,SUM(CASE WHEN a.IsStraightSetting = 1 THEN ISNULL(Revenue, 0) ELSE 0 END)	AS Revenue
					,COUNT(DISTINCT IIF(r.productId > 0 AND a.IsStraightSetting = 0, r.CustId, NULL))AS ActivePlayer
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
					LEFT JOIN #ProductSetting a ON r.AffId = a.AffId AND r.ProductId = a.ProductId AND r.WinlostDate BETWEEN a.FromDate AND a.ToDate
				WHERE r.WinlostDate >= @FromDate 
					AND r.WinlostDate < DATEADD(DAY, 1, @ToDate)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
						WHERE mr.CustId = r.custid AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
					AND (a.ProductId IS NOT NULL OR r.ProductId = -1)
				GROUP BY CONVERT(SMALLDATETIME,EOMONTH(r.WinlostDate))
					,r.AffId
					,Currency
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
				,t.Deposit
				,t.Withdrawal
				,t.Bonus
				,t.Rebate
				,t.Turnover
				,t.Winloss
				,t.Revenue
				,0 AS P2PFee
				,0 AS PlatFormFee
				,0 AS OperationalFee
				,0 AS DepositFee
				,0 AS WithdrawalFee
				,t.GrossWinloss
				,0 AS NetWinloss
				,0 AS NetTurnover
				,t.ActivePlayer
				,0 AS QualifiedMember
				,0 AS CommissionRate
				,0 AS Commission
				,0 AS StraightCommission
				,0 AS SubAffCommission
				,0 AS IsMultiGroupProduct 
		FROM(
				SELECT r.AffId
					,SUM(r.Deposit		* e.Rate)	AS Deposit
					,SUM(r.Withdrawal	* e.Rate)	AS Withdrawal
					,SUM(r.Bonus		* e.Rate)	AS Bonus
					,SUM(r.Rebate		* e.Rate)	AS Rebate
					,SUM(r.Turnover		* e.Rate)	AS Turnover
					,SUM(r.Winloss		* e.Rate)	AS Winloss
					,SUM(r.Revenue		* e.Rate)	AS Revenue
					,- SUM(r.Winloss	* e.Rate)	AS GrossWinloss
					,SUM(ISNULL(r.ActivePlayer,0))	AS ActivePlayer
				FROM CTE_Data r
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.MonthDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
				GROUP BY r.AffId
			)t				
			DROP TABLE #ProductSetting
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
			SELECT AffId, SUM(TotalClick), COUNT(1) AS UniqueClick
			FROM
			(
				SELECT
					AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)) AS MonthDate,
					IP,
					COUNT(1) AS TotalClick
				FROM dbo.ClickStatistics_bk WITH (NOLOCK)
				WHERE Date BETWEEN @tempFromDate AND @tempToDate
				GROUP BY
					AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)),
					IP
			) AS c
			GROUP BY AffId
		END

		-- Signup, FDM
		CREATE TABLE #Signup (AffId INT, Signup INT, FDM INT)
		INSERT INTO #Signup (AffId, Signup, FDM)
		SELECT mi.AffId
			,COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < DATEADD(DAY, 1, @ToDate) THEN 1 ELSE NULL END) AS Signup
			,COUNT(CASE WHEN mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < DATEADD(DAY, 1, @ToDate) THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
		GROUP BY mi.AffId

		-- AffWithdrawal, AffAdjustment
		CREATE TABLE #AffTrans (AffId INT, AffWithdrawal MONEY, AffAdjustment MONEY, BFF MONEY, CurrentBBF MONEY)
		INSERT INTO #AffTrans (AffId, AffWithdrawal, AffAdjustment, BFF, CurrentBBF)
		SELECT at.AffId,
			SUM((CASE WHEN at.TransType = 202 AND at.TransDate >= @FromDate THEN ABS(at.Amount) ELSE 0 END) * e.Rate) AS AffWithdrawal,
			SUM((CASE WHEN at.TransType = 203 AND at.TransDate >= @FromDate THEN at.Amount ELSE 0 END) * e.Rate) AS AffAdjustment,
			SUM(CASE WHEN TransDate < DATEADD(DAY, 1, @ToDate) THEN Amount * e.Rate ELSE NULL END) AS BFF,
			SUM(Amount * e.Rate) AS CurrentBBF		
		FROM dbo.AffTrans at WITH (NOLOCK)
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON at.AffCurrency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(at.TransDate, ISNULL(t.ExchangeId, at.AffCurrency), @BaseExchangeId) e
		WHERE Status IN ('Pending', 'Approved', 'Completed')
		GROUP BY AffId

		-- Total Deposit
		CREATE TABLE #TotalDeposit(AffId INT, TotalDeposit BIGINT)
		INSERT INTO #TotalDeposit(AffId, TotalDeposit)
		SELECT mi.AffId
			,COUNT(1) AS TotalDeposit
		FROM bodb_12B.dbo.DepositInfo d WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.CustId = mi.CustId
		WHERE d.WinlostDate BETWEEN DATEADD(DAY, -1, @FromDate) AND DATEADD(DAY, 1, @ToDate)
			AND d.Status = 3 -- Approved
			AND d.CreateTime >= @FromDateTimeGMT0 
			AND d.CreateTime < DATEADD(DAY, 1, @ToDateTimeGMT0)
		GROUP BY mi.AffId
	END

	-- Return data
	BEGIN
		CREATE TABLE #Result
		(
			AffId				INT,
			Username			NVARCHAR(30),
			PaymentCurrency		VARCHAR(5),
			TotalClick			INT,
			UniqueClick			INT,
			Signup				INT,
			FDM					INT,
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
		INSERT INTO #Result
		(
			AffId,
			Username,
			PaymentCurrency,
			TotalClick,
			UniqueClick,
			Signup,
			FDM,
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
			ad.Player_CurrencyCode AS PaymentCurrency,
			ISNULL(s.TotalClick, 0)				AS TotalClick,
			ISNULL(s.UniqueClick, 0)			AS UniqueClick,
			ISNULL(su.Signup, 0)				AS Signup,
			ISNULL(su.FDM, 0)					AS FDM,
			ISNULL(tc.ActivePlayer, 0)			AS ActivePlayer,
			ISNULL(tc.QualifiedMember, 0)		AS QualifiedMember,
			ISNULL(a.NoOfSubAff, 0)				AS NoOfSubAff,
			ISNULL(tc.Deposit, 0)				AS Deposit,
			ISNULL(tc.Withdrawal, 0)			AS Withdrawal,
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
				CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN ISNULL(tc.Commission, 0) END DESC) AS RowIdx
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
			INNER JOIN bodb_12B.dbo.Customer c WITH(NOLOCK) ON ad.Player_CustId = c.CustId
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
			LEFT JOIN (
				SELECT ParentAffId, COUNT(1) AS NoOfSubAff
				FROM dbo.AffInfo WITH (NOLOCK)
				WHERE Status = 'Approved'
					AND ApprovedDate >= @FromDate AND ApprovedDate < DATEADD(DAY, 1, @ToDate)
				GROUP BY ParentAffId
			) a ON ai.AffId = a.ParentAffId
			LEFT JOIN #TotalDeposit td ON td.AffId = ai.AffId
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
			AND	1 = (CASE
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
	SELECT AffId, Username, PaymentCurrency, TotalClick, UniqueClick, Signup, FDM, ActivePlayer, QualifiedMember, NoOfSubAff
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
		,SUM(ActivePlayer)		AS ActivePlayer
		,SUM(QualifiedMember)		AS QualifiedMember
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