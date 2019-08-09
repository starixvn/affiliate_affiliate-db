/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_Rpt_Commission]
	@AffId			INT,
	@Winlostdate	SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: User site - Commission Report

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT
	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

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
	SELECT  @CutOffDate		= CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'
	SELECT  @FromDate		= MAX(FromDate) FROM (VALUES (@FromDate), (@MinReportDate), (DATEADD(DAY, 1, @CutOffDate))) AS f (FromDate)

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
			MonthDate				SMALLDATETIME,
			AffId					INT,
			GroupId					INT,
			ProductId				INT,
			Deposit					MONEY,
			Withdrawal				MONEY,
			Bonus					MONEY,
			Turnover				MONEY,
			Winloss					MONEY,
			AWinloss				MONEY,
			AComm					MONEY,
			-- Fees
			PlatFormFee				MONEY,
			OperationalFee			MONEY,
			BankingFee				MONEY,
			ExchangeWinlossShare	MONEY,
			ExchangeCommShare		MONEY,
			-- Calculation
			GrossWinloss			MONEY,
			NetWinloss				MONEY,
			ActivePlayer			INT,
			QualifiedMember			INT,
			QMTurnover				MONEY,
			CommissionRate			FLOAT,
			Commission				MONEY,
			-- for monthdate -- 0: temporary, 1: uncalculated, 2: calculated
			CalculatedType	TINYINT DEFAULT ((2))
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
				Turnover,
				Winloss,
				AWinloss,
				AComm,
				PlatFormFee,
				OperationalFee,
				BankingFee,
				ExchangeWinlossShare,
				ExchangeCommShare,
				GrossWinloss,
				NetWinloss,
				ActivePlayer,
				QualifiedMember,
				QMTurnOver,
				CommissionRate,
				Commission
			)
			EXEC dbo.Aff_Commission_UnCalc
				@AffIds				= @AffIds,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= '0',
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
				Turnover,
				Winloss,
				AWinloss,
				AComm,
				PlatFormFee,
				OperationalFee,
				BankingFee,
				ExchangeWinlossShare,
				ExchangeCommShare,
				GrossWinloss,
				NetWinloss,
				ActivePlayer,
				QualifiedMember,
				QMTurnOver,
				CommissionRate,
				Commission
			)
			EXEC dbo.Aff_Commission_Calc
				@AffIds				= @AffIds,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= '0',
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
		-d.Winloss AS Winloss, -- Gross Winloss = - Member Winloss
		d.PlatformFee,
		d.OperationalFee,
		d.BankingFee,
		d.Bonus,
		d.CommissionRate,
		d.Commission,
		d.CalculatedType
	FROM #TempCommission d
		LEFT JOIN dbo.Products p WITH (NOLOCK) ON d.ProductId = p.ProductId
	ORDER BY
		MonthDate DESC,
		d.ProductId ASC
	
	DROP TABLE #TempCommission
END
GO