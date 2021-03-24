/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_Commission_UnCalc]
	@AffIds				VARCHAR(MAX) = 'all'
	,@FromMonthDate		SMALLDATETIME
	,@ToMonthDate		SMALLDATETIME
	,@ProductIds		VARCHAR(MAX) = '0'
	,@Currencies		VARCHAR(MAX) = ''
	,@BaseCurrency		INT = 0
	,@IsSumAll			BIT = 0
	,@GetRowTotalOnly	BIT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core SP - Calculate commission for months which are not calculated yet

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @BeginOfFromMonthDate SMALLDATETIME, @EndOfToMonthDate SMALLDATETIME

	SELECT  @BeginOfFromMonthDate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate), 0) -- First day of @FromMonthDate
	SELECT  @EndOfToMonthDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0)) -- Last day of @ToMonthDate

	SELECT  @FromMonthDate = @BeginOfFromMonthDate, @ToMonthDate = @EndOfToMonthDate

	DECLARE @SoftLaunchDate SMALLDATETIME, @LaunchDate SMALLDATETIME
	SELECT  @SoftLaunchDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'SoftLaunchDate'
	SELECT  @LaunchDate		= CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'LaunchDate'

	IF @BeginOfFromMonthDate BETWEEN @SoftLaunchDate AND DATEADD(DAY, -1, @LaunchDate)
		SELECT @BeginOfFromMonthDate = @SoftLaunchDate

	-- Get sub affiliate
	DECLARE @InputAffIds VARCHAR(MAX) = @AffIds
	
	IF @AffIds <> 'all'
	BEGIN
		SELECT @AffIds = COALESCE(@AffIds + ',', '') + CONVERT(VARCHAR(20), ai.AffId)
		FROM dbo.Aff_f_StringSplit(@AffIds, ',') f
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ',' + ai.AllParentAffId + ',' LIKE '%,' + f.val + ',%'
	END

	-- AffCurrency
	DECLARE @AffCurrency INT
	SELECT  @AffCurrency = dbo.Aff_f_GetSetting('AffCurrency')

	IF @BaseCurrency = 0
		SET @BaseCurrency = @AffCurrency

	-- Get data
	BEGIN
		CREATE TABLE #ExchangeOanda (MonthDate SMALLDATETIME, Currency INT, Rate FLOAT)
		INSERT INTO #ExchangeOanda (MonthDate, Currency, Rate)
		SELECT ExchangeDate, ExchangeId,
			CASE @BaseCurrency
				WHEN  2 THEN MYR
				WHEN  3 THEN USD
				WHEN  6 THEN EUR
				WHEN 13 THEN CNY
				WHEN 20 THEN 1 -- cheat code for UAT testing
				WHEN 34 THEN IDR / 1000.0
				WHEN 43 THEN THB
				WHEN 51 THEN VND / 1000.0
				ELSE 0 END AS Rate
		FROM dbo.ExchangeOanda WITH (NOLOCK)
		WHERE ExchangeDate BETWEEN @BeginOfFromMonthDate AND @EndOfToMonthDate

		CREATE TABLE #Data
		(
			MonthDate		SMALLDATETIME,
			AffId			INT,
			CustId			INT,
			Currency		INT,
			ProductId		INT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Bonus			MONEY,
			Rebate			MONEY,
			Turnover		MONEY,
			Winloss			MONEY,
			IsDataInMonth	BIT DEFAULT ((1)) -- for first n months commission
		)

		INSERT INTO #Data
		(
			MonthDate,
			AffId,
			CustId,
			Currency,
			ProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Rebate,
			Turnover,
			Winloss
		)
		SELECT r.MonthDate, r.AffId, r.CustId, r.Currency, r.ProductId
			,SUM(r.Deposit		* e.Rate)	AS Deposit
			,SUM(r.Withdrawal	* e.Rate)	AS Withdrawal
			,SUM(r.Bonus		* e.Rate)	AS Bonus
			,SUM(r.Rebate		* e.Rate)	AS Rebate
			,SUM(r.Turnover		* e.Rate)	AS Turnover
			,SUM(r.Winloss		* e.Rate)	AS Winloss
		FROM (
			SELECT CONVERT(SMALLDATETIME, DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0))) AS MonthDate
				,AffId, CustId, Currency, CASE WHEN ProductId < 0 THEN 0 ELSE ProductId END AS ProductId
				,SUM(ISNULL(Deposit, 0))	AS Deposit
				,SUM(ISNULL(Withdrawal, 0))	AS Withdrawal
				,SUM(ISNULL(Bonus, 0))		AS Bonus
				,SUM(ISNULL(Rebate, 0))		AS Rebate
				,SUM(ISNULL(Turnover, 0))	AS Turnover
				,SUM(ISNULL(Winloss, 0))	AS Winloss
			FROM dbo.rptMemberDaily WITH (NOLOCK)
			WHERE WinlostDate BETWEEN @BeginOfFromMonthDate AND @EndOfToMonthDate
				AND (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), AffId) + ',%')
			GROUP BY CONVERT(SMALLDATETIME, DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)))
				,AffId, CustId, Currency, CASE WHEN ProductId < 0 THEN 0 ELSE ProductId END
		) r
			INNER JOIN #ExchangeOanda e ON r.MonthDate = e.MonthDate AND r.Currency = e.Currency
			LEFT JOIN dbo.MemberRemoval mr WITH (NOLOCK) ON r.CustId = mr.CustId AND mr.RemovedDate < r.MonthDate
		WHERE mr.CustId IS NULL
		GROUP BY r.MonthDate, r.AffId, r.CustId, r.Currency, r.ProductId
	END

	-- First n months commission (From SoftLaunchDate to LaunchDate)
	BEGIN
		IF EXISTS (SELECT 1 FROM #Data WHERE MonthDate < DATEADD(DAY, -1, @LaunchDate))
		BEGIN
			INSERT INTO #Data
			(
				MonthDate,
				AffId,
				CustId,
				Currency,
				ProductId,
				Deposit,
				Withdrawal,
				Bonus,
				Rebate,
				Turnover,
				Winloss,
				IsDataInMonth
			)
			SELECT
				DATEADD(DAY, -1, @LaunchDate) AS MonthDate,
				AffId,
				CustId,
				Currency,
				ProductId,
				Deposit,
				Withdrawal,
				Bonus,
				Rebate,
				Turnover,
				Winloss,
				0 AS IsDataInMonth
			FROM #Data
			WHERE MonthDate < DATEADD(DAY, -1, @LaunchDate)
		END
	END

	-- Setting
	BEGIN
		DECLARE @AffGroupInfo TABLE (MonthDate SMALLDATETIME, AffId INT, GroupId INT)
		
		;WITH CTE_AffGroup AS (SELECT DISTINCT MonthDate, AffId FROM #Data)
		INSERT INTO @AffGroupInfo (MonthDate, AffId, GroupId)
		SELECT agh.MonthDate, agh.AffId, agh.GroupId
		FROM CTE_AffGroup d
			INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON d.MonthDate = agh.MonthDate AND d.AffId = agh.AffId

		INSERT INTO @AffGroupInfo (MonthDate, AffId, GroupId)
		SELECT agh.MonthDate, agh.AffId, agh.GroupId
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		WHERE agh.MonthDate BETWEEN @FromMonthDate AND @ToMonthDate
			AND (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), agh.AffId) + ',%')
			AND EXISTS (SELECT 1 FROM dbo.DeductionSettingHistory dsh WITH (NOLOCK) WHERE dsh.MonthDate = agh.MonthDate AND dsh.GroupId = agh.GroupId AND dsh.DeductedAmount <> 0)
			AND NOT EXISTS (SELECT 1 FROM @AffGroupInfo a WHERE a.AffId = agh.AffId AND a.MonthDate = agh.MonthDate)

		DECLARE @Setting TABLE
		(
			MonthDate				SMALLDATETIME,
			GroupId					INT,
			ProductId				INT,
			GroupProductId			TINYINT,
			PlatFormFee				DECIMAL(9,8) DEFAULT (0),
			PlatFormAmount			MONEY DEFAULT (0),
			OperationalFee			DECIMAL(9,8) DEFAULT (0),
			OperationalAmount		MONEY DEFAULT (0),
			DepositFee				DECIMAL(9,8) DEFAULT (0),
			DepositAmount			MONEY DEFAULT (0),
			WithdrawalFee			DECIMAL(9,8) DEFAULT (0),
			WithdrawalAmount		MONEY DEFAULT (0)
		)

		;WITH CTE_Group AS (SELECT DISTINCT MonthDate, GroupId FROM @AffGroupInfo)
		INSERT INTO @Setting (MonthDate, GroupId, ProductId, GroupProductId, PlatFormFee, PlatFormAmount, OperationalFee, OperationalAmount, DepositFee, DepositAmount, WithdrawalFee, WithdrawalAmount)
		SELECT a.MonthDate, a.GroupId, ds.ProductId, ds.GroupProductId, ds.PlatFormFee, ds.PlatFormAmount, ds.OperationalFee, ds.OperationalAmount, ds.DepositFee, ds.DepositAmount, ds.WithdrawalFee, ds.WithdrawalAmount
		FROM CTE_Group a
			CROSS APPLY (
				SELECT
					dsh.ProductId,
					dsh.GroupProductId,
					SUM(CASE WHEN dsh.DeductionId = 10 THEN dsh.DeductedPercentage ELSE 0 END) AS PlatFormFee,
					SUM(CASE WHEN dsh.DeductionId = 10 THEN dsh.DeductedAmount ELSE 0 END) AS PlatFormAmount,
					SUM(CASE WHEN dsh.DeductionId = 11 THEN dsh.DeductedPercentage ELSE 0 END) AS OperationalFee,
					SUM(CASE WHEN dsh.DeductionId = 11 THEN dsh.DeductedAmount ELSE 0 END) AS OperationalAmount,
					SUM(CASE WHEN dsh.DeductionId = 13 THEN dsh.DeductedPercentage ELSE 0 END) AS DepositFee,
					SUM(CASE WHEN dsh.DeductionId = 13 THEN dsh.DeductedAmount ELSE 0 END) AS DepositAmount,
					SUM(CASE WHEN dsh.DeductionId = 14 THEN dsh.DeductedPercentage ELSE 0 END) AS WithdrawalFee,
					SUM(CASE WHEN dsh.DeductionId = 14 THEN dsh.DeductedAmount ELSE 0 END) AS WithdrawalAmount
				FROM dbo.DeductionSettingHistory dsh WITH (NOLOCK)
				WHERE a.MonthDate = dsh.MonthDate AND a.GroupId = dsh.GroupId
				GROUP BY
					dsh.ProductId,
					dsh.GroupProductId
			) AS ds

		UPDATE s
		SET s.PlatFormAmount = s.PlatFormAmount * e.Rate,
			s.OperationalAmount = s.OperationalAmount * e.Rate,
			s.DepositAmount = s.DepositAmount * e.Rate,
			s.WithdrawalAmount = s.WithdrawalAmount * e.Rate
		FROM @Setting s
			INNER JOIN #ExchangeOanda e ON s.MonthDate = e.MonthDate AND e.Currency = @BaseCurrency
	END

	DELETE d
	FROM #Data d
		INNER JOIN dbo.AffGroupHistory agh ON d.AffId = agh.AffId AND d.MonthDate = agh.MonthDate
		LEFT JOIN @Setting s ON agh.GroupId = s.GroupId AND agh.MonthDate = s.MonthDate AND d.ProductId = s.ProductId
	WHERE d.ProductId > 0 AND s.GroupId IS NULL

	-- Calculate commission
	BEGIN
		CREATE TABLE #Commission
		(
			MonthDate				SMALLDATETIME,
			AffId					INT,
			GroupId					INT,
			ProductId				INT,
			GroupProductId			TINYINT DEFAULT (0),
			Deposit					MONEY DEFAULT (0),
			Withdrawal				MONEY DEFAULT (0),
			Bonus					MONEY DEFAULT (0),
			Rebate					MONEY DEFAULT (0),
			Turnover				MONEY DEFAULT (0),
			Winloss					MONEY DEFAULT (0),
			-- Fees
			PlatFormFee				MONEY DEFAULT (0),
			OperationalFee			MONEY DEFAULT (0),
			DepositFee				MONEY DEFAULT (0),
			WithdrawalFee			MONEY DEFAULT (0),
			-- Calculation
			GrossWinloss			MONEY DEFAULT (0),
			NetWinloss				MONEY DEFAULT (0),
			QualifiedMember			INT DEFAULT (0),
			CommissionRate			DECIMAL(9,8) DEFAULT (0),
			Commission				MONEY DEFAULT (0),
			SubAffCommission		MONEY DEFAULT (0),
			IsHasMemberData			BIT DEFAULT (1)
		)
	
		CREATE NONCLUSTERED INDEX IX_MonthDate ON #Commission (MonthDate, AffId, GroupId, ProductId)
		
		-- Group by Product
		INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, GroupProductId, Turnover, Winloss, GrossWinloss, PlatFormFee)
		SELECT d.MonthDate, d.AffId, a.GroupId, d.ProductId, ISNULL(s.GroupProductId, 0), d.Turnover, d.Winloss,
			CASE WHEN s.GroupId IS NULL THEN 0 ELSE -d.Winloss END				AS GrossWinloss,
			-d.Winloss * ISNULL(s.PlatFormFee, 0) + ISNULL(s.PlatFormAmount, 0)	AS PlatFormFee
		FROM (
			SELECT MonthDate, AffId, ProductId, SUM(Turnover) Turnover, SUM(Winloss) Winloss
			FROM #Data
			WHERE ProductId > 0
			GROUP BY MonthDate, AffId, ProductId
		) d
			INNER JOIN @AffGroupInfo a ON d.MonthDate = a.MonthDate AND d.AffId = a.AffId
			LEFT JOIN @Setting s ON a.GroupId = s.GroupId AND d.MonthDate = s.MonthDate AND d.ProductId = s.ProductId
		
		-- Total
		INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, GroupProductId, Turnover, Winloss, Deposit, Withdrawal, Bonus, Rebate)
		SELECT d.MonthDate, d.AffId, a.GroupId, 0 AS ProductId, 0 AS GroupProductId, d.Turnover, d.Winloss, d.Deposit, d.Withdrawal, d.Bonus, d.Rebate
		FROM (
			SELECT MonthDate, AffId,
				0 AS Turnover,
				0 AS Winloss,
				SUM(Deposit)	AS Deposit,
				SUM(Withdrawal)	AS Withdrawal,
				SUM(Bonus)		AS Bonus,
				SUM(Rebate)		AS Rebate
			FROM #Data
			WHERE ProductId = 0
			GROUP BY MonthDate, AffId

			UNION ALL
			SELECT MonthDate, AffId,
				SUM(Turnover)	AS Turnover,
				SUM(Winloss)	AS Winloss,
				0 AS Deposit,
				0 AS Withdrawal,
				0 AS Bonus,
				0 AS Rebate
			FROM #Commission
			GROUP BY MonthDate, AffId
		) d
			INNER JOIN @AffGroupInfo a ON d.MonthDate = a.MonthDate AND d.AffId = a.AffId

		-- Update ActivePlayers
		UPDATE c
		SET c.QualifiedMember = t.ActivePlayers
		FROM #Commission c
			INNER JOIN (
				SELECT d.MonthDate, d.AffId, COUNT(DISTINCT d.CustId) AS ActivePlayers
				FROM #Data d
					INNER JOIN @AffGroupInfo a ON d.MonthDate = a.MonthDate AND d.AffId = a.AffId
					INNER JOIN @Setting s ON a.GroupId = s.GroupId AND d.MonthDate = s.MonthDate AND d.ProductId = s.ProductId
				WHERE d.ProductId > 0
				GROUP BY d.MonthDate, d.AffId
			) t ON c.MonthDate = t.MonthDate AND c.AffId = t.AffId
		WHERE c.ProductId = 0

		-- Update GrossWinloss, PlatFormFee
		UPDATE c
		SET c.GrossWinloss		= t.GrossWinloss,
			c.PlatFormFee		= t.PlatFormFee
		FROM #Commission c
			INNER JOIN (
				SELECT MonthDate, AffId, GroupId,
					SUM(GrossWinloss)		AS GrossWinloss,
					SUM(ABS(PlatFormFee))	AS PlatFormFee
				FROM (
					SELECT MonthDate, AffId, GroupId,
						SUM(GrossWinloss)	AS GrossWinloss,
						SUM(PlatFormFee)	AS PlatFormFee
					FROM #Commission
					WHERE ProductId > 0
					GROUP BY MonthDate, AffId, GroupId, GroupProductId -- PlatFormFee group by GroupProductId
				) s
				GROUP BY MonthDate, AffId, GroupId
			) t ON c.MonthDate = t.MonthDate AND c.AffId = t.AffId
		WHERE c.ProductId = 0

		-- Update OperationalFee, DepositFee, WithdrawalFee
		UPDATE c
		SET c.OperationalFee	= ABS(c.GrossWinloss) * s.OperationalFee + s.OperationalAmount,
			c.DepositFee		= c.Deposit * s.DepositFee + s.DepositAmount,
			c.WithdrawalFee		= c.WithdrawalFee * s.DepositFee + s.WithdrawalAmount
		FROM #Commission c
			INNER JOIN @Setting s ON c.MonthDate = s.MonthDate AND c.GroupId = s.GroupId AND c.ProductId = s.ProductId
		WHERE c.ProductId = 0

		-- Update NetWinloss
		UPDATE #Commission
		SET NetWinloss = GrossWinloss - (PlatFormFee + OperationalFee + DepositFee + WithdrawalFee) - (Bonus + Rebate)
		WHERE ProductId = 0
	
		-- Update Commission
		UPDATE c
		SET c.CommissionRate	= ISNULL(s.Commission, 0),
			c.Commission		= ISNULL(s.Commission, 0) * c.NetWinloss
		FROM #Commission c
			CROSS APPLY (
				SELECT gsh.TierId
				FROM dbo.TierSettingHistory gsh WITH (NOLOCK)
				WHERE c.MonthDate = gsh.MonthDate AND c.GroupId = gsh.GroupId
					AND FLOOR(ABS(c.NetWinloss)) BETWEEN gsh.MinAmount AND gsh.MaxAmount
			) AS t
			CROSS APPLY (
				SELECT TOP 1 gsh.Commission
				FROM dbo.TierSettingHistory gsh WITH (NOLOCK)
				WHERE c.MonthDate = gsh.MonthDate AND c.GroupId = gsh.GroupId
					AND c.QualifiedMember BETWEEN gsh.MinAM AND gsh.MaxAM
					AND gsh.TierId <= t.TierId
				ORDER BY gsh.TierId DESC
			) AS s
		WHERE c.ProductId = 0

		-- Reset PlatFormFee per product
		UPDATE #Commission
		SET PlatFormFee = 0
		WHERE ProductId > 0

		-- Filter by Currencies
		IF @Currencies <> ''
		BEGIN
			UPDATE c
			SET c.Turnover	= ISNULL(d.Turnover, 0),
				c.Winloss	= ISNULL(d.Winloss, 0)
			FROM #Commission c
				LEFT JOIN (
					SELECT MonthDate, AffId, ProductId,
						SUM(Turnover)	AS Turnover,
						SUM(Winloss)	AS Winloss
					FROM #Data
					WHERE ProductId > 0
						AND ',' + @Currencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), Currency) + ',%'
					GROUP BY MonthDate, AffId, ProductId
				) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId AND c.ProductId = d.ProductId
			WHERE c.ProductId > 0

			UPDATE c1
			SET c1.Turnover	= ISNULL(c2.Turnover, 0),
				c1.Winloss	= ISNULL(c2.Winloss, 0)
			FROM #Commission c1
				LEFT JOIN (
					SELECT MonthDate, AffId,
						SUM(Turnover)	AS Turnover,
						SUM(Winloss)	AS Winloss
					FROM #Commission
					WHERE ProductId > 0
					GROUP BY MonthDate, AffId
				) c2 ON c1.MonthDate = c2.MonthDate AND c1.AffId = c2.AffId
			WHERE c1.ProductId = 0
		END

		-- Filter by Products
		IF @ProductIds <> '0'
		BEGIN
			IF @ProductIds = ''
			BEGIN
				DELETE #Commission WHERE ProductId > 0
				UPDATE #Commission SET Turnover = 0, Winloss = 0
			END
			ELSE
			BEGIN
				UPDATE c1
				SET c1.Turnover	= ISNULL(c2.Turnover, 0),
					c1.Winloss	= ISNULL(c2.Winloss, 0)
				FROM #Commission c1
					LEFT JOIN (
						SELECT MonthDate, AffId,
							SUM(Turnover)	AS Turnover,
							SUM(Winloss)	AS Winloss
						FROM #Commission
						WHERE ',' + @ProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(10), ProductId) + ',%'
						GROUP BY MonthDate, AffId
					) c2 ON c1.MonthDate = c2.MonthDate AND c1.AffId = c2.AffId
				WHERE c1.ProductId = 0

				IF @GetRowTotalOnly = 0
					DELETE #Commission WHERE ',' + @ProductIds + ',' NOT LIKE '%,' + CONVERT(VARCHAR(10), ProductId) + ',%' AND ProductId <> 0
				ELSE
					DELETE #Commission WHERE ProductId <> 0
			END
		END
		ELSE IF @GetRowTotalOnly = 1
		BEGIN
			DELETE #Commission WHERE ProductId <> 0
		END

		IF EXISTS (SELECT 1 FROM #Commission WHERE MonthDate < @FromMonthDate OR MonthDate > @ToMonthDate)
		BEGIN
			DELETE #Commission WHERE MonthDate < @FromMonthDate OR MonthDate > @ToMonthDate
		END
	END

	-- Sub Affiliate Commission
	DECLARE @SubAffCommRate FLOAT = 0.1 -- 10%
	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME, AffId INT)

	IF EXISTS (SELECT 1 FROM #Commission WHERE ProductId = 0)
	BEGIN
		IF @InputAffIds <> 'all'
		BEGIN
			WITH CTE_MonthDate AS (
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0))
			)
			INSERT INTO @MonthDate (MonthDate, AffId)
			SELECT md.MonthDate, f.val
			FROM CTE_MonthDate md
				CROSS JOIN dbo.Aff_f_StringSplit(@InputAffIds, ',') f
			OPTION (MAXRECURSION 0)
		END
		ELSE
		BEGIN
			WITH CTE_MonthDate AS (
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0))
			)
			INSERT INTO @MonthDate (MonthDate, AffId)
			SELECT md.MonthDate, ai.AffId
			FROM CTE_MonthDate md
				CROSS JOIN dbo.AffInfo ai WITH (NOLOCK)
			WHERE ai.Status = 'Approved' AND ai.IsClosed = 0
			OPTION (MAXRECURSION 0)
		END
		
		IF EXISTS (
			SELECT 1
			FROM @MonthDate md
				LEFT JOIN #Commission c ON c.MonthDate = md.MonthDate AND c.AffId = md.AffId AND c.ProductId = 0
			WHERE c.AffId IS NULL
		)
		BEGIN
			INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, GroupProductId, IsHasMemberData)
			SELECT md.MonthDate, md.AffId, agh.GroupId, 0, 0, 0
			FROM @MonthDate md
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON agh.MonthDate = md.MonthDate AND agh.AffId = md.AffId
				LEFT JOIN #Commission c ON c.MonthDate = md.MonthDate AND c.AffId = md.AffId AND c.ProductId = 0
			WHERE c.AffId IS NULL
		END

		;WITH CTE_SubAffCommission AS
		(
			SELECT
				c.MonthDate,
				f.val AS AffId,
				SUM(POWER(@SubAffCommRate, f.Id) * c.NetWinloss * c.CommissionRate) AS SubAffCommission
			FROM #Commission c
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON agh.MonthDate = c.MonthDate AND agh.AffId = c.AffId
				CROSS APPLY dbo.Aff_f_StringSplit(agh.AllParentAffId, ',') f
			WHERE c.ProductId = 0
			GROUP BY
				c.MonthDate
				,f.val
		)
		UPDATE c
		SET c.SubAffCommission = s.SubAffCommission
		FROM #Commission c
			INNER JOIN CTE_SubAffCommission s ON s.AffId = c.AffId AND s.MonthDate = c.MonthDate
		WHERE c.ProductId = 0

		IF @AffIds <>  'all'
		BEGIN
			DELETE #Commission
			WHERE ',' + @InputAffIds + ',' NOT LIKE '%,' + CONVERT(VARCHAR(20), AffId) + ',%'
		END

		DELETE #Commission
		WHERE IsHasMemberData = 0 AND SubAffCommission = 0
	END

	-- Reset Fee, Commission if MonthDate < LaunchDate
	IF EXISTS (SELECT 1 FROM #Commission WHERE MonthDate < DATEADD(DAY, -1, @LaunchDate))
	BEGIN
		UPDATE #Commission
		SET Commission				= 0,
			SubAffCommission		= 0,
			PlatFormFee				= 0,
			OperationalFee			= 0,
			DepositFee				= 0,
			WithdrawalFee			= 0,
			CommissionRate			= 0
		WHERE MonthDate < DATEADD(DAY, -1, @LaunchDate)
	END

	-- Data between SoftLaunchDate and LaunchDate
	IF EXISTS (SELECT 1 FROM #Data WHERE IsDataInMonth = 0)
	BEGIN
		UPDATE c
		SET c.Deposit		= ISNULL(d.Deposit, 0),
			c.Withdrawal	= ISNULL(d.Withdrawal, 0),
			c.Bonus			= ISNULL(d.Bonus, 0),
			c.Rebate		= ISNULL(d.Rebate, 0),
			c.Turnover		= ISNULL(d.Turnover, 0),
			c.Winloss		= ISNULL(d.Winloss, 0),
			c.GrossWinloss	= ISNULL(-d.Winloss, 0)
		FROM #Commission c
			INNER JOIN (
				SELECT MonthDate, AffId, ProductId,
					SUM(Deposit)	AS Deposit,
					SUM(Withdrawal)	AS Withdrawal,
					SUM(Bonus)		AS Bonus,
					SUM(Rebate)		AS Rebate,
					SUM(Turnover)	AS Turnover,
					SUM(Winloss)	AS Winloss
				FROM #Data
				WHERE IsDataInMonth = 1
			) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId AND c.ProductId = d.ProductId
		WHERE c.MonthDate = DATEADD(DAY, -1, @LaunchDate)

		UPDATE c
		SET c.Turnover		= d.Turnover,
			c.Winloss		= d.Winloss,
			c.GrossWinloss	= d.GrossWinloss
		FROM #Commission c
			INNER JOIN (
				SELECT MonthDate, AffId,
					SUM(Turnover)		AS Turnover,
					SUM(Winloss)		AS Winloss,
					SUM(GrossWinloss)	AS GrossWinloss
				FROM #Commission
				WHERE MonthDate = DATEADD(DAY, -1, @LaunchDate)
					AND ProductId > 0
				GROUP BY MonthDate, AffId
			) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId
		WHERE c.MonthDate = DATEADD(DAY, -1, @LaunchDate)
			AND c.ProductId = 0
	END

	-- Return data
	IF @IsSumAll = 1
	BEGIN
		SELECT
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0)) AS MonthDate,
			c.AffId,
			c.GroupId,
			c.ProductId,
			SUM(c.Deposit)			AS Deposit,
			SUM(c.Withdrawal)		AS Withdrawal,
			SUM(c.Bonus)			AS Bonus,
			SUM(c.Rebate)			AS Rebate,
			SUM(c.Turnover)			AS Turnover,
			SUM(c.Winloss)			AS Winloss,
			SUM(c.PlatFormFee)		AS PlatFormFee,
			SUM(c.OperationalFee)	AS OperationalFee,
			SUM(c.DepositFee)		AS DepositFee,
			SUM(c.WithdrawalFee)	AS WithdrawalFee,
			SUM(c.GrossWinloss)		AS GrossWinloss,
			SUM(c.NetWinloss)		AS NetWinloss,
			SUM(c.QualifiedMember)	AS QualifiedMember,
			SUM(c.CommissionRate)	AS CommissionRate,
			SUM(c.Commission)		AS Commission,
			SUM(c.SubAffCommission)	AS SubAffCommission
		FROM #Commission c
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON c.AffId = ai.AffId
		GROUP BY
			c.AffId,
			c.GroupId,
			c.ProductId
	END
	ELSE
	BEGIN
		SELECT
			c.MonthDate,
			c.AffId,
			c.GroupId,
			c.ProductId,
			c.Deposit,
			c.Withdrawal,
			c.Bonus,
			c.Rebate,
			c.Turnover,
			c.Winloss,
			c.PlatFormFee,
			c.OperationalFee,
			c.DepositFee,
			c.WithdrawalFee,
			c.GrossWinloss,
			c.NetWinloss,
			c.QualifiedMember,
			c.CommissionRate,
			c.Commission,
			c.SubAffCommission
		FROM #Commission c
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON c.AffId = ai.AffId
	END

	DROP TABLE #Data
	DROP TABLE #Commission
	DROP TABLE #ExchangeOanda
END
GO