ALTER PROCEDURE [dbo].[Aff_CalMonthlyEarningCurrent] (
	@AffID INT
	,
	--@TodayPSP money=0, --PSP Get from Deposit DB
	@QualifiedMembers INT = 0 OUTPUT
	,@CAQualifiedMembers INT = 0 OUTPUT
	,@CAAmount MONEY = 0 OUTPUT
	,-- Amount with Marketing Fee included for Casino
	@Amount MONEY OUTPUT
	,-- Amount with Marketing Fee included
	@SPCommission FLOAT OUTPUT
	,@HRCommission FLOAT OUTPUT
	,@CACommission FLOAT = 0 OUTPUT
	)
AS
/*
	Task : Calculate monthy earning for affiliate current month
	DB: DB052.Affiliate_12BET
	Author : Peter@20090909
	-20100709@Peter:
					http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890&st=0&sk=t&sd=a&start=10
					Change the way to calculation:

					if CNW <0 then we must also use the condition of Qualifying Members ( old way does not have)
					 and the minimum commission in this case is 10%  if the qualifying members <5.
	 -20100927@Peter:
				 http://ccs.sunplus.vn/viewtopic.php?f=4&t=3845&p=19236#p19236  
				 Change the way to calculation:
				   PSP=deposit * depositpercent + withdrawal * withdrawalpercent
					  For European Currencies: EURO,AUD,GBP, US$
						  + depositpercent=0.06
						  + withdrawalpercent=0.03
					  For Asian Currencies:
						  + depositpercent=0.02
						  + withdrawalpercent=0.02
				   PSP now follow tier commission
				   New Fee:  Odds Management Fee = 17 % MemberWinlost
				   CNW= MemberWinlost - Odds Management Fee - Marketing Fee - PSP Fee
				   From CNW => AComm
				   Affiliate Earning=(CNW - Bonus - Adjustement)* AComm                 
	- 20101228@Henry: change bettype to new range
	- 20110816@Johnny: Output one more result "QualifiedMembers".
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20120223@Peter:
					 http://ccs.nexcel.vn/viewtopic.php?f=4&t=6247
					Final decision confirmed by our Management :
					1)To take away the ‘Adjustment’ formula in the Affiliate System : Affiliate Monthly Commission = (Company Net Winloss - Bonus) * commission percent
					2) Although the ‘Adjustment’ is taken out from the formula but we still maintain this column inside the system.
	- 20120511@Peter : Add Casino Commission to formula
					http://ccs.nexcel.vn/viewtopic.php?f=4&t=6320

	- 20120115@Peter : Modify Casino negative commission
					 http://ccs.nexcel.vn/viewtopic.php?f=6&t=7524&p=35897#p35897 
	- 20140403@Bobby:  exclude Keno product & other sports

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Today SMALLDATETIME
		,@FirstDay SMALLDATETIME
		,@LastDay SMALLDATETIME
		,@TransType INT
		,@SportsBookID INT
		,@HorseRacingID INT
		,@CasinoID INT
		,@MarketingTransType INT
		,@DeductionPercent FLOAT
		,@MinimumNegativeCommission FLOAT
		,@MinimumNegativeCasinoCommission FLOAT

	SELECT @MinimumNegativeCommission = 0.1
		,@MinimumNegativeCasinoCommission = 0.05

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')
		,@CasinoID = dbo.Aff_GetSportID('Casino')

	SELECT @FirstDay = cast(cast(year(getdate()) AS VARCHAR(5)) + '-' + cast(Month(getdate()) AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)

	--Get last day of inputted month
	SELECT @Today = convert(VARCHAR(12), current_timestamp)

	SELECT @LastDay = dateadd(d, - 1, @Today)

	DECLARE @AffSummary TABLE (
		SportID INT
		,MemWinlost MONEY
		,MemBonus MONEY
		,MemAdjustment MONEY
		,MemPSP MONEY
		,Marketing MONEY
		,MemDeposit MONEY
		,MemTurnover MONEY
		,Commission DECIMAL(9, 8)
		,TotalQM INT
		,NetWinlost MONEY
		,BonusPercent FLOAT
		,MarketingPercent FLOAT
		,AdjustmentPercent FLOAT
		,PSPPercent FLOAT
		,OddsFeePercent FLOAT
		,PlayTechRoyaltiesPercent FLOAT
		)
	DECLARE @GroupID INT

	SELECT @GroupID = GroupID
	FROM AffInfo(NOLOCK)
	WHERE AffID = @AffID

	--No need to get PSP from Deposit DB
	/*Select @TodayPSP=Sum(PSP * AffExRate)
   from MemberDaily (nolock)
  where AffID=@AffID and WinlostDate=@Today*/
	INSERT INTO @AffSummary (
		SportID
		,MemWinlost
		,MemBonus
		,MemAdjustment
		,MemPSP
		,Marketing
		,MemDeposit
		,MemTurnover
		,TotalQM
		,BonusPercent
		,MarketingPercent
		,AdjustmentPercent
		,PSPPercent
		,OddsFeePercent
		,PlayTechRoyaltiesPercent
		)
	SELECT r.SportType AS SportID
		,sum(isnull(r.Winlost, 0)) AS MemWinlost
		,sum(isnull(r.Bonus, 0)) AS MemBonus
		,sum(isnull(r.Adjustment, 0)) AS MemAdjustment
		,sum(isnull(r.PSP, 0)) AS MemPSP
		,sum(isnull(r.Marketing, 0)) AS Marketing
		,sum(isnull(r.Deposit, 0)) AS MemDeposit
		,sum(isnull(r.Turnover, 0)) AS MemTurnover
		,sum(CASE 
				WHEN r.TurnOver >= s.QMTurnOver
					AND r.Deposit >= s.QMDeposit THEN 1
				ELSE 0
				END) AS TotalQM
		,dbo.Aff_GetDeductionPercent(@AffID, r.SportType, 'Bonus', NULL) AS BonusPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.SportType, 'Marketing', NULL) AS MarketingPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.SportType, 'Adjustment', NULL) AS AdjustmentPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.SportType, 'PSP', NULL) AS PercentPSP
		,dbo.Aff_GetDeductionPercent(@AffID, r.SportType, 'Odds Fee', NULL) AS OddsFeePercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.SportType, 'PlayTech Royalties', NULL) AS PlayTechRoyaltiesPercent
	FROM (
		SELECT md.IBCCustID
			,md.SportType
			,sum(isnull(md.Winlost, 0) * isnull(md.AffExRate, 1)) AS Winlost
			,sum(isnull(md.Bonus, 0) * isnull(md.AffExRate, 1)) AS Bonus
			,sum(isnull(Adjustment, 0) * isnull(AffExRate, 1)) AS Adjustment
			,sum(isnull(PSP, 0) * isnull(AffExRate, 1)) AS PSP
			,sum(isnull(Marketing, 0) * isnull(AffExRate, 1)) AS Marketing
			,sum(isnull(TurnOver, 0) * isnull(AffExRate, 1)) AS TurnOver
			,sum(isnull(Deposit, 0) * isnull(AffExRate, 1)) AS Deposit
		FROM (
			SELECT IBCCustID
				,SportType
				,Winlost
				,Bonus
				,Adjustment
				,PSP
				,Marketing
				,TurnOver
				,AffExRate
				,Currency
				,Deposit
			FROM MemberDaily md(NOLOCK)
			WHERE AffID = @AffID
				AND WinlostDate BETWEEN @FirstDay AND @LastDay
			
			UNION ALL
			-- addd casino data for current day
			SELECT IBCCustID
				,SportType
				,Winlost
				,Bonus
				,Adjustment
				,PSP
				,Marketing
				,TurnOver
				,AffExRate
				,Currency
				,Deposit
			FROM MemberDaily md(NOLOCK)
			WHERE AffID = @AffID
				AND WinlostDate = @Today
				AND SportType NOT IN (@SportsBookID, @HorseRacingID)
			
			UNION ALL
			SELECT ci.IBCCustID
				,CASE 
					WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN @HorseRacingID
					ELSE @SportsBookID
					END AS SportType
				,isnull(sum(CASE bettype
							WHEN 22001 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
							ELSE 0
							END), 0) AS Deposit
				,isnull(sum(CASE 
							WHEN BetType <= 999 
								AND ruben = 1 THEN (b.Winlost - abs(b.actual_stake))
							ELSE 0
							END), 0) AS Winlost
				,isnull(sum(CASE bettype
							WHEN 22004 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
							ELSE 0
							END), 0) AS Bonus
				,isnull(sum(CASE 
							WHEN bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
							ELSE 0
							END), 0) AS Adjustment
				,isnull(sum(CASE bettype
							WHEN 22001 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
							ELSE 0
							END), 0) * e.DepositPercent + abs(- isnull(sum(CASE 
								WHEN bettype IN (22002, 22003) THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
								ELSE 0
								END), 0) * e.WithdrawalPercent) AS PSP
				,0 AS Marketing
				,isnull(sum(CASE 
							WHEN BetType <= 999  THEN (CASE 
									WHEN Bettype IN (33, 43)
										AND liveawayscore = 0 THEN isnull(abs(stake), 0) / 2 * e.Actualrate2
									ELSE isnull(abs(stake), 0) END
									)
							ELSE 0
							END), 0) AS Turnover
				,e.Actualrate2 AS AffExRate
				,e.exchangeid AS exchangeid
			FROM MemberInfo ci WITH (NOLOCK)
				INNER JOIN bodb02.dbo.bettrans b WITH (NOLOCK)
				ON b.custid = ci.IBCCustID
				INNER JOIN Exchange_Current e WITH (NOLOCK)
				ON e.exchangeid = ci.currency
			WHERE b.winlostdate = @Today
				AND ci.AffID = @AffID
				AND ci.IsRemoved = 0
				AND (
					Bettype <= 999
					OR Bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
				)
				AND bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game
				AND bettype NOT IN (1000) --games
				AND bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
				AND bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
				AND bettype NOT BETWEEN 1501 AND 1599 -- Keno  
				AND b.StatusID NOT IN (101, 102, 103, 121, 1)
				--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'  
				AND b.custid > 0
			GROUP BY ci.IBCCustID
				,CASE 
					WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN @HorseRacingID
					ELSE @SportsBookID
					END
				,e.Actualrate2
				,e.exchangeid
				,e.DepositPercent
				,e.WithdrawalPercent
			) md
		GROUP BY IBCCustID
			,SportType
		) r
		LEFT JOIN SportType s(NOLOCK)
		ON s.SportID = r.SportType
	GROUP BY r.SportType

	--Choose commission value and calculate Total Balance after deduction for each Affiliate and SportID
	UPDATE a
	SET a.NetWinlost = (- isnull(a.MemWinlost, 0) - isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 0) - abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 0) - abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 0) - abs(isnull(a.MemWinlost, 0)) * isnull(a.PlayTechRoyaltiesPercent, 0))
		,a.commission = isnull((
				SELECT TOP (1) Commission
				FROM (
					SELECT isnull((
								SELECT Commission
								FROM GroupSetting(NOLOCK)
								WHERE GroupID = @GroupID
									AND SportType = a.SportID
									AND floor(abs(- isnull(a.MemWinlost, 0) - isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 0) - abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 0) - abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 0) - abs(isnull(a.MemWinlost, 0)) * isnull(a.PlayTechRoyaltiesPercent, 0))) BETWEEN MinAmount AND MaxAmount
								), 0) AS Commission
					
					UNION ALL
					SELECT isnull((
								SELECT TOP (1) Commission
								FROM GroupSetting(NOLOCK)
								WHERE GroupID = @GroupID
									AND SportType = a.SportID
									AND a.TotalQM BETWEEN MinQM AND MaxQM
								), 0) AS Commission
					) t
				ORDER BY t.Commission ASC
				), 0)
	FROM @AffSummary a

	IF @GroupID NOT IN (
			SELECT groupId
			FROM CommGroup WITH (NOLOCK)
			WHERE GroupName = 'NoCommission'
			)
	BEGIN
		UPDATE a
		SET a.Commission = (CASE 
				WHEN a.SportID = @CasinoID THEN @MinimumNegativeCasinoCommission
				ELSE @MinimumNegativeCommission END
				)
		FROM @AffSummary a
		WHERE a.NetWinlost < 0
			AND a.Commission = 0
			AND a.SportID IN (
				SELECT DISTINCT SportID
				FROM GroupSetting(NOLOCK)
				WHERE GroupID = @GroupID
				)
	END

	/*select @Amount=sum((a.NetWinlost- Cast(a.HasBonus as int)* isnull(a.MemBonus,0)*isnull(a.BonusPercent,1) - Cast(a.HasAdjustment as int) *  isnull(a.MemAdjustment,0) * isnull(a.AdjustmentPercent,1))*isnull(a.Commission,0))*/
	SELECT @Amount = sum((NetWinlost - isnull(a.MemBonus, 0) * isnull(a.BonusPercent, 1)) * isnull(Commission, 0))
	FROM @AffSummary a
	WHERE SportID = @SportsBookID

	SELECT @CAAmount = sum((NetWinlost - isnull(a.MemBonus, 0) * isnull(a.BonusPercent, 1)) * isnull(Commission, 0))
	FROM @AffSummary a
	WHERE SportID = @CasinoID

	SELECT @SPCommission = a.Commission
		,@QualifiedMembers = TotalQM
	FROM @AffSummary a
	WHERE SportID = @SportsBookID

	SELECT @HRCommission = a.Commission
	FROM @AffSummary a
	WHERE SportID = @HorseRacingID

	SELECT @CACommission = a.Commission
		,@CAQualifiedMembers = TotalQM
	FROM @AffSummary a
	WHERE SportID = @CasinoID
END
GO

GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbAdminNet]
GO

GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbDownlineNetView]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [vnteam]
