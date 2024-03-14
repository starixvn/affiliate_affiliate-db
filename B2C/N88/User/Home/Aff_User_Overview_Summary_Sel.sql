/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Overview_Summary_Sel]
	@AffId			INT
	,@MonthDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Home - Account Overview - Summary

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201109@Percy: Change way to get FDM [RedmineID: #145020]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
		- 20210714@Percy: Include P2P Earning into Monthly Earning [RedmineID: #157958]
		- 20220307@Malcolm: Revenue Share Calculation Enhancement [RedmineId: #167335]
*/

BEGIN
	SET NOCOUNT ON

	-- date range for get data whole month of @MonthDate
	DECLARE @BeginOfMonth SMALLDATETIME, @EndOfMonth SMALLDATETIME
	SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @EndOfMonth		= DATEADD(DAY, -1, DATEADD(MONTH, 1, @BeginOfMonth))

	-- Total Signup/Deposited Members
	BEGIN
		DECLARE @Signups INT, @DepositedMembers INT
		
		SELECT  @Signups = COUNT(CASE WHEN RegisteredDate >= @BeginOfMonth AND RegisteredDate < DATEADD(DAY, 1, @EndOfMonth) THEN 1 ELSE NULL END)
				,@DepositedMembers = COUNT(CASE WHEN FirstDepositDate >= @BeginOfMonth AND FirstDepositDate < DATEADD(DAY, 1, @EndOfMonth) THEN 1 ELSE NULL END)
		FROM dbo.MemberInfo WITH (NOLOCK)
		WHERE AffId = @AffId
	END

	-- Balance Brought Forward
	BEGIN
		DECLARE @BBF MONEY
		SELECT  @BBF = SUM(Amount)
		FROM dbo.AffTrans WITH (NOLOCK)
		WHERE AffId = @AffId
			AND TransDate < DATEADD(DAY, 1, @EndOfMonth)
			AND Status IN ('Pending', 'Approved', 'Completed')
	END

	-- Active Players, Turnover, Deposit, Commission
	BEGIN
		DECLARE @NoOfSubAff INT, @ActivePlayers INT, @Turnover MONEY, @Deposit MONEY, @Commission MONEY, @SubAffCommission MONEY

		SELECT @NoOfSubAff = COUNT(1)
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE ParentAffId = @AffId
			AND Status = 'Approved'
			AND IsClosed = 0
			AND ApprovedDate >= @BeginOfMonth AND ApprovedDate < DATEADD(DAY, 1, @EndOfMonth)

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
			IsMultiGroupProduct BIT 
		)

		DECLARE @MaxCommDate SMALLDATETIME, @AffIds VARCHAR(MAX)
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

		IF @BeginOfMonth > @MaxCommDate
		BEGIN
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
				@FromMonthDate		= @BeginOfMonth,
				@ToMonthDate		= @BeginOfMonth,
				@ProductIds			= '0',
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END
		ELSE
		BEGIN
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
				@FromMonthDate		= @BeginOfMonth,
				@ToMonthDate		= @BeginOfMonth,
				@ProductIds			= '0',
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END

		SELECT
			@ActivePlayers		= SUM(ISNULL(ActivePlayer, 0))
			,@Turnover			= SUM(ISNULL(Turnover, 0))
			,@Deposit			= SUM(ISNULL(Deposit, 0))
			,@Commission		= SUM(ISNULL(Commission, 0) + ISNULL(StraightCommission, 0))
			,@SubAffCommission	= SUM(ISNULL(SubAffCommission, 0))
		FROM #TempCommission

		DROP TABLE #TempCommission
	END

	-- Return result
	BEGIN
		SELECT
			ISNULL(@Signups, 0)				AS Signups
			,ISNULL(@DepositedMembers, 0)	AS DepositedMembers
			,ISNULL(@BBF, 0)				AS BalanceBroughtForward
			,ISNULL(@ActivePlayers, 0)		AS ActivePlayers
			,ISNULL(@Turnover, 0)			AS Turnover
			,ISNULL(@Deposit, 0)			AS Deposit
			,ISNULL(@Commission, 0)			AS Commission
			,ISNULL(@NoOfSubAff, 0)			AS NoOfSubAff
			,ISNULL(@SubAffCommission, 0)	AS SubAffCommission
	END
END
GO