/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_GeneralInfo_Sel]
	@Languages VARCHAR(MAX)
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin site - Home page overview

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20190808@Percy: Add Exchange [RedmineID: #106504]
		- 20200303@Percy: Support multiple sizes and categories on banner [RedmineID: #121974]
		- 20200731@Percy: Change way to input Language [RedmineID: #121975]
		- 20230208@Bobby: Implement Bonus & FDM Setting [RedmineId : #191139]
		- 20230802@Eddie: 'ExchangeWinlossShare' and 'ExchangeCommShare' out of use [RedmineID: #189569]
		- 20231108@Eddie: Remove 'image banners' and 'flash banners' statistics [RedmineID: #181590]
		- 20240325@Eddie: Merge VS2 into Virtual Sports and change metadata "bodbAdminNet" [RedmineID: #201095]
		- 20240611@Eddie: Add new Product VS3&4 and change metadata "wsv_aff" [RedmineId : #206363]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @BeginOfCurrentMonth SMALLDATETIME, @LastOfCurrentMonth SMALLDATETIME
	SELECT	@BeginOfCurrentMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
	SELECT	@LastOfCurrentMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 1, @BeginOfCurrentMonth))

	-- member statistics
	BEGIN
		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

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
		)

		-- Uncalculated Months
		BEGIN
			SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
					@tempToDate		= CONVERT(DATE, GETDATE())

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
				@AffIds				= 'all'
				,@FromMonthDate		= @tempFromDate
				,@ToMonthDate		= @tempToDate
				,@ProductIds		= '0'
				,@IsSumAll			= 0
				,@GetRowTotalOnly	= 1
		END

		-- Calculated Months
		BEGIN
			SELECT	@tempFromDate	= dbo.Aff_f_GetMinReportDate(0),
					@tempToDate		= @MaxCommDate

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
				@AffIds				= 'all'
				,@FromMonthDate		= @tempFromDate
				,@ToMonthDate		= @tempToDate
				,@ProductIds		= '0'
				,@IsSumAll			= 1
				,@GetRowTotalOnly	= 1
		END

		DECLARE @DepositAll MONEY, @WinlostAll MONEY, @BonusAll MONEY, @PSPFeeAll MONEY, @NetWinlostAll MONEY, @DepositMonth MONEY, @WinlostMonth MONEY, @BonusMonth MONEY, @PSPFeeMonth MONEY, @NetWinlostMonth MONEY, @FDMByMonth INT, @FDMDepositMonth MONEY;

		SELECT
			@DepositAll			= SUM(ISNULL(Deposit, 0))
			,@WinlostAll		= SUM(ISNULL(Winloss, 0))
			,@BonusAll			= SUM(ISNULL(Bonus, 0))
			,@PSPFeeAll			= SUM(ISNULL(BankingFee, 0))
			,@NetWinlostAll		= SUM(ISNULL(NetWinloss, 0))
			,@DepositMonth		= SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(Deposit, 0)    ELSE 0 END)
			,@WinlostMonth		= SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(Winloss, 0)    ELSE 0 END)
			,@BonusMonth		= SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(Bonus, 0) 	   ELSE 0 END)
			,@PSPFeeMonth		= SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(BankingFee, 0) ELSE 0 END)
			,@NetWinlostMonth	= SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(NetWinloss, 0) ELSE 0 END)
			,@FDMByMonth		= SUM(FDMCount)
			,@FDMDepositMonth	= SUM(FDMDeposit)
		FROM #TempCommission t
			INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON t.AffId = ad.AffId AND ',' + @Languages + ',' LIKE '%,' + ad.PreferredLanguage + ',%'

		DROP TABLE #TempCommission
	END

	-- deposit members
	BEGIN
		DECLARE @DepositMemAllNum INT, @DepositMemMonthNum INT
		SELECT
			@DepositMemAllNum		= SUM(1)
			,@DepositMemMonthNum	= SUM(CASE WHEN CreatedDate < @BeginOfCurrentMonth THEN 0 ELSE 1 END)
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON mi.AffId = ad.AffId AND ',' + @Languages + ',' LIKE '%,' + ad.PreferredLanguage + ',%'
		WHERE mi.IsRemoved = 0
	END

	-- affiliate
	BEGIN
		DECLARE @AffInProAllNum INT, @PendingAllNum INT, @ApprovedAllNum INT, @DisapprovedAllNum INT, @ClosedAllNum INT, @AffInProMonthNum INT, @PendingMonthNum INT, @ApprovedMonthNum INT, @DisapprovedMonthNum INT, @ClosedMonthNum INT
		SELECT
			-- total
			@AffInProAllNum			= SUM(Total)
			,@PendingAllNum			= SUM(Pending)
			,@ApprovedAllNum		= SUM(Approved)
			,@DisapprovedAllNum		= SUM(Disapproved)
			,@ClosedAllNum			= SUM(Closed)
			-- current month
			,@AffInProMonthNum		= SUM(Total * CurrentMonth)
			,@PendingMonthNum		= SUM(Pending * CurrentMonth)
			,@ApprovedMonthNum		= SUM(Approved * CurrentMonth)
			,@DisapprovedMonthNum	= SUM(Disapproved * CurrentMonth)
			,@ClosedMonthNum		= SUM(Closed * CurrentMonth)
		FROM
		(
			SELECT CASE WHEN RegisteredDate < @BeginOfCurrentMonth THEN 0 ELSE 1 END AS CurrentMonth
				,SUM(1) AS Total
				,SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS Pending
				,SUM(CASE WHEN status = 'Approved' AND IsClosed = 0 THEN 1 ELSE 0 END) AS Approved
				,SUM(CASE WHEN status = 'Disapproved' THEN 1 ELSE 0 END) AS Disapproved
				,SUM(CASE WHEN status = 'Approved' AND IsClosed = 1 THEN 1 ELSE 0 END) AS Closed
			FROM dbo.AffInfo ai WITH (NOLOCK)
				INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId AND ',' + @Languages + ',' LIKE '%,' + ad.PreferredLanguage + ',%'
			GROUP BY CASE WHEN RegisteredDate < @BeginOfCurrentMonth THEN 0 ELSE 1 END
		) AS a
	END

	-- payment requests
	BEGIN
		DECLARE @PaymentReqNum INT
		SELECT @PaymentReqNum = SUM(1)
		FROM dbo.AffTrans at WITH (NOLOCK)
			INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON at.AffId = ad.AffId AND ',' + @Languages + ',' LIKE '%,' + ad.PreferredLanguage + ',%'
		WHERE at.TransType = 202 AND at.Status = 'Pending'
	END

	-- banner statistics
	DECLARE @LanguageNames VARCHAR(MAX)
	SELECT  @LanguageNames = COALESCE(@LanguageNames + ',', '') + MarketName FROM dbo.Market WITH (NOLOCK)
	WHERE ',' + @Languages + ',' LIKE '%,' + MarketId + ',%'
	
	BEGIN
		DECLARE @BannerNum INT

		SELECT @BannerNum = SUM(CASE WHEN ImageType <> 'Text' THEN 1 ELSE 0 END)
		FROM dbo.Banners WITH (NOLOCK)
		WHERE ',' + @LanguageNames + ',' LIKE '%,' + Language + ',%'
	END

	-- return
	SELECT
		-- payment
		@PaymentReqNum			AS PaymentReqNum
		-- banner	
		,@BannerNum				AS BannerNum
		-- all
		,@AffInProAllNum		AS AffInProAllNum
		,@PendingAllNum			AS PendingAllNum
		,@ApprovedAllNum		AS ApprovedAllNum
		,@DisapprovedAllNum		AS DisapprovedAllNum
		,@DepositMemAllNum		AS DepositMemAllNum
		,@ClosedAllNum			AS ClosedAllNum
		,@DepositAll			AS DepositAll
		,@WinlostAll			AS WinlostAll
		,@BonusAll				AS BonusAll
		,@PSPFeeAll				AS PSPFeeAll
		,0						AS AdjustmentAll
		,@NetWinlostAll			AS NetWinlostAll
		-- current month
		,@AffInProMonthNum		AS AffInProMonthNum
		,@PendingMonthNum		AS PendingMonthNum
		,@ApprovedMonthNum		AS ApprovedMonthNum
		,@DisapprovedMonthNum	AS DisapprovedMonthNum
		,@DepositMemMonthNum	AS DepositMemMonthNum
		,@ClosedMonthNum		AS ClosedMonthNum
		,@DepositMonth			AS DepositMonth
		,@WinlostMonth			AS WinlostMonth
		,@BonusMonth			AS BonusMonth
		,@PSPFeeMonth			AS PSPFeeMonth
		,0						AS AdjustmentMonth
		,@NetWinlostMonth		AS NetWinlostMonth
		---FDM  & Bonus
		,@FDMByMonth			AS FDMByMonth
		,@FDMDepositMonth		AS FDMDepositMonth
END
GO