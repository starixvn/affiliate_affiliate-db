/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_ReportDetailSelByAff] 
	@AffID INT
	,@Fromdate DATETIME
	,@Todate DATETIME
AS
/*
	Created: @VinhTrinh
	Task : Get report by date for all affiliate.
	DB: DB052.Affiliate_12BET
	Original: [Aff_CustomerSelDetailsByAff]
	
	Revisions:
		- 20101228@Henry: change bettype to new range
		- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
		- 20140403@Bobby:  exclude Keno product & other sports
		- 20141218@Bobby: Update SS's bettype
		- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]
		- 20180222@Percy: Change range of winlostdate when getting data [RedmineID: #90861]

	Param's Explanation:
		• @Fromdate Month search from
		• @Todate To month.
*/
BEGIN
	SET NOCOUNT ON

	IF (
			@Fromdate > @Todate
			OR @Fromdate > current_timestamp
			) RETURN

	DECLARE @CurrDate SMALLDATETIME
		,@BeforeCurrDate SMALLDATETIME
		,@MaxTransDate SMALLDATETIME
		,@OldReportDate SMALLDATETIME
		,@TmpToDate SMALLDATETIME

	SELECT @OldReportDate = SValue
	FROM SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_OldReportDate'

	IF (@OldReportDate IS NULL)
		SELECT @OldReportDate = '31 Oct 2009'

	SELECT @CurrDate = convert(VARCHAR(10), current_timestamp, 120)
		,@BeforeCurrDate = DATEADD(DAY, -1, @CurrDate)
		,@Fromdate = convert(VARCHAR(10), @Fromdate, 120)
		,@Todate = convert(VARCHAR(10), @Todate, 120)

	SELECT @TmpToDate = @ToDate

	IF (@Todate >= @BeforeCurrDate)
		SELECT @TmpToDate = dateadd(d, - 1, @BeforeCurrDate)

	DECLARE @COWLShare DECIMAL(9,8)
	SELECT  @COWLShare = ds.DeductedPercentage
	FROM dbo.DeductionSetting ds WITH(NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ds.GroupID = ai.GroupID AND ds.DeductionID = 9
	WHERE ai.AffID = @AffId

	SELECT  @COWLShare = ISNULL(@COWLShare, 0)

	SELECT t.*
	FROM (
		(
			SELECT Winlostdate
				,a.Currency AS exchangeID
				,e.Currency
				,a.ExRate2 AS Actualrate
				,isnull(Sum(MemDeposit), 0) AS Deposit
				,isnull(Sum(MemTurnover), 0) AS Turnover
				,isnull(Sum(MemBonus), 0) AS Bonus
				,isnull(Sum(MemWinLost), 0) AS MemberWinLost
				,isnull(Sum(AffWinLost), 0) AS AffiliateWinLost
				,isnull(Sum(HouseWinLost), 0) AS HouseWinLost
				,isnull(Sum(AffNetWinLost), 0) AS AffiliateNetWinLost
				,isnull(Sum(HouseNetWinLost), 0) AS HouseNetWinLost
			FROM AffDaily a WITH (NOLOCK)
				INNER JOIN Exchange_Current e WITH (NOLOCK)
				ON a.Currency = e.ExchangeID
			WHERE winlostdate BETWEEN @FromDate AND @TmpToDate
				AND a.AffID = @AffId
			GROUP BY Winlostdate
				,a.Currency
				,e.Currency
				,a.ExRate2
			)
		
		UNION ALL
		(
			SELECT b.Winlostdate
				,b.Currency AS exchangeID
				,e.Currency
				,e.ActualRate2 AS Actualrate
				,ISNULL(SUM(CASE bettype
							WHEN 22001 THEN b.winlost - abs(b.actual_stake)
							ELSE 0
							END), 0) AS Deposit
				,ISNULL(SUM(CASE 
						WHEN bettype = 911 THEN 0
						WHEN (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399)) THEN (CASE 
								WHEN Bettype IN (33, 43)
									AND liveawayscore = 0 THEN isnull(abs(stake), 0) / 2
								ELSE isnull(abs(stake), 0) END
								)
						ELSE 0
						END), 0) AS Turnover
				,ISNULL(SUM(CASE bettype
							WHEN 22004 THEN winlost - abs(actual_stake)
							ELSE 0
							END), 0) AS Bonus
				,ISNULL(SUM(CASE 
							WHEN (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
								AND ruben = 1 THEN winlost - abs(actual_stake) + playercomm
							ELSE 0
							END
							*
							CASE
							WHEN bettype = 911 THEN @COWLShare
							ELSE 1
							END), 0) AS MemberWinLost
				,NULL AS AffiliateWinLost
				,NULL AS HouseWinLost
				,NULL AS AffiliateNetWinLost
				,NULL AS HouseNetWinLost
			FROM bodb02.dbo.bettrans b WITH (NOLOCK)
				INNER JOIN MemberInfo m WITH (NOLOCK)
				ON m.IBCCustId = b.CustId
					AND m.IsRemoved = 0
					AND m.AffID = @AffID
				INNER JOIN Exchange_Current e WITH (NOLOCK)
				ON e.exchangeid = b.currency
			WHERE @ToDate >= @BeforeCurrDate
				AND b.Winlostdate BETWEEN @BeforeCurrDate AND @CurrDate
				AND (
					b.bettype <= 999
					OR ( b.bettype BETWEEN 1301 AND 1399)
					OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
					) --get SB only
				AND b.bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
				AND b.bettype NOT IN (1000) --games
				AND b.bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
				AND b.bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
				AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno  
				AND bettype NOT IN (912, 913, 914) -- Cash Out (keep 911)
						--and bettype not in (31,32,33,41,42,43)   
				AND b.StatusID NOT IN (101, 102, 103, 121, 1)
			--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'  
			GROUP BY b.Winlostdate
				,b.Currency
				,e.Currency
				,e.ActualRate2
			)
		) t
	ORDER BY t.Winlostdate
		,t.Currency
END
GO