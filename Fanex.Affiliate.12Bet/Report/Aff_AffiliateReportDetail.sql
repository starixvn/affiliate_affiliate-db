ALTER PROCEDURE [dbo].[Aff_AffiliateReportDetail] 
	@AffUsername VARCHAR(50)
	,@AffId INT = 0 OUTPUT
	,@Fromdate DATETIME
	,@Todate DATETIME
	,@SportId INT = NULL
	,@IsGetAll BIT = 0
AS
/*
	DB052.Affiliate_12BET
	Revisions:
	- 20101228@Henry: change bettype to new range
	- 20110420@Johnny: Filter by Sporttype and restore code to old bettype range
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20140403@Bobby:  exclude Keno product & other sports
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

	IF @AffId = 0 --Invalid AffUsernameRETURN

	DECLARE @CurrDate SMALLDATETIME
		,@OldReportDate SMALLDATETIME
		,@TmpFromDate SMALLDATETIME
		,@TmpToDate SMALLDATETIME
		,@TmpOldWayDate SMALLDATETIME
		,@SportsBookID INT
		,@HorseRacingID INT

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')

	SELECT @CurrDate = convert(VARCHAR(10), current_timestamp, 120)

	SELECT @ToDate = dateadd(s, - 60, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))

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
			,CASE 
				WHEN (
						@SportId IS NULL
						OR @SportId = @SportsBookID
						)
					AND bettype = 22001 THEN isnull(sum(winlost - abs(actual_stake)), 0)
				ELSE 0
				END AS Deposit
			,CASE 
				WHEN (
						@SportId IS NULL
						OR @SportId = @SportsBookID
						)
					AND bettype IN (22002, 22003) THEN - isnull(sum(winlost - abs(actual_stake)), 0)
				ELSE 0
				END AS Withdrawal
			,CASE 
				WHEN @SportId IS NULL
					AND BetType <= 999  THEN isnull(sum(CASE 
								WHEN Bettype IN (33, 43)
									AND liveawayscore = 0 THEN isnull(abs(stake), 0) / 2
								ELSE isnull(abs(stake), 0)
								END), 0)
				WHEN @SportId = @SportsBookID
					AND BetType <= 999 
					AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN isnull(sum(isnull(abs(stake), 0)), 0)
				WHEN @SportId = @HorseRacingID
					AND bettype IN (31, 32, 33, 41, 42, 43) THEN isnull(sum(CASE 
								WHEN Bettype IN (33, 43)
									AND liveawayscore = 0 THEN isnull(abs(stake), 0) / 2
								ELSE isnull(abs(stake), 0)
								END), 0)
				ELSE 0
				END AS Turnover
			,CASE 
				WHEN @SportId IS NULL THEN isnull(sum(CASE 
								WHEN bettype <= 999
									AND ruben = 1 THEN (winlost - abs(actual_stake))
								ELSE 0
								END), 0)
				WHEN @SportId = @SportsBookID THEN isnull(sum(CASE 
								WHEN bettype <= 999
									AND ruben = 1
									AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN (winlost - abs(actual_stake))
								ELSE 0
								END), 0)
				WHEN @SportId = @HorseRacingID THEN isnull(sum(CASE 
								WHEN bettype IN (31, 32, 33, 41, 42, 43)
									AND ruben = 1 THEN (winlost - abs(actual_stake))
								ELSE 0
								END), 0)
				ELSE 0
				END AS Winlost
			,CASE 
				WHEN (
						@SportId IS NULL
						OR @SportId = @SportsBookID
						)
					AND bettype = 22004 THEN isnull(sum((winlost - abs(actual_stake))), 0)
				ELSE 0
				END AS Bonus
			,CASE 
				WHEN @SportId IS NULL
					OR @SportId = @SportsBookID THEN isnull(sum(CASE bettype
								WHEN 22001 THEN (winlost - abs(actual_stake))
								ELSE 0
								END), 0) * e.DepositPercent + abs(- isnull(sum(CASE 
									WHEN bettype IN (22002, 22003) THEN (winlost - abs(actual_stake))
									ELSE 0
									END), 0)) * e.WithdrawalPercent
				ELSE 0
				END AS PSP
			,CASE 
				WHEN @SportId IS NULL
					OR @SportId = @SportsBookID
					AND bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN isnull(sum((winlost - abs(actual_stake))), 0)
				ELSE 0
				END AS Adjustment
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
				OR Bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
				)
			AND bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game
			AND bettype NOT IN (1000) --games
			AND bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
			AND bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
			AND bettype NOT BETWEEN 1501 AND 1599 -- Keno  
			AND StatusID NOT IN (101, 102, 103, 121, 1)
			--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'  
			AND b.custid > 0
		GROUP BY b.WinlostDate
			,m.Currency
			,e.ActualRate2
			,e.DepositPercent
			,e.WithdrawalPercent
			,b.Bettype
		
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

GRANT EXECUTE ON [dbo].[Aff_AffiliateReportDetail] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateReportDetail] TO [VNTeam]
