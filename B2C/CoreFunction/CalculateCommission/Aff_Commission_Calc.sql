/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_Commission_Calc]
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
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core SP - Calculate commission for months which are calculated

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tempFromMonth SMALLDATETIME, @tempToMonth SMALLDATETIME
	SELECT  @tempFromMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0))
	SELECT  @tempToMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0))

	DECLARE @BeginOfFromMonthDate SMALLDATETIME, @EndOfToMonthDate SMALLDATETIME
	SELECT  @BeginOfFromMonthDate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate), 0) -- First day of @FromMonthDate
	SELECT  @EndOfToMonthDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0)) -- Last day of @ToMonthDate

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME, AffId INT, GroupId INT)

	CREATE TABLE #AffCommission
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
		GrossWinloss		MONEY,
		NetWinloss			MONEY,
		PlatFormFee			MONEY,
		OperationalFee		MONEY,
		DepositFee			MONEY,
		WithdrawalFee		MONEY,
		ActivePlayer		INT,
		QualifiedMember		INT,
		QMTurnover			MONEY,
		CommissionRate		DECIMAL(9,8),
		Commission			MONEY,
		SubAffCommission	MONEY
	)

	BEGIN
		DELETE @MonthDate

		IF @AffIds = 'all'
		BEGIN
			WITH CTE_MonthDate AS
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @tempFromMonth) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempToMonth
			)
			INSERT INTO @MonthDate (MonthDate)
			SELECT MonthDate FROM CTE_MonthDate
			OPTION (MAXRECURSION 0)

			INSERT INTO #AffCommission
			(
				MonthDate,AffId,GroupId,ProductId,Deposit,Withdrawal,Bonus,Rebate,Turnover,Winloss,
				GrossWinloss,NetWinloss,ActivePlayer,QualifiedMember,QMTurnover,CommissionRate,Commission,SubAffCommission
			)
			SELECT
				dt.MonthDate,dt.AffId,dt.GroupId,dt.ProductId,dt.Deposit,dt.Withdrawal,dt.Bonus,dt.Rebate,dt.Turnover,dt.Winloss,
				dt.GrossWinloss,dt.NetWinloss,dt.ActivePlayer,dt.QualifiedMember,dt.QMTurnover,dt.CommissionRate,0,0
			FROM @MonthDate md
				CROSS APPLY (
					SELECT
						MonthDate,AffId,GroupId,ProductId,Deposit,Withdrawal,Bonus,ISNULL(Rebate, 0) AS Rebate,Turnover,Winloss,
						GrossWinloss,NetWinloss,ActivePlayer,QualifiedMember,QMTurnover,CommissionRate
					FROM dbo.rptAffCommission ac WITH (NOLOCK)
					WHERE ac.MonthDate = md.MonthDate
				) AS dt

			UPDATE d
			SET d.Commission		= ISNULL(at.Commission, 0)
				,d.SubAffCommission = ISNULL(at.SubAffCommission, 0)
			FROM #AffCommission d
				CROSS APPLY (
					SELECT
						SUM(CASE WHEN at.TransType = 201 THEN at.Amount ELSE 0 END) AS Commission
						,SUM(CASE WHEN at.TransType = 204 THEN at.Amount ELSE 0 END) AS SubAffCommission
					FROM dbo.AffTrans at WITH (NOLOCK)
					WHERE d.MonthDate = at.TransDate
						AND d.AffId = at.AffId
						AND at.TransType IN (201, 204)
				) at
			WHERE d.ProductId = 0

			UPDATE d
			SET d.PlatFormFee	= ad.Amount
			FROM #AffCommission d
				INNER JOIN dbo.rptAffDeduction ad WITH (NOLOCK) ON d.MonthDate = ad.MonthDate AND d.AffId = ad.AffId AND d.ProductId = ad.ProductId
			WHERE ad.DeductionId = 10 AND d.ProductId > 0

			;WITH CTE_Fees AS
			(
				SELECT
					MonthDate,
					AffId,
					SUM(ABS(PlatFormFee))	AS PlatFormFee,
					SUM(OperationalFee)		AS OperationalFee,
					SUM(DepositFee)			AS DepositFee,
					SUM(WithdrawalFee)		AS WithdrawalFee
				FROM
				(
					SELECT
						ad.MonthDate,
						ad.AffId,
						ad.GroupProductId,
						SUM(CASE WHEN ad.DeductionId = 10 THEN ad.Amount ELSE 0 END) AS PlatFormFee,
						SUM(CASE WHEN ad.DeductionId = 11 THEN ad.Amount ELSE 0 END) AS OperationalFee,
						SUM(CASE WHEN ad.DeductionId = 13 THEN ad.Amount ELSE 0 END) AS DepositFee,
						SUM(CASE WHEN ad.DeductionId = 14 THEN ad.Amount ELSE 0 END) AS WithdrawalFee
					FROM @MonthDate md
						CROSS APPLY dbo.rptAffDeduction ad WITH (NOLOCK)
					WHERE md.MonthDate = ad.MonthDate
					GROUP BY
						ad.MonthDate,
						ad.AffId,
						ad.GroupProductId
				) AS pf
				GROUP BY
					MonthDate,
					AffId
			)
			UPDATE d
			SET d.PlatFormFee		= f.PlatFormFee,
				d.OperationalFee	= f.OperationalFee,
				d.DepositFee		= f.DepositFee,
				d.WithdrawalFee		= f.WithdrawalFee
			FROM #AffCommission d
				INNER JOIN CTE_Fees f ON d.MonthDate = f.MonthDate AND d.AffId = f.AffId
			WHERE d.ProductId = 0
		END
		ELSE
		BEGIN
			WITH CTE_MonthDate AS
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @tempFromMonth) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempToMonth
			)
			INSERT INTO @MonthDate (MonthDate, AffId)
			SELECT MonthDate, val AS AffId FROM CTE_MonthDate CROSS JOIN dbo.Aff_f_StringSplit(@AffIds, ',') f
			OPTION (MAXRECURSION 0)

			INSERT INTO #AffCommission
			(
				MonthDate,AffId,GroupId,ProductId,Deposit,Withdrawal,Bonus,Rebate,Turnover,Winloss,
				GrossWinloss,NetWinloss,ActivePlayer,QualifiedMember,QMTurnover,CommissionRate,Commission,SubAffCommission
			)
			SELECT
				dt.MonthDate,dt.AffId,dt.GroupId,dt.ProductId,dt.Deposit,dt.Withdrawal,dt.Bonus,dt.Rebate,dt.Turnover,dt.Winloss,
				dt.GrossWinloss,dt.NetWinloss,dt.ActivePlayer,dt.QualifiedMember,dt.QMTurnover,dt.CommissionRate,0,0
			FROM @MonthDate md
				CROSS APPLY (
					SELECT
						MonthDate,AffId,GroupId,ProductId,Deposit,Withdrawal,Bonus,ISNULL(Rebate, 0) AS Rebate,Turnover,Winloss,
						GrossWinloss,NetWinloss,ActivePlayer,QualifiedMember,QMTurnover,CommissionRate
					FROM dbo.rptAffCommission ac WITH (NOLOCK)
					WHERE ac.MonthDate = md.MonthDate
						AND ac.AffId = md.AffId
				) AS dt

			UPDATE d
			SET d.Commission		= ISNULL(at.Commission, 0)
				,d.SubAffCommission = ISNULL(at.SubAffCommission, 0)
			FROM #AffCommission d
				CROSS APPLY (
					SELECT
						SUM(CASE WHEN at.TransType = 201 THEN at.Amount ELSE 0 END) AS Commission
						,SUM(CASE WHEN at.TransType = 204 THEN at.Amount ELSE 0 END) AS SubAffCommission
					FROM dbo.AffTrans at WITH (NOLOCK)
					WHERE d.MonthDate = at.TransDate
						AND d.AffId = at.AffId
						AND at.TransType IN (201, 204)
				) at
			WHERE d.ProductId = 0
			
			UPDATE d
			SET d.PlatFormFee	= ad.Amount
			FROM #AffCommission d
				INNER JOIN dbo.rptAffDeduction ad WITH (NOLOCK) ON d.MonthDate = ad.MonthDate AND d.AffId = ad.AffId AND d.ProductId = ad.ProductId
			WHERE ad.DeductionId = 10 AND d.ProductId > 0

			;WITH CTE_Fees AS
			(
				SELECT
					MonthDate,
					AffId,
					SUM(ABS(PlatFormFee))	AS PlatFormFee,
					SUM(OperationalFee)		AS OperationalFee,
					SUM(DepositFee)			AS DepositFee,
					SUM(WithdrawalFee)		AS WithdrawalFee
				FROM
				(
					SELECT
						ad.MonthDate,
						ad.AffId,
						ad.GroupProductId,
						SUM(CASE WHEN ad.DeductionId = 10 THEN ad.Amount ELSE 0 END) AS PlatFormFee,
						SUM(CASE WHEN ad.DeductionId = 11 THEN ad.Amount ELSE 0 END) AS OperationalFee,
						SUM(CASE WHEN ad.DeductionId = 13 THEN ad.Amount ELSE 0 END) AS DepositFee,
						SUM(CASE WHEN ad.DeductionId = 14 THEN ad.Amount ELSE 0 END) AS WithdrawalFee
					FROM @MonthDate md
						CROSS APPLY dbo.rptAffDeduction ad WITH (NOLOCK)
					WHERE md.MonthDate = ad.MonthDate AND md.AffId = ad.AffId
					GROUP BY
						ad.MonthDate,
						ad.AffId,
						ad.GroupProductId
				) AS pf
				GROUP BY
					MonthDate,
					AffId
			)
			UPDATE d
			SET d.PlatFormFee		= f.PlatFormFee,
				d.OperationalFee	= f.OperationalFee,
				d.DepositFee		= f.DepositFee,
				d.WithdrawalFee		= f.WithdrawalFee
			FROM #AffCommission d
				INNER JOIN CTE_Fees f ON d.MonthDate = f.MonthDate AND d.AffId = f.AffId
			WHERE d.ProductId = 0
		END
	END

	DECLARE @AffCurrency INT
	SELECT  @AffCurrency = dbo.Aff_f_GetSetting('AffCurrency')

	IF @BaseCurrency <> 0 AND @BaseCurrency <> @AffCurrency
	BEGIN
		UPDATE c
		SET c.Deposit			= c.Deposit * e.Rate,
			c.Withdrawal		= c.Withdrawal * e.Rate,
			c.Bonus				= c.Bonus * e.Rate,
			c.Rebate			= c.Rebate * e.Rate,
			c.Turnover			= c.Turnover * e.Rate,
			c.Winloss			= c.Winloss * e.Rate,
			c.PlatFormFee		= c.PlatFormFee * e.Rate,
			c.OperationalFee	= c.OperationalFee * e.Rate,
			c.DepositFee		= c.DepositFee * e.Rate,
			c.WithdrawalFee		= c.WithdrawalFee * e.Rate,
			c.GrossWinloss		= c.GrossWinloss * e.Rate,
			c.NetWinloss		= c.NetWinloss * e.Rate,
			c.Commission		= c.Commission * e.Rate,
			c.SubAffCommission	= c.SubAffCommission * e.Rate
		FROM #AffCommission c
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(c.MonthDate, @AffCurrency, @BaseCurrency) e
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
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0)) AS MonthDate,
			AffId,
			GroupId,
			ProductId,
			SUM(Deposit)	AS Deposit,
			SUM(Withdrawal) AS Withdrawal,
			SUM(Bonus)		AS Bonus,
			SUM(Rebate)		AS Rebate,
			SUM(Turnover)	AS Turnover,
			SUM(Winloss)	AS Winloss,
			SUM(ISNULL(PlatFormFee, 0))		AS PlatFormFee,
			SUM(ISNULL(OperationalFee, 0))	AS OperationalFee,
			SUM(ISNULL(DepositFee, 0))		AS DepositFee,
			SUM(ISNULL(WithdrawalFee, 0))	AS WithdrawalFee,
			SUM(GrossWinloss)		AS GrossWinloss,
			SUM(NetWinloss)			AS NetWinloss,
			SUM(ActivePlayer)		AS ActivePlayer,
			SUM(QualifiedMember)	AS QualifiedMember,
			SUM(QMTurnOver)			AS QMTurnOver,
			SUM(CommissionRate)		AS CommissionRate,
			SUM(Commission)			AS Commission,
			SUM(SubAffCommission)	AS SubAffCommission
		FROM #AffCommission
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
			ISNULL(PlatFormFee, 0)		AS PlatFormFee,
			ISNULL(OperationalFee, 0)	AS OperationalFee,
			ISNULL(DepositFee, 0)		AS DepositFee,
			ISNULL(WithdrawalFee, 0)	AS WithdrawalFee,
			GrossWinloss,
			NetWinloss,
			ActivePlayer,
			QualifiedMember,
			QMTurnOver,
			CommissionRate,
			Commission,
			SubAffCommission
		FROM #AffCommission
	END

	DROP TABLE #AffCommission
END
GO