/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_EarningSelDetail] 
	@AffId INT = 0
	,@SportType TINYINT = 0
	,@MonthDate SMALLDATETIME
AS

/*
	Created: 200900911@VinhTrinh
	Task : [description of SP]  
	DB: DBAFF12BET.Affiliate_12BET
	Revisions:  		
	       - 20101228@Henry: change bettype to new range
		   - 20111031@Peter: Exclude Number Game from Sportsbook commission (bettype from [81-120])	
		   - 20120606@Peter: Exclude waiting tickets	
		   - 20140403@Bobby: Exclude Keno product & other sports
		   - 20141218@Bobby: Update SS's bettype
		   - 20170525@Percy: Integrate Cash Out [RedmineID: #74874]

	Param's Explanation:  
	• @AffId affliate Id  
	• @MonthDate Month date need to view.  
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @CurrDate SMALLDATETIME
		,@SportsBookID INT
		,@HorseRacingID INT
		,@GroupId INT
		,@DeductedPercentage DECIMAL(9,8)

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')

	SELECT @GroupId = GroupId FROM dbo.AffInfo WITH(NOLOCK) WHERE AffId = @AffId
	SELECT @DeductedPercentage = DeductedPercentage FROM dbo.DeductionSetting WITH(NOLOCK) WHERE GroupId = @GroupId AND DeductionID = 9
	
	IF @DeductedPercentage IS NULL
		SELECT @DeductedPercentage = 0

	SET @CurrDate = convert(VARCHAR(10), CURRENT_TIMESTAMP, 120)

	SELECT @MonthDate = dateadd(d, datediff(d, 0, @MonthDate), 0)

	IF (
			@SportType <> 3
			AND @CurrDate = @MonthDate
			)
	BEGIN --Get current date data for sp and hr in bettrans table
		SELECT b.CustID AS CustID
			,m.UserName
			,m.IBCUserName
			,isnull(sum(CASE 
						WHEN (
								@SportType = @SportsBookID
								OR @SportType = 0
								)
							AND bettype = 22001 THEN (winlost - abs(actual_stake)) * e.ActualRate2
						ELSE 0
						END), 0) AS Deposit
			,- isnull(sum(CASE 
						WHEN (
								@SportType = 0
								OR @SportType = @SportsBookID
								)
							AND bettype IN (22002, 22003) THEN (winlost - abs(actual_stake)) * e.ActualRate2
						ELSE 0
						END), 0) AS Withdrawal
			,isnull(sum(CASE 
						WHEN b.ruben = 1
							AND @SportType = 0
							AND (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))  THEN (winlost - abs(actual_stake) + playercomm) * e.ActualRate2
						WHEN b.ruben = 1
							AND @SportType = @SportsBookID
							AND (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
							AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN (winlost - abs(actual_stake) + playercomm) * e.ActualRate2
						WHEN b.ruben = 1
							AND @SportType = @HorseRacingID
							AND (bettype < 999 OR ( b.bettype BETWEEN 1301 AND 1399))
							AND bettype IN (31, 32, 33, 41, 42, 43) THEN (winlost - abs(actual_stake) + playercomm) * e.ActualRate2
						ELSE 0
						END
						*
						CASE
						WHEN bettype = 911 THEN @DeductedPercentage
						ELSE 1
						END), 0) AS WinLost
			,isnull(sum(CASE 
						WHEN bettype = 911 THEN 0
						WHEN (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))  THEN isnull(abs(stake) * e.ActualRate2, 0)
						ELSE 0
						END), 0) AS Turnover
			,isnull(sum(CASE 
						WHEN (
								@SportType = @SportsBookID
								OR @SportType = 0
								)
							AND bettype = 22004 THEN (winlost - abs(actual_stake)) * e.ActualRate2
						ELSE 0
						END), 0) AS Bonus
			,isnull(sum(CASE 
						WHEN (
								@SportType = @SportsBookID
								OR @SportType = 0
								)
							AND bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN (winlost - abs(actual_stake)) * e.ActualRate2
						ELSE 0
						END), 0) AS Adjustment
			,isnull(sum(CASE 
						WHEN (
								@SportType = @SportsBookID
								OR @SportType = 0
								)
							AND bettype = 22001 THEN (winlost - abs(actual_stake)) * e.ActualRate2
						ELSE 0
						END), 0) * e.DepositPercent + abs(- isnull(sum(CASE 
							WHEN (
									@SportType = 0
									OR @SportType = @SportsBookID
									)
								AND bettype IN (22002, 22003) THEN (winlost - abs(actual_stake)) * e.ActualRate2
							ELSE 0
							END), 0)) * e.WithdrawalPercent AS PSP
			,e.ActualRate2 AS AffExRate
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN (
			SELECT IBCCustID
				,Currency
				,UserName
				,IBCUserName
			FROM MemberInfo WITH (NOLOCK)
			WHERE AffID = @AffID
				AND IsRemoved = 0
			) m
			ON m.IBCCustID = b.CustId
			INNER JOIN Exchange_current e WITH (NOLOCK)
			ON m.Currency = e.Exchangeid
		WHERE b.Winlostdate = @MonthDate
			AND b.ruben = 1
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
			AND b.bettype NOT BETWEEN 912 AND 914 -- Cash Out (keep 911)  
			AND b.StatusID NOT IN (101, 102, 103, 121, 1)
			AND b.custid > 0
		GROUP BY b.CustID
			,m.UserName
			,m.IBCUserName
			,e.DepositPercent
			,e.WithdrawalPercent
			,e.ActualRate2
	END
	ELSE
	BEGIN --Currdate for Casino sport just need to get in MemberDaily table
		SELECT m.IBCCustId AS CustID
			,m.UserName
			,m.IBCUserName
			,isnull(Sum(d.Winlost * AffExRate), 0) AS winlost
			,isnull(Sum(d.Withdrawal * AffExRate), 0) AS Withdrawal
			,isnull(Sum(d.TurnOver * AffExRate), 0) AS Turnover
			,isnull(Sum(d.Deposit * AffExRate), 0) AS Deposit
			,isnull(Sum(d.Withdrawal * AffExRate), 0) AS Withdrawal
			,isnull(Sum(d.Bonus * AffExRate), 0) AS Bonus
			,isnull(Sum(d.Adjustment * AffExRate), 0) AS Adjustment
			,isnull(Sum(d.PSP * AffExRate), 0) AS PSP
			,d.AffExRate
		FROM MemberDaily d WITH (NOLOCK)
			INNER JOIN MemberInfo m WITH (NOLOCK)
			ON d.IBCCustId = m.IBCCustId
		WHERE d.AffID = @AffID
			AND d.winlostdate = @MonthDate
			AND (CASE 
				WHEN @SportType = 0 THEN 1
				WHEN @SportType = SportType THEN 1
				ELSE 0 END
				) = 1
			AND (
				isnull(d.TurnOver, 0) <> 0
				OR isnull(d.Winlost, 0) <> 0
				OR isnull(d.Bonus, 0) <> 0
				OR isnull(d.Adjustment, 0) <> 0
				OR isnull(d.PSP, 0) <> 0
				OR isnull(d.Marketing, 0) <> 0
				OR isnull(d.Deposit, 0) <> 0
				OR isnull(Withdrawal, 0) <> 0
				)
		GROUP BY m.IBCCustId
			,m.UserName
			,m.IBCUserName
			,d.AffExRate
	END
END
GO