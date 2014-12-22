ALTER FUNCTION [dbo].[Aff_CommissionForCurrentMonth] (@AffID INT)
RETURNS @AffComm TABLE (
	SportID INT
	,TotalQM INT
	,commission DECIMAL(9, 8)
	,amount MONEY
	,MemDeposit MONEY
	,MemTurnOver MONEY
	,MemWinlost MONEY
	,NetWinlost MONEY
	)
AS
/*
	Revisions:
		- 20120514@Peter : Apply new formula according to Joycee's request
			 IF Winloss in SPORTSBOOK > winloss in Casino then 		 
				   CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee - PSP Fe
					Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee
			 else
				   CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee
				   Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee - PSP Fee
		- 20140403@Bobby:  exclude Keno product & other sports
		- 20141218@Bobby: Update SS's bettype
*/
BEGIN
	DECLARE @Today SMALLDATETIME
		,@FirstDay SMALLDATETIME
		,@LastDay SMALLDATETIME
		,@SportsBookID INT
		,@HorseRacingID INT
		,@CasinoID INT
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
		,IsPSPIncluded INT -- flag to check PSP Fee is included or not for this product   
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
		,AdjustmentPercent
		,MarketingPercent
		,PSPPercent
		,OddsFeePercent
		,PlayTechRoyaltiesPercent
		,IsPSPIncluded
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
		,dbo.Aff_GetDeductionPercent(@AffID, r.SportType, 'Adjustment', NULL) AS AdjustmentPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.SportType, 'Marketing', NULL) AS MarketingPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.SportType, 'PSP', NULL) AS PercentPSP
		,dbo.Aff_GetDeductionPercent(@AffID, r.SportType, 'Odds Fee', NULL) AS OddsFeePercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.SportType, 'PlayTech Royalties', NULL) AS PlayTechRoyaltiesPercent
		,0 AS IsPSPIncluded
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
				,Deposit
				,Winlost
				,Bonus
				,Adjustment
				,PSP
				,Marketing
				,TurnOver
				,AffExRate
				,Currency
			FROM MemberDaily md(NOLOCK)
			WHERE AffID = @AffID
				AND WinlostDate BETWEEN @FirstDay AND @LastDay
			-- addd casino data for current day  
			
			UNION ALL
			SELECT IBCCustID
				,SportType
				,Deposit
				,Winlost
				,Bonus
				,Adjustment
				,PSP
				,Marketing
				,TurnOver
				,AffExRate
				,Currency
			FROM MemberDaily md(NOLOCK)
			WHERE AffID = @AffID
				AND WinlostDate = @Today
				AND SportType = @CasinoID
			
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
							WHEN (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
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
						WHEN (bettype <= 999 
								OR ( bettype BETWEEN 1301 AND 1399)
							) THEN isnull(abs(stake), 0)
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
					b.bettype <= 999
					OR ( b.bettype BETWEEN 1301 AND 1399) -- SS tickets
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

	-- Decide which SportID should include PSP
	DECLARE @PSP MONEY
		,@maxwinlost MONEY
		,@maxWinlostSportID INT
		,@PSPPercent FLOAT

	SELECT @PSP = MemPSP
		,@PSPPercent = PSPPercent
	FROM @AffSummary a
	WHERE a.SportID = @SportsBookID

	SELECT @maxwinlost = max(abs(MemWinlost))
	FROM @AffSummary

	SELECT TOP (1) @maxWinlostSportID = sportid
	FROM @AffSummary
	WHERE abs(MemWinlost) = @maxwinlost
		AND SportID <> @SportsBookID

	SELECT @maxWinlostSportID = coalesce(@maxWinlostSportID, @SportsBookID)
		,@PSP = coalesce(@PSP, 0)
		,@PSPPercent = coalesce(@PSPPercent, 0)

	UPDATE a
	SET a.IsPSPIncluded = 1
	FROM @AffSummary a
	WHERE a.sportid = @maxWinlostSportID

	--Choose commission value and calculate Total Balance after deduction for each Affiliate and SportID  
	UPDATE a
	SET a.NetWinlost = (- isnull(a.MemWinlost, 0) - isnull(@PSP, 0) * @PSPPercent * a.IsPSPIncluded - abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 0) - abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 0) - abs(isnull(a.MemWinlost, 0)) * isnull(a.PlayTechRoyaltiesPercent, 0))
		,a.commission = isnull((
				SELECT TOP (1) Commission
				FROM (
					SELECT isnull((
								SELECT Commission
								FROM GroupSetting(NOLOCK)
								WHERE GroupID = @GroupID
									AND SportType = a.SportID
									AND floor(abs(- isnull(a.MemWinlost, 0) - isnull(@PSP, 0) * @PSPPercent * a.IsPSPIncluded - abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 0) - abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 0) - abs(isnull(a.MemWinlost, 0)) * isnull(a.PlayTechRoyaltiesPercent, 0))) BETWEEN MinAmount AND MaxAmount
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

	UPDATE a
	SET a.Commission = (CASE 
			WHEN a.SportID = @CasinoID THEN @MinimumNegativeCasinoCommission
			ELSE @MinimumNegativeCommission END
			)
	FROM @AffSummary a
	WHERE a.NetWinlost < 0
		AND a.Commission = 0
		AND [dbo].[IsZeroCommissionGroup](@GroupID, @Today) = 0
		AND a.SportID IN (
			SELECT DISTINCT SportID
			FROM GroupSetting(NOLOCK)
			WHERE GroupID = @GroupID
			)

	INSERT INTO @AffComm (
		SportID
		,TotalQM
		,commission
		,amount
		,MemDeposit
		,MemTurnOver
		,MemWinlost
		,NetWinlost
		)
	SELECT sportid
		,TotalQM
		,commission
		,sum((NetWinlost - isnull(a.MemBonus, 0) * isnull(a.BonusPercent, 1)) * isnull(Commission, 0))
		,SUM(ISNULL(a.MemDeposit, 0))
		,SUM(ISNULL(a.MemTurnover, 0))
		,SUM(ISNULL(a.MemWinlost, 0))
		,SUM(ISNULL(a.NetWinlost, 0))
	FROM @AffSummary a
	GROUP BY sportid
		,TotalQM
		,commission

	RETURN
END
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_CommissionForCurrentMonth] TO [vnteam] AS [dbo]
