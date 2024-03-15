/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap,wsv_alp,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Rpt_Commission]
	@AffId			INT
	,@Winlostdate	SMALLDATETIME
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User site - Commission Report

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
		- 20240222@Sally: Merge VS 1,2,3 into VS only [RedmineID: #199895]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @CurrentDate SMALLDATETIME
	SELECT  @CurrentDate = CONVERT(DATE, GETDATE())

	-- whole year of @Winlostdate
	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME
	SELECT  @FromDate	= DATEADD(YEAR, DATEDIFF(YEAR, 0, @Winlostdate), 0),
			@ToDate		= DATEADD(DAY, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, @Winlostdate) + 1, 0))

	IF @ToDate > @CurrentDate
		SELECT @ToDate = @CurrentDate

	DECLARE @MinReportDate SMALLDATETIME, @CutOffDate SMALLDATETIME
	SELECT  @MinReportDate	= dbo.Aff_f_GetMinReportDate(@AffId)

	IF @FromDate < @MinReportDate 
		SELECT @FromDate = @MinReportDate

	IF @FromDate > @ToDate
		RETURN

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

	-- Get data win loss
	BEGIN
		DECLARE @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

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
			ActivePlayer		INT,
			CommissionRate		FLOAT,
			Commission			MONEY,
			StraightCommission	MONEY,
			SubAffCommission	MONEY,
			IsMultiGroupProduct BIT,
			-- for monthdate -- 0: temporary, 1: uncalculated, 2: calculated
			CalculatedType		TINYINT DEFAULT ((2))
		)

		-- Uncalculated Months
		IF @ToDate > @MaxCommDate
		BEGIN
			SELECT	@tempFromDate	= CASE WHEN @FromDate <= @MaxCommDate THEN DATEADD(DAY, 1, @MaxCommDate) ELSE @FromDate END,
					@tempToDate		= @ToDate

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
				ActivePlayer,
				CommissionRate,
				Commission,
				StraightCommission,
				SubAffCommission,
				IsMultiGroupProduct
			)
			EXEC dbo.Aff_Commission_UnCalc
				@AffIds				= @AffIds,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= '0',
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 0,
				@GetRowTotalOnly	= 0

			UPDATE #TempCommission
			SET CalculatedType = CASE WHEN DATEDIFF(MONTH, @CurrentDate, MonthDate) = 0 THEN 0 ELSE 1 END
		END

		-- Calculated Months
		IF @FromDate <= @MaxCommDate
		BEGIN
			SELECT	@tempFromDate	= @FromDate,
					@tempToDate		= CASE WHEN @ToDate > @MaxCommDate THEN @MaxCommDate ELSE @ToDate END

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
				ActivePlayer,
				CommissionRate,
				Commission,
				StraightCommission,
				SubAffCommission,
				IsMultiGroupProduct
			)
			EXEC dbo.Aff_Commission_Calc
				@AffIds				= @AffIds,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= '0',
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 0,
				@GetRowTotalOnly	= 0
		END
	END

-- Return Data
	;WITH CTE_SubCommRate AS
	(
		SELECT cgh.MonthDate, cgh.SubCommRate
		FROM dbo.AffGroupHistory agh WITH(NOLOCK)
			INNER JOIN dbo.CommGroupHistory cgh WITH(NOLOCK) ON cgh.GroupId = agh.GroupId AND agh.MonthDate = cgh.MonthDate
		WHERE agh.AffId = @AffId AND agh.MonthDate BETWEEN @FromDate AND DATEADD(MONTH, 1, @ToDate)
	),
	CTE_CommResult AS(
		SELECT
			d.MonthDate,
			ISNULL(t.GroupProductId,d.ProductId) AS ProductId,
			p.ProductName,
			SUM(d.Turnover) AS Turnover,
			SUM(-d.Winloss + d.Revenue) AS GGR,
			SUM(d.P2PFee + d.PlatformFee) AS PlatformFee,
			SUM(d.OperationalFee) AS OperationalFee,
			SUM(d.DepositFee) AS DepositFee,
			SUM(d.WithdrawalFee) AS WithdrawalFee,
			SUM(d.Bonus) AS Bonus,
			SUM(d.Rebate) AS Rebate,
			d.CommissionRate,
			d.IsMultiGroupProduct,
			SUM(d.Commission) AS Commission,
			SUM(d.StraightCommission) AS P2PCommission,
			SUM(d.SubAffCommission) AS SubAffCommission,
			s.SubCommRate,
			d.CalculatedType
		FROM #TempCommission d
			LEFT JOIN CTE_SubCommRate s ON s.MonthDate = d.MonthDate
			LEFT JOIN [dbo].[Aff_f_GroupProduct]() t ON d.ProductId = t.ProductId
			LEFT JOIN dbo.Products p WITH (NOLOCK) ON  ISNULL(t.GroupProductId,d.ProductId) = p.ProductId
		GROUP BY d.MonthDate,
			ISNULL(t.GroupProductId,d.ProductId),
			p.ProductName,
			d.CommissionRate,
			d.IsMultiGroupProduct,
			s.SubCommRate,
			d.CalculatedType
	)
	SELECT d.MonthDate,
		d.ProductId,
		d.ProductName,
		d.Turnover,
		d.GGR,
		d.PlatformFee,
		d.OperationalFee,
		d.DepositFee,
		d.WithdrawalFee,
		d.Bonus,
		d.Rebate,
		d.CommissionRate,
		d.IsMultiGroupProduct,
		d.Commission,
		d.P2PCommission,
		d.SubAffCommission,
		d.SubCommRate,
		d.CalculatedType
	FROM CTE_CommResult d
	ORDER BY d.MonthDate DESC, d.ProductId ASC

	DROP TABLE #TempCommission
END
GO