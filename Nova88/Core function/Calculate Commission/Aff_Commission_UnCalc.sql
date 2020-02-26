/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_Commission_UnCalc]
	@AffIds				VARCHAR(MAX) = 'all',
	@FromMonthDate		SMALLDATETIME,
	@ToMonthDate		SMALLDATETIME,
	@ProductIds			VARCHAR(MAX) = '0',
	@BaseCurrency		INT = 0,
	@IsSumAll			BIT = 0,
	@GetRowTotalOnly	BIT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Core SP - Calculate commission for months which are not calculated yet

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @BeginOfFromMonthDate SMALLDATETIME, @EndOfToMonthDate SMALLDATETIME

	SELECT  @BeginOfFromMonthDate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate), 0) -- First day of @FromMonthDate
	SELECT  @EndOfToMonthDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0)) -- Last day of @ToMonthDate

	IF @EndOfToMonthDate > CONVERT(DATE, GETDATE())
		SELECT @EndOfToMonthDate = CONVERT(DATE, GETDATE())

	-- Get data
	BEGIN
		CREATE TABLE #Data
		(
			MonthDate		SMALLDATETIME,
			AffId			INT,
			IBCCustId		INT,
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
			Winloss_Base	MONEY
		)

		INSERT INTO #Data
		(
			MonthDate,
			AffId,
			IBCCustId,
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
			,md.IBCCustId
			,md.ProductId

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
					AND mr.IBCCustId = md.IBCCustId
				)
		GROUP BY
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
			,md.AffId
			,md.IBCCustId
			,md.ProductId
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

		DECLARE @Setting TABLE
		(
			MonthDate				SMALLDATETIME
			,GroupId				INT
			,ProductId				INT
			,GroupProductId			TINYINT
			,PlatFormFee			DECIMAL(9,8) DEFAULT (0)
			,OperationalFee			DECIMAL(9,8) DEFAULT (0)
			,BankingFee				DECIMAL(9,8) DEFAULT (0)
		)
	
		INSERT INTO @Setting
		(
			MonthDate,
			GroupId,
			ProductId,
			GroupProductId,
			PlatFormFee,
			OperationalFee,
			BankingFee
		)
		SELECT
			a.MonthDate,
			a.GroupId,
			ds.ProductId,
			ds.GroupProductId,
			ds.PlatFormFee,
			ds.OperationalFee,
			ds.BankingFee
		FROM @AffGroupInfo a
			CROSS APPLY (
				SELECT
					dsh.ProductId,
					dsh.GroupProductId,
					SUM(CASE WHEN dsh.DeductionId = 10 THEN dsh.DeductedPercentage ELSE 0 END) AS PlatFormFee,
					SUM(CASE WHEN dsh.DeductionId = 11 THEN dsh.DeductedPercentage ELSE 0 END) AS OperationalFee,
					SUM(CASE WHEN dsh.DeductionId = 12 THEN dsh.DeductedPercentage ELSE 0 END) AS BankingFee
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
			Commission_Base			MONEY DEFAULT (0)
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
			SELECT MonthDate, AffId, IBCCustId
				,SUM(Turnover)	AS Turnover
			FROM #Data
			GROUP BY MonthDate, AffId, IBCCustId
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
		UPDATE c
		SET c.GroupId				= s.GroupId,
			c.GroupProductId		= s.GroupProductId,
			c.GrossWinloss			= -c.Winloss,
			c.GrossWinloss_Base		= -c.Winloss_Base,
			c.PlatFormFee			= -c.Winloss * s.PlatFormFee,
			c.OperationalFee		= ABS(c.Winloss) * s.OperationalFee,
			c.BankingFee			= (c.Deposit + c.Withdrawal) * s.BankingFee,
			c.BankingFee_Base		= (c.Deposit_Base + c.Withdrawal_Base) * s.BankingFee
		FROM #Commission c
			INNER JOIN @AffGroupInfo a ON c.AffId = a.AffId AND c.MonthDate = a.MonthDate
			INNER JOIN @Setting s ON a.GroupId = s.GroupId AND c.MonthDate = s.MonthDate AND c.ProductId = s.ProductId

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
		SET c.PlatFormFee	= pf.PlatFormFee
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
		SET c.CommissionRate	= ISNULL(ISNULL(s.Commission, t.Commission), 0),
			c.Commission		= ISNULL(ISNULL(s.Commission, t.Commission), 0) * (c.NetWinloss - c.Bonus)
		FROM #Commission c
			CROSS APPLY (
				SELECT gsh.TierId, gsh.Commission
				FROM dbo.TierSettingHistory gsh WITH (NOLOCK)
				WHERE c.MonthDate = gsh.MonthDate AND c.GroupId = gsh.GroupId
					AND FLOOR(ABS(c.NetWinloss)) BETWEEN gsh.MinAmount AND gsh.MaxAmount
			) AS t
			CROSS APPLY (
				SELECT MAX(gsh.Commission) AS Commission
				FROM dbo.TierSettingHistory gsh WITH (NOLOCK)
				WHERE c.MonthDate = gsh.MonthDate AND c.GroupId = gsh.GroupId
					AND c.QualifiedMember BETWEEN gsh.MinAM AND gsh.MaxAM
					AND gsh.TierId <= t.TierId
			) AS s
		WHERE c.ProductId = 0

		DECLARE @AffCurrency INT
		SELECT  @AffCurrency = dbo.Aff_f_GetSetting('AffCurrency')

		UPDATE c
		SET c.Commission_Base	= c.Commission * e.Rate,
			c.PlatFormFee		= c.PlatFormFee * e.Rate,
			c.OperationalFee	= c.OperationalFee * e.Rate,
			c.NetWinloss		= c.NetWinloss * e.Rate,
			c.Commission		= c.Commission * e.Rate
		FROM #Commission c
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(c.MonthDate, @AffCurrency, @BaseCurrency) e

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
	END

	IF @BaseCurrency <> 0 AND @BaseCurrency <> @AffCurrency
	BEGIN
		UPDATE #Commission
		SET Deposit			= Deposit_Base,
			Withdrawal		= Withdrawal_Base,
			Bonus			= Bonus_Base,
			Turnover		= Turnover_Base,
			Winloss			= Winloss_Base,
			PlatFormFee		= PlatFormFee_Base,
			OperationalFee	= OperationalFee_Base,
			BankingFee		= BankingFee_Base,
			GrossWinloss	= GrossWinloss_Base,
			NetWinloss		= NetWinloss_Base,
			Commission		= Commission_Base
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
			SUM(c.Commission)		AS Commission
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
			c.Commission
		FROM #Commission c
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON c.AffId = ai.AffId
	END

	DROP TABLE #Data
	DROP TABLE #Commission
END
GO