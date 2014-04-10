ALTER PROCEDURE [dbo].[Aff_AffiliateReport] 
	@PreferredLanguage VARCHAR(11) = NULL
	,@Fromdate DATETIME
	,@Todate DATETIME
	,@IsGetAll BIT
	,@AffType SMALLINT = 0
	,@SportId SMALLINT = NULL
AS
/*
Created: @VinhTrinh
Task : Get report by date for each affiliate.
DB: DB052.Affiliate_12BET
Original: [Aff_AffiliateReport]
Revisions:
	- 20101228@Henry: change bettype to new range
	- 20110420@Johnny: Filter by Sporttype and restore code to old bettype range
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20140403@Bobby:  exclude Keno product & other sports


Param's Explanation:
	• @Fromdate Time search From
	• @Todate Time search To,
	• @IsGetAll if getall = 1 => get data in all date,
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CurrDate SMALLDATETIME
		,@OldReportDate SMALLDATETIME
		,@TmpToDate SMALLDATETIME
		,@TmpFromDate SMALLDATETIME
		,@TmpOldWayDate SMALLDATETIME
		,@SportsBookID INT
		,@HorseRacingID INT

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')

	IF (
			@Fromdate > @Todate
			OR @Fromdate > current_timestamp
			) RETURN

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

	--select @FromDate as FromDate, @ToDate as ToDate , @TmpFromDate as TmpFromDate, @TmpToDate as TmpToDate, @TmpOldWayDate as TmpOldWayDate
	SELECT t.AffId
		,t.Username
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
	FROM (
		SELECT ai.AffId
			,ai.Username
		FROM AffDetail ad WITH (NOLOCK)
			INNER JOIN AffInfo ai WITH (NOLOCK)
			ON ad.AffId = ai.AffId
			INNER JOIN AffType at WITH (NOLOCK)
			ON ai.AffType = at.TypeId
		WHERE PreferredLanguage = isnull(@PreferredLanguage, PreferredLanguage)
			AND at.IsShown = 1
		) t
		INNER JOIN (
		SELECT AffId
			,--Calculate winlost member below Aff in MemberDaily
			Sum(MemDeposit * ExRate2) AS Deposit
			,Sum(MemWithdrawal * ExRate2) AS Withdrawal
			,Sum(MemTurnover * ExRate2) AS Turnover
			,Sum(MemWinlost * ExRate2) AS Winlost
			,Sum(MemBonus * ExRate2) AS Bonus
			,Sum(MemPSP * ExRate2) AS PSP
			,Sum(MemAdjustment * ExRate2) AS Adjustment
			,0 AS AffAdjustment
			,0 AS AffWithdrawal
			,sum(AffNetWinlost * ExRate2) AS AffBF
		FROM AffDaily WITH (NOLOCK)
		WHERE WinlostDate BETWEEN @FromDate AND @TmpToDate
			AND isnull(@SportId, SPortId) = SPortId
		GROUP BY AffID
		
		UNION ALL
		SELECT m.AffID
			,--Get winlost member in Bettrans table
			CASE 
				WHEN (
						@SportId IS NULL
						OR @SportId = @SportsBookID
						)
					AND bettype = 22001 THEN isnull(sum((winlost - abs(actual_stake)) * e.ActualRate2), 0)
				ELSE 0
				END AS Deposit
			,CASE 
				WHEN (
						@SportId IS NULL
						OR @SportId = @SportsBookID
						)
					AND bettype IN (22002, 22003) THEN - isnull(sum((winlost - abs(actual_stake)) * e.ActualRate2), 0)
				ELSE 0
				END AS Withdrawal
			,CASE 
				WHEN @SportId IS NULL
					AND bettype <= 999 THEN isnull(sum(CASE 
								WHEN Bettype IN (33, 43)
									AND liveawayscore = 0 THEN isnull(abs(stake), 0) / 2 * e.ActualRate2
								ELSE isnull(abs(stake), 0) * e.ActualRate2
								END), 0)
				WHEN @SportId = @SportsBookID
					AND BetType <= 999
					AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN isnull(sum(isnull(abs(stake), 0) * e.ActualRate2), 0)
				WHEN @SportId = @HorseRacingID
					AND bettype IN (31, 32, 33, 41, 42, 43) THEN isnull(sum(CASE 
								WHEN Bettype IN (33, 43)
									AND liveawayscore = 0 THEN isnull(abs(stake), 0) / 2 * e.ActualRate2
								ELSE isnull(abs(stake), 0) * e.ActualRate2
								END), 0)
				ELSE 0
				END AS Turnover
			,CASE 
				WHEN @SportId IS NULL THEN isnull(sum(CASE 
								WHEN bettype <= 999
									AND ruben = 1 THEN (winlost - abs(actual_stake)) * e.ActualRate2
								ELSE 0
								END), 0)
				WHEN @SportId = @SportsBookID THEN isnull(sum(CASE 
								WHEN bettype <= 999
									AND ruben = 1
									AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN (winlost - abs(actual_stake)) * e.ActualRate2
								ELSE 0
								END), 0)
				WHEN @SportId = @HorseRacingID THEN isnull(sum(CASE 
								WHEN bettype IN (31, 32, 33, 41, 42, 43)
									AND ruben = 1 THEN (winlost - abs(actual_stake)) * e.ActualRate2
								ELSE 0
								END), 0)
				ELSE 0
				END AS Winlost
			,CASE 
				WHEN (
						@SportId IS NULL
						OR @SportId = @SportsBookID
						)
					AND bettype = 22004 THEN isnull(sum((winlost - abs(actual_stake)) * e.ActualRate2), 0)
				ELSE 0
				END AS Bonus
			,CASE 
				WHEN @SportId IS NULL
					OR @SportId = @SportsBookID THEN isnull(sum(CASE bettype
								WHEN 22001 THEN (winlost - abs(actual_stake)) * e.ActualRate2
								ELSE 0
								END), 0) * e.DepositPercent + abs(- isnull(sum(CASE 
									WHEN bettype IN (22002, 22003) THEN (winlost - abs(actual_stake)) * e.ActualRate2
									ELSE 0
									END), 0)) * e.WithdrawalPercent
				ELSE 0
				END AS PSP
			,CASE 
				WHEN @SportId IS NULL
					OR @SportId = @SportsBookID
					AND bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN isnull(sum((winlost - abs(actual_stake)) * e.ActualRate2), 0)
				ELSE 0
				END AS Adjustment
			,0 AS AffAdjustment
			,0 AS AffWithdrawal
			,0 AS AffBF
		FROM bodb02.dbo.Bettrans b WITH (NOLOCK)
			INNER JOIN MemberInfo m WITH (NOLOCK)
			ON m.IBCCustID = b.CustId
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
		GROUP BY m.AffId
			,e.DepositPercent
			,e.WithdrawalPercent
			,b.Bettype
		
		UNION ALL
		SELECT AffId
			,--Get Aff Adjusment and Aff Widthrawal
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
					WHEN Transtype = 202 THEN abs(Amount)
					ELSE 0
					END) AS AffWithdrawal
			,0 AS AffBF
		FROM AffTrans a WITH (NOLOCK)
		--inner join #TmpTable t on a.AffID = t.AffId
		WHERE (
				@IsGetAll = 1
				OR dateadd(d, datediff(d, 0, TransDate), 0) BETWEEN @FromDate AND dateadd(d, datediff(d, 0, @ToDate), 0)
				)
			AND Transtype IN (202, 203)
			AND STATUS IN ('Pending', 'Approved', 'Completed')
		GROUP BY AffId
		) b
		ON t.AffId = b.AffId
	GROUP BY t.AffId
		,t.Username
	ORDER BY t.AffId
END
GO

GRANT EXECUTE ON [dbo].[Aff_AffiliateReport] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateReport] TO [VNTeam]
GO


