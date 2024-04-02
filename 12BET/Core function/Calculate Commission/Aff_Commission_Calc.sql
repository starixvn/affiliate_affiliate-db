/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_aff,wsv_affv" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_Commission_Calc]
	@AffIds				VARCHAR(MAX) = 'all'
	,@FromMonthDate		SMALLDATETIME = '20230801'
	,@ToMonthDate		SMALLDATETIME = '20230901'
	,@ProductIds		VARCHAR(MAX) = '0'
	,@IsSumAll			BIT = 1
	,@GetRowTotalOnly	BIT = 0
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Core SP - Calculate commission for months which are calculated

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20181120@Percy: Change way to get amount of fees [RedmineID: #104963]
		- 20190808@Percy: Add Exchange [RedmineID: #106504]
		- 20211207@Percy: Apply core function Group Product [RedmineID: #165777]
		- 20230208@Bobby: Implement Bonus & FDM Setting [RedmineId : #191139]
		- 20230731@Eddie: Change WL formula Of Exchange Product [RedmineID: #189569]
		- 20240325@Eddie: Merge VS2 into Virtual Sports and change metadata "bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" [RedmineID: #201095]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @CutOffDate SMALLDATETIME, @n INT = 2147483647 -- max int
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

	DECLARE @tempFromMonth SMALLDATETIME, @tempToMonth SMALLDATETIME
	SELECT  @tempFromMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0))
	SELECT  @tempToMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0))

	DECLARE @tempFrom SMALLDATETIME, @tempTo SMALLDATETIME

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME, AffId INT, GroupId INT)

	DROP TABLE IF EXISTS #AffCommission;
	CREATE TABLE #AffCommission
	(
		MonthDate			SMALLDATETIME
		,AffId				INT
		,GroupId			INT
		,ProductId			INT
		,Deposit			MONEY
		,Withdrawal			MONEY
		,Bonus				MONEY
		,Turnover			MONEY
		,Winloss			MONEY
		,AWinloss			MONEY
		,AComm				MONEY
		,GrossWinloss		MONEY
		,NetWinloss			MONEY
		,PlatFormFee		MONEY
		,OperationalFee		MONEY
		,BankingFee			MONEY
		,ActivePlayer		INT
		,QualifiedMember	INT
		,QMTurnover			MONEY
		,CommissionRate		DECIMAL(9,8)
		,Commission			MONEY
		-----------FDM & Bonus
		,IsApplyBonus		BIT
		,FDMCount			INT
		,FDMDeposit			MONEY DEFAULT (0)
		,FDMCommissionRate	DECIMAL(9,8) DEFAULT (0)
		,FDMCommission		MONEY DEFAULT (0)
	)
	
	-- TODO: Suport FDM & Bonus on AffCommission table
	IF @tempToMonth > @CutOffDate
	BEGIN
		DELETE @MonthDate

		SELECT @tempFrom = CASE WHEN @tempFromMonth <= @CutOffDate THEN DATEADD(DAY, 1, @CutOffDate) ELSE @tempFromMonth END
		SELECT @tempTo = @tempToMonth

		IF @AffIds = 'all'
		BEGIN
			;WITH CTE_MonthDate AS
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @tempFrom) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempTo
			)
			INSERT INTO @MonthDate (MonthDate)
			SELECT MonthDate FROM CTE_MonthDate
			OPTION (MAXRECURSION 0)

			INSERT INTO #AffCommission
			(
				MonthDate, AffId, GroupId, ProductId, IsApplyBonus, Deposit, Withdrawal, Bonus, Turnover, Winloss, AWinloss, AComm, GrossWinloss, NetWinloss, ActivePlayer, QualifiedMember, QMTurnover, CommissionRate, Commission, PlatFormFee, FDMCount, FDMDeposit, FDMCommissionRate, FDMCommission
			)
			SELECT
				dt.MonthDate, dt.AffId, dt.GroupId, dt.ProductId, dt.IsApplyBonus, dt.Deposit, dt.Withdrawal, dt.Bonus, dt.Turnover, dt.Winloss, dt.AWinloss, dt.AComm, dt.GrossWinloss, dt.NetWinloss, dt.ActivePlayer, dt.QualifiedMember, dt.QMTurnover, dt.CommissionRate, 0 AS Commission, dt.PlatFormFee, dt.FDMCount, dt.FDMDeposit, dt.FDMCommissionRate, dt.FDMCommission
			FROM @MonthDate md
				CROSS APPLY (
					SELECT TOP (@n)
						ac.MonthDate, ac.AffId, ac.GroupId
						,ISNULL(g.GroupProductId, ac.ProductId) AS ProductId
						,ISNULL(ac.IsApplyBonus, 0) AS IsApplyBonus
						,SUM(ac.Deposit) 			AS Deposit
						,SUM(ac.Withdrawal) 		AS Withdrawal
						,SUM(ac.Bonus) 				AS Bonus
						,SUM(ac.Turnover) 			AS Turnover
						,SUM(ac.Winloss) 			AS Winloss
						,SUM(ac.AWinloss) 			AS AWinloss
						,SUM(ac.AComm) 				AS AComm
						,SUM(ac.GrossWinloss) 		AS GrossWinloss
						,SUM(ac.NetWinloss) 		AS NetWinloss
						,SUM(ac.ActivePlayer) 		AS ActivePlayer
						,SUM(ac.QualifiedMember) 	AS QualifiedMember
						,SUM(ac.QMTurnover) 		AS QMTurnover
						,SUM(ac.CommissionRate) 	AS CommissionRate
						,SUM(ISNULL(ad.Amount, 0)) 	AS PlatFormFee
						---- FDM
						,SUM(ac.FDMCount) 			AS FDMCount
						,SUM(ac.FDMDeposit) 		AS FDMDeposit
						,SUM(ac.FDMCommissionRate) 	AS FDMCommissionRate
						,SUM(ac.FDMCommission) 		AS FDMCommission
					FROM dbo.rptAffCommission ac WITH (NOLOCK)
						LEFT JOIN dbo.rptAffDeduction ad WITH (NOLOCK) ON ac.MonthDate = ad.MonthDate AND ac.AffId = ad.AffId AND ac.ProductId = ad.ProductId AND ad.DeductionId = 10 AND ad.ProductId > 0
						LEFT JOIN dbo.Aff_f_GroupProduct() g ON ac.ProductId = g.ProductId
					WHERE ac.MonthDate = md.MonthDate
					GROUP BY ac.MonthDate, ac.AffId, ac.GroupId, ISNULL(g.GroupProductId, ac.ProductId), ac.IsApplyBonus
				) AS dt
			OPTION (OPTIMIZE FOR (@n=1))

			UPDATE d
			SET d.Commission = at.Amount
			FROM #AffCommission d
				INNER JOIN dbo.AffTrans at WITH (NOLOCK) ON d.MonthDate = at.TransDate AND d.AffId = at.AffId
			WHERE d.ProductId = 0 AND at.TransType = 201

			;WITH CTE_Fees AS
			(
				SELECT MonthDate
					   ,AffId
					   ,SUM(ABS(PlatFormFee))	AS PlatFormFee
					   ,SUM(OperationalFee)		AS OperationalFee
					   ,SUM(BankingFee)			AS BankingFee
				FROM
				(
					SELECT ad.MonthDate
						   ,ad.AffId
						   ,ad.GroupProductId
						   ,SUM(CASE WHEN ad.DeductionId = 10 THEN ad.Amount ELSE 0 END) AS PlatFormFee
						   ,SUM(CASE WHEN ad.DeductionId = 11 THEN ad.Amount ELSE 0 END) AS OperationalFee
						   ,SUM(CASE WHEN ad.DeductionId = 12 THEN ad.Amount ELSE 0 END) AS BankingFee
					FROM @MonthDate md
						CROSS APPLY dbo.rptAffDeduction ad WITH (NOLOCK)
					WHERE md.MonthDate = ad.MonthDate
					GROUP BY ad.MonthDate, ad.AffId, ad.GroupProductId
				) AS pf
				GROUP BY MonthDate, AffId
			)
			UPDATE d
			SET d.PlatFormFee			= f.PlatFormFee
				,d.OperationalFee		= f.OperationalFee
				,d.BankingFee			= f.BankingFee
			FROM #AffCommission d
				INNER JOIN CTE_Fees f ON d.MonthDate = f.MonthDate AND d.AffId = f.AffId
			WHERE d.ProductId = 0
		END
		ELSE
		BEGIN
			;WITH CTE_MonthDate AS
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @tempFrom) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempTo
			)
			INSERT INTO @MonthDate (MonthDate, AffId)
			SELECT MonthDate, [value] AS AffId FROM CTE_MonthDate CROSS JOIN STRING_SPLIT(@AffIds, ',')
			OPTION (MAXRECURSION 0)

			INSERT INTO #AffCommission
			(
				MonthDate, AffId, GroupId, ProductId, IsApplyBonus, Deposit, Withdrawal, Bonus, Turnover, Winloss, AWinloss, AComm, GrossWinloss, NetWinloss, ActivePlayer, QualifiedMember, QMTurnover, CommissionRate, Commission, PlatFormFee, FDMCount, FDMDeposit, FDMCommissionRate, FDMCommission
			)
			SELECT
				dt.MonthDate, dt.AffId, dt.GroupId, dt.ProductId, dt.IsApplyBonus, dt.Deposit, dt.Withdrawal, dt.Bonus, dt.Turnover, dt.Winloss, dt.AWinloss, dt.AComm, dt.GrossWinloss, dt.NetWinloss, dt.ActivePlayer, dt.QualifiedMember, dt.QMTurnover, dt.CommissionRate, 0 AS Commission, dt.PlatFormFee, dt.FDMCount, dt.FDMDeposit, dt.FDMCommissionRate, dt.FDMCommission
			FROM @MonthDate md
				CROSS APPLY (
					SELECT TOP (@n)
						ac.MonthDate, ac.AffId, ac.GroupId
						,ISNULL(g.GroupProductId, ac.ProductId) AS ProductId
						,ISNULL(ac.IsApplyBonus, 0) AS IsApplyBonus
						,SUM(ac.Deposit) 			AS Deposit
						,SUM(ac.Withdrawal) 		AS Withdrawal
						,SUM(ac.Bonus) 				AS Bonus
						,SUM(ac.Turnover) 			AS Turnover
						,SUM(ac.Winloss) 			AS Winloss
						,SUM(ac.AWinloss) 			AS AWinloss
						,SUM(ac.AComm) 				AS AComm
						,SUM(ac.GrossWinloss) 		AS GrossWinloss
						,SUM(ac.NetWinloss) 		AS NetWinloss
						,SUM(ac.ActivePlayer) 		AS ActivePlayer
						,SUM(ac.QualifiedMember) 	AS QualifiedMember
						,SUM(ac.QMTurnover) 		AS QMTurnover
						,SUM(ac.CommissionRate) 	AS CommissionRate
						,SUM(ISNULL(ad.Amount, 0)) 	AS PlatFormFee
						---- FDM
						,SUM(ac.FDMCount) 			AS FDMCount
						,SUM(ac.FDMDeposit) 		AS FDMDeposit
						,SUM(ac.FDMCommissionRate) 	AS FDMCommissionRate
						,SUM(ac.FDMCommission) 		AS FDMCommission
					FROM dbo.rptAffCommission ac WITH (NOLOCK)
						LEFT JOIN dbo.rptAffDeduction ad WITH (NOLOCK) ON ac.MonthDate = ad.MonthDate AND ac.AffId = ad.AffId AND ac.ProductId = ad.ProductId AND ad.DeductionId = 10 AND ad.ProductId > 0
						LEFT JOIN dbo.Aff_f_GroupProduct() g ON ac.ProductId = g.ProductId
					WHERE ac.MonthDate = md.MonthDate AND ac.AffId = md.AffId
					GROUP BY ac.MonthDate, ac.AffId, ac.GroupId, ISNULL(g.GroupProductId, ac.ProductId), ac.IsApplyBonus
				) AS dt
			OPTION (OPTIMIZE FOR (@n=1))

			UPDATE d
			SET d.Commission = at.Amount
			FROM #AffCommission d
				INNER JOIN dbo.AffTrans at WITH (NOLOCK) ON d.MonthDate = at.TransDate AND d.AffId = at.AffId
			WHERE d.ProductId = 0 AND at.TransType = 201
			
			;WITH CTE_Fees AS
			(
				SELECT MonthDate
					   ,AffId
					   ,SUM(ABS(PlatFormFee))	AS PlatFormFee
					   ,SUM(OperationalFee)		AS OperationalFee
					   ,SUM(BankingFee)			AS BankingFee
				FROM
				(
					SELECT ad.MonthDate
						   ,ad.AffId
						   ,ad.GroupProductId
						   ,SUM(CASE WHEN ad.DeductionId = 10 THEN ad.Amount ELSE 0 END) AS PlatFormFee
						   ,SUM(CASE WHEN ad.DeductionId = 11 THEN ad.Amount ELSE 0 END) AS OperationalFee
						   ,SUM(CASE WHEN ad.DeductionId = 12 THEN ad.Amount ELSE 0 END) AS BankingFee
					FROM @MonthDate md
						CROSS APPLY dbo.rptAffDeduction ad WITH (NOLOCK)
					WHERE md.MonthDate = ad.MonthDate AND md.AffId = ad.AffId
					GROUP BY ad.MonthDate, ad.AffId, ad.GroupProductId
				) AS pf
				GROUP BY MonthDate, AffId
			)
			UPDATE d
			SET d.PlatFormFee			= f.PlatFormFee
				,d.OperationalFee		= f.OperationalFee
				,d.BankingFee			= f.BankingFee
			FROM #AffCommission d
				INNER JOIN CTE_Fees f ON d.MonthDate = f.MonthDate AND d.AffId = f.AffId
			WHERE d.ProductId = 0
		END
	END
	
	-- NOT suport FDM & Bonus on AffCommission table
	IF @tempFromMonth <= @CutOffDate
	BEGIN
		DELETE @MonthDate

		SELECT @tempFrom = @tempFromMonth
		SELECT @tempTo = CASE WHEN @tempToMonth > @CutOffDate THEN @CutOffDate ELSE @tempToMonth END

		DECLARE @tempData TABLE
		(
			MonthDate SMALLDATETIME, AffId INT, GroupId INT, ProductId INT, Deposit MONEY, Withdrawal MONEY, Bonus MONEY, Turnover MONEY, Winloss MONEY, PlatFormFee MONEY, OperationalFee MONEY, BankingFee MONEY, ActivePlayer INT, QualifiedMember INT, NetWinloss MONEY, CommissionRate DECIMAL(9,8), Commission MONEY
		)

		IF @AffIds = 'all'
		BEGIN
			;WITH CTE_MonthDate AS
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @tempFrom) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempTo
			)
			INSERT INTO @MonthDate (MonthDate)
			SELECT MonthDate FROM CTE_MonthDate
			OPTION (MAXRECURSION 0)

			INSERT INTO @tempData
			(
				MonthDate, AffId, GroupId, ProductId, Deposit, Withdrawal, Bonus, Turnover, Winloss, ActivePlayer, QualifiedMember, NetWinloss, CommissionRate, Commission
			)
			SELECT
				dt.MonthDate, dt.AffId, dt.GroupId, dt.ProductId, dt.Deposit, dt.Withdrawal, dt.Bonus, dt.Turnover, dt.Winloss, dt.ActivePlayer, dt.QualifiedMember, dt.NetWinloss, dt.CommissionRate, dt.Commission
			FROM @MonthDate md
				CROSS APPLY (
					SELECT TOP (@n)
						MonthDate, AffId, GroupId, SportId AS ProductId, MemberDeposit AS Deposit, MemberWithdrawal AS Withdrawal, MemberBonus AS Bonus, MemberTurnover AS Turnover, MemberWinlost AS Winloss, ActivePlayer, QualifiedMember, -MemberSum AS NetWinloss, Commission AS CommissionRate, AffWinlost AS Commission
					FROM dbo.AffCommission ac WITH (NOLOCK)
					WHERE ac.WinlostDate = md.MonthDate
						AND (ac.MemberDeposit > 0 OR MemberWithdrawal > 0 OR ac.MemberTurnover > 0)
				) AS dt
			OPTION (OPTIMIZE FOR (@n=1))
		END
		ELSE
		BEGIN
			;WITH CTE_MonthDate AS
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @tempFrom) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempTo
			)
			INSERT INTO @MonthDate (MonthDate, AffId)
			SELECT MonthDate, [value] AS AffId FROM CTE_MonthDate CROSS JOIN STRING_SPLIT(@AffIds, ',')
			OPTION (MAXRECURSION 0)

			INSERT INTO @tempData
			(
				MonthDate, AffId, GroupId, ProductId, Deposit, Withdrawal, Bonus, Turnover, Winloss, ActivePlayer, QualifiedMember, NetWinloss, CommissionRate, Commission
			)
			SELECT
				dt.MonthDate, dt.AffId, dt.GroupId, dt.ProductId, dt.Deposit, dt.Withdrawal, dt.Bonus, dt.Turnover, dt.Winloss, dt.ActivePlayer, dt.QualifiedMember, dt.NetWinloss, dt.CommissionRate, dt.Commission
			FROM @MonthDate md
				CROSS APPLY (
					SELECT TOP (@n)
						MonthDate, AffId, GroupId, SportId AS ProductId, MemberDeposit AS Deposit, MemberWithdrawal AS Withdrawal, MemberBonus AS Bonus, MemberTurnover AS Turnover, MemberWinlost AS Winloss, ActivePlayer, QualifiedMember, -MemberSum AS NetWinloss, Commission AS CommissionRate, AffWinlost AS Commission
					FROM dbo.AffCommission ac WITH (NOLOCK)
					WHERE ac.WinlostDate = md.MonthDate
						AND ac.AffId = md.AffId
						AND (ac.MemberDeposit > 0 OR ac.MemberTurnover > 0)
				) AS dt
			OPTION (OPTIMIZE FOR (@n=1))
		END

		-- By Product
		INSERT INTO #AffCommission
		(
			MonthDate, AffId, GroupId, ProductId, Deposit, Withdrawal, Bonus, Turnover, Winloss, NetWinloss, ActivePlayer, QualifiedMember, QMTurnover, CommissionRate, Commission
		)
		SELECT
			MonthDate, AffId, GroupId, ProductId, 0 AS Deposit, 0 AS Withdrawal, 0 AS Bonus, SUM(Turnover), SUM(Winloss), 0 AS NetWinloss, 0 AS ActivePlayer, 0 AS QualifiedMember, 0 AS QMTurnover, 0 AS CommissionRate, 0 AS Commission
		FROM @tempData
		GROUP BY MonthDate, AffId, GroupId, ProductId

		-- Total
		INSERT INTO #AffCommission
		(
			MonthDate, AffId, GroupId, ProductId, Deposit, Withdrawal, Bonus, Turnover, Winloss, AWinloss, AComm, GrossWinloss, NetWinloss, ActivePlayer, QualifiedMember, QMTurnover, CommissionRate, Commission
		)
		SELECT
			MonthDate, AffId
			,MAX(GroupId) AS GroupId
			,0 AS ProductId
			,SUM(ISNULL(Deposit, 0))
			,SUM(ISNULL(Withdrawal, 0))
			,SUM(ISNULL(Bonus, 0))
			,SUM(ISNULL(Turnover, 0))
			,SUM(ISNULL(Winloss, 0))
			,0 AS AWinloss
			,0 AS AComm
			,0 AS GrossWinloss
			,SUM(ISNULL(NetWinloss, 0))
			,SUM(ISNULL(ActivePlayer, 0))
			,SUM(ISNULL(QualifiedMember, 0))
			,100 AS QMTurnover
			,AVG(ISNULL(CommissionRate, 0))
			,SUM(ISNULL(Commission, 0))
		FROM @tempData
		GROUP BY MonthDate, AffId
	END

	-- Filter by Products
	IF @ProductIds <> '0'
	BEGIN
		IF @ProductIds = ''
		BEGIN
			DELETE #AffCommission WHERE ProductId <> 0

			UPDATE #AffCommission SET Turnover = 0, Winloss = 0
		END
		ELSE
		BEGIN
			UPDATE c1
			SET c1.Turnover = ISNULL(c2.Turnover, 0), c1.Winloss = ISNULL(c2.Winloss, 0)
			FROM #AffCommission c1
				CROSS APPLY (
					SELECT SUM(c2.Turnover) AS Turnover, SUM(c2.Winloss) AS Winloss
					FROM #AffCommission c2
					WHERE c1.MonthDate = c2.MonthDate AND c1.AffId = c2.AffId
					  AND ',' + @ProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(10), c2.ProductId) + ',%'
				) AS c2
			WHERE c1.ProductId = 0

			IF @GetRowTotalOnly = 0
				DELETE #AffCommission WHERE ',' + @ProductIds + ',' NOT LIKE '%,' + CONVERT(VARCHAR(10), ProductId) + ',%' AND ProductId <> 0
			ELSE
				DELETE #AffCommission WHERE ProductId <> 0
		END
	END
	ELSE IF @GetRowTotalOnly = 1
	BEGIN
		DELETE #AffCommission WHERE ProductId <> 0
	END

	-- Return data
	IF @IsSumAll = 1
	BEGIN
		SELECT
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0)) AS MonthDate
			,AffId
			,GroupId
			,ProductId
			,SUM(Deposit)		AS Deposit
			,SUM(Withdrawal) 	AS Withdrawal
			,SUM(Bonus)			AS Bonus
			,SUM(Turnover)		AS Turnover
			,SUM(Winloss)		AS Winloss
			,SUM(AWinloss)		AS AWinloss
			,SUM(AComm)			AS AComm
			,SUM(ISNULL(PlatFormFee, 0))		AS PlatFormFee
			,SUM(ISNULL(OperationalFee, 0))		AS OperationalFee
			,SUM(ISNULL(BankingFee, 0))			AS BankingFee
			,SUM(GrossWinloss)					AS GrossWinloss
			,SUM(NetWinloss)					AS NetWinloss
			,SUM(ActivePlayer)					AS ActivePlayer
			,SUM(QualifiedMember)				AS QualifiedMember
			,SUM(QMTurnOver)					AS QMTurnOver
			,SUM(CommissionRate)				AS CommissionRate
			,SUM(Commission)					AS Commission
			---FDM & Bonus
			,IsApplyBonus
			,SUM(FDMCount)						AS FDMCount
			,SUM(FDMDeposit)					AS FDMDeposit
			,SUM(FDMCommissionRate)				AS FDMCommissionRate
			,SUM(FDMCommission)					AS FDMCommission
		FROM #AffCommission
		GROUP BY AffId, GroupId, ProductId, IsApplyBonus
	END
	ELSE
	BEGIN
		SELECT MonthDate
			   ,AffId
			   ,GroupId
			   ,ProductId
			   ,Deposit
			   ,Withdrawal
			   ,Bonus
			   ,Turnover
			   ,Winloss
			   ,AWinloss
			   ,AComm
			   ,ISNULL(PlatFormFee, 0)		AS PlatFormFee
			   ,ISNULL(OperationalFee, 0)	AS OperationalFee
			   ,ISNULL(BankingFee, 0)		AS BankingFee
			   ,GrossWinloss
			   ,NetWinloss
			   ,ActivePlayer
			   ,QualifiedMember
			   ,QMTurnOver
			   ,CommissionRate
			   ,Commission
			   	---FDM & Bonus
			   ,IsApplyBonus
			   ,FDMCount
			   ,FDMDeposit
			   ,FDMCommissionRate
			   ,FDMCommission
		FROM #AffCommission
	END

	DROP TABLE #AffCommission
END
GO