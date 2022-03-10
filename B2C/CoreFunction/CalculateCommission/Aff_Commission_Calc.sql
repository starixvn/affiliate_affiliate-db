/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_Commission_Calc]
	@AffIds				VARCHAR(MAX) = 'all'
	,@FromMonthDate		SMALLDATETIME
	,@ToMonthDate		SMALLDATETIME
	,@ProductIds		VARCHAR(MAX) = '0'
	,@BaseCurrency		INT = 0
	,@IsSumAll			BIT = 0
	,@GetRowTotalOnly	BIT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core SP - Calculate commission for months which are calculated

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210317@Percy: Change ExchangeOanda [RedmineID: #151391]
		- 20210714@Percy: Calculate P2P Fee [RedmineID: #157958]
		- 20210916@Percy: Use Exchange function [RedmineID: #161540]
		- 20220307@Malcolm: Revenue Share Calculation Enhancement [RedmineId: #167335]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tempFromMonth SMALLDATETIME, @tempToMonth SMALLDATETIME
	SELECT  @tempFromMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0))
	SELECT  @tempToMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0))

	DECLARE @BeginOfFromMonthDate SMALLDATETIME, @EndOfToMonthDate SMALLDATETIME
	SELECT  @BeginOfFromMonthDate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate), 0) -- First day of @FromMonthDate
	SELECT  @EndOfToMonthDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0)) -- Last day of @ToMonthDate

	-- AffCurrency
	DECLARE @AffCurrency INT
	SELECT  @AffCurrency = dbo.Aff_f_GetSetting('AffCurrency')

	IF @BaseCurrency = 0
		SET @BaseCurrency = @AffCurrency

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME)
	
	;WITH CTE_MonthDate AS
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

	CREATE TABLE #ExchangeOanda (MonthDate SMALLDATETIME, Rate FLOAT)
	INSERT INTO #ExchangeOanda (MonthDate, Rate)
	SELECT m.MonthDate, e.Rate
	FROM @MonthDate m
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(m.MonthDate, @AffCurrency, @BaseCurrency) e

	CREATE TABLE #Commission
	(
		MonthDate			SMALLDATETIME,
		AffId				INT,
		GroupId				INT,
		ProductId			INT,
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
		IsMultiGroupProduct TINYINT DEFAULT (0)
	)

	BEGIN
		-- By Product
		INSERT INTO #Commission (MonthDate, AffId, GroupId, ProductId, Turnover, Winloss, Revenue)
		SELECT r.MonthDate, r.AffId, r.GroupId, r.ProductId, r.Turnover, r.Winloss, r.Revenue
		FROM @MonthDate md
			CROSS APPLY (
				SELECT r.MonthDate, r.AffId, r.GroupId, r.ProductId, r.Turnover, r.Winloss, r.Revenue
				FROM dbo.rptAffMonthly r WITH (NOLOCK)
				WHERE r.MonthDate = md.MonthDate
					AND (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), r.AffId) + ',%')
			) r
		
		-- Total
		INSERT INTO #Commission (
			MonthDate, AffId, GroupId, ProductId, Deposit, Withdrawal, Bonus, Rebate, Turnover, Winloss, Revenue
			,P2PFee, PlatFormFee, OperationalFee, DepositFee, WithdrawalFee, GrossWinloss, NetWinloss, ActivePlayer, CommissionRate
		)
		SELECT
			r.MonthDate, r.AffId, r.GroupId, 0 AS ProductId, r.Deposit, r.Withdrawal, r.Bonus, r.Rebate, r.Turnover, r.Winloss, r.Revenue
			,r.P2PFee, r.PlatFormFee, r.OperationalFee, r.DepositFee, r.WithdrawalFee, r.GrossWinloss, r.NetWinloss, r.ActivePlayer, r.CommissionRate
		FROM @MonthDate md
			CROSS APPLY (
				SELECT
					r.MonthDate
					,r.AffId
					,r.GroupId
					,SUM(r.Deposit)			AS Deposit
					,SUM(r.Withdrawal)		AS Withdrawal
					,SUM(r.Bonus)			AS Bonus
					,SUM(r.Rebate)			AS Rebate
					,SUM(r.Turnover)		AS Turnover
					,SUM(r.Winloss)			AS Winloss
					,SUM(r.Revenue)			AS Revenue
					,SUM(r.P2PFee)			AS P2PFee
					,SUM(r.PlatFormFee)		AS PlatFormFee
					,SUM(r.OperationalFee)	AS OperationalFee
					,SUM(r.DepositFee)		AS DepositFee
					,SUM(r.WithdrawalFee)	AS WithdrawalFee
					,SUM(r.GrossWinloss)	AS GrossWinloss
					,SUM(r.NetWinloss)		AS NetWinloss
					,SUM(r.ActivePlayer)	AS ActivePlayer
					,SUM(CASE WHEN r.GroupProductId IN (0, 1) THEN r.CommissionRate ELSE 0 END)	AS CommissionRate
				FROM dbo.rptAffCommission r WITH (NOLOCK)
				WHERE r.MonthDate = md.MonthDate
					AND (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), r.AffId) + ',%')
				GROUP BY r.MonthDate, r.AffId, r.GroupId
			) r

		-- Total: Commission
		UPDATE d
		SET d.Commission			= ISNULL(at.Commission, 0)
			,d.StraightCommission	= ISNULL(at.StraightCommission, 0)
			,d.SubAffCommission		= ISNULL(at.SubAffCommission, 0)
		FROM #Commission d
			CROSS APPLY (
				SELECT
					SUM(CASE WHEN at.TransType = 201 THEN at.Amount ELSE 0 END) AS Commission
					,SUM(CASE WHEN at.TransType = 204 THEN at.Amount ELSE 0 END) AS SubAffCommission
					,SUM(CASE WHEN at.TransType = 205 THEN at.Amount ELSE 0 END) AS StraightCommission
				FROM dbo.AffTrans at WITH (NOLOCK)
				WHERE d.MonthDate = at.TransDate
					AND d.AffId = at.AffId
					AND at.TransType IN (201, 204, 205)
			) at
		WHERE d.ProductId = 0
	END
	
	-- Base Currency
	BEGIN
		UPDATE c
		SET c.Deposit			= c.Deposit * e.Rate,
			c.Withdrawal		= c.Withdrawal * e.Rate,
			c.Bonus				= c.Bonus * e.Rate,
			c.Rebate			= c.Rebate * e.Rate,
			c.Turnover			= c.Turnover * e.Rate,
			c.Winloss			= c.Winloss * e.Rate,
			c.Revenue			= c.Revenue * e.Rate,
			c.P2PFee			= c.P2PFee * e.Rate,
			c.PlatFormFee		= c.PlatFormFee * e.Rate,
			c.OperationalFee	= c.OperationalFee * e.Rate,
			c.DepositFee		= c.DepositFee * e.Rate,
			c.WithdrawalFee		= c.WithdrawalFee * e.Rate,
			c.GrossWinloss		= c.GrossWinloss * e.Rate,
			c.NetWinloss		= c.NetWinloss * e.Rate,
			c.Commission		= c.Commission * e.Rate,
			c.StraightCommission= c.StraightCommission * e.Rate,
			c.SubAffCommission	= c.SubAffCommission * e.Rate
		FROM #Commission c
			INNER JOIN #ExchangeOanda e ON c.MonthDate = e.MonthDate
	END

	-- Filter by Products
	IF @ProductIds <> '0'
	BEGIN
		IF @ProductIds = ''
		BEGIN
			DELETE #Commission WHERE ProductId <> 0
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

	-- Update Multi Group Products
	UPDATE c
		SET c.IsMultiGroupProduct = CASE WHEN ISNULL(l.NoGroupProduct, 0) > 1 THEN 1 ELSE 0 END
	FROM #Commission c
		OUTER APPLY (SELECT COUNT(DISTINCT tsh.GroupProductId) AS NoGroupProduct FROM dbo.TierSettingHistory tsh WITH(NOLOCK) WHERE tsh.MonthDate = c.MonthDate AND tsh.GroupId = c.GroupId) AS l
	WHERE c.ProductId = 0

	-- Return data
	IF @IsSumAll = 1
	BEGIN
		SELECT
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0)) AS MonthDate,
			AffId,
			GroupId,
			ProductId,
			SUM(Deposit)			AS Deposit,
			SUM(Withdrawal)			AS Withdrawal,
			SUM(Bonus)				AS Bonus,
			SUM(Rebate)				AS Rebate,
			SUM(Turnover)			AS Turnover,
			SUM(Winloss)			AS Winloss,
			SUM(Revenue)			AS Revenue,
			SUM(P2PFee)				AS P2PFee,
			SUM(PlatFormFee)		AS PlatFormFee,
			SUM(OperationalFee)		AS OperationalFee,
			SUM(DepositFee)			AS DepositFee,
			SUM(WithdrawalFee)		AS WithdrawalFee,
			SUM(GrossWinloss)		AS GrossWinloss,
			SUM(NetWinloss)			AS NetWinloss,
			SUM(ActivePlayer)		AS ActivePlayer,
			SUM(CommissionRate)		AS CommissionRate,
			SUM(Commission)			AS Commission,
			SUM(StraightCommission)	AS StraightCommission,
			SUM(SubAffCommission)	AS SubAffCommission,
			MAX(IsMultiGroupProduct)AS IsMultiGroupProduct
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

	DROP TABLE #Commission
	DROP TABLE #ExchangeOanda
END
GO