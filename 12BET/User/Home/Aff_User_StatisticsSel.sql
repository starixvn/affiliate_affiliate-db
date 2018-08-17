/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_StatisticsSel]
	@AffId		INT,
	@MonthDate	SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Account Overview - Statistics

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @EndOfMonth SMALLDATETIME
	SELECT  @EndOfMonth = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))
	
	-- date params for get data whole month of @MonthDate
	DECLARE @FromBeginMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	SELECT  @FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @ToNextMonth	= DATEADD(MONTH, 1, @FromBeginMonth)

	IF @ToNextMonth > GETDATE()
		SELECT @ToNextMonth = DATEADD(DAY, 1, CONVERT(DATE, GETDATE()))

	-- Total Players
	DECLARE @TotalPlayers INT
	SELECT  @TotalPlayers = COUNT(1)
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
	WHERE AffiliateID = @AffId

	-- Balance Brought Forward
	DECLARE @BFF MONEY
	SELECT  @BFF = dbo.Aff_GetAffBalance(@AffID)

	-- New Signups
	DECLARE @NewSignups INT
	SELECT  @NewSignups = COUNT(1)
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
	WHERE
		creatdate >= @FromBeginMonth AND creatdate < @ToNextMonth
		AND AffiliateID = @AffID

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME
	
	DECLARE @AffIds VARCHAR(MAX)
	SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

	-- Active Players, Qualified Active Players, Turnover, Deposit
	CREATE TABLE #TotalStatistics
	(
		MonthDate		SMALLDATETIME,
		ActivePlayer	INT,
		QualifiedMember INT,
		Turnover		MONEY,
		Deposit			MONEY
	)

	CREATE TABLE #TempCommission
	(
		MonthDate		SMALLDATETIME,
		AffId			INT,
		GroupId			INT,
		ProductId		INT,
		Deposit			MONEY,
		Withdrawal		MONEY,
		Bonus			MONEY,
		Turnover		MONEY,
		Winloss			MONEY,
		-- Fees
		PlatFormFee		MONEY,
		OperationalFee	MONEY,
		BankingFee		MONEY,
		-- Calculation
		NetWinloss		MONEY,
		ActivePlayer	INT,
		QualifiedMember INT,
		QMTurnover		MONEY,
		CommissionRate	DECIMAL(9,8),
		Commission		MONEY
	)

	-- Calculated months
	SELECT @tempFromDate = DATEADD(DAY, 1, CONVERT(DATE, SValue)) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_OldReportDate'
	SELECT @tempToDate = @MaxCommDate

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
		NetWinloss,
		ActivePlayer,
		QualifiedMember,
		QMTurnOver,
		CommissionRate,
		Commission
	)
	EXEC dbo.Aff_Commission_Calc @AffIds = @AffIds, @FromMonthDate = @tempFromDate, @ToMonthDate = @tempToDate

	-- Uncalculated months
	SELECT  @tempFromDate = DATEADD(DAY, 1, @MaxCommDate),
			@tempToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))
	
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
		NetWinloss,
		ActivePlayer,
		QualifiedMember,
		QMTurnOver,
		CommissionRate,
		Commission
	)
	EXEC dbo.Aff_Commission_UnCalc @AffIds = @AffIds, @FromMonthDate = @tempFromDate, @ToMonthDate = @tempToDate

	INSERT INTO #TotalStatistics
	(
		MonthDate,
		ActivePlayer,
		QualifiedMember,
		Turnover,
		Deposit
	)
	SELECT
		MonthDate,
		SUM(ISNULL(ActivePlayer, 0)),
		SUM(ISNULL(QualifiedMember, 0)),
		SUM(ISNULL(Turnover, 0)),
		SUM(ISNULL(Deposit, 0))
	FROM #TempCommission
	GROUP BY
		MonthDate

	-- Return data
	DECLARE @ActivePlayers INT, @QualifiedMembers INT,
			@Deposit MONEY, @DepositUp MONEY,
			@Turnover MONEY, @TurnoverUp MONEY
	
	SELECT
		@ActivePlayers		= SUM(ISNULL(ActivePlayer, 0)),
		@QualifiedMembers	= SUM(ISNULL(QualifiedMember, 0)),
		@Deposit			= SUM(ISNULL(Deposit, 0)),
		@Turnover			= SUM(ISNULL(Turnover, 0))
	FROM #TotalStatistics
	WHERE MonthDate = @EndOfMonth

	SELECT
		@DepositUp	= SUM(ISNULL(Deposit, 0)),
		@TurnoverUp = SUM(ISNULL(Turnover, 0))
	FROM #TotalStatistics

	SELECT
		-- For month of @MonthDate
		ISNULL(@NewSignups, 0)			AS NewSignups,
		ISNULL(@ActivePlayers, 0)		AS ActivePlayers,
		ISNULL(@QualifiedMembers, 0)	AS QualifiedMembers,
		ISNULL(@Deposit, 0)				AS Deposit,
		ISNULL(@Turnover, 0)			AS Turnover,
		-- Up to now
		ISNULL(@TotalPlayers, 0)		AS TotalPlayers,
		ISNULL(@TurnoverUp, 0)			AS TurnoverUp,
		ISNULL(@DepositUp, 0)			AS DepositUp,
		ISNULL(@BFF, 0)					AS BalanceBroughtForward

	DROP TABLE #TotalStatistics
	DROP TABLE #TempCommission
END
GO