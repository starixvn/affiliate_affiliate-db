/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_Commission_UnCalc]
	@AffIds				VARCHAR(MAX) = 'all'
	,@FromMonthDate		SMALLDATETIME
	,@ToMonthDate		SMALLDATETIME
	,@ProductIds		VARCHAR(MAX) = '0'
	,@Currencies		VARCHAR(MAX) = ''
	,@BaseCurrency		INT = 0
	,@SubLevel			TINYINT = 0
	,@IsSumAll			BIT = 0
	,@GetRowTotalOnly	BIT = 0
	,@IsForJob			BIT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core SP - Calculate commission for months which are not calculated yet

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
		- 20210506@Percy: Max Sub Affiliate Commission Setting [RedmineID: #153465]
		- 20210604@Percy: Fix Withdrawal Amount [RedmineID: #156487]
		- 20210714@Percy: Calculate P2P Fee [RedmineID: #157958]
		- 20210916@Percy: Use Exchange function [RedmineID: #161540]
		- 20210916@Percy: Exclude Jackpot from WL [RedmineID: #161540]
		- 20211105@Percy: Exclude non-deposited player from active players [RedmineID: #164246]
		- 20220307@Malcolm: Revenue Share Calculation Enhancement [RedmineId: #167335]
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

	-- Max Sub Affiliate Commission Setting
	DECLARE @MaxSubAff INT
	IF @SubLevel <> 0
		SELECT @MaxSubAff = @SubLevel
	ELSE
		SELECT @MaxSubAff = 3
	
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
		CREATE TABLE #Data
		(
			MonthDate		SMALLDATETIME,
			AffId			INT,
			GroupId			INT,
			CustId			INT,
			Currency		INT,
			ProductId		INT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Bonus			MONEY,
			Rebate			MONEY,
			Turnover		MONEY,
			Winloss			MONEY,
			Revenue			MONEY,
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
			Winloss,
			Revenue
		)
		SELECT r.MonthDate, r.AffId, r.CustId, r.Currency, r.ProductId
			,SUM(r.Deposit		* e.Rate)	AS Deposit
			,SUM(r.Withdrawal	* e.Rate)	AS Withdrawal
			,SUM(r.Bonus		* e.Rate)	AS Bonus
			,SUM(r.Rebate		* e.Rate)	AS Rebate
			,SUM(r.Turnover		* e.Rate)	AS Turnover
			,SUM(r.Winloss		* e.Rate)	AS Winloss
			,SUM(r.Revenue		* e.Rate)	AS Revenue
		FROM (
			SELECT CONVERT(SMALLDATETIME, DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0))) AS MonthDate
				,AffId, CustId, Currency, CASE WHEN ProductId < 0 THEN 0 ELSE ProductId END AS ProductId
				,SUM(ISNULL(Deposit, 0))	AS Deposit
				,SUM(ISNULL(Withdrawal, 0))	AS Withdrawal
				,SUM(ISNULL(Bonus, 0))		AS Bonus
				,SUM(ISNULL(Rebate, 0))		AS Rebate
				,SUM(ISNULL(Turnover, 0))	AS Turnover
				,SUM(ISNULL(Winloss, 0) - ISNULL(ProgressiveWin, 0) + ISNULL(ProgressiveBet, 0)) AS Winloss
				,SUM(ISNULL(Revenue, 0))	AS Revenue
			FROM dbo.rptMemberDaily WITH (NOLOCK)
			WHERE WinlostDate BETWEEN @BeginOfFromMonthDate AND @EndOfToMonthDate
				AND (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), AffId) + ',%')
			GROUP BY CONVERT(SMALLDATETIME, DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)))
				,AffId, CustId, Currency, CASE WHEN ProductId < 0 THEN 0 ELSE ProductId END
		) r
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.MonthDate, r.Currency, @BaseCurrency) e
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
				Revenue,
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
				Revenue,
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
			MonthDate			SMALLDATETIME,
			GroupId				INT,
			ProductId			INT,
			GroupProductId		INT,
			PlatFormFee			DECIMAL(9,8) DEFAULT (0),
			PlatFormAmount		MONEY DEFAULT (0),
			OperationalFee		DECIMAL(9,8) DEFAULT (0),
			OperationalAmount	MONEY DEFAULT (0),
			DepositFee			DECIMAL(9,8) DEFAULT (0),
			DepositAmount		MONEY DEFAULT (0),
			WithdrawalFee		DECIMAL(9,8) DEFAULT (0),
			WithdrawalAmount	MONEY DEFAULT (0),
			StraightCommission	DECIMAL(9,8) DEFAULT (0),
			IsStraightSetting	BIT DEFAULT(0)
		)

		;WITH CTE_Group AS (SELECT DISTINCT MonthDate, GroupId FROM @AffGroupInfo)
		INSERT INTO @Setting (MonthDate, GroupId, ProductId, GroupProductId, PlatFormFee, PlatFormAmount, OperationalFee, OperationalAmount, DepositFee, DepositAmount, WithdrawalFee, WithdrawalAmount)
		SELECT a.MonthDate, a.GroupId, ds.ProductId, ds.GroupProductId, ds.PlatFormFee, ds.PlatFormAmount, ds.OperationalFee, ds.OperationalAmount, ds.DepositFee, ds.DepositAmount, ds.WithdrawalFee, ds.WithdrawalAmount
		FROM CTE_Group a
			CROSS APPLY (
				SELECT dsh.ProductId, dsh.GroupProductId,
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
				GROUP BY dsh.ProductId, dsh.GroupProductId
			) AS ds

		UPDATE s
		SET s.PlatFormAmount = s.PlatFormAmount * e.Rate,
			s.OperationalAmount = s.OperationalAmount * e.Rate,
			s.DepositAmount = s.DepositAmount * e.Rate,
			s.WithdrawalAmount = s.WithdrawalAmount * e.Rate
		FROM @Setting s
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(s.MonthDate, @AffCurrency, @BaseCurrency) e

		;WITH CTE_Group AS (SELECT DISTINCT MonthDate, GroupId FROM @AffGroupInfo)
		INSERT INTO @Setting (MonthDate, GroupId, ProductId, GroupProductId, PlatFormFee, StraightCommission, IsStraightSetting)
		SELECT a.MonthDate, a.GroupId, ssh.ProductId, ssh.GroupProductId, ssh.DeductedPercentage, ssh.Commission, 1
		FROM CTE_Group a
			INNER JOIN dbo.StraightSettingHistory ssh WITH (NOLOCK) ON a.GroupId = ssh.GroupId AND a.MonthDate = ssh.MonthDate
			LEFT JOIN @Setting s ON ssh.MonthDate = s.MonthDate AND ssh.GroupId = s.GroupId AND ssh.ProductId = s.ProductId
		WHERE s.MonthDate IS NULL
	END

	UPDATE d
	SET d.GroupId	= a.GroupId
		,d.Turnover = CASE WHEN s.IsStraightSetting = 1 THEN 0 ELSE d.Turnover END
		,d.Winloss	= CASE WHEN s.IsStraightSetting = 1 THEN 0 ELSE d.Winloss END
		,d.Revenue	= CASE WHEN s.IsStraightSetting = 1 THEN d.Revenue ELSE 0 END
	FROM #Data d
		INNER JOIN @AffGroupInfo a ON d.MonthDate = a.MonthDate AND d.AffId = a.AffId
		INNER JOIN @Setting s ON d.MonthDate = s.MonthDate AND a.GroupId = s.GroupId AND d.ProductId = s.ProductId

	DELETE d
	FROM #Data d
		LEFT JOIN @Setting s ON d.MonthDate = s.MonthDate AND d.GroupId = s.GroupId AND d.ProductId = s.ProductId
	WHERE d.ProductId > 0 AND s.MonthDate IS NULL

	-- Calculate commission
	BEGIN
		CREATE TABLE #Commission
		(
			MonthDate			SMALLDATETIME,
			AffId				INT,
			GroupId				INT,
			ProductId			INT,
			GroupProductId		INT DEFAULT (0),
			Deposit				MONEY DEFAULT (0),
			Withdrawal			MONEY DEFAULT (0),
			Bonus				MONEY DEFAULT (0),
			Rebate				MONEY DEFAULT (0),
			Turnover			MONEY DEFAULT (0),
			Winloss				MONEY DEFAULT (0),
			Revenue				MONEY DEFAULT (0),
			-- Fees
			P2PFee				MONEY DEFAULT (0),
			PlatFormFee			MONEY DEFAULT (0),
			OperationalFee		MONEY DEFAULT (0),
			DepositFee			MONEY DEFAULT (0),
			WithdrawalFee		MONEY DEFAULT (0),
			-- Calculation
			GrossWinloss		MONEY DEFAULT (0),
			NetWinloss			MONEY DEFAULT (0),
			ActivePlayer		INT DEFAULT (0),
			CommissionRate		DECIMAL(9,8) DEFAULT (0),
			Commission			MONEY DEFAULT (0),
			StraightCommission	MONEY DEFAULT (0),
			SubAffCommission	MONEY DEFAULT (0),
			IsHasMemberData		BIT DEFAULT (1),
			ActivePlayerSum		INT DEFAULT (0),
			IsMultiGroupProduct TINYINT DEFAULT (0)
		)
	
		CREATE NONCLUSTERED INDEX IX_MonthDate ON #Commission (MonthDate, AffId, GroupId, ProductId)

		DECLARE @P2P_CutOffDate DATETIME
		SELECT  @P2P_CutOffDate = dbo.Aff_f_GetSetting('P2P_CutOffDate')
		
		IF @BeginOfFromMonthDate < @P2P_CutOffDate -- Old formula
		BEGIN
			-- By Product
			INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, GroupProductId, Turnover, Winloss, GrossWinloss, PlatFormFee)
			SELECT d.MonthDate, d.AffId, a.GroupId, d.ProductId, ISNULL(s.GroupProductId, 0), d.Turnover, d.Winloss,
				CASE WHEN s.GroupId IS NULL THEN 0 ELSE -d.Winloss END				AS GrossWinloss,
				-d.Winloss * ISNULL(s.PlatFormFee, 0) + ISNULL(s.PlatFormAmount, 0)	AS PlatFormFee
			FROM (
				SELECT MonthDate, AffId, ProductId, SUM(Turnover) Turnover, SUM(Winloss) Winloss
				FROM #Data
				WHERE ProductId > 0 AND MonthDate < @P2P_CutOffDate
				GROUP BY MonthDate, AffId, ProductId
			) d
				INNER JOIN @AffGroupInfo a ON d.MonthDate = a.MonthDate AND d.AffId = a.AffId
				LEFT JOIN @Setting s ON a.GroupId = s.GroupId AND d.MonthDate = s.MonthDate AND d.ProductId = s.ProductId
		
			-- Total
			INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, GroupProductId, Turnover, Winloss, Deposit, Withdrawal, Bonus, Rebate)
			SELECT d.MonthDate, d.AffId, a.GroupId, 0 AS ProductId, 0 AS GroupProductId,
				SUM(d.Turnover),
				SUM(d.Winloss),
				SUM(d.Deposit),
				SUM(d.Withdrawal),
				SUM(d.Bonus),
				SUM(d.Rebate)
			FROM (
				SELECT MonthDate, AffId,
					0 AS Turnover,
					0 AS Winloss,
					SUM(Deposit)	AS Deposit,
					SUM(Withdrawal)	AS Withdrawal,
					SUM(Bonus)		AS Bonus,
					SUM(Rebate)		AS Rebate
				FROM #Data
				WHERE ProductId = 0 AND MonthDate < @P2P_CutOffDate
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
				WHERE MonthDate < @P2P_CutOffDate
				GROUP BY MonthDate, AffId
			) d
				INNER JOIN @AffGroupInfo a ON d.MonthDate = a.MonthDate AND d.AffId = a.AffId
			GROUP BY d.MonthDate, d.AffId, a.GroupId

			-- Update ActivePlayers
			UPDATE c
			SET c.ActivePlayer = t.ActivePlayer
			FROM #Commission c
				INNER JOIN (
					SELECT d.MonthDate, d.AffId, COUNT(DISTINCT d.CustId) AS ActivePlayer
					FROM #Data d
						INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.CustId = m.CustId AND d.MonthDate >= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, m.FirstDepositDate) + 1, 0))
						INNER JOIN @AffGroupInfo a ON d.MonthDate = a.MonthDate AND d.AffId = a.AffId
						INNER JOIN @Setting s ON a.GroupId = s.GroupId AND d.MonthDate = s.MonthDate AND d.ProductId = s.ProductId
					WHERE d.ProductId > 0 AND d.MonthDate < @P2P_CutOffDate
					GROUP BY d.MonthDate, d.AffId
				) t ON c.MonthDate = t.MonthDate AND c.AffId = t.AffId
			WHERE c.ProductId = 0 AND c.MonthDate < @P2P_CutOffDate

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
						WHERE ProductId > 0 AND MonthDate < @P2P_CutOffDate
						GROUP BY MonthDate, AffId, GroupId, GroupProductId -- PlatFormFee group by GroupProductId
					) s
					GROUP BY MonthDate, AffId, GroupId
				) t ON c.MonthDate = t.MonthDate AND c.AffId = t.AffId
			WHERE c.ProductId = 0 AND c.MonthDate < @P2P_CutOffDate

			-- Update OperationalFee, DepositFee, WithdrawalFee
			UPDATE c
			SET c.OperationalFee	= ABS(c.GrossWinloss) * s.OperationalFee + s.OperationalAmount,
				c.DepositFee		= c.Deposit * s.DepositFee + s.DepositAmount,
				c.WithdrawalFee		= c.Withdrawal * s.WithdrawalFee + s.WithdrawalAmount
			FROM #Commission c
				INNER JOIN @Setting s ON c.MonthDate = s.MonthDate AND c.GroupId = s.GroupId AND c.ProductId = s.ProductId
			WHERE c.ProductId = 0 AND c.MonthDate < @P2P_CutOffDate

			-- Update NetWinloss
			UPDATE #Commission
			SET NetWinloss = GrossWinloss - (PlatFormFee + OperationalFee + DepositFee + WithdrawalFee) - (Bonus + Rebate)
			WHERE ProductId = 0 AND MonthDate < @P2P_CutOffDate
		END
		ELSE -- New formula
		BEGIN
			-- By Product
			UPDATE s
				SET s.GroupProductId = 0
			FROM @Setting s
			WHERE EXISTS (SELECT 1 FROM dbo.TierSettingHistory t WITH(NOLOCK) WHERE s.MonthDate = t.MonthDate AND s.GroupId = t.GroupId AND t.GroupProductId = 0)
				AND s.MonthDate >= @P2P_CutOffDate

			INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, GroupProductId, Turnover, Winloss, Revenue, GrossWinloss, P2PFee, PlatFormFee, OperationalFee, StraightCommission)
			SELECT d.MonthDate, d.AffId, d.GroupId, d.ProductId, s.GroupProductId, d.Turnover, d.Winloss, d.Revenue, -d.Winloss AS GrossWinloss
				,CASE WHEN d.Revenue < 0 THEN 0 ELSE d.Revenue * ISNULL(s.PlatFormFee, 0) END AS P2PFee
				,CASE WHEN d.Winloss > 0 THEN 0 ELSE -d.Winloss * ISNULL(s.PlatFormFee, 0) + ISNULL(s.PlatFormAmount, 0) END AS PlatFormFee
				,CASE WHEN d.Winloss > 0 THEN 0 ELSE -d.Winloss END AS OperationalFee
				,CASE WHEN d.Revenue < 0 THEN d.Revenue ELSE d.Revenue * (1.0 - ISNULL(s.PlatFormFee, 0)) END * ISNULL(s.StraightCommission, 0) AS StraightCommission
			FROM (
				SELECT MonthDate, AffId, GroupId, ProductId, SUM(Turnover) Turnover, SUM(Winloss) Winloss, SUM(Revenue) AS Revenue
				FROM #Data
				WHERE ProductId > 0 AND MonthDate >= @P2P_CutOffDate
				GROUP BY MonthDate, AffId, GroupId, ProductId
			) d
				INNER JOIN @Setting s ON d.MonthDate = s.MonthDate AND d.GroupId = s.GroupId AND d.ProductId = s.ProductId

			-- Total
			INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, GroupProductId, Turnover, Winloss, Revenue, GrossWinloss, P2PFee, PlatFormFee, OperationalFee, StraightCommission)
			SELECT c.MonthDate, c.AffId, c.GroupId, 0 AS ProductId, c.GroupProductId, c.Turnover, c.Winloss, c.Revenue, c.GrossWinloss, c.P2PFee, c.PlatFormFee, c.OperationalFee * ISNULL(s.OperationalFee, 0) + ISNULL(s.OperationalAmount, 0), c.StraightCommission
			FROM (
				SELECT MonthDate, AffId, GroupId, 0 AS ProductId, GroupProductId
					,SUM(Turnover) AS Turnover
					,SUM(Winloss) AS Winloss
					,SUM(Revenue) AS Revenue
					,SUM(GrossWinloss) AS GrossWinloss
					,SUM(P2PFee) AS P2PFee
					,SUM(PlatFormFee) AS PlatFormFee
					,SUM(OperationalFee) AS OperationalFee
					,SUM(StraightCommission) AS StraightCommission
				FROM #Commission
				WHERE MonthDate >= @P2P_CutOffDate
				GROUP BY MonthDate, AffId, GroupId, GroupProductId
			)  c
				LEFT JOIN @Setting s ON c.MonthDate = s.MonthDate AND c.GroupId = s.GroupId AND c.ProductId = s.ProductId

			UPDATE #Commission SET P2PFee = 0, PlatFormFee = 0, OperationalFee = 0 WHERE ProductId > 0

			-- Total: Deposit, Withdrawal, ActivePlayer, Net WinLoss
		    ;WITH CTE_GroupProduct AS (SELECT MonthDate, GroupId, COUNT(DISTINCT GroupProductId) AS [NoGroupProduct] FROM @Setting WHERE IsStraightSetting = 0 GROUP BY MonthDate, GroupId)
			UPDATE c
			SET c.Deposit			= ISNULL(d.Deposit, 0) / e.[NoGroupProduct]
				,c.Withdrawal		= ISNULL(d.Withdrawal, 0) / e.[NoGroupProduct]
				,c.Bonus			= ISNULL(d.Bonus, 0) / e.[NoGroupProduct]
				,c.Rebate			= ISNULL(d.Rebate, 0) / e.[NoGroupProduct]
				,c.DepositFee		= ISNULL(d.DepositFee, 0) / e.[NoGroupProduct]
				,c.WithdrawalFee	= ISNULL(d.WithdrawalFee, 0) / e.[NoGroupProduct]
				,c.NetWinloss = c.GrossWinloss - c.PlatFormFee - (c.OperationalFee + ISNULL(d.DepositFee, 0) + ISNULL(d.WithdrawalFee, 0) + ISNULL(d.Bonus, 0) + ISNULL(d.Rebate, 0))/ e.NoGroupProduct
			FROM #Commission c
				LEFT JOIN (
					SELECT d.MonthDate, d.AffId, d.GroupId
						,SUM(d.Deposit) AS Deposit
						,SUM(d.Withdrawal) AS Withdrawal
						,SUM(d.Bonus) AS Bonus
						,SUM(d.Rebate) AS Rebate
						,SUM(d.Deposit * ISNULL(s.DepositFee, 0) + ISNULL(s.DepositAmount, 0)) AS DepositFee
						,SUM(d.Withdrawal * ISNULL(s.WithdrawalFee, 0) + ISNULL(s.WithdrawalAmount, 0)) AS WithdrawalFee
					FROM #Data d
						LEFT JOIN @Setting s ON d.MonthDate = s.MonthDate AND d.GroupId = s.GroupId AND d.ProductId = s.ProductId
					WHERE d.ProductId = 0 AND d.MonthDate >= @P2P_CutOffDate
					GROUP BY d.MonthDate, d.AffId, d.GroupId
				) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId AND c.GroupId = d.GroupId
				LEFT JOIN CTE_GroupProduct e ON c.MonthDate = e.MonthDate AND c.GroupId = e.GroupId 
			WHERE c.ProductId = 0 AND c.MonthDate >= @P2P_CutOffDate

			-- Update active player
			;WITH CTE AS
			(
				SELECT d.MonthDate, d.AffId, s.GroupProductId, d.CustId, l.IsActivePlayerSum
				FROM #Data d
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.CustId = m.CustId AND d.MonthDate >= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, m.FirstDepositDate) + 1, 0))
					INNER JOIN @Setting s ON d.MonthDate = s.MonthDate AND d.GroupId = s.GroupId AND d.ProductId = s.ProductId
					OUTER APPLY (SELECT TOP(1) IsActivePlayerSum FROM dbo.TierSettingHistory h WITH(NOLOCK) WHERE h.MonthDate = d.MonthDate AND h.GroupId = d.GroupId) AS l
				WHERE d.ProductId > 0 AND d.MonthDate >= @P2P_CutOffDate
			),CTE_GroupProduct AS 
			(
				SELECT MonthDate, AffId, GroupProductId, COUNT(DISTINCT CustId) AS ActivePlayer FROM CTE WHERE IsActivePlayerSum = 0 GROUP BY MonthDate, AffId, GroupProductId
			),CTE_SUM AS
			(
				SELECT MonthDate, AffId, COUNT(DISTINCT CustId) AS ActivePlayer FROM CTE GROUP BY MonthDate, AffId
			)
			UPDATE c
				SET c.ActivePlayer = ISNULL(ISNULL(p.ActivePlayer, a.ActivePlayer), 0), c.ActivePlayerSum = ISNULL(a.ActivePlayer, 0)
			FROM #Commission c 
				LEFT JOIN CTE_GroupProduct p ON c.MonthDate = p.MonthDate AND c.AffId = p.AffId AND c.GroupProductId = p.GroupProductId
				LEFT JOIN CTE_SUM a ON a.MonthDate = c.MonthDate AND a.AffId = c.AffId
			WHERE c.ProductId = 0 AND c.MonthDate >= @P2P_CutOffDate
		END

		-- Total: Commission
		UPDATE c
		SET c.CommissionRate		= ISNULL(s.Commission, 0)
			,c.Commission			= ISNULL(s.Commission, 0) * c.NetWinloss
		FROM #Commission c
			OUTER APPLY (
				SELECT gsh.TierId
				FROM dbo.TierSettingHistory gsh WITH (NOLOCK)
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(gsh.MonthDate, @AffCurrency, @BaseCurrency) e
				WHERE c.MonthDate = gsh.MonthDate AND c.GroupId = gsh.GroupId AND c.GroupProductId = gsh.GroupProductId
					AND FLOOR(ABS(c.NetWinloss)) BETWEEN gsh.MinAmount * e.Rate AND gsh.MaxAmount * e.Rate
			) AS t
			OUTER APPLY (
				SELECT TOP 1 gsh.Commission
				FROM dbo.TierSettingHistory gsh WITH (NOLOCK)
				WHERE c.MonthDate = gsh.MonthDate AND c.GroupId = gsh.GroupId AND c.GroupProductId = gsh.GroupProductId
					AND c.ActivePlayer BETWEEN gsh.MinAM AND gsh.MaxAM
					AND gsh.TierId <= t.TierId
				ORDER BY gsh.TierId DESC
			) AS s
		WHERE c.ProductId = 0

		--Update Active player
		UPDATE #Commission
			SET ActivePlayer = CASE WHEN GroupProductId > 1 THEN 0 
									WHEN GroupProductId = 1 THEN ActivePlayerSum
							   ELSE ActivePlayer END
				,IsMultiGroupProduct = CASE WHEN GroupProductId > 1 THEN 1 ELSE 0 END 
		WHERE MonthDate >= @P2P_CutOffDate AND ProductId = 0

		IF @IsForJob = 0
		BEGIN
			INSERT INTO #Commission
			(
				MonthDate,
				AffId,
				GroupId,
				GroupProductId,
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
				ActivePlayer,
				CommissionRate,
				Commission,
				StraightCommission,
				SubAffCommission,
				IsMultiGroupProduct
			)
			SELECT 
				MonthDate,
				AffId,
				GroupId,
				0 AS GroupProductId,
				0 AS ProductId,
				SUM(Deposit),
				SUM(Withdrawal),
				SUM(Bonus),
				SUM(Rebate),
				SUM(Turnover),
				SUM(Winloss),
				SUM(Revenue),
				SUM(P2PFee),
				SUM(PlatFormFee),
				SUM(OperationalFee),
				SUM(DepositFee),
				SUM(WithdrawalFee),
				SUM(GrossWinloss),
				SUM(NetWinloss),
				MAX(ActivePlayer),
				SUM(CASE WHEN GroupProductId IN (0, 1) THEN CommissionRate ELSE 0 END),
				SUM(Commission),
				SUM(StraightCommission),
				SUM(SubAffCommission),
				MAX(CASE WHEN GroupProductId > 1 THEN 1 ELSE 0 END) AS IsMultiGroupProduct
			FROM #Commission
			WHERE ProductId = 0 AND MonthDate > @P2P_CutOffDate AND GroupProductId <> 0
			GROUP BY MonthDate, AffId, GroupId
	
			DELETE #Commission WHERE ProductId = 0 AND GroupProductId <> 0
		END
		

		-- Filter by Currencies
		IF @Currencies <> ''
		BEGIN
			UPDATE c
			SET c.Turnover	= ISNULL(d.Turnover, 0)
				,c.Winloss	= ISNULL(d.Winloss, 0)
				,c.Revenue	= ISNULL(d.Revenue, 0)
			FROM #Commission c
				LEFT JOIN (
					SELECT MonthDate, AffId, ProductId
						,SUM(Turnover)	AS Turnover
						,SUM(Winloss)	AS Winloss
						,SUM(Revenue)	AS Revenue
					FROM #Data
					WHERE ProductId > 0
						AND ',' + @Currencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), Currency) + ',%'
					GROUP BY MonthDate, AffId, ProductId
				) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId AND c.ProductId = d.ProductId
			WHERE c.ProductId > 0

			UPDATE c
			SET c.Turnover	= ISNULL(d.Turnover, 0)
				,c.Winloss	= ISNULL(d.Winloss, 0)
				,c.Revenue	= ISNULL(d.Revenue, 0)
			FROM #Commission c
				LEFT JOIN (
					SELECT MonthDate, AffId
						,SUM(Turnover)	AS Turnover
						,SUM(Winloss)	AS Winloss
						,SUM(Revenue)	AS Revenue
					FROM #Commission
					WHERE ProductId > 0
					GROUP BY MonthDate, AffId
				) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId
			WHERE c.ProductId = 0
		END

		-- Filter by Products
		IF @ProductIds <> '0'
		BEGIN
			IF @ProductIds = ''
			BEGIN
				DELETE #Commission WHERE ProductId > 0
				UPDATE #Commission SET Turnover = 0, Winloss = 0, Revenue = 0
			END
			ELSE
			BEGIN
				UPDATE c
				SET c.Turnover	= ISNULL(d.Turnover, 0)
					,c.Winloss	= ISNULL(d.Winloss, 0)
					,c.Revenue	= ISNULL(d.Revenue, 0)
				FROM #Commission c
					LEFT JOIN (
						SELECT MonthDate, AffId
							,SUM(Turnover)	AS Turnover
							,SUM(Winloss)	AS Winloss
							,SUM(Revenue)	AS Revenue
						FROM #Commission
						WHERE ',' + @ProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(10), ProductId) + ',%'
						GROUP BY MonthDate, AffId
					) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId
				WHERE c.ProductId = 0

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
			INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, IsHasMemberData)
			SELECT md.MonthDate, md.AffId, agh.GroupId, 0, 0
			FROM @MonthDate md
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON agh.MonthDate = md.MonthDate AND agh.AffId = md.AffId
				LEFT JOIN #Commission c ON c.MonthDate = md.MonthDate AND c.AffId = md.AffId AND c.ProductId = 0
			WHERE c.AffId IS NULL
		END

		;WITH CTE_SubAffCommission AS
		(
			SELECT c.MonthDate, f.val AS AffId
				,SUM(CASE WHEN f.Id <= @MaxSubAff THEN POWER(@SubAffCommRate, f.Id) * (c.Commission + c.StraightCommission) ELSE 0 END) AS SubAffCommission
			FROM #Commission c
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON agh.MonthDate = c.MonthDate AND agh.AffId = c.AffId
				CROSS APPLY dbo.Aff_f_StringSplit(agh.AllParentAffId, ',') f
			WHERE c.ProductId = 0
			GROUP BY c.MonthDate, f.val
		)
		UPDATE c
		SET c.SubAffCommission = s.SubAffCommission
		FROM #Commission c
			INNER JOIN CTE_SubAffCommission s ON s.MonthDate = c.MonthDate AND s.AffId = c.AffId
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
		SET Commission				= 0
			,StraightCommission		= 0
			,SubAffCommission		= 0
			,P2PFee					= 0
			,PlatFormFee			= 0
			,OperationalFee			= 0
			,DepositFee				= 0
			,WithdrawalFee			= 0
			,CommissionRate			= 0
		WHERE MonthDate < DATEADD(DAY, -1, @LaunchDate)
	END

	-- Data between SoftLaunchDate and LaunchDate
	IF EXISTS (SELECT 1 FROM #Data WHERE IsDataInMonth = 0)
	BEGIN
		UPDATE c
		SET c.Deposit		= ISNULL(d.Deposit, 0)
			,c.Withdrawal	= ISNULL(d.Withdrawal, 0)
			,c.Bonus		= ISNULL(d.Bonus, 0)
			,c.Rebate		= ISNULL(d.Rebate, 0)
			,c.Turnover		= ISNULL(d.Turnover, 0)
			,c.Winloss		= ISNULL(d.Winloss, 0)
			,c.Revenue		= ISNULL(d.Revenue, 0)
			,c.GrossWinloss	= ISNULL(-d.Winloss, 0)
		FROM #Commission c
			INNER JOIN (
				SELECT MonthDate, AffId, ProductId
					,SUM(Deposit)		AS Deposit
					,SUM(Withdrawal)	AS Withdrawal
					,SUM(Bonus)			AS Bonus
					,SUM(Rebate)		AS Rebate
					,SUM(Turnover)		AS Turnover
					,SUM(Winloss)		AS Winloss
					,SUM(Revenue)		AS Revenue
				FROM #Data
				WHERE IsDataInMonth = 1
			) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId AND c.ProductId = d.ProductId
		WHERE c.MonthDate = DATEADD(DAY, -1, @LaunchDate)

		UPDATE c
		SET c.Turnover		= d.Turnover
			,c.Winloss		= d.Winloss
			,c.Revenue		= d.Revenue
			,c.GrossWinloss	= d.GrossWinloss
		FROM #Commission c
			INNER JOIN (
				SELECT MonthDate, AffId
					,SUM(Turnover)		AS Turnover
					,SUM(Winloss)		AS Winloss
					,SUM(Revenue)		AS Revenue
					,SUM(GrossWinloss)	AS GrossWinloss
				FROM #Commission
				WHERE MonthDate = DATEADD(DAY, -1, @LaunchDate)
					AND ProductId > 0
				GROUP BY MonthDate, AffId
			) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId
		WHERE c.MonthDate = DATEADD(DAY, -1, @LaunchDate)
			AND c.ProductId = 0
	END

	-- Return data
	IF @IsForJob = 1
	BEGIN
		IF @IsSumAll = 1
		BEGIN
			SELECT
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0)) AS MonthDate,
				AffId,
				GroupId,
				ProductId,
				GroupProductId,
				SUM(Deposit)				AS Deposit,
				SUM(Withdrawal)				AS Withdrawal,
				SUM(Bonus)					AS Bonus,
				SUM(Rebate)					AS Rebate,
				SUM(Turnover)				AS Turnover,
				SUM(Winloss)				AS Winloss,
				SUM(Revenue)				AS Revenue,
				SUM(P2PFee)					AS P2PFee,
				SUM(PlatFormFee)			AS PlatFormFee,
				SUM(OperationalFee)			AS OperationalFee,
				SUM(DepositFee)				AS DepositFee,
				SUM(WithdrawalFee)			AS WithdrawalFee,
				SUM(GrossWinloss)			AS GrossWinloss,
				SUM(NetWinloss)				AS NetWinloss,
				SUM(ActivePlayer)			AS ActivePlayer,
				SUM(CommissionRate)			AS CommissionRate,
				SUM(Commission)				AS Commission,
				SUM(StraightCommission)		AS StraightCommission,
				SUM(SubAffCommission)		AS SubAffCommission,
				MAX(IsMultiGroupProduct)    AS IsMultiGroupProduct
			FROM #Commission
			GROUP BY
				AffId,
				GroupId,
				ProductId
		END
		ELSE
		BEGIN
			SELECT
				MonthDate,
				AffId,		
				GroupId,
				ProductId,
				GroupProductId,
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
				ActivePlayer,
				CommissionRate,
				Commission,
				StraightCommission,
				SubAffCommission,
				IsMultiGroupProduct
			FROM #Commission
		END
	END
	ELSE
	BEGIN
		IF @IsSumAll = 1
		BEGIN
			SELECT
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0)) AS MonthDate,
				AffId,
				GroupId,
				ProductId,
				SUM(Deposit)				AS Deposit,
				SUM(Withdrawal)				AS Withdrawal,
				SUM(Bonus)					AS Bonus,
				SUM(Rebate)					AS Rebate,
				SUM(Turnover)				AS Turnover,
				SUM(Winloss)				AS Winloss,
				SUM(Revenue)				AS Revenue,
				SUM(P2PFee)					AS P2PFee,
				SUM(PlatFormFee)			AS PlatFormFee,
				SUM(OperationalFee)			AS OperationalFee,
				SUM(DepositFee)				AS DepositFee,
				SUM(WithdrawalFee)			AS WithdrawalFee,
				SUM(GrossWinloss)			AS GrossWinloss,
				SUM(NetWinloss)				AS NetWinloss,
				SUM(ActivePlayer)			AS ActivePlayer,
				SUM(CommissionRate)			AS CommissionRate,
				SUM(Commission)				AS Commission,
				SUM(StraightCommission)		AS StraightCommission,
				SUM(SubAffCommission)		AS SubAffCommission,
				MAX(IsMultiGroupProduct)    AS IsMultiGroupProduct
			FROM #Commission
			GROUP BY
				AffId,
				GroupId,
				ProductId
		END
		ELSE
		BEGIN
			SELECT
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
				ActivePlayer,
				CommissionRate,
				Commission,
				StraightCommission,
				SubAffCommission,
				IsMultiGroupProduct
			FROM #Commission
		END
	END

	DROP TABLE #Data
	DROP TABLE #Commission
END
GO