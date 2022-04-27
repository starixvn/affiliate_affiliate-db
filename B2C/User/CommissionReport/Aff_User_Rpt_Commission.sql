/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Rpt_Commission]
	@AffId			INT
	,@Winlostdate	SMALLDATETIME
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Commission Report

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
		- 20210714@Percy: Add column P2P Earning & Treat TO, WL = 0 for P2P Products [RedmineID: #157958]
		- 20210916@Percy: Change WL to GGR [RedmineID: #161540]
		- 20220307@Malcolm: Revenue Share Calculation Enhancement [RedmineId: #167335]
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
	SELECT
		d.MonthDate,
		d.ProductId,
		p.ProductName,
		d.Turnover,
		-d.Winloss + d.Revenue AS GGR,
		d.P2PFee + d.PlatformFee AS PlatformFee,
		d.OperationalFee,
		d.DepositFee,
		d.WithdrawalFee,
		d.Bonus,
		d.Rebate,
		d.CommissionRate,
		d.IsMultiGroupProduct,
		d.Commission,
		d.StraightCommission AS P2PCommission,
		d.SubAffCommission,
		d.CalculatedType
	FROM #TempCommission d
		LEFT JOIN dbo.Products p WITH (NOLOCK) ON d.ProductId = p.ProductId
	ORDER BY
		MonthDate DESC,
		d.ProductId ASC
	
	DROP TABLE #TempCommission
END
GO