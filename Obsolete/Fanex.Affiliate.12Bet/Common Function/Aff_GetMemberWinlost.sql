ALTER FUNCTION [dbo].[Aff_GetMemberWinlost] (
	@AffID INT
	,@SportID TINYINT
	,@MonthDate SMALLDATETIME
	)
RETURNS MONEY
AS
/*
	Task : Get MemberWinlost for Affiliate
	Author : Peter@20100508
	Revisions:
		- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
		- 20120606@Peter : Exclude waiting tickets
		- 20140403@Bobby:  exclude Keno product & other sports
		- 20141218@Bobby: Update SS's bettype

	Params explaination:
		@MonthDate=null : current month
*/
BEGIN
	DECLARE @MemberWinlost MONEY

	SELECT @MemberWinlost = 0

	IF Datediff(m, @monthdate, current_timestamp) = 0
	BEGIN
		DECLARE @Today SMALLDATETIME
			,@FirstDay SMALLDATETIME
			,@LastDay SMALLDATETIME
			,@SportsBookID INT
			,@HorseRacingID INT
			,@MemberWinlostCurrentDate MONEY

		SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
			,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')

		SELECT @FirstDay = cast(cast(year(getdate()) AS VARCHAR(5)) + '-' + cast(Month(getdate()) AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)

		--Get last day of inputted month
		SELECT @Today = convert(VARCHAR(12), current_timestamp)

		SELECT @LastDay = dateadd(d, - 1, @Today)

		SELECT @MemberWinlost = sum(isnull(MemWinlost, 0) * isnull(ExRate2, 0))
		FROM AffDaily(NOLOCK)
		WHERE AffId = @AffID
			AND SportId = @SportID
			AND winlostdate BETWEEN @FirstDay AND @LastDay

		SELECT @MemberWinlostCurrentDate = sum(isnull(MemberWinlost, 0) * isnull(ExRate2, 0))
		FROM (
			SELECT ci.IBCCustID
				,CASE 
					WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN @HorseRacingID
					ELSE @SportsBookID
					END AS SportID
				,sum(isnull(winlost, 0) - isnull(abs(actual_stake), 0) + isnull(playercomm, 0)) AS MemberWinlost
				,e.Actualrate2 AS ExRate2
			FROM MemberInfo ci WITH (NOLOCK)
				INNER JOIN bodb02.dbo.bettrans b WITH (NOLOCK)
				ON b.custid = ci.IBCCustID
				INNER JOIN Exchange_Current e WITH (NOLOCK)
				ON e.exchangeid = ci.currency
			WHERE b.winlostdate = @Today
				AND b.ruben = 1
				AND ci.AffID = @AffID
				AND ci.IsRemoved = 0
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
						--and bettype not in (31,32,33,41,42,43)   
				AND b.StatusID NOT IN (101, 102, 103, 121, 1)
				AND b.custid > 0
			--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'  
			GROUP BY ci.IBCCustID
				,CASE 
					WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN @HorseRacingID
					ELSE @SportsBookID
					END
				,e.Actualrate2
			) AS a
		WHERE SportID = @SportID

		SELECT @MemberWinlost = isnull(@MemberWinlost, 0) + isnull(@MemberWinlostCurrentDate, 0)
	END
	ELSE
	BEGIN
		DECLARE @MaxTransDate SMALLDATETIME

		SELECT @MaxTransDate = Max(winlostdate)
		FROM AffCommission(NOLOCK)

		IF @MaxTransDate < @monthdate
		BEGIN
			SELECT @MemberWinlost = sum(isnull(MemWinlost, 0) * isnull(ExRate2, 0))
			FROM AffDaily(NOLOCK)
			WHERE AffId = @AffID
				AND SportId = @SportID
				AND datediff(m, WinlostDate, @MonthDate) = 0
		END
		ELSE
		BEGIN
			SELECT @MemberWinlost = isnull(MemberWinlost, 0)
			FROM AffCommission NOLOCK
			WHERE AffId = @AffId
				AND WinlostDate = @monthdate
				AND SportID = @SportID
		END
	END

	RETURN isnull(@MemberWinlost, 0)
END
