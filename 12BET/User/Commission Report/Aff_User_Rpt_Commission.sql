/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
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
		- 20190808@Percy: Add Exchange [RedmineID: #106504]
		- 20230208@Bobby: Implement Bonus & FDM Setting [RedmineId : #191139]
		- 20230804@Eddie: 'ExchangeWinlossShare' and 'ExchangeCommShare' out of use [RedmineID: #189569]
		- 20240325@Eddie: Merge VS2 into Virtual Sports and change metadata "bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" [RedmineID: #201095]
		- 20240611@Eddie: Add new Product VS3&4 and change metadata "wsv_aff,wsv_affv" [RedmineId : #206363]
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

		DROP TABLE IF EXISTS #TempCommission;
		CREATE TABLE #TempCommission
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
			-- Fees
			,PlatFormFee		MONEY
			,OperationalFee		MONEY
			,BankingFee			MONEY
			-- Calculation
			,GrossWinloss		MONEY
			,NetWinloss			MONEY
			,ActivePlayer		INT
			,QualifiedMember	INT
			,QMTurnover			MONEY
			,CommissionRate		FLOAT
			,Commission			MONEY
			-----FDM & Bonus
			,IsApplyBonus		BIT
			,FDMCount			INT
			,FDMDeposit			MONEY
			,FDMCommissionRate	DECIMAL(9, 8)
			,FDMCommission		MONEY
			-- for monthdate -- 0: temporary, 1: uncalculated, 2: calculated
			,CalculatedType		TINYINT DEFAULT ((2))
		)

		-- Uncalculated Months
		IF @ToDate > @MaxCommDate
		BEGIN
			SELECT	@tempFromDate	= CASE WHEN @FromDate <= @MaxCommDate THEN DATEADD(DAY, 1, @MaxCommDate) ELSE @FromDate END,
					@tempToDate		= @ToDate

			INSERT INTO #TempCommission
			(
				MonthDate
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
				,PlatFormFee
				,OperationalFee
				,BankingFee
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
			)
			EXEC dbo.Aff_Commission_UnCalc
				@AffIds				= @AffIds
				,@FromMonthDate		= @tempFromDate
				,@ToMonthDate		= @tempToDate
				,@ProductIds		= '0'
				,@IsSumAll			= 0
				,@GetRowTotalOnly	= 0

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
				MonthDate
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
				,PlatFormFee
				,OperationalFee
				,BankingFee
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
			)
			EXEC dbo.Aff_Commission_Calc
				@AffIds				= @AffIds
				,@FromMonthDate		= @tempFromDate
				,@ToMonthDate		= @tempToDate
				,@ProductIds		= '0'
				,@IsSumAll			= 0
				,@GetRowTotalOnly	= 0
		END
	END

	-- Return Data
	SELECT
		d.MonthDate
		,d.ProductId
		,p.ProductName
		,d.Turnover
		,d.GrossWinloss AS Winloss
		,d.PlatformFee
		,d.OperationalFee
		,d.BankingFee
		,d.Bonus
		,d.CommissionRate
		,d.Commission
		,ISNULL(d.FDMCommission, 0) AS FDMCommission
		,d.CalculatedType
	FROM #TempCommission d
		LEFT JOIN dbo.Products p WITH (NOLOCK) ON d.ProductId = p.ProductId
	ORDER BY MonthDate DESC, d.ProductId ASC

	DROP TABLE #TempCommission
END
GO