/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE  PROCEDURE [dbo].[Aff_User_Overview_Summary_Sel]
	@AffId			INT
	,@MonthDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Account Overview - Summary

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241226@Sally: Apply QM Turnover [RedmineID: #212201]
		- 20250313@Sally: Missing data on total FDM's Deposit by month [RedmineID: #219974]
		- 20250313@Sally: Get Rate for  FDM's Deposit [RedmineID: #219974]
		- 20250416@Sally: Change the data retrieval method for Deposit [RedmineID: #224116]
		- 20250401@Sally: Enhance get BBF by TimeZone [RedmineID: #222352]
*/

BEGIN
	SET NOCOUNT ON
	
	-- date range for get data whole month of @MonthDate
	DECLARE @BeginOfMonth SMALLDATETIME, @EndOfMonth SMALLDATETIME
	SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @EndOfMonth		= DATEADD(DAY, -1, DATEADD(MONTH, 1, @BeginOfMonth))

	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	-- Total Signup/Deposited Members
	BEGIN
		DECLARE @Signups INT, @DepositedMembers INT, @FDMDeposit MONEY
		
		SELECT  @Signups		   = COUNT(CASE WHEN RegisteredDate >= @BeginOfMonth AND RegisteredDate < DATEADD(DAY, 1, @EndOfMonth) THEN 1 ELSE NULL END)
				,@DepositedMembers = COUNT(CASE WHEN FirstDepositDate >= @BeginOfMonth AND FirstDepositDate < DATEADD(DAY, 1, @EndOfMonth) THEN 1 ELSE NULL END)			
		FROM dbo.MemberInfo m WITH (NOLOCK)
		WHERE AffId = @AffId

		SELECT @FDMDeposit = SUM(ISNULL(FirstDepositAmount,0) * e.Rate)
		FROM dbo.MemberInfo r WITH (NOLOCK)
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel (r.FirstDepositDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
		WHERE AffId = @AffId
			AND FirstDepositDate >= @BeginOfMonth 
			AND FirstDepositDate < DATEADD(DAY, 1, @EndOfMonth)
	END

	-- Total Deposit
	BEGIN
		DECLARE @Deposit MONEY
		SELECT @Deposit =SUM(ISNULL(Deposit, 0) * e.Rate)	   
		FROM dbo.rptMemberDaily r WITH (NOLOCK)
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.WinlostDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
		WHERE r.WinlostDate >= @BeginOfMonth 
			AND r.WinlostDate < DATEADD(DAY, 1, @EndOfMonth)
			AND r.AffId = @AffId
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
				WHERE mr.CustId = r.custid AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
			)	
	END

	-- Balance Brought Forward
	BEGIN
		DECLARE @BBF MONEY
		SELECT  @BBF = SUM(Amount)
		FROM dbo.AffTrans WITH (NOLOCK)
		WHERE AffId = @AffId
			AND WinlostDate < DATEADD(DAY, 1, @EndOfMonth)
			AND Status IN ('Pending', 'Approved', 'Completed')
	END

	-- Active Players, Turnover, Deposit, Commission, QualifiedMember
	BEGIN
		DECLARE @NoOfSubAff INT, @ActivePlayers INT, @QualifiedMember INT, @Turnover MONEY, @Commission MONEY, @SubAffCommission MONEY

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
			NetTurnover			MONEY,
			ActivePlayer		INT,
			QualifiedMember     INT,
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
				NetTurnover,
				ActivePlayer,
				QualifiedMember,
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
				NetTurnover,
				ActivePlayer,
				QualifiedMember,
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
			,@QualifiedMember	= SUM(ISNULL(QualifiedMember, 0))
			,@Turnover			= SUM(ISNULL(Turnover, 0))
			,@Commission		= SUM(ISNULL(Commission, 0))
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
			,ISNULL(@QualifiedMember, 0)	AS QualifiedMember
			,ISNULL(@Turnover, 0)			AS Turnover
			,ISNULL(@Deposit, 0)			AS Deposit
			,ISNULL(@Commission, 0)			AS Commission
			,ISNULL(@NoOfSubAff, 0)			AS NoOfSubAff
			,ISNULL(@SubAffCommission, 0)	AS SubAffCommission
			,ISNULL(@FDMDeposit, 0)			AS FDMDeposit
	END
END
GO