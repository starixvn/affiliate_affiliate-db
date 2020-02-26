/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Overview_Summary_Sel]
	@AffId		INT,
	@MonthDate	SMALLDATETIME
AS

/*
	Created: 20191210@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: User site - Home - Account Overview - Summary

	Revisions:
		- 20191210@Percy: Initialize SP [RedmineID: #121971]
*/

BEGIN
	SET NOCOUNT ON

	-- date range for get data whole month of @MonthDate
	DECLARE @FromBeginMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	SELECT  @FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @ToNextMonth	= DATEADD(MONTH, 1, @FromBeginMonth)

	-- Total Signup/Deposited Members
	BEGIN
		DECLARE @Signups INT, @DepositedMembers INT
		
		SELECT  @Signups = COUNT(CASE WHEN RegisteredDate >= @FromBeginMonth AND RegisteredDate < @ToNextMonth THEN 1 ELSE NULL END)
				,@DepositedMembers = COUNT(CASE WHEN CreatedDate >= @FromBeginMonth AND CreatedDate < @ToNextMonth THEN 1 ELSE NULL END)
		FROM dbo.MemberInfo WITH (NOLOCK)
		WHERE AffId = @AffId
	END

	-- Balance Brought Forward
	BEGIN
		DECLARE @BBF MONEY
		SELECT  @BBF = BalBroughtForward FROM dbo.Aff_f_GetBalBroughtForward(@AffId)
	END

	-- Active Players, Qualified Active Players, Turnover, Deposit, Commission
	BEGIN
		DECLARE @ActivePlayers INT, @QualifiedActivePlayers INT, @Turnover MONEY, @Deposit MONEY, @Commission MONEY
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
			-- Fees
			PlatFormFee				MONEY,
			OperationalFee			MONEY,
			BankingFee				MONEY,
			-- Calculation
			GrossWinloss			MONEY,
			NetWinloss				MONEY,
			ActivePlayer			INT,
			QualifiedMember			INT,
			QMTurnover				MONEY,
			CommissionRate			FLOAT,
			Commission				MONEY
		)

		DECLARE @MaxCommDate SMALLDATETIME, @AffIds VARCHAR(MAX)
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

		IF @FromBeginMonth > @MaxCommDate
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
				Turnover,
				Winloss,
				PlatFormFee,
				OperationalFee,
				BankingFee,
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
				@FromMonthDate		= @FromBeginMonth,
				@ToMonthDate		= @FromBeginMonth,
				@ProductIds			= '0',
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
				Turnover,
				Winloss,
				PlatFormFee,
				OperationalFee,
				BankingFee,
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
				@FromMonthDate		= @FromBeginMonth,
				@ToMonthDate		= @FromBeginMonth,
				@ProductIds			= '0',
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END

		SELECT
			@ActivePlayers				= SUM(ISNULL(ActivePlayer, 0))
			,@QualifiedActivePlayers	= SUM(ISNULL(QualifiedMember, 0))
			,@Turnover					= SUM(ISNULL(Turnover, 0))
			,@Deposit					= SUM(ISNULL(Deposit, 0))
			,@Commission				= SUM(ISNULL(Commission, 0))
		FROM #TempCommission

		DROP TABLE #TempCommission
	END

	-- Return result
	BEGIN
		SELECT
			ISNULL(@Signups, 0)					AS Signups
			,ISNULL(@DepositedMembers, 0)		AS DepositedMembers
			,ISNULL(@BBF, 0)					AS BalanceBroughtForward
			,ISNULL(@ActivePlayers, 0)			AS ActivePlayers
			,ISNULL(@QualifiedActivePlayers, 0)	AS QualifiedActivePlayers
			,ISNULL(@Turnover, 0)				AS Turnover
			,ISNULL(@Deposit, 0)				AS Deposit
			,ISNULL(@Commission, 0)				AS Commission
	END
END
