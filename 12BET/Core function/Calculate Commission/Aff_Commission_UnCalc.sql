/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_Commission_UnCalc]
	@AffIds				VARCHAR(MAX) = 'all',
	@FromMonthDate		SMALLDATETIME,
	@ToMonthDate		SMALLDATETIME,
	@ProductIds			VARCHAR(MAX) = '0',
	@IsGetMonthly       BIT = 1,
	@IsSumAll			BIT = 0,
	@GetRowTotalOnly	BIT = 0,
	@IsGroupProduct		BIT = 1
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Core SP - Calculate commission for months which are not calculated yet

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20181001@Percy: Add CutOffDate [RedmineID: #102399]
		- 20181120@Percy: Keep line total (productId = 0) [RedmineID: #104963]
		- 20190808@Percy: Add Exchange [RedmineID: #106504]
		- 20191127@Percy: Enhance performance [RedmineID: #118992]
		- 20210528@Malcolm: Get date daily [RedmineID: #149210]
		- 20211207@Percy: Apply core function Group Product [RedmineID: #165777]
		- 20211222@Malcolm: remove move bet date  [RedmineID: #165095]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @BeginOfFromMonthDate SMALLDATETIME = @FromMonthDate, @EndOfToMonthDate SMALLDATETIME = @ToMonthDate
	
	IF @IsGetMonthly = 1
	BEGIN 
		SELECT  @BeginOfFromMonthDate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate), 0) -- First day of @FromMonthDate
		SELECT  @EndOfToMonthDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0)) -- Last day of @ToMonthDate
	END

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
			ParentProductId	INT, -- GroupProductId
			Deposit			MONEY,
			Withdrawal		MONEY,
			Bonus			MONEY,
			Turnover		MONEY,
			Winloss			MONEY,
			AWinloss		MONEY,
			AComm			MONEY
		)

		INSERT INTO #Data
		(
			MonthDate,
			AffId,
			IBCCustId,
			ProductId,
			ParentProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Turnover,
			Winloss,
			AWinloss,
			AComm
		)
		SELECT
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate
			,md.AffId
			,md.IBCCustId
			,md.ProductId
			,ISNULL(g.GroupProductId, md.ProductId)
			,SUM(ISNULL(md.Deposit, 0)		* ISNULL(md.AffExRate, 1)) AS Deposit
			,SUM(ISNULL(md.Withdrawal, 0)	* ISNULL(md.AffExRate, 1)) AS Withdrawal
			,SUM(ISNULL(md.Bonus, 0)		* ISNULL(md.AffExRate, 1)) AS Bonus
			,SUM(ISNULL(md.Turnover, 0)		* ISNULL(md.AffExRate, 1)) AS Turnover
			,SUM(ISNULL(md.Winloss, 0)		* ISNULL(md.AffExRate, 1)) AS Winloss
			,SUM(ISNULL(md.AWinloss, 0)		* ISNULL(md.AffExRate, 1)) AS AWinloss
			,SUM(ISNULL(md.AComm, 0)		* ISNULL(md.AffExRate, 1)) AS AComm
		FROM dbo.rptMemberDaily md WITH (NOLOCK)
			LEFT JOIN dbo.Aff_f_GroupProduct() g ON md.ProductId = g.ProductId
		WHERE (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%' + CONVERT(VARCHAR(20), md.AffId) + '%')
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
			,ISNULL(g.GroupProductId, md.ProductId)
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
		SELECT DISTINCT agh.MonthDate, agh.AffId, agh.GroupId, qm.QMTurnOver
		FROM #Data d
			INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON d.MonthDate = agh.MonthDate AND d.AffId = agh.AffId
			CROSS APPLY (
				SELECT TOP 1 ISNULL(cgh.QMTurnOver, 0) AS QMTurnOver
				FROM dbo.CommGroupHistory cgh WITH (NOLOCK)
				WHERE agh.GroupId = cgh.GroupId AND agh.MonthDate = cgh.MonthDate
			) qm

		DECLARE @Setting TABLE
		(
			MonthDate				SMALLDATETIME
			,GroupId				INT
			,ProductId				INT
			,GroupProductId			TINYINT -- for setting
			,PlatFormFee			DECIMAL(9,8) DEFAULT (0)
			,OperationalFee			DECIMAL(9,8) DEFAULT (0)
			,BankingFee				DECIMAL(9,8) DEFAULT (0)
			,ExchangeWinlossShare	DECIMAL(9,8) DEFAULT (0)
			,ExchangeCommShare		DECIMAL(9,8) DEFAULT (0)
		)
	
		INSERT INTO @Setting
		(
			MonthDate,
			GroupId,
			ProductId,
			GroupProductId,
			PlatFormFee,
			OperationalFee,
			BankingFee,
			ExchangeWinlossShare,
			ExchangeCommShare
		)
		SELECT
			a.MonthDate,
			a.GroupId,
			ds.ProductId,
			ds.GroupProductId,
			ds.PlatFormFee,
			ds.OperationalFee,
			ds.BankingFee,
			ds.ExchangeWinlossShare,
			ds.ExchangeCommShare
		FROM @AffGroupInfo a
			CROSS APPLY (
				SELECT
					dsh.ProductId,
					dsh.GroupProductId,
					SUM(CASE WHEN dsh.DeductionId = 10 THEN dsh.DeductedPercentage ELSE 0 END) AS PlatFormFee,
					SUM(CASE WHEN dsh.DeductionId = 11 THEN dsh.DeductedPercentage ELSE 0 END) AS OperationalFee,
					SUM(CASE WHEN dsh.DeductionId = 12 THEN dsh.DeductedPercentage ELSE 0 END) AS BankingFee,
					SUM(CASE WHEN dsh.DeductionId = 13 THEN dsh.DeductedPercentage ELSE 0 END) AS ExchangeWinlossShare,
					SUM(CASE WHEN dsh.DeductionId = 14 THEN dsh.DeductedPercentage ELSE 0 END) AS ExchangeCommShare
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
			ParentProductId			INT,
			GroupProductId			TINYINT,
			Deposit					MONEY DEFAULT (0),
			Withdrawal				MONEY DEFAULT (0),
			Bonus					MONEY DEFAULT (0),
			Turnover				MONEY DEFAULT (0),
			Winloss					MONEY DEFAULT (0),
			AWinloss				MONEY DEFAULT (0),
			AComm					MONEY DEFAULT (0),
			-- Fees
			PlatFormFee				MONEY DEFAULT (0),
			OperationalFee			MONEY DEFAULT (0),
			BankingFee				MONEY DEFAULT (0),
			-- Exchange Share
			ExchangeWinlossShare	MONEY DEFAULT (0),
			ExchangeCommShare		MONEY DEFAULT (0),
			-- Calculation
			GrossWinloss			MONEY DEFAULT (0),
			NetWinloss				MONEY DEFAULT (0),
			ActivePlayer			INT DEFAULT (0),
			QualifiedMember			INT DEFAULT (0),
			QMTurnover				MONEY DEFAULT (0),
			CommissionRate			DECIMAL(9,8) DEFAULT (0),
			Commission				MONEY DEFAULT (0)
		)
	
		CREATE NONCLUSTERED INDEX IX_MonthDate ON #Commission (MonthDate, AffId, GroupId, ProductId)
		
		-- Group by Product
		INSERT INTO #Commission
		(
			MonthDate,
			AffId,
			ProductId,
			ParentProductId,
			Turnover,
			Winloss,
			AWinloss,
			AComm
		)
		SELECT MonthDate, AffId, ProductId, ParentProductId
			,SUM(Turnover)	AS Turnover
			,SUM(Winloss)	AS Winloss
			,SUM(AWinloss)	AS AWinloss
			,SUM(AComm)		AS AComm
		FROM #Data
		WHERE ProductId > 0
		GROUP BY MonthDate, AffId, ProductId, ParentProductId

		-- Total
		;WITH CTE_SumMember AS
		(
			SELECT MonthDate, AffId, IBCCustId
				,SUM(Turnover) AS Turnover
				,SUM(Deposit) AS Deposit
			FROM #Data
			GROUP BY MonthDate, AffId, IBCCustId
		)
		INSERT INTO #Commission
		(
			MonthDate,
			AffId,
			ProductId,
			ParentProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Turnover,
			Winloss,
			AWinloss,
			AComm,
			ActivePlayer,
			QualifiedMember,
			QMTurnover
		)
		SELECT MonthDate, AffId, 0 AS ProductId, 0 AS ParentProductId,
			SUM(Deposit)			AS Deposit,
			SUM(Withdrawal)			AS Withdrawal,
			SUM(Bonus)				AS Bonus,
			SUM(Turnover)			AS Turnover,
			SUM(Winloss)			AS Winloss,
			SUM(AWinloss)			AS AWinloss,
			SUM(AComm)				AS AComm,
			SUM(ActivePlayer)		AS ActivePlayer,
			SUM(QualifiedMember)	AS QualifiedMember,
			SUM(QMTurnover)			AS QMTurnover
		FROM
		(
			SELECT dt.MonthDate, dt.AffId, a.QMTurnover
				,0 AS Deposit
				,0 AS Withdrawal
				,0 AS Bonus
				,0 AS Turnover
				,0 AS Winloss
				,0 AS AWinloss
				,0 AS AComm
				,SUM(CASE WHEN dt.Turnover > 0 OR dt.Deposit > 0 THEN 1 ELSE 0 END) AS ActivePlayer
				,SUM(CASE WHEN dt.Turnover >= a.QMTurnOver THEN 1 ELSE 0 END) AS QualifiedMember
			FROM CTE_SumMember dt
				INNER JOIN @AffGroupInfo a ON dt.AffId = a.AffId AND dt.MonthDate = a.MonthDate
			GROUP BY dt.MonthDate, dt.AffId, a.QMTurnover

			UNION ALL
			SELECT MonthDate, AffId, 0 AS QMTurnover
				,SUM(Deposit)		AS Deposit
				,SUM(Withdrawal)	AS Withdrawal
				,SUM(Bonus)			AS Bonus
				,SUM(Turnover)		AS Turnover
				,SUM(Winloss)		AS Winloss
				,SUM(AWinloss)		AS AWinloss
				,SUM(AComm)			AS AComm
				,0 AS ActivePlayer
				,0 AS QualifiedMember
			FROM #Data
			GROUP BY MonthDate, AffId
		) AS A
		GROUP BY MonthDate, AffId

		-- Calculate fees
		DECLARE @ExchangeWinlossShare	MONEY,
				@ExchangeCommShare		MONEY,
				@GrossWinLoss			MONEY
		
		UPDATE c
		SET @ExchangeWinlossShare	= c.AWinloss * s.ExchangeWinlossShare,
			@ExchangeCommShare		= c.AComm * s.ExchangeCommShare,
			@GrossWinLoss			= CASE WHEN c.ProductId = 19 THEN @ExchangeWinlossShare + @ExchangeCommShare ELSE - c.Winloss END,
			c.GroupId				= s.GroupId,
			c.GroupProductId		= s.GroupProductId,
			c.ExchangeWinlossShare	= @ExchangeWinlossShare,
			c.ExchangeCommShare		= @ExchangeCommShare,
			c.GrossWinloss			= @GrossWinLoss,
			c.PlatFormFee			= @GrossWinLoss * s.PlatFormFee,
			c.OperationalFee		= ABS(@GrossWinLoss) * s.OperationalFee,
			c.BankingFee			= (c.Deposit + c.Withdrawal) * s.BankingFee
		FROM #Commission c
			INNER JOIN @AffGroupInfo a ON c.AffId = a.AffId AND c.MonthDate = a.MonthDate
			INNER JOIN @Setting s ON a.GroupId = s.GroupId AND c.MonthDate = s.MonthDate AND c.ParentProductId = s.ProductId

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

		-- Exchange Winloss Share, Exchange Comm Share, Total Gross Winloss, Total Net Winloss
		UPDATE c
		SET c.ExchangeWinlossShare	= e.ExchangeWinlossShare,
			c.ExchangeCommShare		= e.ExchangeCommShare,
			c.GrossWinloss			= e.GrossWinloss,
			c.NetWinloss			= e.GrossWinloss - (c.PlatFormFee + c.OperationalFee + c.BankingFee)
		FROM #Commission c
			CROSS APPLY (
				SELECT
					SUM(ExchangeWinlossShare)	AS ExchangeWinlossShare,
					SUM(ExchangeCommShare)		AS ExchangeCommShare,
					SUM(GrossWinloss)			AS GrossWinloss
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
					AND c.QualifiedMember BETWEEN gsh.MinQM AND gsh.MaxQM
					AND gsh.TierId <= t.TierId
			) AS s
		WHERE c.ProductId = 0

		IF @IsGroupProduct = 1 -- 0 for job (keep original data), 1 for report (merge product)
		BEGIN
			MERGE #Commission AS t
			USING (
				SELECT MonthDate, AffId, GroupId, GroupProductId, ParentProductId AS ProductId, Turnover, Winloss, PlatFormFee
				FROM #Commission WHERE ProductId <> ParentProductId
			) AS s ON t.MonthDate = s.MonthDate AND t.AffId = s.AffId AND t.ProductId = s.ProductId
			WHEN MATCHED THEN UPDATE
				SET t.Turnover = t.Turnover + s.Turnover
				,t.Winloss = t.Winloss + s.Winloss
				,t.PlatFormFee = t.PlatFormFee + s.PlatFormFee
			WHEN NOT MATCHED THEN INSERT
				(MonthDate, AffId, GroupId, ProductId, GroupProductId, Turnover, Winloss, PlatFormFee)
				VALUES (MonthDate, AffId, GroupId, ProductId, GroupProductId, Turnover, Winloss, PlatFormFee);

			DELETE #Commission WHERE ProductId <> ParentProductId
		END

		-- Filter by Products
		IF @ProductIds <> '0'
		BEGIN
			IF @ProductIds = ''
			BEGIN
				DELETE #Commission WHERE ProductId <> 0

				UPDATE #Commission SET Turnover = 0, Winloss = 0
			END
			ELSE
			BEGIN
				UPDATE c1
				SET c1.Turnover = ISNULL(c2.Turnover, 0), c1.Winloss = ISNULL(c2.Winloss, 0)
				FROM #Commission c1
					CROSS APPLY (
						SELECT SUM(c2.Turnover) AS Turnover, SUM(c2.Winloss) AS Winloss
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

	-- Return data
	IF @IsSumAll = 1
	BEGIN
		SELECT
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0)) AS MonthDate,
			c.AffId,
			c.GroupId,
			c.ProductId,
			SUM(c.Deposit)				AS Deposit,
			SUM(c.Withdrawal)			AS Withdrawal,
			SUM(c.Bonus)				AS Bonus,
			SUM(c.Turnover)				AS Turnover,
			SUM(c.Winloss)				AS Winloss,
			SUM(c.AWinloss)				AS AWinloss,
			SUM(c.AComm)				AS AComm,
			SUM(c.PlatFormFee)			AS PlatFormFee,
			SUM(c.OperationalFee)		AS OperationalFee,
			SUM(c.BankingFee)			AS BankingFee,
			SUM(c.ExchangeWinlossShare) AS ExchangeWinlossShare,
			SUM(c.ExchangeCommShare)	AS ExchangeCommShare,
			SUM(c.GrossWinloss)			AS GrossWinloss,
			SUM(c.NetWinloss)			AS NetWinloss,
			SUM(c.ActivePlayer)			AS ActivePlayer,
			SUM(c.QualifiedMember)		AS QualifiedMember,
			SUM(c.QMTurnOver)			AS QMTurnOver,
			SUM(c.CommissionRate)		AS CommissionRate,
			SUM(c.Commission)			AS Commission
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
			c.AWinloss,
			c.AComm,
			c.PlatFormFee,
			c.OperationalFee,
			c.BankingFee,
			c.ExchangeWinlossShare,
			c.ExchangeCommShare,
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