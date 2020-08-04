/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
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
	DB: DBAFFN8B-Affiliate_N8B
	Task: Core SP - Calculate commission for months which are not calculated yet

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
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

	-- Get data
	BEGIN
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
			Turnover		MONEY,
			Winloss			MONEY,

			Deposit_Base	MONEY,
			Withdrawal_Base	MONEY,
			Bonus_Base		MONEY,
			Turnover_Base	MONEY,
			Winloss_Base	MONEY,

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
			Turnover,
			Winloss,

			Deposit_Base,
			Withdrawal_Base,
			Bonus_Base,
			Turnover_Base,
			Winloss_Base
		)
		SELECT
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate
			,md.AffId
			,md.CustId
			,md.Currency
			,CASE WHEN md.ProductId < 0 THEN 0 ELSE md.ProductId END   AS ProductId

			,SUM(ISNULL(md.Deposit, 0)		* ISNULL(md.AffExRate, 1)) AS Deposit
			,SUM(ISNULL(md.Withdrawal, 0)	* ISNULL(md.AffExRate, 1)) AS Withdrawal
			,SUM(ISNULL(md.Bonus, 0)		* ISNULL(md.AffExRate, 1)) AS Bonus
			,SUM(ISNULL(md.Turnover, 0)		* ISNULL(md.AffExRate, 1)) AS Turnover
			,SUM(ISNULL(md.Winloss, 0)		* ISNULL(md.AffExRate, 1)) AS Winloss

			,SUM(ISNULL(md.Deposit, 0)		* ISNULL(e.Rate, 1)) AS Deposit_Base
			,SUM(ISNULL(md.Withdrawal, 0)	* ISNULL(e.Rate, 1)) AS Withdrawal_Base
			,SUM(ISNULL(md.Bonus, 0)		* ISNULL(e.Rate, 1)) AS Bonus_Base
			,SUM(ISNULL(md.Turnover, 0)		* ISNULL(e.Rate, 1)) AS Turnover_Base
			,SUM(ISNULL(md.Winloss, 0)		* ISNULL(e.Rate, 1)) AS Winloss_Base
		FROM dbo.rptMemberDaily md WITH (NOLOCK)
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(md.WinlostDate, md.Currency, @BaseCurrency) e
		WHERE (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), md.AffId) + ',%')
			AND md.winlostdate BETWEEN @BeginOfFromMonthDate AND @EndOfToMonthDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate < DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
					AND mr.CustId = md.CustId
				)
		GROUP BY
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
			,md.AffId
			,md.CustId
			,md.Currency
			,CASE WHEN md.ProductId < 0 THEN 0 ELSE md.ProductId END
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
				Turnover,
				Winloss,

				Deposit_Base,
				Withdrawal_Base,
				Bonus_Base,
				Turnover_Base,
				Winloss_Base,

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
				Turnover,
				Winloss,

				Deposit_Base,
				Withdrawal_Base,
				Bonus_Base,
				Turnover_Base,
				Winloss_Base,

				0 AS IsDataInMonth
			FROM #Data
			WHERE MonthDate < DATEADD(DAY, -1, @LaunchDate)
		END
	END

	-- Setting
	BEGIN
		DECLARE @AffGroupInfo TABLE
		(
			MonthDate	SMALLDATETIME
			,AffId		INT
			,GroupId	INT
			,QMTurnOver	MONEY
		)
		INSERT INTO @AffGroupInfo (MonthDate, AffId, GroupId, QMTurnOver)
		SELECT DISTINCT agh.MonthDate, agh.AffId, agh.GroupId, 0
		FROM #Data d
			INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON d.MonthDate = agh.MonthDate AND d.AffId = agh.AffId

		INSERT INTO @AffGroupInfo (MonthDate, AffId, GroupId, QMTurnOver)
		SELECT agh.MonthDate, agh.AffId, agh.GroupId, 0
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		WHERE agh.MonthDate BETWEEN @FromMonthDate AND @ToMonthDate
			AND (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), agh.AffId) + ',%')
			AND EXISTS (SELECT 1 FROM dbo.DeductionSettingHistory dsh WITH (NOLOCK) WHERE dsh.MonthDate = agh.MonthDate AND dsh.GroupId = agh.GroupId AND dsh.DeductedAmount <> 0)
			AND NOT EXISTS (SELECT 1 FROM @AffGroupInfo a WHERE a.AffId = agh.AffId AND a.MonthDate = agh.MonthDate)

		DECLARE @Setting TABLE
		(
			MonthDate				SMALLDATETIME
			,GroupId				INT
			,ProductId				INT
			,GroupProductId			TINYINT
			,PlatFormFee			DECIMAL(9,8) DEFAULT (0)
			,PlatFormAmount			MONEY DEFAULT (0)
			,OperationalFee			DECIMAL(9,8) DEFAULT (0)
			,OperationalAmount		MONEY DEFAULT (0)
			,BankingFee				DECIMAL(9,8) DEFAULT (0)
			,BankingAmount			MONEY DEFAULT (0)
		)

		;WITH CTE_Group AS
		(
			SELECT MonthDate, GroupId
			FROM @AffGroupInfo
			GROUP BY MonthDate, GroupId
		)
		INSERT INTO @Setting
		(
			MonthDate,
			GroupId,
			ProductId,
			GroupProductId,
			PlatFormFee,
			PlatFormAmount,
			OperationalFee,
			OperationalAmount,
			BankingFee,
			BankingAmount
		)
		SELECT
			a.MonthDate,
			a.GroupId,
			ds.ProductId,
			ds.GroupProductId,
			ds.PlatFormFee,
			ds.PlatFormAmount,
			ds.OperationalFee,
			ds.OperationalAmount,
			ds.BankingFee,
			ds.BankingAmount
		FROM CTE_Group a
			CROSS APPLY (
				SELECT
					dsh.ProductId,
					dsh.GroupProductId,
					SUM(CASE WHEN dsh.DeductionId = 10 THEN dsh.DeductedPercentage ELSE 0 END) AS PlatFormFee,
					SUM(CASE WHEN dsh.DeductionId = 10 THEN dsh.DeductedAmount ELSE 0 END) AS PlatFormAmount,
					SUM(CASE WHEN dsh.DeductionId = 11 THEN dsh.DeductedPercentage ELSE 0 END) AS OperationalFee,
					SUM(CASE WHEN dsh.DeductionId = 11 THEN dsh.DeductedAmount ELSE 0 END) AS OperationalAmount,
					SUM(CASE WHEN dsh.DeductionId = 12 THEN dsh.DeductedPercentage ELSE 0 END) AS BankingFee,
					SUM(CASE WHEN dsh.DeductionId = 12 THEN dsh.DeductedAmount ELSE 0 END) AS BankingAmount
				FROM dbo.DeductionSettingHistory dsh WITH (NOLOCK)
				WHERE a.MonthDate = dsh.MonthDate AND a.GroupId = dsh.GroupId
				GROUP BY
					dsh.ProductId,
					dsh.GroupProductId
			) AS ds
	END

	-- Calculate commission
	BEGIN
		CREATE TABLE #Commission
		(
			MonthDate				SMALLDATETIME,
			AffId					INT,
			GroupId					INT,
			ProductId				INT,
			GroupProductId			TINYINT,
			Deposit					MONEY DEFAULT (0),
			Withdrawal				MONEY DEFAULT (0),
			Bonus					MONEY DEFAULT (0),
			Turnover				MONEY DEFAULT (0),
			Winloss					MONEY DEFAULT (0),
			-- Fees
			PlatFormFee				MONEY DEFAULT (0),
			OperationalFee			MONEY DEFAULT (0),
			BankingFee				MONEY DEFAULT (0),
			-- Calculation
			GrossWinloss			MONEY DEFAULT (0),
			NetWinloss				MONEY DEFAULT (0),
			ActivePlayer			INT DEFAULT (0),
			QualifiedMember			INT DEFAULT (0),
			QMTurnover				MONEY DEFAULT (0),
			CommissionRate			DECIMAL(9,8) DEFAULT (0),
			Commission				MONEY DEFAULT (0),
			SubAffCommission		MONEY DEFAULT (0),
			-- Base Currency
			Deposit_Base			MONEY DEFAULT (0),
			Withdrawal_Base			MONEY DEFAULT (0),
			Bonus_Base				MONEY DEFAULT (0),
			Turnover_Base			MONEY DEFAULT (0),
			Winloss_Base			MONEY DEFAULT (0),
			PlatFormFee_Base		MONEY DEFAULT (0),
			OperationalFee_Base		MONEY DEFAULT (0),
			BankingFee_Base			MONEY DEFAULT (0),
			GrossWinloss_Base		MONEY DEFAULT (0),
			NetWinloss_Base			MONEY DEFAULT (0),
			Commission_Base			MONEY DEFAULT (0),
			SubAffCommission_Base	MONEY DEFAULT (0),
			IsHaveDataMember		BIT DEFAULT (1),
		)
	
		CREATE NONCLUSTERED INDEX IX_MonthDate ON #Commission (MonthDate, AffId, GroupId, ProductId)
		
		-- Group by Product
		INSERT INTO #Commission
		(
			MonthDate,
			AffId,
			ProductId,
			
			Turnover,
			Winloss,

			Turnover_Base,
			Winloss_Base
		)
		SELECT MonthDate, AffId, ProductId
			,SUM(Turnover)		AS Turnover
			,SUM(Winloss)		AS Winloss
			,SUM(Turnover_Base)	AS Turnover_Base
			,SUM(Winloss_Base)	AS Winloss_Base
		FROM #Data
		WHERE ProductId > 0
		GROUP BY MonthDate, AffId, ProductId

		-- Total
		;WITH CTE_SumMember AS
		(
			SELECT MonthDate, AffId, CustId
				,SUM(Turnover)	AS Turnover
			FROM #Data
			GROUP BY MonthDate, AffId, CustId
		)
		INSERT INTO #Commission
		(
			MonthDate,
			AffId,
			ProductId,

			Deposit,
			Withdrawal,
			Bonus,
			Turnover,
			Winloss,

			Deposit_Base,
			Withdrawal_Base,
			Bonus_Base,
			Turnover_Base,
			Winloss_Base,

			ActivePlayer,
			QualifiedMember,
			QMTurnover
		)
		SELECT MonthDate, AffId, 0	AS ProductId,
			SUM(Deposit)			AS Deposit,
			SUM(Withdrawal)			AS Withdrawal,
			SUM(Bonus)				AS Bonus,
			SUM(Turnover)			AS Turnover,
			SUM(Winloss)			AS Winloss,

			SUM(Deposit_Base)		AS Deposit_Base,
			SUM(Withdrawal_Base)	AS Withdrawal_Base,
			SUM(Bonus_Base)			AS Bonus_Base,
			SUM(Turnover_Base)		AS Turnover_Base,
			SUM(Winloss_Base)		AS Winloss_Base,

			SUM(ActivePlayer)		AS ActivePlayer,
			SUM(ActivePlayer)		AS QualifiedMember, -- base on ActivePlayer
			SUM(QMTurnover)			AS QMTurnover
		FROM
		(
			SELECT dt.MonthDate, dt.AffId, a.QMTurnover
				,0 AS Deposit
				,0 AS Withdrawal
				,0 AS Bonus
				,0 AS Turnover
				,0 AS Winloss

				,0 AS Deposit_Base
				,0 AS Withdrawal_Base
				,0 AS Bonus_Base
				,0 AS Turnover_Base
				,0 AS Winloss_Base

				,SUM(CASE WHEN dt.Turnover > 0 THEN 1 ELSE 0 END) AS ActivePlayer
			FROM CTE_SumMember dt
				INNER JOIN @AffGroupInfo a ON dt.AffId = a.AffId AND dt.MonthDate = a.MonthDate
			GROUP BY dt.MonthDate, dt.AffId, a.QMTurnover

			UNION ALL
			SELECT MonthDate, AffId, 0 AS QMTurnover
				,SUM(Deposit)			AS Deposit
				,SUM(Withdrawal)		AS Withdrawal
				,SUM(Bonus)				AS Bonus
				,SUM(Turnover)			AS Turnover
				,SUM(Winloss)			AS Winloss

				,SUM(Deposit_Base)		AS Deposit_Base
				,SUM(Withdrawal_Base)	AS Withdrawal_Base
				,SUM(Bonus_Base)		AS Bonus_Base
				,SUM(Turnover_Base)		AS Turnover_Base
				,SUM(Winloss_Base)		AS Winloss_Base

				,0 AS ActivePlayer
			FROM #Data
			GROUP BY MonthDate, AffId
		) AS A
		GROUP BY MonthDate, AffId

		-- Calculate fees
		;MERGE #Commission AS t
		USING
		(
			SELECT a.AffId, a.GroupId, a.MonthDate, s.ProductId
					,s.GroupProductId, s.PlatFormFee, s.PlatFormAmount
					,s.OperationalFee, s.OperationalAmount
					,s.BankingFee, s.BankingAmount
			FROM @AffGroupInfo a
				INNER JOIN @Setting s ON a.GroupId = s.GroupId AND a.MonthDate = s.MonthDate
		) AS s
			ON		t.AffId = s.AffId
				AND t.MonthDate = s.MonthDate
				AND t.ProductId = s.ProductId
		WHEN MATCHED THEN UPDATE
			SET t.GroupId				= s.GroupId,
				t.GroupProductId		= s.GroupProductId,
				t.GrossWinloss			= -t.Winloss,
				t.GrossWinloss_Base		= -t.Winloss_Base,
				t.PlatFormFee			= -t.Winloss * s.PlatFormFee + s.PlatFormAmount,
				t.OperationalFee		= ABS(t.Winloss) * s.OperationalFee + s.OperationalAmount,
				t.BankingFee			= (t.Deposit + t.Withdrawal) * s.BankingFee + s.BankingAmount
		WHEN NOT MATCHED BY TARGET THEN INSERT
			(MonthDate,AffId,GroupId,ProductId,GroupProductId,PlatFormFee,OperationalFee,BankingFee)
			VALUES
			(MonthDate,AffId,GroupId,ProductId,GroupProductId,PlatFormAmount,OperationalAmount,BankingAmount);

		;WITH CTE_PlatFormFee AS
		(
			SELECT
				MonthDate,
				AffId,
				SUM(ABS(PlatFormFee)) AS PlatFormFee
			FROM
			(
				SELECT
					MonthDate,
					AffId,
					GroupProductId,
					SUM(PlatFormFee) AS PlatFormFee
				FROM #Commission
				WHERE ProductId > 0
				GROUP BY
					MonthDate,
					AffId,
					GroupProductId
			) AS pf
			GROUP BY
				MonthDate,
				AffId
		)
		UPDATE c
		SET c.PlatFormFee = pf.PlatFormFee
		FROM #Commission c
			INNER JOIN CTE_PlatFormFee pf ON c.MonthDate = pf.MonthDate AND c.AffId = pf.AffId
		WHERE c.ProductId = 0

		-- Total Gross Winloss, Total Net Winloss
		UPDATE c
		SET c.GrossWinloss			= e.GrossWinloss,
			c.GrossWinloss_Base		= e.GrossWinloss_Base,
			c.NetWinloss			= e.GrossWinloss - (c.PlatFormFee + c.OperationalFee + c.BankingFee)
		FROM #Commission c
			CROSS APPLY (
				SELECT
					SUM(GrossWinloss)		AS GrossWinloss,
					SUM(GrossWinloss_Base)	AS GrossWinloss_Base
				FROM #Commission e
				WHERE c.MonthDate = e.MonthDate AND c.AffId = e.AffId
					AND e.ProductId > 0
			) AS e
		WHERE c.ProductId = 0
	
		-- Commission
		UPDATE c
		SET c.CommissionRate	= ISNULL(s.Commission, 0),
			c.Commission		= ISNULL(s.Commission, 0) * (c.NetWinloss - c.Bonus)
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

		-- Filter by Currencies
		IF @Currencies <> ''
		BEGIN
			UPDATE c
			SET c.Turnover			= d.Turnover
				,c.Winloss			= d.Winloss
				,c.Turnover_Base	= d.Turnover_Base
				,c.Winloss_Base		= d.Winloss_Base
			FROM #Commission c
				CROSS APPLY (
					SELECT
						SUM(d.Turnover)			AS Turnover
						,SUM(d.Winloss)			AS Winloss
						,SUM(d.Turnover_Base)	AS Turnover_Base
						,SUM(d.Winloss_Base)	AS Winloss_Base
					FROM #Data d
					WHERE c.MonthDate = d.MonthDate AND c.AffId = d.AffId AND c.ProductId = d.ProductId
						AND ',' + @Currencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), d.Currency) + ',%'
				) d
			WHERE c.ProductId > 0

			UPDATE c1
			SET c1.Turnover			= c2.Turnover
				,c1.Winloss			= c2.Winloss
				,c1.Turnover_Base	= c2.Turnover_Base
				,c1.Winloss_Base	= c2.Winloss_Base
			FROM #Commission c1
				CROSS APPLY (
					SELECT
						SUM(c2.Turnover)		AS Turnover
						,SUM(c2.Winloss)		AS Winloss
						,SUM(c2.Turnover_Base)	AS Turnover_Base
						,SUM(c2.Winloss_Base)	AS Winloss_Base
					FROM #Commission c2
					WHERE c1.MonthDate = c2.MonthDate AND c1.AffId = c2.AffId
						AND c2.ProductId > 0
				) c2
			WHERE c1.ProductId = 0
		END

		-- Filter by Products
		IF @ProductIds <> '0'
		BEGIN
			IF @ProductIds = ''
			BEGIN
				DELETE #Commission WHERE ProductId <> 0

				UPDATE #Commission SET Turnover = 0, Winloss = 0, Turnover_Base = 0, Winloss_Base = 0
			END
			ELSE
			BEGIN
				UPDATE c1
				SET c1.Turnover			= ISNULL(c2.Turnover, 0)
					,c1.Winloss			= ISNULL(c2.Winloss, 0)
					,c1.Turnover_Base	= ISNULL(c2.Turnover_Base, 0)
					,c1.Winloss_Base	= ISNULL(c2.Winloss_Base, 0)
				FROM #Commission c1
					CROSS APPLY (
						SELECT
							SUM(c2.Turnover)		AS Turnover
							,SUM(c2.Winloss)		AS Winloss
							,SUM(c2.Turnover_Base)	AS Turnover_Base
							,SUM(c2.Winloss_Base)	AS Winloss_Base
						FROM #Commission c2
						WHERE c1.MonthDate = c2.MonthDate AND c1.AffId = c2.AffId
							AND ',' + @ProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(10), c2.ProductId) + ',%'
					) AS c2
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
			INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, GroupProductId, IsHaveDataMember)
			SELECT md.MonthDate, md.AffId, agh.GroupId, 0, 0, 0
			FROM @MonthDate md
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON agh.MonthDate = md.MonthDate AND agh.AffId = md.AffId
				LEFT JOIN #Commission c ON c.MonthDate = md.MonthDate AND c.AffId = md.AffId AND c.ProductId = 0
			WHERE c.AffId IS NULL
		END

		;WITH CTE_SubAffCommission AS
		(
			SELECT
				c.MonthDate
				,f.val AS AffId
				,SUM(POWER(@SubAffCommRate, f.Id) * (c.NetWinloss - c.Bonus) * c.CommissionRate) AS SubAffCommission
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
		WHERE IsHaveDataMember = 0 AND SubAffCommission = 0
	END

	IF EXISTS (SELECT 1 FROM #Commission WHERE MonthDate < DATEADD(DAY, -1, @LaunchDate))
	BEGIN
		UPDATE #Commission
		SET Commission			= 0
			,SubAffCommission	= 0
			,CommissionRate		= 0
			,PlatFormFee		= 0
			,OperationalFee		= 0
			,BankingFee			= 0
		WHERE MonthDate < DATEADD(DAY, -1, @LaunchDate)
	END

	IF EXISTS (SELECT 1 FROM #Data WHERE IsDataInMonth = 0)
	BEGIN
		UPDATE c
		SET c.Deposit			= ISNULL(d.Deposit, 0),
			c.Withdrawal		= ISNULL(d.Withdrawal, 0),
			c.Bonus				= ISNULL(d.Bonus, 0),
			c.Turnover			= ISNULL(d.Turnover, 0),
			c.Winloss			= ISNULL(d.Winloss, 0),
			c.Deposit_Base		= ISNULL(d.Deposit_Base, 0),
			c.Withdrawal_Base	= ISNULL(d.Withdrawal_Base, 0),
			c.Bonus_Base		= ISNULL(d.Bonus_Base, 0),
			c.Turnover_Base		= ISNULL(d.Turnover_Base, 0),
			c.Winloss_Base		= ISNULL(d.Winloss_Base, 0),
			c.GrossWinloss		= ISNULL(-d.Winloss, 0)
		FROM #Commission c
			CROSS APPLY (
				SELECT
					SUM(d.Deposit)			AS Deposit,
					SUM(d.Withdrawal)		AS Withdrawal,
					SUM(d.Bonus)			AS Bonus,
					SUM(d.Turnover)			AS Turnover,
					SUM(d.Winloss)			AS Winloss,
					SUM(d.Deposit_Base)		AS Deposit_Base,
					SUM(d.Withdrawal_Base)	AS Withdrawal_Base,
					SUM(d.Bonus_Base)		AS Bonus_Base,
					SUM(d.Turnover_Base)	AS Turnover_Base,
					SUM(d.Winloss_Base)		AS Winloss_Base
				FROM #Data d
				WHERE c.AffId = d.AffId
					AND c.MonthDate = d.MonthDate
					AND c.ProductId = d.ProductId
					AND d.IsDataInMonth = 1
			) d
		WHERE c.MonthDate = DATEADD(DAY, -1, @LaunchDate)

		UPDATE c
		SET c.Turnover			= d.Turnover,
			c.Winloss			= d.Winloss,
			c.Turnover_Base		= d.Turnover_Base,
			c.Winloss_Base		= d.Winloss_Base,
			c.GrossWinloss		= d.GrossWinloss,
			c.GrossWinloss_Base	= d.GrossWinloss_Base
		FROM #Commission c
			CROSS APPLY (
				SELECT
					SUM(d.Turnover)				AS Turnover,
					SUM(d.Winloss)				AS Winloss,
					SUM(d.GrossWinloss)			AS GrossWinloss,
					SUM(d.Turnover_Base)		AS Turnover_Base,
					SUM(d.Winloss_Base)			AS Winloss_Base,
					SUM(d.GrossWinloss_Base)	AS GrossWinloss_Base
				FROM #Commission d
				WHERE c.AffId = d.AffId
					AND c.MonthDate = d.MonthDate
					AND d.ProductId > 0
			) d
		WHERE c.MonthDate = DATEADD(DAY, -1, @LaunchDate)
			AND c.ProductId = 0
	END

	-- Base Currency
	BEGIN
		DECLARE @AffCurrency INT
		SELECT  @AffCurrency = dbo.Aff_f_GetSetting('AffCurrency')

		UPDATE c
		SET c.Commission_Base		= c.Commission * e.Rate,
			c.SubAffCommission_Base	= c.SubAffCommission * e.Rate,
			c.PlatFormFee_Base		= c.PlatFormFee * e.Rate,
			c.OperationalFee_Base	= c.OperationalFee * e.Rate,
			c.BankingFee_Base		= c.BankingFee * e.Rate,
			c.NetWinloss_Base		= c.NetWinloss * e.Rate
		FROM #Commission c
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(c.MonthDate, @AffCurrency, @BaseCurrency) e
	END

	IF @BaseCurrency <> 0 AND @BaseCurrency <> @AffCurrency
	BEGIN
		UPDATE #Commission
		SET Deposit				= Deposit_Base,
			Withdrawal			= Withdrawal_Base,
			Bonus				= Bonus_Base,
			Turnover			= Turnover_Base,
			Winloss				= Winloss_Base,
			PlatFormFee			= PlatFormFee_Base,
			OperationalFee		= OperationalFee_Base,
			BankingFee			= BankingFee_Base,
			GrossWinloss		= GrossWinloss_Base,
			NetWinloss			= NetWinloss_Base,
			Commission			= Commission_Base,
			SubAffCommission	= SubAffCommission_Base
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
			SUM(c.Turnover)			AS Turnover,
			SUM(c.Winloss)			AS Winloss,
			SUM(c.PlatFormFee)		AS PlatFormFee,
			SUM(c.OperationalFee)	AS OperationalFee,
			SUM(c.BankingFee)		AS BankingFee,
			SUM(c.GrossWinloss)		AS GrossWinloss,
			SUM(c.NetWinloss)		AS NetWinloss,
			SUM(c.ActivePlayer)		AS ActivePlayer,
			SUM(c.QualifiedMember)	AS QualifiedMember,
			SUM(c.QMTurnOver)		AS QMTurnOver,
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
			c.Turnover,
			c.Winloss,
			c.PlatFormFee,
			c.OperationalFee,
			c.BankingFee,
			c.GrossWinloss,
			c.NetWinloss,
			c.ActivePlayer,
			c.QualifiedMember,
			c.QMTurnOver,
			c.CommissionRate,
			c.Commission,
			c.SubAffCommission
		FROM #Commission c
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON c.AffId = ai.AffId
	END

	DROP TABLE #Data
	DROP TABLE #Commission
END
GO