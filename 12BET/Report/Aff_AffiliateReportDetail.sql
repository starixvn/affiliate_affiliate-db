/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_AffiliateReportDetail]
	@AffUsername 	VARCHAR(50)
	,@AffId 		INT = 0 OUTPUT
	,@Fromdate 		DATE
	,@Todate 		DATE
	,@SportId 		INT = NULL
	,@IsGetAll 		BIT = 0
AS
/*
	DB052.Affiliate_12BET
	Revisions:
	- 20101228@Henry: change bettype to new range
	- 20110420@Johnny: Filter by Sporttype and restore code to old bettype range
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20140403@Bobby:  exclude Keno product & other sports
	- 20141113@Bobby: Change report time range from datetime to date only
	- 20141218@Bobby: Update SS's bettype
	- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]
*/
BEGIN
	SET NOCOUNT ON

	IF (
			@Fromdate > @Todate
			OR @Fromdate > current_timestamp
			) RETURN

	SELECT @AffId = AffId
	FROM AffInfo WITH (NOLOCK)
	WHERE Username = @AffUsername

	IF @AffId = 0 --Invalid AffUsername
		RETURN

	DECLARE @CurrDate 	DATE
		,@OldReportDate DATE
		,@TmpFromDate 	DATE
		,@TmpToDate 	DATE
		,@TmpOldWayDate DATE
		,@SportsBookID 	INT
		,@HorseRacingID INT

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')

	SELECT @CurrDate 	= CURRENT_TIMESTAMP

	SELECT @OldReportDate = SValue
	FROM SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_OldReportDate'

	IF (@OldReportDate IS NULL)
		SELECT @OldReportDate = '31 Oct 2009'

	IF @IsGetAll = 1
	BEGIN
		SELECT @FromDate = min(WinlostDate)
		FROM MemberDaily WITH (NOLOCK)

		SELECT @ToDate = current_timestamp

		SELECT @TmpFromDate = dateadd(d, 1, @OldReportDate) --From date for new way calculate winlost

		SELECT @TmpToDate = dateadd(d, - 1, @CurrDate) --To date for new way calculate winlost

		SELECT @TmpOldWayDate = @OldReportDate
	END
	ELSE
	BEGIN
		SELECT @TmpFromDate = CASE 
				WHEN @FromDate <= @OldReportDate THEN dateadd(d, 1, @OldReportDate)
				ELSE @FromDate
				END

		SELECT @TmpToDate = CASE 
				WHEN @ToDate >= @CurrDate THEN dateadd(d, - 1, @CurrDate)
				ELSE @ToDate
				END

		SELECT @TmpOldWayDate = CASE 
				WHEN @ToDate >= @OldReportDate THEN @OldReportDate
				ELSE @ToDate
				END
	END

	DECLARE @COWLShare DECIMAL(9,8)
	SELECT  @COWLShare = ds.DeductedPercentage
	FROM dbo.DeductionSetting ds WITH(NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ds.GroupID = ai.GroupID AND ds.DeductionID = 9
	WHERE ai.AffID = @AffId

	SELECT  @COWLShare = ISNULL(@COWLShare, 0)

	SELECT WinlostDate
		,AffExRate
		,e.Currency
		,Sum(b.Deposit) AS Deposit
		,Sum(b.Withdrawal) AS Withdrawal
		,Sum(b.Turnover) AS Turnover
		,Sum(b.Winlost) AS Winlost
		,Sum(b.Bonus) AS Bonus
		,Sum(b.PSP) AS PSP
		,Sum(b.Adjustment) AS Adjustment
		,Sum(b.AffAdjustment) AS AffAdjustment
		,Sum(b.AffWithdrawal) AS AffWithdrawal
		,Sum(b.AffBF) AS AffBF
	FROM Exchange_Current e WITH (NOLOCK)
		INNER JOIN (
		SELECT WinlostDate
			,--Calculate winlost member below Aff in MemberDaily and AffCommission table
			Currency
			,ExRate2 AS AffExRate
			,Sum(MemDeposit) AS Deposit
			,Sum(MemWithdrawal) AS Withdrawal
			,Sum(MemTurnover) AS Turnover
			,Sum(MemWinlost) AS Winlost
			,Sum(MemBonus) AS Bonus
			,Sum(MemPSP) AS PSP
			,Sum(MemAdjustment) AS Adjustment
			,0 AS AffAdjustment
			,0 AS AffWithdrawal
			,sum(AffNetWinlost) AS AffBF
		FROM AffDaily WITH (NOLOCK)
		WHERE WinlostDate BETWEEN @FromDate AND @TmpToDate
			AND AffId = @AffId
			AND isnull(@SportId, SPortId) = SPortId
		GROUP BY WinlostDate
			,Currency
			,ExRate2
		
		UNION ALL
		SELECT @CurrDate AS WinlostDate
			,--Get winlost member in Bettrans table
			m.Currency
			,e.ActualRate2 AS AffExRate
			,ISNULL(SUM(
				CASE 
					WHEN (
							@SportId IS NULL
							OR @SportId = @SportsBookID
							)
						AND bettype = 22001 THEN winlost - ABS(actual_stake)
					ELSE 0
					END), 0) AS Deposit
			,ISNULL(SUM(
				CASE 
					WHEN (
							@SportId IS NULL
							OR @SportId = @SportsBookID
							)
						AND bettype IN (22002, 22003) THEN -(winlost - ABS(actual_stake))
					ELSE 0
					END), 0) AS Withdrawal
			,ISNULL(SUM(
				CASE
					WHEN bettype = 911 THEN 0
					WHEN @SportId IS NULL AND (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
						THEN CASE WHEN Bettype IN (33, 43) AND liveawayscore = 0 THEN ABS(stake) / 2 ELSE ABS(stake) END
					WHEN @SportId = @SportsBookID AND (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399)) AND bettype NOT IN (31, 32, 33, 41, 42, 43)
						THEN ABS(stake)
					WHEN @SportId = @HorseRacingID AND bettype IN (31, 32, 33, 41, 42, 43)
						THEN CASE WHEN Bettype IN (33, 43) AND liveawayscore = 0 THEN ABS(stake) / 2 ELSE ABS(stake) END
					ELSE 0
					END), 0) AS Turnover
			,ISNULL(SUM(
				CASE 
					WHEN @SportId IS NULL
						THEN CASE WHEN (bettype <= 999 OR (b.bettype BETWEEN 1301 AND 1399)) AND ruben = 1 THEN (winlost - ABS(actual_stake)) ELSE 0 END
					WHEN @SportId = @SportsBookID
						THEN CASE WHEN (bettype <= 999 OR (b.bettype BETWEEN 1301 AND 1399)) AND ruben = 1
										AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN (winlost - ABS(actual_stake)) ELSE 0 END
					WHEN @SportId = @HorseRacingID
						THEN CASE WHEN bettype IN (31, 32, 33, 41, 42, 43) AND ruben = 1 THEN (winlost - abs(actual_stake)) ELSE 0 END
					ELSE 0
					END
				*
				CASE
					WHEN bettype = 911 THEN @COWLShare
					ELSE 1
					END), 0) AS Winlost
			,ISNULL(SUM(
				CASE 
					WHEN (
							@SportId IS NULL
							OR @SportId = @SportsBookID
							)
						AND bettype = 22004 THEN (winlost - ABS(actual_stake))
					ELSE 0
					END), 0) AS Bonus
			,ISNULL(SUM(
				CASE 
					WHEN @SportId IS NULL OR @SportId = @SportsBookID
						THEN CASE WHEN bettype = 22001 THEN (winlost - ABS(actual_stake)) ELSE 0 END * e.DepositPercent
						- CASE WHEN bettype IN (22002, 22003) THEN (winlost - abs(actual_stake)) ELSE 0 END * e.WithdrawalPercent
					ELSE 0
					END), 0) AS PSP
			,ISNULL(SUM(
				CASE 
					WHEN @SportId IS NULL
						OR @SportId = @SportsBookID
						AND bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN (winlost - abs(actual_stake))
					ELSE 0
					END), 0) AS Adjustment
			,0 AS AffAdjustment
			,0 AS AffWithdrawal
			,0 AS AffBF
		FROM bodb02.dbo.Bettrans b WITH (NOLOCK)
			INNER JOIN MemberInfo m WITH (NOLOCK)
			ON m.IBCCustID = b.CustId
				AND m.AffId = @AffId
				AND m.IsRemoved = 0
			INNER JOIN Exchange_Current e WITH (NOLOCK)
			ON m.Currency = e.ExchangeId
		WHERE @ToDate >= @CurrDate
			AND b.WinlostDate = @CurrDate
			AND (
				Bettype <= 999
				OR ( b.bettype BETWEEN 1301 AND 1399)
				OR Bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
				)
			AND bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game
			AND bettype NOT IN (1000) --games
			AND bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
			AND bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
			AND bettype NOT BETWEEN 1501 AND 1599 -- Keno  
			AND bettype NOT IN (912, 913, 914) -- Cash Out (keep 911)
			AND StatusID NOT IN (101, 102, 103, 121, 1)
			--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'  
			AND b.custid > 0
		GROUP BY m.Currency
			,e.ActualRate2
		
		UNION ALL
		SELECT dateadd(d, datediff(d, 0, a.TransDate), 0) AS WinlostDate
			,--Get Aff Adjusment and Aff Widthrawal
			a.Currency
			,1 AS AffExRate
			,--Default currency $US for Aff
			0 AS Deposit
			,0 AS Withdrawal
			,0 AS Turnover
			,0 AS Winlost
			,0 AS Bonus
			,0 AS PSP
			,0 AS Adjustment
			,Sum(CASE 
					WHEN Transtype = 203 THEN Amount
					ELSE 0
					END) AS AffAdjustment
			,Sum(CASE 
					WHEN Transtype = 202 THEN Amount
					ELSE 0
					END) AS AffWithdrawal
			,0 AS AffBF
		FROM AffTrans a WITH (NOLOCK)
		WHERE (
				@IsGetAll = 1
				OR TransDate BETWEEN @FromDate AND @ToDate
				)
			AND Transtype IN (202, 203)
			AND STATUS IN ('Pending', 'Approved', 'Completed')
			AND a.AffId = @AffId
		GROUP BY dateadd(d, datediff(d, 0, a.TransDate), 0)
			,a.Currency
		) b
		ON b.Currency = e.ExchangeID
	GROUP BY WinlostDate
		,AffExRate
		,e.Currency
	ORDER BY WinlostDate
END
GO