ALTER PROCEDURE [dbo].[Aff_CheckSum] 
	@Date		SMALLDATETIME	= NULL
	,@IsMatch	BIT				= 1 OUTPUT
AS
/*
Created: @VinhTrinh
Task :
	- Check the summary of winlost + bonus + turnover + deposit + withdrawal + Adjustment + outstanding of MemberDaily table with bettrans
	- Check on the 9th day of every month to make sure the job is run exactly.
DB: DB052.Affiliate_12BET
Original: [Aff_CheckSum]
Revisions:    
		 - 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
		 - 20120606@Peter : Exclude waiting tickets
		 - 20120717@Johnny : Exclude Horse racing data and run for yesterday only
		 - 20120718@Johnny : Add parameter @Date to Check
		 - 20130306@Johnny: Sportbook bettype is less than 999 and exclude bettype from 31 to 120
		 - 20141218@Bobby: Update SS's bettype
*/
BEGIN
	SET NOCOUNT ON

	--Bettrans variables
	DECLARE @BT_Deposit MONEY
		,@BT_Withdrawal MONEY
		,@BT_Bonus MONEY
		,@BT_Adjustment MONEY
		,@BT_Turnover MONEY
		,@BT_Winlost MONEY
	--MemberDaily variables
	DECLARE @MD_Deposit MONEY
		,@MD_Withdrawal MONEY
		,@MD_Bonus MONEY
		,@MD_Adjustment MONEY
		,@MD_Turnover MONEY
		,@MD_Winlost MONEY
	DECLARE @MoveBetsDay SMALLDATETIME
	--Check sum data for the day before yesterday
	DECLARE @PreviousDate SMALLDATETIME
		,@SportbookId INT

	SELECT @PreviousDate = isnull(@Date, dateadd(d, 0, datediff(d, 0, current_timestamp) - 2))

	SELECT @SportbookId = dbo.Aff_GetSportID('SportsBook')

	SELECT @MoveBetsDay = max(eventdate)
	FROM bodb02.dbo.match14 WITH (NOLOCK)

	SELECT @BT_Deposit = isnull(sum(CASE bettype
					WHEN 22001 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
					ELSE 0
					END), 0)
		,@BT_Withdrawal = - isnull(sum(CASE 
					WHEN bettype IN (22002, 22003) THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
					ELSE 0
					END), 0)
		,@BT_Bonus = isnull(sum(CASE bettype
					WHEN 22004 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
					ELSE 0
					END), 0)
		,@BT_Adjustment = isnull(sum(CASE 
					WHEN bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
					ELSE 0
					END), 0)
		,@BT_Turnover = isnull(sum(CASE 
					WHEN (bettype < 999 OR ( b.bettype BETWEEN 1301 AND 1399)) THEN isnull(abs(stake), 0)
					ELSE 0
					END), 0)
		,@BT_Winlost = isnull(sum(CASE 
					WHEN (bettype < 999 OR ( b.bettype BETWEEN 1301 AND 1399))
						AND ruben = 1 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0) + isnull(playercomm, 0)
					ELSE 0
					END), 0)
	FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN (
		SELECT IBCCustID
		FROM MemberInfo m WITH (NOLOCK)
		WHERE CreatedDate IS NOT NULL
			AND IBCCustID NOT IN (
				SELECT IBCCustID
				FROM MemberRemoval WITH (NOLOCK)
				WHERE datediff(mm, RemovedDate, @PreviousDate) >= 0
				)
			AND datediff(d, CreatedDate, @PreviousDate) >= 0
		) m ON m.IBCCustID = b.custid
	WHERE winlostdate = @PreviousDate
		AND (
			bettype <= 999
			OR ( bettype BETWEEN 1301 AND 1399) -- SS tickets
			OR bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
		) --get SB only
		AND bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
		AND bettype NOT IN (1000) --games
		AND bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
		AND bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
		AND bettype NOT BETWEEN 1501 AND 1599 -- Keno  
		AND StatusID NOT IN (101, 102, 103, 121, 1)


	IF (@PreviousDate <= @MoveBetsDay)
	BEGIN --Select Turnover and winlost again in the date that equal or less than Move bet date
		SELECT @BT_Turnover = sum(isnull(abs(stake), 0))
			,@BT_Winlost = isnull(sum(CASE 
						WHEN ruben = 1 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0) + isnull(playercomm, 0)
						ELSE 0
						END), 0)
		FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
			INNER JOIN (
			SELECT IBCCustID
				,AffID
			FROM MemberInfo m WITH (NOLOCK)
			WHERE CreatedDate IS NOT NULL
				AND datediff(d, CreatedDate, @PreviousDate) >= 0
				AND IBCCustID NOT IN (
					SELECT IBCCustID
					FROM MemberRemoval WITH (NOLOCK)
					WHERE datediff(mm, RemovedDate, @PreviousDate) >= 0
					)
			) m ON m.IBCCustID = b.custid
		WHERE winlostdate = @PreviousDate
			AND (bettype < 999
				OR ( bettype BETWEEN 1301 AND 1399) -- SS tickets
			)
			AND bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
			AND bettype NOT IN (1000) --games
			AND bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
			AND bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
			AND bettype NOT BETWEEN 1501 AND 1599 -- Keno  
			AND StatusID NOT IN (101, 102, 103, 121, 1)
	END

	SELECT @MD_Deposit = isnull(sum(isnull(Deposit, 0)), 0)
		,@MD_Withdrawal = isnull(sum(isnull(Withdrawal, 0)), 0)
		,@MD_Bonus = isnull(sum(isnull(Bonus, 0)), 0)
		,@MD_Adjustment = isnull(sum(isnull(Adjustment, 0)), 0)
		,@MD_Turnover = isnull(sum(isnull(Turnover, 0)), 0)
		,@MD_Winlost = isnull(sum(isnull(Winlost, 0)), 0)
	FROM MemberDaily NOLOCK
	WHERE WinlostDate = @PreviousDate
		AND sporttype = @SportbookId

	IF (
			@MD_Deposit <> @BT_Deposit
			OR @MD_Withdrawal <> @BT_Withdrawal
			OR @MD_Bonus <> @BT_Bonus
			OR @MD_Adjustment <> @BT_Adjustment
			OR @MD_Turnover <> @BT_Turnover
			OR @MD_Winlost <> @BT_Winlost
			)
	BEGIN
		SELECT @IsMatch = 0

		SELECT 'Summary Data in Bettrans' AS Description
			,@BT_Deposit AS Deposit
			,@BT_Withdrawal AS Withdrawal
			,@BT_Bonus AS Bonus
			,@BT_Adjustment AS Adjustment
			,@BT_Turnover AS Turnover
			,@BT_Winlost AS Winlost
		
		UNION ALL
		SELECT 'Summary Data in MemberDaily' AS Description
			,@MD_Deposit
			,@MD_Withdrawal
			,@MD_Bonus
			,@MD_Adjustment
			,@MD_Turnover
			,@MD_Winlost

		RETURN
	END

	SELECT @IsMatch = 1
END
GO

GRANT EXECUTE ON [dbo].[Aff_CheckSum] TO [bodbAdminNet]
GO


