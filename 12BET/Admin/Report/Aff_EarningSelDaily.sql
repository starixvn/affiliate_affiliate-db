/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_EarningSelDaily] 
	@AffID INT
	,@SportType TINYINT = 0
	,@monthdate SMALLDATETIME
	,@MarketingPercent FLOAT = 0 OUTPUT
	,@OddsFeePercent FLOAT = 0 OUTPUT
	,@PSPFeePercent FLOAT = 0 OUTPUT
	,@CasinoMarketingPercent FLOAT = 0 OUTPUT
	,@PLayTechFeePercent FLOAT = 0 OUTPUT
AS

/*
	Created: 200900911@VinhTrinh 
	Task : [description of SP]  
	DB: DBAFF12BET.Affiliate_12BET
	
	Revisions:  		
		- Get data for daily report from table AffDaily instead of MemberDaily
		- 20100520@Johnny: apply StatusID in bettrans table
		- 20100930@Peter: Change the new formula for displayed winlost
					Winlost on Aff site=Winlost-Odds Management - Marketing cost -  PSP
					--The formula change since 1 Oct 2010--need to consider a new column MemWinlostFake on MemberDaily table if it is changed again
					MemWinlostFake need to be updated on TaskMemberDaily
		- 20101228@Henry: change bettype to new range
		- 20111031@Peter: Exclude Number Game from Sportsbook commission (bettype from [81-120])
		- 20120606@Peter: Exclude waiting tickets
		- 20140403@Bobby: Exclude Keno product & other sports
		- 20141218@Bobby: Update SS's bettype & fix Casiso time range
		- 20150106@Bobby: Update WL fake
		- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]
		- 20180222@Percy: Change range of winlostdate when getting data [RedmineID: #90861]

	Param's Explanation:  
		• @custid: affliate Id  
		• @monthdate: Month date need to view.
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @CurrDate SMALLDATETIME
		,@PrevCurrDate SMALLDATETIME
		,@fromdate SMALLDATETIME
		,@todate SMALLDATETIME
		,@SportsBookID INT
		,@HorseRacingID INT
		,@CasinoId INT --,@MarketingPercent float,@OddsFeePercent float
		,@GroupId INT
		,@DeductedPercentage DECIMAL(9,8)
		
	CREATE TABLE #AffDailyWL(
		WinlostDate 	SMALLDATETIME
		,SportId		INT
		,Deposit 		MONEY
		,Withdrawal		MONEY
		,MemberWinlost	MONEY
		,MemWinlostFake	MONEY
		,Bonus			MONEY
		,Adjustment		MONEY
		,PSP			MONEY
	);
	CREATE TABLE #AffComm(
		SportID			INT
		,NetWinlost		MONEY
	);

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')
		,@CasinoId = dbo.Aff_GetSportID('Casino')

	SET @CurrDate = convert(VARCHAR(10), CURRENT_TIMESTAMP, 120)
	SET @PrevCurrDate = DATEADD(DAY, -1, @CurrDate)

	SELECT @monthdate = dateadd(d, datediff(d, 0, @monthdate), 0)

	SELECT @MarketingPercent = isnull(dbo.[Aff_GetDeductionPercent](@AffId, @SportsBookID, 'Marketing', @monthdate), 0)

	SELECT @OddsFeePercent = isnull(dbo.[Aff_GetDeductionPercent](@AffId, @SportsBookID, 'Odds Fee', @monthdate), 0)

	SELECT @PSPFeePercent = isnull(dbo.[Aff_GetDeductionPercent](@AffId, @SportsBookID, 'PSP', @monthdate), 0)

	SELECT @PLayTechFeePercent = isnull(dbo.[Aff_GetDeductionPercent](@AffId, @CasinoId, 'PlayTech Royalties', @monthdate), 0)

	SELECT @CasinoMarketingPercent = isnull(dbo.[Aff_GetDeductionPercent](@AffId, @CasinoId, 'Marketing', @monthdate), 0)

	SELECT @GroupId = GroupId FROM dbo.AffInfo WITH(NOLOCK) WHERE AffId = @AffId
	SELECT @DeductedPercentage = DeductedPercentage FROM dbo.DeductionSetting WITH(NOLOCK) WHERE GroupId = @GroupId AND DeductionID = 9
	
	IF @DeductedPercentage IS NULL
		SELECT @DeductedPercentage = 0

	SELECT @fromdate = DATEADD(mm, DATEDIFF(m, 0, @monthdate), 0)

	SELECT @todate = CASE 
			WHEN @monthdate >= @PrevCurrDate THEN dateadd(d, - 1, @PrevCurrDate)
			ELSE @monthdate
			END

	IF @monthdate >= @PrevCurrDate
	BEGIN
		-- query Casino
		IF(@SportType IN(0, @CasinoId))
		BEGIN
			INSERT INTO #AffDailyWL
			SELECT d.winlostdate
				,@CasinoId AS SportId
				,sum(d.MemDeposit) AS Deposit
				,sum(d.MemWithdrawal) AS Withdrawal
				,sum(d.MemWinlost) AS MemberWinlost
				,sum(d.MemWinlostFake) AS MemWinlostFake
				,sum(d.MemBonus) AS Bonus
				,sum(d.MemAdjustment) AS Adjustment
				,sum(d.MemPSP) AS PSP
			FROM AffDailySummary d WITH (NOLOCK)
			WHERE AffID = @AffID
				AND d.winlostdate BETWEEN @fromdate AND @CurrDate
				AND (SportId = @CasinoId)
				AND (
					isnull(MemTurnOver, 0) <> 0
					OR isnull(MemWinlost, 0) <> 0
					OR isnull(MemBonus, 0) <> 0
					OR isnull(MemAdjustment, 0) <> 0
					OR isnull(MemPSP, 0) <> 0
					OR isnull(MemMarketing, 0) <> 0
					OR isnull(MemDeposit, 0) <> 0
					OR isnull(MemWithdrawal, 0) <> 0
					)
			GROUP BY d.winlostdate
		END
		
		-- query sportsbook & HorseRacing
		IF(@SportType IN(0, @SportsBookID, @HorseRacingID))
		BEGIN
			
			INSERT INTO #AffDailyWL
			SELECT d.winlostdate
				,@SportsBookID AS SportId
				,sum(d.MemDeposit) AS Deposit
				,sum(d.MemWithdrawal) AS Withdrawal
				,sum(d.MemWinlost) AS MemberWinlost
				,sum(d.MemWinlostFake) AS MemWinlostFake
				,sum(d.MemBonus) AS Bonus
				,sum(d.MemAdjustment) AS Adjustment
				,sum(d.MemPSP) AS PSP
			FROM AffDailySummary d WITH (NOLOCK)
			WHERE AffID = @AffID
				AND d.winlostdate BETWEEN @fromdate AND @todate
				AND (SportId = @SportsBookID)
				AND (
					isnull(MemTurnOver, 0) <> 0
					OR isnull(MemWinlost, 0) <> 0
					OR isnull(MemBonus, 0) <> 0
					OR isnull(MemAdjustment, 0) <> 0
					OR isnull(MemPSP, 0) <> 0
					OR isnull(MemMarketing, 0) <> 0
					OR isnull(MemDeposit, 0) <> 0
					OR isnull(MemWithdrawal, 0) <> 0
					)
			GROUP BY d.winlostdate
			
			UNION ALL
			SELECT winlostdate
				,@SportsBookID AS SportId
				,sum(Deposit) AS Deposit
				,sum(Withdrawal) AS Withdrawal
				,sum(MemberWinlost) AS MemberWinlost
				,- sum(- isnull(MemberWinlost, 0) - PSP - abs(isnull(MemberWinlost, 0)) * @OddsFeePercent - abs(isnull(MemberWinlost, 0)) * @MarketingPercent) AS MemWinlostFake
				,sum(Bonus) AS Bonus
				,sum(Adjustment) AS Adjustment
				,sum(PSP) AS PSP
			FROM (
				SELECT b.winlostdate
					,isnull(sum(CASE 
								WHEN (
										@SportType = 0
										OR @SportType = @SportsBookID
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
								WHEN @SportType = 0
									AND (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))  THEN (winlost - abs(actual_stake) + playercomm) * e.ActualRate2
								WHEN @SportType = @SportsBookID
									AND (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
									AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN (winlost - abs(actual_stake) + playercomm) * e.ActualRate2
								WHEN @SportType = @HorseRacingID
									AND (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
									AND bettype IN (31, 32, 33, 41, 42, 43) THEN (winlost - abs(actual_stake) + playercomm) * e.ActualRate2
								ELSE 0
								END
								*
								CASE
								WHEN bettype = 911 THEN @DeductedPercentage
								ELSE 1
								END), 0) AS MemberWinLost
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
										@SportType = 0
										OR @SportType = @SportsBookID
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
				FROM bodb02.dbo.bettrans b WITH (NOLOCK)
					INNER JOIN (
						SELECT IBCCustID
							,Currency
						FROM MemberInfo WITH (NOLOCK)
						WHERE AffID = @AffID
							AND IsRemoved = 0
					) m ON m.IBCCustID = b.CustId
					INNER JOIN Exchange_current e WITH (NOLOCK) ON e.Exchangeid = m.Currency
				WHERE @SportType <> @CasinoId
					AND b.Winlostdate BETWEEN @PrevCurrDate AND @CurrDate
					AND b.winlostdate >= @fromdate
					AND b.ruben = 1
					AND (
						b.bettype <= 999
						OR ( b.bettype BETWEEN 1301 AND 1399)
						OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
						) --get SB only
					AND b.bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
					AND b.bettype NOT BETWEEN 912 AND 914 -- Cash Out (keep 911 only)
					AND b.StatusID NOT IN (101, 102, 103, 121, 1)
					AND b.custid > 0
				GROUP BY b.winlostdate
					,e.DepositPercent
					,e.WithdrawalPercent
				) t
			GROUP BY t.winlostdate
			ORDER BY winlostdate
		END
		
		INSERT INTO #AffComm (
			SportID
			,NetWinlost
		)
		SELECT SportID
			,NetWinlost
		FROM dbo.[Aff_CommissionForCurrentMonth](@AffID)
		WHERE @SportType = 0
			OR SportId = @SportType
	END
	ELSE
	BEGIN
		INSERT INTO #AffDailyWL
		SELECT d.winlostdate
			,SportId
			,sum(d.MemDeposit) AS Deposit
			,sum(d.MemWithdrawal) AS Withdrawal
			,sum(d.MemWinlost) AS MemberWinlost
			,sum(d.MemWinlostFake) AS MemWinlostFake
			,sum(d.MemBonus) AS Bonus
			,sum(d.MemAdjustment) AS Adjustment
			,sum(d.MemPSP) AS PSP
		FROM AffDailySummary d WITH (NOLOCK)
		WHERE AffID = @AffID
			AND d.winlostdate BETWEEN @fromdate AND @todate
			AND (CASE 
				WHEN @SportType = 0 THEN 1
				WHEN @SportType = SportId THEN 1
				ELSE 0 END
				) = 1
			AND (
				isnull(MemTurnOver, 0) <> 0
				OR isnull(MemWinlost, 0) <> 0
				OR isnull(MemBonus, 0) <> 0
				OR isnull(MemAdjustment, 0) <> 0
				OR isnull(MemPSP, 0) <> 0
				OR isnull(MemMarketing, 0) <> 0
				OR isnull(MemDeposit, 0) <> 0
				OR isnull(MemWithdrawal, 0) <> 0
				)
		GROUP BY d.winlostdate, SportId
		ORDER BY d.winlostdate

		INSERT INTO #AffComm (
			SportID
			,NetWinlost
		)
		SELECT SportID
			,NetWinlost
		FROM dbo.[Aff_CommissionForMonth](@AffID, MONTH(@monthdate), YEAR(@monthdate))
		WHERE @SportType = 0
			OR SportId = @SportType
	END
	
		
	;WITH MaxWLDate AS (
		SELECT SportId
			, MAX(WinlostDate) AS MaxWinlostDate
		FROM #AffDailyWL wl
		GROUP BY SportId
	)
	,SumWLExcludeMax AS (
		SELECT wl.SportId
			, SUM(MemWinlostFake) AS MemWinlostFake
		FROM #AffDailyWL wl
			INNER JOIN MaxWLDate md ON wl.SportId = md.SportId
		WHERE wl.WinlostDate <> md.MaxWinlostDate
		GROUP BY wl.SportId
	)
	UPDATE wl
		SET wl.MemWinlostFake = ac.NetWinlost - swl.MemWinlostFake
	FROM #AffDailyWL wl
		INNER JOIN MaxWLDate md ON wl.SportId = md.SportId AND wl.WinlostDate = md.MaxWinlostDate
		INNER JOIN SumWLExcludeMax swl ON wl.SportId = swl.SportId
		INNER JOIN #AffComm ac ON wl.SportId = ac.SportId
		
	-- select daily WL
	SELECT WinlostDate 
		,SUM(Deposit) 		AS Deposit
		,SUM(Withdrawal)		AS Withdrawal
		,SUM(MemberWinlost)		AS MemberWinlost
		,SUM(MemWinlostFake)	AS MemWinlostFake
		,SUM(Bonus)				AS Bonus
		,SUM(Adjustment)		AS Adjustment
		,SUM(PSP)				AS PSP
	FROM #AffDailyWL wl
	GROUP BY WinlostDate
	ORDER BY WinlostDate
	
	-- select sum WL
	SELECT SUM(Deposit) 		AS Deposit
		,SUM(Withdrawal)		AS Withdrawal
		,SUM(MemberWinlost)		AS MemberWinlost
		,nwl.NetWinlost			AS MemWinlostFake
		,SUM(Bonus)				AS Bonus
		,SUM(Adjustment)		AS Adjustment
		,SUM(PSP)				AS PSP
	FROM #AffDailyWL
	CROSS APPLY (
		SELECT SUM(NetWinlost) AS NetWinlost
		FROM #AffComm ac
	) AS nwl
	GROUP BY nwl.NetWinlost	
	
	DROP TABLE #AffDailyWL
	DROP TABLE #AffComm
END
GO