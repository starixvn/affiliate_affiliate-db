/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_MemberDaily_CheckData]
	@Winlostdate	SMALLDATETIME,
	@IsMatch		BIT = 1 OUTPUT
AS

/*
	Created by Percy:
	Date: 2017-10-20
	DB: DBAFF12BET.Affiliate_12BET
	Task: Check data after move bet for MemberDaily

	Revisions:
		- 20171020@Percy: Add new SP [RedmineID: #84602]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE
		-- Bettrans variables
		@BT_Deposit		MONEY,
		@BT_Withdrawal	MONEY,
		@BT_Bonus		MONEY,
		@BT_Adjustment	MONEY,
		@BT_Turnover	MONEY,
		@BT_Winlost		MONEY,
		-- MemberDaily variables
		@MD_Deposit		MONEY,
		@MD_Withdrawal	MONEY,
		@MD_Bonus		MONEY,
		@MD_Adjustment	MONEY,
		@MD_Turnover	MONEY,
		@MD_Winlost		MONEY

	DECLARE @CutDate SMALLDATETIME, @MoveBetsDay SMALLDATETIME, @LastDayOfMonth SMALLDATETIME
	
	SELECT @CutDate = MIN(winlostdate) FROM DBRPT.bodb_report.dbo.rptdepwinlost WITH (NOLOCK)
	SELECT @MoveBetsDay = MAX(eventdate) FROM bodb02.dbo.match14 WITH (NOLOCK)

	DECLARE @DeductionOfCashOut INT = 9

	-- get Member Info
	CREATE TABLE #MemberInfo (IBCCustID INT PRIMARY KEY, AffId INT, CashOutWLShare DECIMAL(9, 8))
	
	INSERT INTO #MemberInfo (IBCCustID, AffId)
	SELECT mi.IBCCustID, mi.AffID
	FROM dbo.MemberInfo mi WITH (NOLOCK)
	WHERE mi.CreatedDate IS NOT NULL
		AND mi.CreatedDate < DATEADD(DAY, 1, @Winlostdate)
		AND (
			mi.IsRemoved = 0
			OR (
				mi.IsRemoved = 1
				AND EXISTS (
					SELECT mr.IBCCustID
					FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mi.IBCCustID = mr.IBCCustID AND DATEDIFF(MM, mr.RemovedDate, @Winlostdate) < 0
				)
			)
		)

	IF DATEADD(MONTH, DATEDIFF(MONTH, 0, @winlostdate), 0) = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) -- current setting
	BEGIN
		UPDATE m
		SET m.CashOutWLShare = ISNULL(c.DeductedPercentage, 0)
		FROM #MemberInfo m
			LEFT JOIN (
				SELECT ai.AffId, ds.DeductedPercentage
				FROM dbo.DeductionSetting ds WITH(NOLOCK)
					INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ds.GroupID = ai.GroupID AND ds.DeductionID = @DeductionOfCashOut
			) AS c ON m.AffID = c.AffID
	END
	ELSE
	BEGIN
		SELECT @LastDayOfMonth = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @winlostdate) + 1, 0))

		UPDATE m
		SET m.CashOutWLShare = ISNULL(c.DeductedPercentage, 0)
		FROM #MemberInfo m
			LEFT JOIN (
				SELECT ai.AffId, ds.DeductedPercentage
				FROM dbo.DeductionSettingHistory ds WITH(NOLOCK)
					INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ds.GroupID = ai.GroupID AND ds.DeductionID = @DeductionOfCashOut AND ds.MonthDate = @LastDayOfMonth
			) AS c ON m.AffID = c.AffID
	END

	-- get data to compare
	-- 1. MemberDaily
	SELECT
		@MD_Deposit		= ISNULL(SUM(Deposit), 0),
		@MD_Withdrawal	= ISNULL(SUM(Withdrawal), 0),
		@MD_Bonus		= ISNULL(SUM(Bonus), 0),
		@MD_Adjustment	= ISNULL(SUM(Adjustment), 0),
		@MD_Turnover	= ISNULL(SUM(Turnover), 0),
		@MD_Winlost		= ISNULL(SUM(Winlost), 0)
	FROM dbo.MemberDaily WITH (NOLOCK)
	WHERE WinlostDate = @Winlostdate
		AND sporttype = 1 -- Sportbook

	-- 2. bettrans or sum table
	IF @Winlostdate > @MoveBetsDay
	BEGIN
		SELECT
			@BT_Deposit		= ISNULL(SUM(CASE WHEN b.bettype = 22001 THEN b.winlost-b.actual_stake ELSE 0 END), 0),
			@BT_Withdrawal	= -ISNULL(SUM(CASE WHEN b.bettype IN (22002, 22003) THEN b.winlost-b.actual_stake ELSE 0 END), 0),
			@BT_Bonus		= ISNULL(SUM(CASE WHEN b.bettype = 22004 THEN b.winlost-b.actual_stake ELSE 0 END), 0),
			@BT_Adjustment	= ISNULL(SUM(CASE WHEN b.bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN b.winlost-b.actual_stake ELSE 0 END), 0),
			@BT_Turnover	= ISNULL(SUM(CASE WHEN b.bettype < 19999 AND b.bettype <> 911 THEN b.stake ELSE 0 END), 0),
			@BT_Winlost		= ISNULL(SUM(CASE WHEN b.bettype < 19999 THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END
									* CASE WHEN b.bettype = 911 THEN m.CashOutWLShare ELSE 1 END), 0)
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #MemberInfo m ON m.IBCCustID = b.custid
		WHERE b.winlostdate = @Winlostdate
			AND (
				(b.bettype <= 999 AND b.bettype NOT BETWEEN 31 AND 120) OR b.bettype BETWEEN 1301 AND 1399 -- Sportbook
				OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005) -- transfer
			) 
			AND b.statusID NOT IN (101, 102, 103, 121, 0, 1)
	END
	ELSE IF @Winlostdate >= @CutDate
	BEGIN
		SELECT
			@BT_Turnover	= ISNULL(SUM(b.turnover), 0),
			@BT_Winlost		= ISNULL(SUM(b.winlost), 0)
		FROM DBRPT.bodb_Report.dbo.rptDepWinlostByProduct b WITH (NOLOCK)
			INNER JOIN #MemberInfo m ON m.IBCCustID = b.custid
		WHERE b.winlostdate = @Winlostdate
			AND b.SportType IN (0, -1) -- Sportbook + Bettrade

		SELECT
			@BT_Winlost		= @BT_Winlost + ISNULL(SUM(b.winlost*m.CashOutWLShare), 0)
		FROM DBRPT.bodb_Report.dbo.rptDepWinlostByProduct b WITH (NOLOCK)
			INNER JOIN #MemberInfo m ON m.IBCCustID = b.custid
		WHERE b.winlostdate = @Winlostdate
			AND b.SportType = -6 -- Cash Out

		SELECT
			@BT_Deposit		= ISNULL(SUM(b.deposit), 0),
			@BT_Withdrawal	= ISNULL(SUM(b.withdrawal), 0),
			@BT_Bonus		= ISNULL(SUM(b.bonus), 0),
			@BT_Adjustment	= ISNULL(SUM(b.Adjustment), 0)
		FROM DBRPT.bodb_Report.dbo.rptDepWinlost b WITH (NOLOCK)
			INNER JOIN #MemberInfo m ON m.IBCCustID = b.custid
		WHERE b.winlostdate = @Winlostdate
	END
	ELSE
	BEGIN
		SELECT
			@BT_Turnover	= ISNULL(SUM(b.turnover), 0),
			@BT_Winlost		= ISNULL(SUM(b.winlost), 0)
		FROM DBRPT.bodb_Report.dbo.rptDepWinlostByProduct_bk b WITH (NOLOCK)
			INNER JOIN #MemberInfo m ON m.IBCCustID = b.custid
		WHERE b.winlostdate = @Winlostdate
			AND b.SportType IN (0, -1) -- Sportbook + Bettrade

		SELECT
			@BT_Winlost		= @BT_Winlost + ISNULL(SUM(b.winlost*m.CashOutWLShare), 0)
		FROM DBRPT.bodb_Report.dbo.rptDepWinlostByProduct_bk b WITH (NOLOCK)
			INNER JOIN #MemberInfo m ON m.IBCCustID = b.custid
		WHERE b.winlostdate = @Winlostdate
			AND b.SportType = -6 -- Cash Out

		SELECT
			@BT_Deposit		= ISNULL(SUM(b.deposit), 0),
			@BT_Withdrawal	= ISNULL(SUM(b.withdrawal), 0),
			@BT_Bonus		= ISNULL(SUM(b.bonus), 0),
			@BT_Adjustment	= ISNULL(SUM(b.Adjustment), 0)
		FROM DBRPT.bodb_Report.dbo.rptDepWinlost_bk b WITH (NOLOCK)
			INNER JOIN #MemberInfo m ON m.IBCCustID = b.custid
		WHERE b.winlostdate = @Winlostdate
	END

	-- Compare data
	IF
	(
			@BT_Deposit		<> @MD_Deposit
		OR	@BT_Withdrawal	<> @MD_Withdrawal
		OR	@BT_Bonus		<> @MD_Bonus
		OR	@BT_Adjustment	<> @MD_Adjustment
		OR	@BT_Turnover	<> @MD_Turnover
		OR	@BT_Winlost		<> @MD_Winlost
	)
	BEGIN
		SELECT @IsMatch = 0
	END
	ELSE
	BEGIN
		SELECT @IsMatch = 1
	END
END
GO