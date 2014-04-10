ALTER FUNCTION [dbo].[Aff_MemberDailyForCurrentDate] (@AffID INT)
RETURNS @MemberDaily TABLE (
	IBCCustID INT
	,SportID INT
	,Deposit MONEY
	,Winlost MONEY
	,Bonus MONEY
	,Adjustment MONEY
	,PSP MONEY
	,Marketing MONEY
	,TurnOver MONEY
	)
AS
/*
	Task : Get MemberDaily Info
	Author : Peter@20100508
	Revisions:
		- 20120606@Peter : Exclude waiting tickets
		- 20140403@Bobby:  exclude Keno product & other sports

	Params explaination:
*/
BEGIN
	DECLARE @Today SMALLDATETIME
		,@SportsBookID INT
		,@HorseRacingID INT

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')

	--Get last day of inputted month
	SELECT @Today = convert(VARCHAR(12), current_timestamp)

	INSERT INTO @MemberDaily (
		IBCCustID
		,SportID
		,Deposit
		,Winlost
		,Bonus
		,Adjustment
		,PSP
		,Marketing
		,TurnOver
		)
	SELECT *
	FROM (
		SELECT ci.IBCCustID
			,CASE 
				WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN @HorseRacingID
				ELSE @SportsBookID
				END AS SportType
			,isnull(sum(CASE bettype
						WHEN 22001 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END) * e.Actualrate2, 0) AS Deposit
			,isnull(sum(CASE 
						WHEN BetType <= 999 
							AND ruben = 1 THEN (b.Winlost - abs(b.actual_stake))
						ELSE 0
						END) * e.Actualrate2, 0) AS Winlost
			,isnull(sum(CASE bettype
						WHEN 22004 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END) * e.Actualrate2, 0) AS Bonus
			,isnull(sum(CASE 
						WHEN bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END) * e.Actualrate2, 0) AS Adjustment
			,isnull(sum(CASE bettype
						WHEN 22001 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END) * e.Actualrate2, 0) * e.DepositPercent + abs(- isnull(sum(CASE 
							WHEN bettype IN (22002, 22003) THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
							ELSE 0
							END) * e.Actualrate2, 0) * e.WithdrawalPercent) AS PSP
			,0 AS Marketing
			,isnull(sum(CASE 
						WHEN BetType <= 999  THEN (CASE 
								WHEN Bettype IN (33, 43)
									AND liveawayscore = 0 THEN isnull(abs(stake), 0) / 2 * e.Actualrate2
								ELSE isnull(abs(stake), 0) END
								)
						ELSE 0
						END) * e.Actualrate2, 0) AS Turnover
		FROM MemberInfo ci WITH (NOLOCK)
			INNER JOIN bodb02.dbo.bettrans b WITH (NOLOCK)
			ON b.custid = ci.IBCCustID
			INNER JOIN Exchange_Current e WITH (NOLOCK)
			ON e.exchangeid = ci.currency
		WHERE b.winlostdate = @Today
			AND b.recommend = ci.recommend
			AND ci.AffID = @AffID
			AND ci.IsRemoved = 0
			AND (
				b.bettype <= 999
				OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
				) --get SB only
			AND b.bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
			AND b.bettype NOT IN (1000) --games
			AND b.bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
			AND b.bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
			AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno  
					--and bettype not in (31,32,33,41,42,43)   
			AND b.StatusID NOT IN (101, 102, 103, 121, 1)
		--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'  
		GROUP BY ci.IBCCustID
			,CASE 
				WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN @HorseRacingID
				ELSE @SportsBookID
				END
			,e.Actualrate2
			,e.DepositPercent
			,e.WithdrawalPercent
		
		UNION ALL
		SELECT IBCCustID
			,SportType
			,isnull(Deposit * AffExRate, 0)
			,isnull(Winlost * AffExRate, 0)
			,isnull(Bonus * AffExRate, 0)
			,isnull(Adjustment * AffExRate, 0)
			,isnull(PSP * AffExRate, 0)
			,isnull(Marketing * AffExRate, 0)
			,isnull(TurnOver * AffExRate, 0)
		FROM MemberDaily(NOLOCK)
		WHERE winlostdate = @Today
			AND SportType NOT IN (@SportsBookID, @HorseRacingID)
			AND AffID = @AffID
		) t

	RETURN
END
