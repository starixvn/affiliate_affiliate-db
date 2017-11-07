/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_MemberDaily]
	@Winlostdate	SMALLDATETIME
AS

/*
	Created by Percy:
	Date: 2017-10-20
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import data for MemberDaily, AffDaily and AffDailySummary

	Revisions:
		- 20171020@Percy: Add new SP [RedmineID: #84602]
*/

BEGIN
	SET NOCOUNT ON

	IF @Winlostdate < '2011-11-01' OR @Winlostdate > GETDATE()
		RETURN

	DECLARE @DayOfLastMonth SMALLDATETIME, @DayOfFirstMonth SMALLDATETIME
	SELECT  @DayOfLastMonth  = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Winlostdate) + 1, 0)),
			@DayOfFirstMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Winlostdate), 0)

	IF EXISTS (
		SELECT TOP 1 WinlostDate FROM dbo.AffCommission WITH (NOLOCK)
		WHERE WinlostDate = @DayOfLastMonth
	)
		RETURN

	DECLARE @CutDate SMALLDATETIME, @MoveBetsDay SMALLDATETIME
	
	SELECT @CutDate = MIN(winlostdate) FROM DBRPT.bodb_Report.dbo.rptDepwinlost WITH (NOLOCK)
	SELECT @MoveBetsDay = MAX(eventdate) FROM bodb02.dbo.match14 WITH (NOLOCK)

	DECLARE @DeductionOfCashOut INT = 9

	DECLARE @SportsBookID INT
	SELECT  @SportsBookID = dbo.Aff_GetSportID('SportsBook')

	CREATE TABLE #TotalMember
	(
		CustId					INT,
		AffId					INT,
		Currency				INT,
		CashOutWLShare			DECIMAL(9, 8),
		isInvalidCreatedDate	BIT,
		isRemoved				BIT
	)

	CREATE TABLE #ValidMember
	(
		CustId		INT
	)

	CREATE TABLE #InvalidMember
	(
		CustId					INT,
		isInvalidCreatedDate	BIT,
		isRemoved				BIT
	)

	INSERT INTO #TotalMember (CustId, AffId, Currency, isInvalidCreatedDate, isRemoved)
	SELECT mi.IBCCustID, mi.AffID, mi.Currency,
		CASE WHEN mi.CreatedDate IS NULL OR DATEDIFF(DD, mi.CreatedDate, @WinlostDate) < 0 THEN 1 ELSE 0 END,
		CASE WHEN mi.IsRemoved = 1 AND DATEDIFF(MM, RemovedDate, @Winlostdate) >= 0 THEN 1 ELSE 0 END
	FROM dbo.MemberInfo mi WITH (NOLOCK)
		LEFT JOIN dbo.MemberRemoval mr WITH (NOLOCK) ON mi.IBCCustID = mr.IBCCustID

	INSERT INTO #ValidMember (CustID)
	SELECT CustID
	FROM #TotalMember
	WHERE isInvalidCreatedDate = 0 AND isRemoved = 0

	INSERT INTO #InvalidMember (CustID, isInvalidCreatedDate, isRemoved)
	SELECT CustID, isInvalidCreatedDate, isRemoved
	FROM #TotalMember
	WHERE isInvalidCreatedDate = 1 OR isRemoved = 1

	IF DATEADD(MONTH, DATEDIFF(MONTH, 0, @winlostdate), 0) = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) -- current setting
	BEGIN
		UPDATE m
		SET m.CashOutWLShare = ISNULL(c.DeductedPercentage, 0)
		FROM #TotalMember m
			LEFT JOIN (
				SELECT ai.AffId, ds.DeductedPercentage
				FROM dbo.DeductionSetting ds WITH (NOLOCK)
					INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ds.GroupID = ai.GroupID AND ds.DeductionID = @DeductionOfCashOut
			) AS c ON m.AffID = c.AffID
	END
	ELSE
	BEGIN
		UPDATE m
		SET m.CashOutWLShare = ISNULL(c.DeductedPercentage, 0)
		FROM #TotalMember m
			LEFT JOIN (
				SELECT ai.AffId, ds.DeductedPercentage
				FROM dbo.DeductionSettingHistory ds WITH (NOLOCK)
					INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ds.GroupID = ai.GroupID AND ds.DeductionID = @DeductionOfCashOut AND ds.MonthDate = @DayOfLastMonth
			) AS c ON m.AffID = c.AffID
	END

	CREATE TABLE #Data
	(
		IBCCustID		INT PRIMARY KEY,
		AffID			INT,
		Currency		INT,
		Deposit			MONEY,
		Withdrawal		MONEY,
		Bonus			MONEY,
		Adjustment		MONEY,
		TurnOver		MONEY,
		Outstanding		MONEY,
		Winlost			MONEY,
		DrawGame		MONEY,
		AffExRate		FLOAT,
		MemberExRate	FLOAT,
		PSP				MONEY,
		Marketing		MONEY,
		OpeningBalance	MONEY,
		ClosingBalance	MONEY
	)

	-- get data --
	IF DATEDIFF(DAY, @Winlostdate, GETDATE()) <= 1 -- yesterday + today
	BEGIN
		INSERT INTO #Data
		(
			IBCCustID,
			AffID,
			Currency,
			Deposit,
			Withdrawal,
			Bonus,
			Adjustment,
			TurnOver,
			DrawGame,
			Outstanding,
			Winlost,
			OpeningBalance,
			ClosingBalance
		)
		SELECT
			b.custid,
			m.AffID,
			b.currency,
			SUM(CASE WHEN b.bettype = 22001 THEN b.winlost-b.actual_stake ELSE 0 END) AS Deposit,
			SUM(CASE WHEN b.bettype IN (22002, 22003) THEN b.winlost-b.actual_stake ELSE 0 END) AS Withdrawal,
			SUM(CASE WHEN b.bettype = 22004 THEN b.winlost-b.actual_stake ELSE 0 END) AS Bonus,
			SUM(CASE WHEN b.bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN b.winlost-b.actual_stake ELSE 0 END) AS Adjustment,
			SUM(CASE WHEN b.bettype < 19999 AND b.bettype <> 911 THEN b.stake ELSE 0 END) AS Turnover,
			SUM(CASE WHEN b.bettype < 19999 AND b.bettype <> 911 AND b.statusID = 111 THEN b.stake ELSE 0 END) AS DrawGame,
			SUM(CASE WHEN b.bettype < 19999 AND b.bettype <> 911 AND b.ruben = 0 THEN b.actual_stake ELSE 0 END) AS Outstanding,
			SUM(CASE WHEN b.bettype < 19999 AND b.ruben = 1 THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END
				* CASE WHEN b.bettype = 911 THEN m.CashOutWLShare ELSE 1 END) AS Winlost,
			0 AS OpeningBalance,
			0 AS ClosingBalance
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #TotalMember m ON m.CustID = b.custid
		WHERE winlostdate = @winlostdate
			AND (
				(bettype <= 999 AND bettype NOT BETWEEN 31 AND 120) OR bettype BETWEEN 1301 AND 1399 -- Sportbook
				OR bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005) -- transfer
			)
			AND StatusID NOT IN (101, 102, 103, 121)
		GROUP BY b.custid, m.AffID, b.currency

		UPDATE d
		SET
			d.OpeningBalance 	= r.OpeningBalance,
			d.ClosingBalance 	= r.ClosingBalance
		FROM #Data d
			INNER JOIN DBRPT.bodb_Report.dbo.rptDepwinlost r WITH (NOLOCK) ON d.IBCCustID = r.custid
		WHERE r.winlostdate = @Winlostdate
	END
	ELSE IF @Winlostdate >= @CutDate
	BEGIN
		INSERT INTO #Data
		(
			IBCCustID,
			AffID,
			Currency,
			Deposit,
			Withdrawal,
			Bonus,
			Adjustment,
			TurnOver,
			DrawGame,
			Outstanding,
			Winlost,
			OpeningBalance,
			ClosingBalance
		)
		SELECT
			CustId,
			AffID,
			Currency,
			SUM(Deposit),
			SUM(Withdrawal),
			SUM(Bonus),
			SUM(Adjustment),
			SUM(TurnOver),
			SUM(DrawGame),
			SUM(Outstanding),
			SUM(Winlost),
			SUM(OpeningBalance),
			SUM(ClosingBalance)
		FROM
		(
			SELECT
				b.CustId,
				m.AffID,
				m.Currency,
				0 AS Deposit,
				0 AS Withdrawal,
				0 AS Bonus,
				0 AS Adjustment,
				SUM(CASE WHEN b.Sporttype = -6 THEN 0 ELSE ISNULL(b.turnover, 0) END) AS TurnOver,
				SUM(CASE WHEN b.Sporttype = -6 THEN 0 ELSE ISNULL(b.drawTO, 0) END) AS DrawGame,
				SUM(CASE WHEN b.Sporttype = -6 THEN 0 ELSE ISNULL(b.Outstanding, 0) END) AS Outstanding,
				SUM(CASE WHEN b.Sporttype = -6 THEN ISNULL(b.winlost*m.CashOutWLShare, 0) ELSE ISNULL(b.winlost, 0) END) AS Winlost,
				0 AS OpeningBalance,
				0 AS ClosingBalance
			FROM DBRPT.bodb_Report.dbo.rptDepWinlostByProduct b WITH (NOLOCK)
				INNER JOIN #TotalMember m ON m.CustID = b.custid
			WHERE b.winlostdate = @Winlostdate
				AND b.SportType IN (0, -1, -6) -- Sportbook + Bettrade + Cash Out
			GROUP BY b.CustId, m.AffId, m.Currency

			UNION ALL
			SELECT
				b.CustId,
				m.AffID,
				m.Currency,
				ISNULL(b.deposit, 0) AS Deposit,
				ISNULL(b.withdrawal, 0) AS Withdrawal,
				ISNULL(b.Bonus, 0) AS Bonus,
				ISNULL(b.Adjustment, 0) AS Adjustment,
				0 AS TurnOver,
				0 AS DrawGame,
				0 AS Outstanding,
				0 AS Winlost,
				ISNULL(b.OpeningBalance, 0) AS OpeningBalance,
				ISNULL(b.ClosingBalance, 0) AS ClosingBalance
			FROM DBRPT.bodb_Report.dbo.rptDepWinlost b WITH (NOLOCK)
				INNER JOIN #TotalMember m ON m.CustID = b.custid
			WHERE b.winlostdate = @Winlostdate
		) AS A
		GROUP BY
			CustId,
			AffID,
			Currency
	END
	ELSE
	BEGIN
		INSERT INTO #Data
		(
			IBCCustID,
			AffID,
			Currency,
			Deposit,
			Withdrawal,
			Bonus,
			Adjustment,
			TurnOver,
			DrawGame,
			Outstanding,
			Winlost,
			OpeningBalance,
			ClosingBalance
		)
		SELECT
			CustId,
			AffID,
			Currency,
			SUM(Deposit),
			SUM(Withdrawal),
			SUM(Bonus),
			SUM(Adjustment),
			SUM(TurnOver),
			SUM(DrawGame),
			SUM(Outstanding),
			SUM(Winlost),
			SUM(OpeningBalance),
			SUM(ClosingBalance)
		FROM
		(
			SELECT
				b.CustId,
				m.AffID,
				m.Currency,
				0 AS Deposit,
				0 AS Withdrawal,
				0 AS Bonus,
				0 AS Adjustment,
				SUM(CASE WHEN b.Sporttype = -6 THEN 0 ELSE ISNULL(b.turnover, 0) END) AS TurnOver,
				SUM(CASE WHEN b.Sporttype = -6 THEN 0 ELSE ISNULL(b.drawTO, 0) END) AS DrawGame,
				SUM(CASE WHEN b.Sporttype = -6 THEN 0 ELSE ISNULL(b.Outstanding, 0) END) AS Outstanding,
				SUM(CASE WHEN b.Sporttype = -6 THEN ISNULL(b.winlost*m.CashOutWLShare, 0) ELSE ISNULL(b.winlost, 0) END) AS Winlost,
				0 AS OpeningBalance,
				0 AS ClosingBalance
			FROM DBRPT.bodb_Report.dbo.rptDepWinlostByProduct_bk b WITH (NOLOCK)
				INNER JOIN #TotalMember m ON m.CustID = b.custid
			WHERE b.winlostdate = @Winlostdate
				AND b.SportType IN (0, -1, -6) -- Sportbook + Bettrade + Cash Out
			GROUP BY b.CustId, m.AffId, m.Currency

			UNION ALL
			SELECT
				b.CustId,
				m.AffID,
				m.Currency,
				ISNULL(b.deposit, 0) AS Deposit,
				ISNULL(b.withdrawal, 0) AS Withdrawal,
				ISNULL(b.Bonus, 0) AS Bonus,
				ISNULL(b.Adjustment, 0) AS Adjustment,
				0 AS TurnOver,
				0 AS DrawGame,
				0 AS Outstanding,
				0 AS Winlost,
				ISNULL(b.OpeningBalance, 0) AS OpeningBalance,
				ISNULL(b.ClosingBalance, 0) AS ClosingBalance
			FROM DBRPT.bodb_Report.dbo.rptDepWinlost_bk b WITH (NOLOCK)
				INNER JOIN #TotalMember m ON m.CustID = b.custid
			WHERE b.winlostdate = @Winlostdate
		) AS A
		GROUP BY
			CustId,
			AffID,
			Currency
	END
	-- end get data --

	-- import data --
	DECLARE @AffExchange TABLE
	(
		ExchangeID			INT PRIMARY KEY,
		ActualRate			FLOAT,
		ActualRate2			FLOAT,
		DepositPercent		FLOAT,
		WithdrawalPercent FLOAT
	)

	IF (DATEDIFF(DAY, @Winlostdate, GETDATE()) = 0) -- today
	BEGIN
		INSERT INTO @AffExchange
		(
			ExchangeID,
			ActualRate,
			ActualRate2,
			DepositPercent,
			WithdrawalPercent
		)
		SELECT
			ExchangeID,
			ActualRate,
			ActualRate2,
			DepositPercent,
			WithdrawalPercent
		FROM dbo.Exchange_Current WITH (NOLOCK)
	END
	ELSE
	BEGIN
		INSERT INTO @AffExchange
		(
			ExchangeID,
			ActualRate,
			ActualRate2,
			DepositPercent,
			WithdrawalPercent
		)
		SELECT
			ExchangeID,
			ActualRate,
			ActualRate2,
			DepositPercent,
			WithdrawalPercent
		FROM
		(
			SELECT
				ExchangeID,
				ActualRate,
				ActualRate2,
				DepositPercent,
				WithdrawalPercent,
				ROW_NUMBER() OVER(PARTITION BY ExchangeID ORDER BY UpdatedTime DESC) AS RowNum
			FROM dbo.Exchange WITH (NOLOCK)
			WHERE UpdatedTime <= @Winlostdate
		) AS A WHERE A.RowNum = 1
	END

	-- MemberDaily
	DELETE dbo.MemberDaily WITH (ROWLOCK, UPDLOCK)
	WHERE winlostdate = @winlostdate AND SportType = @SportsBookID

	INSERT INTO MemberDaily
	(
		WinlostDate,
		IBCCustID,
		AffID,
		Sporttype,
		Currency,
		Deposit,
		Withdrawal,
		Bonus,
		Adjustment,
		Turnover,
		Outstanding,
		Winlost,
		AffExRate,
		MemberExRate,
		DrawGame,
		PSP,
		Marketing,
		MemOddsFee,
		MemWinlostFake,
		OpeningBalance,
		ClosingBalance
	)
	SELECT
		@WinlostDate,
		d.IBCCustID,
		d.AffID,
		@SportsBookID,
		d.Currency,
		d.Deposit,
		d.Withdrawal,
		d.Bonus,
		d.Adjustment,
		d.Turnover,
		d.Outstanding,
		d.Winlost,
		e.ActualRate2,
		e.ActualRate,
		d.DrawGame,
		ABS(d.Deposit)*e.DepositPercent + ABS(d.Withdrawal)*e.WithdrawalPercent AS PSP,
		ABS(d.Winlost)*ISNULL(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Marketing', @WinlostDate), 0) AS Marketing,
		ABS(d.Winlost)*ISNULL(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Odds Fee', @WinlostDate), 0) AS MemOddsFee,
		-(
			-d.Winlost
			-(ABS(d.Deposit)*e.DepositPercent + ABS(d.Withdrawal)*e.WithdrawalPercent)*ISNULL(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'PSP', @WinlostDate), 0)
			-(ABS(d.Winlost)*ISNULL(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Marketing', @WinlostDate), 0))
			-(ABS(d.Winlost)*ISNULL(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Odds Fee', @WinlostDate), 0))
		) AS MemWinlostFake,
		d.OpeningBalance,
		d.ClosingBalance
	FROM #Data d WITH (NOLOCK)
		INNER JOIN @AffExchange e ON e.ExchangeID = d.currency
		INNER JOIN #ValidMember m ON d.IBCCustID = m.CustId
	WHERE Deposit <> 0
		OR Withdrawal <> 0
		OR Bonus <> 0
		OR Adjustment <> 0
		OR TurnOver <> 0
		OR DrawGame <> 0
		OR Outstanding <> 0
		OR Winlost <> 0

	-- Member Daily Invalid
	DELETE dbo.MemberDaily_Invalid WITH (ROWLOCK, UPDLOCK)
	WHERE winlostdate = @winlostdate AND SportType = @SportsBookID

	INSERT INTO MemberDaily_Invalid
	(
		WinlostDate,
		IBCCustID,
		AffID,
		Sporttype,
		Currency,
		Deposit,
		Withdrawal,
		Bonus,
		Adjustment,
		Turnover,
		Outstanding,
		Winlost,
		AffExRate,
		MemberExRate,
		DrawGame,
		PSP,
		Marketing,
		MemOddsFee,
		MemWinlostFake,
		OpeningBalance,
		ClosingBalance,
		Reason
	)
	SELECT
		@WinlostDate,
		d.IBCCustID,
		d.AffID,
		@SportsBookID,
		d.Currency,
		d.Deposit,
		d.Withdrawal,
		d.Bonus,
		d.Adjustment,
		d.Turnover,
		d.Outstanding,
		d.Winlost,
		e.ActualRate2,
		e.ActualRate,
		d.DrawGame,
		ABS(d.Deposit)*e.DepositPercent + ABS(d.Withdrawal)*e.WithdrawalPercent AS PSP,
		ABS(d.Winlost)*ISNULL(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Marketing', @WinlostDate), 0) AS Marketing,
		ABS(d.Winlost)*ISNULL(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Odds Fee', @WinlostDate), 0) AS MemOddsFee,
		-(
			-d.Winlost
			-(ABS(d.Deposit)*e.DepositPercent + ABS(d.Withdrawal)*e.WithdrawalPercent)*ISNULL(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'PSP', @WinlostDate), 0)
			-(ABS(d.Winlost)*ISNULL(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Marketing', @WinlostDate), 0))
			-(ABS(d.Winlost)*ISNULL(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Odds Fee', @WinlostDate), 0))
		) AS MemWinlostFake,
		d.OpeningBalance,
		d.ClosingBalance,
		CASE
			WHEN m.isInvalidCreatedDate = 1 AND m.isRemoved = 1 THEN 'Invalid CreateDate, Removed'
			WHEN m.isInvalidCreatedDate = 1 THEN 'Invalid CreateDate'
			WHEN m.isRemoved = 1 THEN 'Removed'
		END AS Reason
	FROM #Data d WITH (NOLOCK)
		INNER JOIN @AffExchange e ON e.ExchangeID = d.currency
		INNER JOIN #InValidMember m ON d.IBCCustID = m.CustId
	WHERE Deposit <> 0
		OR Withdrawal <> 0
		OR Bonus <> 0
		OR Adjustment <> 0
		OR TurnOver <> 0
		OR DrawGame <> 0
		OR Outstanding <> 0
		OR Winlost <> 0

	-- Aff Daily
	DELETE dbo.AffDaily WITH (ROWLOCK, UPDLOCK)
	WHERE winlostdate = @winlostdate AND SportID = @SportsBookID

	INSERT INTO AffDaily
	(
		[AffID],
		[Currency],
		[Winlostdate],
		[SportID],
		[ExRate2],
		[MemDeposit],
		[MemWithdrawal],
		[MemTurnover],
		[MemBonus],
		[MemAdjustment],
		[MemMarketing],
		[MemPSP],
		[MemWinlost],
		[AffWinlost],
		[HouseWinlost],
		[AffNetWinlost],
		[HouseNetWinlost],
		[MemWinlostFake],
		[MemOddsFee]
	)
	SELECT
		d.AffID AS AffID,
		d.Currency AS Currency,
		d.Winlostdate AS Winlostdate,
		d.SportType AS SportID,
		d.AffExRate AS Exrate2,
		SUM(ISNULL(d.Deposit, 0)) AS MemDeposit,
		SUM(ISNULL(d.Withdrawal, 0)) AS MemWithdrawal,
		SUM(ISNULL(d.Turnover, 0)) AS MemTurnover,
		SUM(ISNULL(d.Bonus, 0)) AS MemBonus,
		SUM(ISNULL(d.Adjustment, 0)) AS MemAdjustment,
		0 AS MemMarketing,
		SUM(ISNULL(d.PSP, 0)) AS MemPSP,
		SUM(ISNULL(d.Winlost, 0)) AS MemWinLost,
		0 AS AffWinLost,
		-SUM(d.Winlost) AS HouseWinLost,
		0 AS AffNetWinlost,
		0 AS HouseNetWinLost,
		0 AS MemWinlostFake,
		0 AS MemOddsFee
	FROM MemberDaily d WITH (NOLOCK)
	WHERE d.WinlostDate = @winlostdate
		AND d.SportType = @SportsBookID
	GROUP BY
		d.AffID,
		d.Winlostdate,
		d.Currency,
		d.SportType,
		d.AffExRate

	UPDATE dbo.AffDaily WITH (ROWLOCK, UPDLOCK)
	SET
		MemMarketing	= ABS(ISNULL(MemWinlost, 0)) * ISNULL(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0),
		MemOddsFee		= ABS(ISNULL(MemWinlost, 0)) * ISNULL(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0),
		HouseNetWinLost = HouseWinLost
							- ISNULL(MemBonus, 0) * ISNULL(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Bonus', Winlostdate), 0)
							- ISNULL(MemAdjustment, 0)
							- ISNULL(MemPSP, 0) * ISNULL(dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', Winlostdate), 0)
							- ABS(ISNULL(MemWinlost, 0)) * ISNULL(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0)
							- ABS(ISNULL(MemWinlost, 0)) * ISNULL(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0),
		MemWinlostFake	= -(
							- ISNULL(MemWinlost, 0)
							- ISNULL(MemPSP, 0) * ISNULL(dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', Winlostdate), 0)
							- ABS(ISNULL(MemWinlost, 0)) * ISNULL(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0)
							- ABS(ISNULL(MemWinlost, 0)) * ISNULL(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0)
							)
	WHERE WinlostDate = @winlostdate
		AND SportID = @SportsBookID

	-- Aff Daily Summary
	DELETE dbo.AffDailySummary WITH (ROWLOCK, UPDLOCK)
	WHERE winlostdate = @winlostdate AND SportID = @SportsBookID

	INSERT INTO [dbo].[AffDailySummary]
	(
		[AffID],
		[Winlostdate],
		[SportID],
		[MemDeposit],
		[MemWithdrawal],
		[MemTurnover],
		[MemBonus],
		[MemAdjustment],
		[MemMarketing],
		[MemPSP],
		[MemWinlost],
		[AffWinlost],
		[HouseWinlost],
		[AffNetWinlost],
		[HouseNetWinlost],
		[MemOddsFee],
		[MemWinlostFake]
	 )
	SELECT
		[AffID],
		[Winlostdate],
		[SportID],
		SUM([MemDeposit] * ExRate2) AS MemDeposit,
		SUM([MemWithdrawal] * ExRate2) AS MemWithdrawal,
		SUM([MemTurnover] * ExRate2) AS MemTurnover,
		SUM([MemBonus] * ExRate2) AS MemBonus,
		SUM([MemAdjustment] * ExRate2) AS MemAdjustment,
		0 AS MemMarketing,
		SUM([MemPSP] * ExRate2) AS MemPSP,
		SUM([MemWinlost] * ExRate2) AS MemWinlost,
		SUM([AffWinlost] * ExRate2) AS AffWinlost,
		SUM([HouseWinlost] * ExRate2) AS HouseWinlost,
		SUM([AffNetWinlost] * ExRate2) AS AffNetWinlost,
		SUM([HouseNetWinlost] * ExRate2) AS HouseNetWinlost,
		0 AS MemOddsFee,
		0 AS MemWinlostFake
	FROM dbo.AffDaily WITH (NOLOCK)
	WHERE WinlostDate = @winlostdate
		AND SportID = @SportsBookID
	GROUP BY
		AffID,
		Winlostdate,
		SportID

	UPDATE dbo.AffDailySummary WITH (ROWLOCK, UPDLOCK)
	SET
		MemOddsFee		= ABS(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate),
		MemMarketing	= ABS(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate),
		MemWinlostFake	= -(
							- MemWinlost
							- ABS(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate)
							- ABS(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate)
							- MemPSP * dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', WinlostDate)
							),
		HouseNetWinlost = (
							- MemWinlost
							- MemBonus * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Bonus', WinlostDate)
							- MemAdjustment
							- MemPSP * dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', WinlostDate)
							- ABS(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate)
							- ABS(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate)
							)
	WHERE WinlostDate = @winlostdate
		AND SportID = @SportsBookID

	/* Update the last MemWinlostFake of the last transaction date for each acount  
		For example:
		Affiliate 1 : last day =28/11  
		Affiliate 2 : last day= 29/11  
		Affiliate 3 : last day= 31/11          
	*/
	DECLARE @temp TABLE
	(
		AffID					INT,
		SportID					INT,
		totalWinlost			MONEY,
		oddsFeePercent			FLOAT,
		marketingPercent		FLOAT,
		PSPPercent				FLOAT,
		WLFake					MONEY,
		totalPSP				MONEY,
		maxWinlostDate			SMALLDATETIME,
		previousMaxWinlostDate	SMALLDATETIME,
		firstday				SMALLDATETIME
	)

	INSERT INTO @temp
	(
		AffID,
		maxWinlostDate,
		SportID
	)
	SELECT
		AffID,
		MAX(winlostdate),
		SportID
	FROM dbo.AffDailySummary WITH (NOLOCK)
	WHERE winlostdate BETWEEN @DayOfFirstMonth AND @DayOfLastMonth
		AND SportID = @SportsBookID
	GROUP BY
		AffID,
		SportID,
		MONTH(winlostdate),
		YEAR(winlostdate)

	UPDATE t
	SET
		t.previousMaxWinlostDate	= ISNULL(
									(	SELECT MAX(ad.winlostdate)
										FROM dbo.AffDailySummary ad WITH (NOLOCK)
										WHERE ad.SportID = t.SportID
											AND ad.winlostdate < t.maxWinlostDate
											AND DATEDIFF(MONTH, ad.winlostdate, t.maxWinlostDate) = 0
											AND ad.AffID = t.AffID
									), t.maxWinlostDate),
	   t.firstday			= [dbo].[Aff_GetFirstDayOfMonth](t.maxWinlostDate),
	   t.oddsFeePercent		= dbo.Aff_GetDeductionPercent(AffID, t.SportID, 'Odds Fee', [dbo].[Aff_GetLastDayOfMonth](t.maxWinlostDate)),
	   t.marketingPercent	= dbo.Aff_GetDeductionPercent(AffID, t.SportID, 'Marketing', [dbo].[Aff_GetLastDayOfMonth](t.maxWinlostDate)),
	   t.PSPPercent			= dbo.Aff_GetDeductionPercent(AffID, t.SportID, 'PSP', [dbo].[Aff_GetLastDayOfMonth](t.maxWinlostDate))
	FROM @temp t

	UPDATE ad
	SET ad.MemWinlostFake	= -(
								- ISNULL(ad.MemWinlost, 0)
								- ABS(ISNULL(ad.MemWinlost, 0)) * ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, t.SportID, 'Odds Fee', ad.Winlostdate), 0)
								- ABS(ISNULL(ad.MemWinlost, 0)) * ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, t.SportID, 'Marketing', ad.Winlostdate), 0)
								- ISNULL(ad.MemPSP, 0) * ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, t.SportID, 'PSP', ad.Winlostdate), 0)
								)
	FROM dbo.AffDailySummary ad WITH (ROWLOCK, UPDLOCK)
		INNER JOIN @temp t ON t.AffID = ad.AffID AND t.previousMaxWinlostDate = ad.WinlostDate AND t.SportID = ad.SportID

	UPDATE d
	SET
		d.totalWinlost	= ISNULL(c.totalwinlost, 0),
		d.WLFake		= ISNULL(c.memWinlostFake, 0),
		d.totalPSP		= ISNULL(c.memPSP, 0)
	FROM @temp d
		LEFT JOIN
		(
			SELECT
				t.AffID
			   ,t.SportID
			   ,SUM(ad.memwinlost) totalwinlost
			   ,SUM(ad.memWinlostFake) memWinlostFake
			   ,SUM(ad.MemPSP) AS memPSP
			FROM dbo.AffDailySummary ad WITH (NOLOCK)
				INNER JOIN @temp t ON t.AffID = ad.AffID AND t.SportID = ad.SportID
			WHERE ad.WinlostDate BETWEEN t.firstday AND t.previousMaxWinlostDate
				AND ad.SportID = @SportsBookID
			GROUP BY
				t.AffID,
				t.SportID
		) AS c ON c.AffID = d.AffID AND c.SportID = d.SportID

	UPDATE d
	SET MemWinlostFake	= -(
							- (d1.totalwinlost + d.memwinlost)
							- ABS(d1.totalwinlost + d.memwinlost) * (d1.oddsFeePercent + d1.marketingPercent)
							- (d1.totalPSP + d.MemPSP) * d1.PSPPercent
							)
						- d1.WLFake
	FROM dbo.AffDailySummary d WITH (ROWLOCK, UPDLOCK)
		INNER JOIN @temp d1 ON d1.AffID = d.AffID AND d1.maxWinlostDate = d.winlostdate AND d1.SportID = d.SportID
	WHERE d.sportid = @SportsBookID
		AND d1.previousMaxWinlostDate < d1.maxWinlostDate

	DROP TABLE #Data
	DROP TABLE #InvalidMember
	DROP TABLE #TotalMember
	DROP TABLE #ValidMember
END
GO