/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="1"></info>*/
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
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core SP - Calculate commission for months which are not calculated yet

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241225@Sally: Apply QM Turnover [RedmineID: #212201]
		- 20250318@Sally: Fix get QM Turnover SUM [RedmineID: #220322]
		- 20250319@Sally: Change Commission Calculation [RedmineID: #219936]

	Param's Explanation:
		- @BaseCurrency : Currency of B2C
		- @Currencies : Currency of B2C, 72: represent for USD( currency 72, 3)
*/


BEGIN
	SET NOCOUNT ON

	DECLARE @BeginOfFromMonthDate SMALLDATETIME, @EndOfToMonthDate SMALLDATETIME

	SELECT  @BeginOfFromMonthDate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate), 0) -- First day of @FromMonthDate
	SELECT  @EndOfToMonthDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0)) -- Last day of @ToMonthDate

	SELECT  @FromMonthDate = @BeginOfFromMonthDate, @ToMonthDate = @EndOfToMonthDate

	DECLARE @SoftLaunchDate SMALLDATETIME, @LaunchDate SMALLDATETIME, @CommissionCal_CutOffDate SMALLDATETIME
	SELECT  @SoftLaunchDate             = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'SoftLaunchDate'
	SELECT  @LaunchDate		            = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'LaunchDate'
    SELECT  @CommissionCal_CutOffDate	= CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'CommissionCal_CutOffDate'
    
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
		OPTION(MAXRECURSION 0)
	END

	-- AffCurrency
	DECLARE @AffCurrency INT
	SELECT  @AffCurrency = dbo.Aff_f_GetSetting('AffCurrency')

	-- Get affcurrency mapping
	DECLARE @AffExchangeId INT = @AffCurrency
	SELECT  @AffExchangeId = tp.ExchangeId
	FROM dbo.TpExchange tp WITH (NOLOCK)
	WHERE tp.TpExchangeId = @AffCurrency

	-- Get BaseCurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	IF @BaseCurrency = 0
		SET @BaseExchangeId = @AffExchangeId
	ELSE
	BEGIN
		SELECT @BaseExchangeId = tp.ExchangeId
		FROM dbo.TpExchange tp WITH (NOLOCK)
		WHERE tp.TpExchangeId = @BaseCurrency
	END 

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
		CREATE CLUSTERED INDEX IX_Data_MonthDate ON #Data (MonthDate, ProductId)

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
				,SUM(ISNULL(Winloss, 0) - ISNULL(ProgressiveWin, 0) + ISNULL(ProgressiveBet, 0)) AS Winloss
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
			WHERE r.WinlostDate BETWEEN @BeginOfFromMonthDate AND @EndOfToMonthDate
				AND (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), AffId) + ',%')
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
					WHERE mr.CustId = r.custid AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
				)
			GROUP BY CONVERT(SMALLDATETIME, DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)))
				,AffId, CustId, Currency, CASE WHEN ProductId < 0 THEN 0 ELSE ProductId END
		) r
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.MonthDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
		GROUP BY r.MonthDate, r.AffId, r.CustId, r.Currency, r.ProductId
	END


	-- Setting
	BEGIN
		DECLARE @AffGroupInfo TABLE (MonthDate SMALLDATETIME, AffId INT, GroupId INT, GroupTypeBy VARCHAR(50), QMTurnover MONEY)
		
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

		UPDATE a SET a.GroupTypeBy = gt.GroupTypeBy
		FROM @AffGroupInfo a
			INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON a.GroupId = cg.GroupId
			INNER JOIN dbo.GroupType gt WITH (NOLOCK) ON gt.GroupTypeId = cg.GroupTypeId

		UPDATE a SET a.QMTurnover = ISNULL(cg.QMTurnover, 0)
		FROM @AffGroupInfo a
			INNER JOIN dbo.CommGroupHistory cg WITH (NOLOCK) ON a.GroupId = cg.GroupId AND a.MonthDate = cg.MonthDate
		
		DECLARE @GroupProductInfo TABLE (MonthDate SMALLDATETIME, GroupId INT, NoGroupProduct SMALLINT)

		DECLARE @Setting TABLE
		(
			MonthDate			SMALLDATETIME,
			GroupId				INT,
			ProductId			INT,
			GroupProductId		INT,
			PlatFormFee			DECIMAL(9,8) DEFAULT (0),
			PlatFormAmount		MONEY DEFAULT (0),
			DepositFee			DECIMAL(9,8) DEFAULT (0),
			DepositAmount		MONEY DEFAULT (0),
			WithdrawalFee		DECIMAL(9,8) DEFAULT (0),
			WithdrawalAmount	MONEY DEFAULT (0)
		)

		;WITH CTE_Group AS (SELECT DISTINCT MonthDate, GroupId FROM @AffGroupInfo)
		INSERT INTO @Setting (MonthDate, GroupId , ProductId, GroupProductId, PlatFormFee, PlatFormAmount, DepositFee, DepositAmount, WithdrawalFee, WithdrawalAmount)
		SELECT a.MonthDate, a.GroupId, ds.ProductId, ds.GroupProductId, ds.PlatFormFee, ds.PlatFormAmount, ds.DepositFee, ds.DepositAmount, ds.WithdrawalFee, ds.WithdrawalAmount
		FROM CTE_Group a
			CROSS APPLY (
				SELECT dsh.ProductId, dsh.GroupProductId,
					SUM(CASE WHEN dsh.DeductionId = 10 THEN dsh.DeductedPercentage ELSE 0 END) AS PlatFormFee,
					SUM(CASE WHEN dsh.DeductionId = 10 THEN dsh.DeductedAmount ELSE 0 END) AS PlatFormAmount,
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
			s.DepositAmount = s.DepositAmount * e.Rate,
			s.WithdrawalAmount = s.WithdrawalAmount * e.Rate
		FROM @Setting s
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(s.MonthDate, @AffExchangeId, @BaseExchangeId) e
	END

	UPDATE d
	SET d.GroupId	= a.GroupId
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
			NetTurnover			MONEY DEFAULT (0),
			ActivePlayer		INT	  DEFAULT (0),
			QualifiedMember		INT   DEFAULT (0),
			CommissionRate		DECIMAL(9,8) DEFAULT (0),
			Commission			MONEY DEFAULT (0),
			StraightCommission	MONEY DEFAULT (0),
			SubAffCommission	MONEY DEFAULT (0),
			IsHasMemberData		BIT DEFAULT (1),
			ActivePlayerSum		INT DEFAULT (0),
			QualifiedMemberSum	INT DEFAULT (0),
			IsMultiGroupProduct BIT DEFAULT (0),
			IsStraightSetting   TINYINT DEFAULT (0)
		)
	
		CREATE NONCLUSTERED INDEX IX_MonthDate ON #Commission (MonthDate, AffId, GroupId, ProductId)

		 -- New formula
		BEGIN
			-- By Product
			UPDATE s
				SET s.GroupProductId = 0
			FROM @Setting s
			WHERE EXISTS (SELECT 1 FROM dbo.TierSettingHistory tsh WITH(NOLOCK) WHERE tsh.MonthDate = s.MonthDate AND tsh.GroupId = s.GroupId AND tsh.GroupProductId = 0)
			
			INSERT INTO @GroupProductInfo (MonthDate, GroupId, NoGroupProduct)
			SELECT MonthDate, GroupId, COUNT(DISTINCT GroupProductId) AS [NoGroupProduct] 
			FROM @Setting 
			GROUP BY MonthDate, GroupId

			INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, GroupProductId, Turnover, Winloss, GrossWinloss, PlatFormFee)
			SELECT 
				d.MonthDate, d.AffId, d.GroupId, d.ProductId
				,s.GroupProductId
				,d.Turnover
				,d.Winloss
				,-d.Winloss AS GrossWinloss
				,CASE WHEN d.MonthDate >= @CommissionCal_CutOffDate THEN abs(-d.Winloss) 
					ELSE IIF( d.Winloss > 0, 0, -d.Winloss) END
					* ISNULL(s.PlatFormFee, 0) + ISNULL(s.PlatFormAmount, 0) AS PlatFormFee
			FROM (
				SELECT MonthDate, AffId, GroupId, ProductId, SUM(Turnover) Turnover, SUM(Winloss) Winloss
				FROM #Data
				WHERE ProductId > 0
				GROUP BY MonthDate, AffId, GroupId, ProductId
			) d
				INNER JOIN @Setting s ON d.MonthDate = s.MonthDate AND d.GroupId = s.GroupId AND d.ProductId = s.ProductId

			-- Total
			INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, GroupProductId, Turnover, Winloss, GrossWinloss, PlatFormFee)
			SELECT c.MonthDate, c.AffId, c.GroupId, 0 AS ProductId, c.GroupProductId, c.Turnover, c.Winloss, c.GrossWinloss, c.PlatFormFee
			FROM (
				SELECT MonthDate, AffId, GroupId, 0 AS ProductId, GroupProductId
					,SUM(Turnover) AS Turnover
					,SUM(Winloss) AS Winloss
					,SUM(GrossWinloss) AS GrossWinloss
					,SUM(PlatFormFee) AS PlatFormFee
				FROM #Commission
				GROUP BY MonthDate, AffId, GroupId, GroupProductId
			)  c
				LEFT JOIN @Setting s ON c.MonthDate = s.MonthDate AND c.GroupId = s.GroupId AND c.ProductId = s.ProductId

			UPDATE #Commission SET P2PFee = 0, PlatFormFee = 0, OperationalFee = 0 WHERE ProductId > 0
			
			-- Total: Deposit, Withdrawal, ActivePlayer, Net WinLoss, Net Turnover, QualifiedMember
			UPDATE c
			SET c.Deposit			= ISNULL(d.Deposit, 0) / ISNULL(e.[NoGroupProduct], 1)
				,c.Withdrawal		= ISNULL(d.Withdrawal, 0) / ISNULL(e.[NoGroupProduct], 1)
				,c.Bonus			= ISNULL(d.Bonus, 0) / ISNULL(e.[NoGroupProduct], 1)
				,c.Rebate			= ISNULL(d.Rebate, 0) / ISNULL(e.[NoGroupProduct], 1)
				,c.DepositFee		= ISNULL(d.DepositFee, 0) / ISNULL(e.[NoGroupProduct], 1)
				,c.WithdrawalFee	= ISNULL(d.WithdrawalFee, 0) / ISNULL(e.[NoGroupProduct], 1)
				,c.NetWinloss		= c.GrossWinloss - c.PlatFormFee - (ISNULL(d.DepositFee, 0) + ISNULL(d.WithdrawalFee, 0) + ISNULL(d.Bonus, 0) + ISNULL(d.Rebate, 0))/ ISNULL(e.NoGroupProduct, 1)
			FROM #Commission c
				INNER JOIN @AffGroupInfo ag ON c.MonthDate = ag.MonthDate AND c.AffId = ag.AffId AND c.GroupId = ag.GroupId
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
					WHERE d.ProductId = 0
					GROUP BY d.MonthDate, d.AffId, d.GroupId
				) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId AND c.GroupId = d.GroupId
				LEFT JOIN @GroupProductInfo e ON c.MonthDate = e.MonthDate AND c.GroupId = e.GroupId 
			WHERE c.ProductId = 0
			
			-- Update active player
			;WITH CTE_Group AS(
				SELECT a.MonthDate, a.GroupId, a.AffId, l.IsActivePlayerSum, ISNULL(a.QMTurnover, 0) * e.Rate AS QMTurnover
				FROM @AffGroupInfo a
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(a.MonthDate, @AffExchangeId, @BaseExchangeId) e
					OUTER APPLY (SELECT TOP(1) h.IsActivePlayerSum FROM dbo.TierSettingHistory h WITH(NOLOCK) WHERE h.MonthDate = a.MonthDate AND h.GroupId = a.GroupId) AS l
			)
			,CTE_DataPlayer AS(
				SELECT d.MonthDate, d.AffId, s.GroupProductId, d.CustId, g.IsActivePlayerSum, SUM(ISNULL(d.Turnover, 0)) AS Turnover, QMTurnover
				FROM #Data d
					INNER JOIN @Setting s ON d.MonthDate = s.MonthDate AND d.GroupId = s.GroupId AND d.ProductId = s.ProductId
					LEFT JOIN CTE_Group g ON g.MonthDate = d.MonthDate AND g.AffId = d.AffId
				WHERE d.ProductId > 0
				GROUP BY d.MonthDate, d.AffId, s.GroupProductId, d.CustId, g.IsActivePlayerSum, QMTurnover
			)		
			,CTE_Player AS(
				SELECT d.MonthDate, d.AffId, d.GroupProductId, d.CustId, d.IsActivePlayerSum, CASE WHEN Turnover >= QMTurnover THEN d.CustId ELSE NULL END AS CustQMTurnover
				FROM CTE_DataPlayer d
			)
			,CTE_GroupProduct AS (
				SELECT MonthDate, AffId, GroupProductId
					,COUNT(DISTINCT CustId) AS ActivePlayer
					,COUNT(DISTINCT CustQMTurnover) AS QualifiedMember
				FROM CTE_Player 
				WHERE IsActivePlayerSum = 0 
				GROUP BY MonthDate, AffId, GroupProductId
			)
			,CTE_ActivePlayerSUM AS(
				SELECT MonthDate, AffId
					,COUNT(DISTINCT CustId) AS ActivePlayer
				FROM CTE_Player
				WHERE IsActivePlayerSum = 1
				GROUP BY MonthDate, AffId
			)
			,CTE_QualifiedPlayerSum AS(
				SELECT d.MonthDate, d.AffId, COUNT(DISTINCT IIF(d.Turnover >= d.QMTurnover, d.CustId, NULL))AS QualifiedMember
				FROM (
					SELECT d.MonthDate, d.AffId, d.CustId, SUM(d.Turnover) AS Turnover, QMTurnover
					FROM CTE_DataPlayer d
					WHERE d.IsActivePlayerSum = 1
					GROUP BY d.MonthDate, d.AffId, d.CustId, QMTurnover
				)d
				GROUP BY d.MonthDate, d.AffId
			)			
			UPDATE c
				SET c.ActivePlayer		 = ISNULL(ISNULL(p.ActivePlayer, cs.ActivePlayer), 0),
					c.QualifiedMember	 = ISNULL(ISNULL(p.QualifiedMember, qs.QualifiedMember), 0),
					c.ActivePlayerSum	 = ISNULL(cs.ActivePlayer, 0),
					c.QualifiedMemberSum = ISNULL(qs.QualifiedMember, 0)
			FROM #Commission c 
				LEFT JOIN CTE_GroupProduct p ON c.MonthDate = p.MonthDate AND c.AffId = p.AffId AND c.GroupProductId = p.GroupProductId
				LEFT JOIN CTE_ActivePlayerSUM cs ON cs.MonthDate = c.MonthDate AND cs.AffId = c.AffId
				LEFT JOIN CTE_QualifiedPlayerSum qs ON qs.MonthDate = c.MonthDate AND qs.AffId = c.AffId
			WHERE c.ProductId = 0
		END

		-- Total: Commission
		UPDATE c
		SET c.CommissionRate = ISNULL(s.Commission, 0)
			,c.Commission	 = ISNULL(s.Commission, 0) * c.NetWinloss									
		FROM #Commission c
			INNER JOIN @AffGroupInfo ag ON c.MonthDate = ag.MonthDate AND c.AffId = ag.AffId AND c.GroupId = ag.GroupId
			OUTER APPLY (
				SELECT gsh.TierId
				FROM dbo.TierSettingHistory gsh WITH (NOLOCK)
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(gsh.MonthDate, @AffExchangeId, @BaseExchangeId) e
				WHERE c.MonthDate = gsh.MonthDate AND c.GroupId = gsh.GroupId AND c.GroupProductId = gsh.GroupProductId
					AND IIF(c.MonthDate >= @CommissionCal_CutOffDate, c.NetWinloss, abs(c.NetWinloss)) BETWEEN gsh.MinAmount * e.Rate AND gsh.MaxAmount * e.Rate
			) AS t
			OUTER APPLY (
				SELECT TOP 1 gsh.Commission
				FROM dbo.TierSettingHistory gsh WITH (NOLOCK)
				WHERE c.MonthDate = gsh.MonthDate AND c.GroupId = gsh.GroupId AND c.GroupProductId = gsh.GroupProductId
					AND c.QualifiedMember BETWEEN gsh.MinQM AND gsh.MaxQM
					AND gsh.TierId <= t.TierId
				ORDER BY gsh.TierId DESC
			) AS s
			LEFT JOIN @GroupProductInfo e ON c.MonthDate = e.MonthDate AND c.GroupId = e.GroupId 
		WHERE c.ProductId = 0

		--Update Active player
		;WITH CTE_Group AS
		(
			SELECT MonthDate, AffId, MAX(GroupProductId) AS GroupProductId, MAX(QualifiedMemberSum) AS QualifiedMemberSum ,  MAX(ActivePlayerSum) AS ActivePlayerSum
			FROM #Commission 
			WHERE ProductId = 0
			GROUP BY MonthDate, AffId
		)
		UPDATE c
			SET QualifiedMember = ISNULL(g.QualifiedMemberSum, 0),
				ActivePlayer	= ISNULL(g.ActivePlayerSum, 0)
		FROM #Commission c
			LEFT JOIN CTE_Group g ON g.MonthDate = c.MonthDate AND g.AffId = c.AffId AND g.GroupProductId = c.GroupProductId	
		WHERE c.ProductId = 0

		UPDATE #Commission
			SET ProductId = -1
		WHERE ProductId = 0

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
			NetTurnover,
			ActivePlayer,
			QualifiedMember,
			CommissionRate,
			Commission,
			StraightCommission,
			SubAffCommission
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
			SUM(NetTurnover),
			MAX(ActivePlayer),
			MAX(QualifiedMember),
			MAX(CommissionRate),
			SUM(Commission),
			SUM(StraightCommission),
			SUM(SubAffCommission)
		FROM #Commission
		WHERE ProductId = -1
		GROUP BY MonthDate, AffId, GroupId

		--Update Deposit, Withdrawal, Bonus, Rebate, DepositFee, WithdrawalFee

		UPDATE c
			SET c.Deposit			= d.Deposit
				,c.Withdrawal		= d.Withdrawal
				,c.Rebate			= d.Rebate
				,c.Bonus			= d.Bonus
				,c.DepositFee		= d.DepositFee
				,c.WithdrawalFee	= d.WithdrawalFee
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
					WHERE d.ProductId = 0
					GROUP BY d.MonthDate, d.AffId, d.GroupId
				) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId AND c.GroupId = d.GroupId
		WHERE c.ProductId = 0

		IF @IsForJob = 0 OR  @IsSumAll = 1
			DELETE #Commission WHERE ProductId = -1
		
		-- Filter by Currencies
		IF @Currencies <> ''
		BEGIN
			--Get list currencies maping
			DECLARE @ListCurrencies VARCHAR(MAX) = ''
			SELECT @ListCurrencies = COALESCE(@ListCurrencies + ',', '') + CONVERT(VARCHAR(20), t.TpExchangeId)
			FROM string_split(@Currencies, ',') f
				CROSS APPLY(
					SELECT TpExchangeId
					FROM dbo.Aff_f_TpExchange_Sel(f.value)
				)t

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
						AND ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), Currency) + ',%'
					GROUP BY MonthDate, AffId, ProductId
				) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId AND c.ProductId = d.ProductId
			WHERE c.ProductId > 0

			UPDATE c
			SET c.Turnover	= ISNULL(d.Turnover, 0)
				,c.Winloss	= ISNULL(d.Winloss, 0)
				,c.Revenue	= ISNULL(d.Revenue, 0)
			FROM #Commission c
				LEFT JOIN (
					SELECT MonthDate, AffId, GroupProductId
						,SUM(Turnover)	AS Turnover
						,SUM(Winloss)	AS Winloss
						,SUM(Revenue)	AS Revenue
					FROM #Commission m
					WHERE m.ProductId > 0
					GROUP BY MonthDate, AffId, GroupProductId
				) d ON c.MonthDate = d.MonthDate AND c.AffId = d.AffId AND c.GroupProductId = d.GroupProductId
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
				SET @ProductIds = dbo.Aff_f_AddRelatedProducts(@ProductIds)

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
	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME, AffId INT)

	CREATE TABLE #SubCommRate(	
		MonthDate		SMALLDATETIME,
		AffId			INT,
		SubAffId		INT,
		[Level]			INT,
		SubCommRate		DECIMAL(9,8) DEFAULT (0)
	)

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
				LEFT JOIN #Commission c ON c.MonthDate = md.MonthDate AND c.AffId = md.AffId AND c.ProductId = 0 AND c.GroupProductId = 0
			WHERE c.AffId IS NULL
		)
		BEGIN
			INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, GroupProductId,IsHasMemberData)
			SELECT md.MonthDate, md.AffId, agh.GroupId, 0, 0, 0
			FROM @MonthDate md
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON agh.MonthDate = md.MonthDate AND agh.AffId = md.AffId
				LEFT JOIN #Commission c ON c.MonthDate = md.MonthDate AND c.AffId = md.AffId AND c.ProductId = 0 AND c.GroupProductId = 0
			WHERE c.AffId IS NULL
		END
		----- Get SubAffCommission
	    ;WITH CTE_SubCommRateDirect AS (
            SELECT agh.MonthDate, agh.AffId AS SubAffId, af.AffId, cgh.SubCommRate, f.Level
            FROM dbo.AffGroupHistory agh WITH(NOLOCK)
                CROSS APPLY (
					SELECT CONVERT(INT, val) AS AffId, CONVERT(INT, Id) AS Level
					FROM dbo.Aff_f_StringSplit(agh.AllParentAffId, ',')
				) f
                INNER JOIN dbo.AffGroupHistory af WITH(NOLOCK) ON f.AffId = af.Affid AND af.MonthDate = agh.MonthDate
                INNER JOIN dbo.CommGroupHistory cgh WITH(NOLOCK) ON cgh.GroupId = af.Groupid AND cgh.MonthDate = agh.MonthDate
            WHERE agh.MonthDate BETWEEN @BeginOfFromMonthDate AND @EndOfToMonthDate
        )
		
		INSERT INTO #SubCommRate (MonthDate, AffId, SubAffId, Level, SubCommRate)
        SELECT t.MonthDate, t.AffId, t.SubAffId, t.Level, n.SubCommRate
        FROM CTE_SubCommRateDirect t
			CROSS APPLY (
				SELECT EXP(SUM(LOG(t1.SubCommRate))) AS SubCommRate
				FROM CTE_SubCommRateDirect t1
				WHERE t1.SubAffId = t.SubAffId AND t.Level >= t1.Level AND t.MonthDate = t1.MonthDate
			) AS n
        OPTION (MAXRECURSION 0)
            
       ;WITH CTE_SubAffCommission AS (
            SELECT s.MonthDate, s.AffId, SUM(CASE WHEN s.Level <= @MaxSubAff THEN s.SubCommRate * (c.Commission + c.StraightCommission) ELSE 0 END) AS SubAffCommission
            FROM #Commission c 
                INNER JOIN #SubCommRate s ON s.SubAffId = c.AffId AND s.MonthDate = c.MonthDate
            WHERE ProductId = 0
            GROUP BY s.MonthDate, s.AffId
        )
        UPDATE c SET c.SubAffCommission = s.SubAffCommission
        FROM #Commission c
            INNER JOIN CTE_SubAffCommission s ON s.MonthDate = c.MonthDate AND s.AffId = c.AffId
        WHERE c.ProductId = 0 AND c.GroupProductId = 0

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
				GROUP BY MonthDate, AffId, ProductId
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

	-- Update Multi Group
	UPDATE c
		SET c.IsMultiGroupProduct = CASE WHEN ISNULL(e.NoGroupProduct, 0) > 1 THEN 1 ELSE 0 END
	FROM #Commission c
		 LEFT JOIN @GroupProductInfo e ON c.MonthDate = e.MonthDate AND c.GroupId = e.GroupId 
	WHERE c.ProductId = 0

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
				SUM(Deposit)															AS Deposit,
				SUM(Withdrawal)															AS Withdrawal,
				SUM(Bonus)																AS Bonus,
				SUM(Rebate)																AS Rebate,
				SUM(Turnover)															AS Turnover,
				SUM(Winloss)															AS Winloss,
				SUM(Revenue)															AS Revenue,
				SUM(P2PFee)																AS P2PFee,
				SUM(PlatFormFee)														AS PlatFormFee,
				SUM(OperationalFee)														AS OperationalFee,
				SUM(DepositFee)															AS DepositFee,
				SUM(WithdrawalFee)														AS WithdrawalFee,
				SUM(GrossWinloss)														AS GrossWinloss,
				SUM(NetWinloss)															AS NetWinloss,
				SUM(NetTurnover)														AS NetTurnover,
				SUM(ActivePlayer)														AS ActivePlayer,
				SUM(QualifiedMember)													AS QualifiedMember,
				SUM(CommissionRate)														AS CommissionRate,
				SUM(Commission)															AS Commission,
				SUM(StraightCommission)													AS StraightCommission,
				SUM(SubAffCommission)													AS SubAffCommission,
				CONVERT(BIT, MAX(CONVERT(TINYINT, IsMultiGroupProduct)))				AS IsMultiGroupProduct
			FROM #Commission
			GROUP BY AffId, GroupId, GroupProductId, ProductId
			ORDER BY AffId, GroupId, GroupProductId, ProductId
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
				NetTurnover,
				ActivePlayer,
				QualifiedMember,
				CommissionRate,
				Commission,
				StraightCommission,
				SubAffCommission,
				IsMultiGroupProduct
			FROM #Commission
			ORDER BY MonthDate, AffId, GroupId, GroupProductId, ProductId
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
				SUM(Deposit)															AS Deposit,
				SUM(Withdrawal)															AS Withdrawal,
				SUM(Bonus)																AS Bonus,
				SUM(Rebate)																AS Rebate,
				SUM(Turnover)															AS Turnover,
				SUM(Winloss)															AS Winloss,
				SUM(Revenue)															AS Revenue,
				SUM(P2PFee)																AS P2PFee,
				SUM(PlatFormFee)														AS PlatFormFee,
				SUM(OperationalFee)														AS OperationalFee,
				SUM(DepositFee)															AS DepositFee,
				SUM(WithdrawalFee)														AS WithdrawalFee,
				SUM(GrossWinloss)														AS GrossWinloss,
				SUM(NetWinloss)															AS NetWinloss,
				SUM(NetTurnover)														AS NetTurnover,
				SUM(ActivePlayer)														AS ActivePlayer,
				SUM(QualifiedMember)													AS QualifiedMember,
				SUM(CommissionRate)														AS CommissionRate,
				SUM(Commission)															AS Commission,
				SUM(StraightCommission)													AS StraightCommission,
				SUM(SubAffCommission)													AS SubAffCommission,
				CONVERT(BIT, MAX(CONVERT(TINYINT, IsMultiGroupProduct)))				AS IsMultiGroupProduct
			FROM #Commission
			GROUP BY AffId, GroupId, ProductId
			ORDER BY AffId, GroupId, ProductId
		END
		ELSE
		BEGIN
			SELECT
				MonthDate,
				AffId,		
				GroupId,
				ProductId,
				SUM(Deposit)															AS Deposit,
				SUM(Withdrawal)															AS Withdrawal,
				SUM(Bonus)																AS Bonus,
				SUM(Rebate)																AS Rebate,
				SUM(Turnover)															AS Turnover,
				SUM(Winloss)															AS Winloss,
				SUM(Revenue)															AS Revenue,
				SUM(P2PFee)																AS P2PFee,
				SUM(PlatFormFee)														AS PlatFormFee,
				SUM(OperationalFee)														AS OperationalFee,
				SUM(DepositFee)															AS DepositFee,
				SUM(WithdrawalFee)														AS WithdrawalFee,
				SUM(GrossWinloss)														AS GrossWinloss,
				SUM(NetWinloss)															AS NetWinloss,
				SUM(NetTurnover)														AS NetTurnover,
				SUM(ActivePlayer)														AS ActivePlayer,
				SUM(QualifiedMember)													AS QualifiedMember,
				SUM(CommissionRate)														AS CommissionRate,
				SUM(Commission)															AS Commission,
				SUM(StraightCommission)													AS StraightCommission,
				SUM(SubAffCommission)													AS SubAffCommission,
				CONVERT(BIT, MAX(CONVERT(TINYINT, IsMultiGroupProduct)))				AS IsMultiGroupProduct
			FROM #Commission
			GROUP BY MonthDate, AffId, GroupId, ProductId
			ORDER BY MonthDate, AffId, GroupId, ProductId
		END
	END

	DROP TABLE #Data
	DROP TABLE #Commission
	DROP TABLE #SubCommRate
END