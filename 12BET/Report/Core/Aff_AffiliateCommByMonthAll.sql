/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_AffiliateCommByMonthAll] 
	@Month					TINYINT			
	,@Year					INT
	,@SportId 				TINYINT = NULL
AS
/*
Created:20141217@Bobby.Nguyen
Task: Calculate affiliate's earning commission by month
DB: DBAFFILIATE12BET/Affiliate_12Bet
Orgiginal: 

Revisions:    
	- 20141217@Bobby.Nguyen: Initial SP
	- 20150105@Bobby.Nguyen: Update fomular commission (check member WL between Sportsbook and Casino)
	- 20150227@DanNguyen: fix bug - wrong last date in case view current month
	- 20150825@Bobby.Nguyen:  Hotfix#42274 - Member is removal but not existing in memberemoval 
	- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]
	- 20180222@Percy: Change range of winlostdate when getting data [RedmineID: #90861]
*/  
BEGIN
	SET NOCOUNT ON
	
	IF (OBJECT_ID('tempdb..#AffList') IS NULL) RETURN
	
	DECLARE @FirstDay 						SMALLDATETIME
		,@LastDay 							SMALLDATETIME
		,@CurrentDay 						SMALLDATETIME
		,@PrevCurrentDay 					SMALLDATETIME
		,@MinimumNegativeCommission 		FLOAT
		,@HorseRacingID 					INT
		,@SportsBookID 						INT
		,@CasinoID 							INT
		,@MinimumNegativeCasinoCommission 	FLOAT
	
	
	
	SELECT @MinimumNegativeCommission 		= 0.1
		,@MinimumNegativeCasinoCommission 	= 0.05
		,@SportsBookID 						= dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID 					= dbo.Aff_GetSportID('Horse Racing')
		,@CasinoID 							= dbo.Aff_GetSportID('Casino')

	SELECT @FirstDay 	= CAST(CAST(@Year AS VARCHAR(5)) + '-' + CAST(@Month AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)
		,@LastDay 		= DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @FirstDay) + 1, 0))
		,@CurrentDay	= CAST(GETDATE() AS DATE)
		,@PrevCurrentDay = DATEADD(DAY, -1, @CurrentDay)

	IF (
			EXISTS (
				SELECT TOP (1) 1
				FROM dbo.AffCommission(NOLOCK)
				WHERE winlostdate = @LastDay
				)
			)
	BEGIN
		SELECT ac.AffId
			,ac.GroupID
			,SportID
			,ac.WinlostDate AS MonthDate
			,QualifiedMember AS TotalQM
			,commission AS CommRate
			,AffWinlost AS Commission
			,ac.MemberDeposit AS Deposit
			,MemberTurnOver As TurnOver
			,MemberWinlost AS Winlost
			,- MemberSum AS NetWinlost
		FROM dbo.AffCommission ac (NOLOCK)
			INNER JOIN #AffList a
			ON ac.AffID = a.AffId
		
		WHERE winlostdate = @LastDay
		ORDER BY ac.AffID
			,ac.SportID
			
		RETURN;
	END
	CREATE TABLE #MemberRealtime
	(
		IBCCustID							INT
		,SportType							TINYINT
		,AffID								INT
		,WinlostDate						SMALLDATETIME
		,Winlost							MONEY
		,Bonus								MONEY
		,Adjustment							MONEY
		,PSP								MONEY
		,Marketing							MONEY
		,TurnOver							MONEY
		,Deposit							MONEY
		,Withdrawal							MONEY
		,AffExRate							FLOAT
		,Currency							INT
	)
	
	CREATE TABLE #AffSummary (
		AffID INT
		,Currency INT
		,GroupID INT
		,SportID INT
		,MonthDate SMALLDATETIME
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
	IF(DATEDIFF(MM, @LastDay, @CurrentDay) = 0)
	BEGIN
		INSERT INTO #MemberRealtime (
			IBCCustID
			,SportType
			,AffID
			,WinlostDate
			,Deposit
			,Withdrawal
			,Bonus
			,Adjustment
			,TurnOver
			,Winlost
			,PSP
			,Marketing
			,AffExRate
			,Currency
		)
		SELECT ci.IBCCustID
			,@SportsBookID AS SportType
			,ci.AffId
			,b.WinlostDate
			,isnull(sum(CASE bettype
						WHEN 22001 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END), 0) AS Deposit
			,- isnull(sum(CASE 
						WHEN bettype IN (22002, 22003) THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END), 0) AS Withdrawal
			,isnull(sum(CASE bettype
						WHEN 22004 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END), 0) AS Bonus
			,isnull(sum(CASE 
						WHEN bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END), 0) AS Adjustment
			,isnull(sum(CASE 
						WHEN bettype = 911 THEN 0
						WHEN (bettype <= 999 
								OR ( bettype BETWEEN 1301 AND 1399)
							) THEN isnull(abs(stake), 0)
						ELSE 0
						END), 0) AS Turnover
			,isnull(sum(CASE 
						WHEN (bettype <= 999 
								OR ( bettype BETWEEN 1301 AND 1399)
							)
							AND ruben = 1 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0) + isnull(playercomm, 0)
						ELSE 0
						END
						*
						CASE WHEN bettype = 911 THEN a.DeductedPercentage
						ELSE 1
						END), 0) AS Winlost
			,0 AS PSP
			,0 AS Marketing
			,e.Actualrate2	
			,ci.Currency
		FROM dbo.MemberInfo ci WITH (NOLOCK)
			INNER JOIN #AffList a
			ON ci.AffID = a.AffId
		
			INNER JOIN bodb02.dbo.bettrans b WITH (NOLOCK)
			ON b.custid = ci.IBCCustID
		
			INNER JOIN dbo.Exchange_Current e WITH (NOLOCK)
			ON e.exchangeid = ci.currency
		
		WHERE b.winlostdate BETWEEN @PrevCurrentDay AND @CurrentDay
			AND b.winlostdate >= @FirstDay
			AND ci.IsRemoved = 0
			AND (
				b.bettype <= 999
				OR ( b.bettype BETWEEN 1301 AND 1399) -- SS tickets
				OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
			) --get SB only
			AND b.bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
			AND b.bettype NOT BETWEEN 912 AND 914 -- Cash Out (keep 911 only)
			AND b.StatusID NOT IN (101, 102, 103, 121, 1)
			AND b.custid > 0
		GROUP BY ci.IBCCustID
			,ci.AffId
			,e.Actualrate2
			,ci.Currency
			,b.winlostdate
			
		-- update PSP & Marketing fees
		UPDATE d
		SET PSP 		= (abs(d.Deposit) * e.DepositPercent + abs(d.Withdrawal) * e.WithdrawalPercent)
			,Marketing  = abs(d.Winlost) * isnull(dbo.Aff_GetDeductionPercent(d.AffID, @SportsBookID, 'Marketing', d.WinlostDate), 0)
		FROM #MemberRealtime d
			INNER JOIN dbo.Exchange_Current e WITH (NOLOCK)
			ON d.Currency = e.exchangeid
	END
	
	;WITH tmpAffGroupInfo 
	AS (
		SELECT a.AffId
			,gh.GroupID
			,a.Currency
			,gh.MonthDate
		FROM #AffList a
			INNER JOIN (
				SELECT a.AffId
					, gh.GroupId
					, @LastDay AS MonthDate
				FROM dbo.AffGroupHistory gh (NOLOCK)
					INNER JOIN #AffList a 
					ON gh.AffID = a.AffId

				WHERE gh.MonthDate = @LastDay

				UNION 
				SELECT a.AffId
					, ai.GroupId
					, @LastDay AS MonthDate
				FROM dbo.AffInfo ai WITH (NOLOCK)
					INNER JOIN #AffList a 
					ON ai.AffID = a.AffId
					INNER JOIN dbo.CommGroup cg 
					ON ai.GroupID = cg.GroupID

				WHERE DATEDIFF(MM, @LastDay, @CurrentDay) = 0

			) gh ON a.AffID = gh.AffID
	)
	INSERT INTO #AffSummary (
		AffID
		,Currency
		,GroupID
		,SportID
		,MonthDate
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
	SELECT t.AffID
		,t.Currency
		,t.GroupID
		,r.SportType
		,t.MonthDate
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
		,dbo.Aff_GetDeductionPercent(t.AffID, r.SportType, 'Bonus', @LastDay) AS BonusPercent
		,dbo.Aff_GetDeductionPercent(t.AffID, r.SportType, 'Adjustment', @LastDay) AS AdjustmentPercent
		,dbo.Aff_GetDeductionPercent(t.AffID, r.SportType, 'Marketing', @LastDay) AS MarketingPercent
		,dbo.Aff_GetDeductionPercent(t.AffID, r.SportType, 'PSP', @LastDay) AS PercentPSP
		,dbo.Aff_GetDeductionPercent(t.AffID, r.SportType, 'Odds Fee', @LastDay) AS OddsFeePercent
		,dbo.Aff_GetDeductionPercent(t.AffID, r.SportType, 'PlayTech Royalties', @LastDay) AS PlayTechRoyaltiesPercent
		,0 AS IsPSPIncluded
	FROM tmpAffGroupInfo t
		INNER JOIN (
			SELECT IBCCustID
				,SportType
				,AffID
				,WinlostDate
				,SUM(ISNULL(Winlost, 0)) AS Winlost
				,SUM(ISNULL(Bonus, 0)) AS Bonus
				,SUM(ISNULL(Adjustment, 0)) AS Adjustment
				,SUM(ISNULL(PSP, 0)) AS PSP
				,SUM(ISNULL(Marketing, 0)) AS Marketing
				,SUM(ISNULL(TurnOver, 0)) AS TurnOver
				,SUM(ISNULL(Deposit, 0)) AS Deposit
			FROM (
				SELECT IBCCustID
					,SportType
					,md.AffID
					,DATEADD(D, -1, DATEADD(M, DATEDIFF(M, 0, DATEADD(M, 1, md.WinlostDate)), 0)) AS WinlostDate
					,SUM(ISNULL(Winlost, 0) * isnull(AffExRate, 1)) AS Winlost
					,sum(isnull(Bonus, 0) * isnull(AffExRate, 1)) AS Bonus
					,sum(isnull(Adjustment, 0) * isnull(AffExRate, 1)) AS Adjustment
					,sum(CASE WHEN SportType = @SportsBookID THEN isnull(PSP, 0) * isnull(AffExRate, 1) ELSE 0 END) AS PSP
					,sum(isnull(Marketing, 0) * isnull(AffExRate, 1)) AS Marketing
					,sum(isnull(TurnOver, 0) * isnull(AffExRate, 1)) AS TurnOver
					,sum(isnull(Deposit, 0) * isnull(AffExRate, 1)) AS Deposit
				FROM dbo.MemberDaily md WITH(NOLOCK)
				INNER JOIN #AffList a ON md.AffID = a.AffId
				WHERE
					md.WinlostDate BETWEEN @FirstDay
						AND CASE WHEN md.SportType = 1 AND DATEDIFF(MM, @LastDay, @PrevCurrentDay) = 0 THEN DATEADD(DD, -1, @PrevCurrentDay)
							ELSE @LastDay END
					AND md.IBCCustID NOT IN (
						SELECT mi.IBCCustID
						FROM dbo.MemberInfo mi WITH (NOLOCK)
							LEFT JOIN dbo.MemberRemoval mr WITH (NOLOCK) 
							ON mi.IBCCustID = mr.IBCCustID
						WHERE mi.IsRemoved = 1
							AND (
								DATEDIFF(mm, mr.RemovedDate, md.WinlostDate) >= 0 
								OR mr.IBCCustID IS NULL
							)
					)
				GROUP BY IBCCustID
					,SportType
					,md.AffID
					,DATEADD(D, -1, DATEADD(M, DATEDIFF(M, 0, DATEADD(M, 1, md.WinlostDate)), 0))
				
				UNION ALL
				SELECT mt.IBCCustID
					,mt.SportType
					,mt.AffID
					,DATEADD(D, -1, DATEADD(M, DATEDIFF(M, 0, DATEADD(M, 1, mt.WinlostDate)), 0)) AS WinlostDate
					,SUM(ISNULL(Winlost, 0) * isnull(AffExRate, 1)) AS Winlost
					,sum(isnull(Bonus, 0) * isnull(AffExRate, 1)) AS Bonus
					,sum(isnull(Adjustment, 0) * isnull(AffExRate, 1)) AS Adjustment
					,sum(CASE WHEN SportType = @SportsBookID THEN isnull(PSP, 0) * isnull(AffExRate, 1) ELSE 0 END) AS PSP
					,sum(isnull(Marketing, 0) * isnull(AffExRate, 1)) AS Marketing
					,sum(isnull(TurnOver, 0) * isnull(AffExRate, 1)) AS TurnOver
					,sum(isnull(Deposit, 0) * isnull(AffExRate, 1)) AS Deposit
				FROM #MemberRealtime AS mt
				GROUP BY IBCCustID
					,SportType
					,AffID
					,DATEADD(D, -1, DATEADD(M, DATEDIFF(M, 0, DATEADD(M, 1, WinlostDate)), 0))
			) mr
			GROUP BY IBCCustID
				,SportType
				,AffID
				,WinlostDate			
		) r ON t.AffID = r.AffID
			AND DATEDIFF(MM, r.WinlostDate, t.MonthDate) = 0
		INNER JOIN dbo.SportType s(NOLOCK) 
		ON r.SportType = s.SportID
	
	GROUP BY t.AffID
		,t.Currency
		,t.GroupID
		,r.SportType
		,t.MonthDate
	
	-- Decide which SportID should include PSP	
	--check max WL
	;WITH MaxMemWL AS (
		SELECT AffId
			, SUM(CASE WHEN SportId = @SportsBookID 	THEN abs(a.MemWinlost) ELSE 0 END) SportsBookWL
			, SUM(CASE WHEN SportId = @CasinoID 		THEN abs(a.MemWinlost) ELSE 0 END) CasinoWL
			, SUM(ISNULL(a.MemPSP, 0)) AS MemPSP
			, SUM(a.PSPPercent) AS PSPPercent
		FROM #AffSummary a
		WHERE a.SportId IN (@SportsBookID, @CasinoID)
		GROUP BY AffId
		
	), PSPSelection AS (
		SELECT AffId
			, CASE WHEN SportsBookWL > CasinoWL THEN @SportsBookID ELSE @CasinoID END AS SportId
			, m.MemPSP
			, m.PSPPercent
		FROM MaxMemWL m
	)
	UPDATE a
	SET a.IsPSPIncluded = 1
		, a.MemPSP 		= f.MemPSP
		,a.PSPPercent	= f.PSPPercent
	FROM #AffSummary a
		INNER JOIN PSPSelection f 
		ON a.AffId = f.AffId
			AND a.SportId = f.SportId
	WHERE a.SportId IN (@SportsBookID, @CasinoID)

	--Choose commission value and calculate Total Balance after deduction for each Affiliate and SportID  	
	;WITH AffNetWin As (
		SELECT a.AffID
			,a.GroupID
			,a.SportID
			,a.MonthDate
			,SUM(
				- isnull(a.MemWinlost, 0)
				- isnull(a.MemPSP, 0) * a.PSPPercent * a.IsPSPIncluded 
				- abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 0) 
				- abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 0) 
				- abs(isnull(a.MemWinlost, 0)) * isnull(a.PlayTechRoyaltiesPercent, 0)
			) AS NetWinLost
		FROM #AffSummary a
		GROUP BY a.AffID
			,a.GroupID
			,a.SportID
			,a.MonthDate
	)
	UPDATE a
	SET a.NetWinlost = aw.NetWinLost
		,a.commission = comm.CommRate
	FROM #AffSummary a
		INNER JOIN AffNetWin aw 
		ON a.AffID = aw.AffId
			AND a.GroupID = aw.GroupID
			AND a.SportID = aw.SportID
			AND a.MonthDate = aw.MonthDate
			
		CROSS APPLY (
			SELECT TOP (1) ISNULL(t.Commission, 0) AS CommRate
				FROM (
						
						SELECT Commission
						FROM dbo.GroupSetting(NOLOCK)
						WHERE GroupID = a.GroupID
							AND SportType = a.SportID
							AND (FLOOR(ABS(aw.NetWinLost)) BETWEEN MinAmount AND MaxAmount)
							AND DATEDIFF(M, a.MonthDate, @CurrentDay) = 0
					
						UNION ALL
						SELECT TOP (1) Commission
						FROM dbo.GroupSetting(NOLOCK)
						WHERE GroupID = a.GroupID
							AND SportType = a.SportID
							AND a.TotalQM BETWEEN MinQM AND MaxQM
							AND DATEDIFF(M, a.MonthDate, @CurrentDay) = 0
						
						UNION ALL
						SELECT Commission
						FROM dbo.GroupSettingHistory(NOLOCK)
						WHERE GroupID = a.GroupID
							AND SportType = a.SportID
							AND (FLOOR(ABS(aw.NetWinLost)) BETWEEN MinAmount AND MaxAmount)
							AND MonthDate = a.MonthDate
					
						UNION ALL
						SELECT TOP (1) Commission
						FROM dbo.GroupSettingHistory(NOLOCK)
						WHERE GroupID = a.GroupID
							AND SportType = a.SportID
							AND a.TotalQM BETWEEN MinQM	AND MaxQM
							AND MonthDate = a.MonthDate

					) t
				ORDER BY t.Commission ASC
		) comm

	UPDATE a
	SET a.Commission = (CASE 
			WHEN a.SportID = @CasinoID THEN @MinimumNegativeCasinoCommission
			ELSE @MinimumNegativeCommission END
			)
	FROM #AffSummary a
	WHERE a.NetWinlost < 0
		AND a.Commission = 0
		AND [dbo].[IsZeroCommissionGroup](a.GroupID, a.MonthDate) = 0
		AND a.SportID IN (
			SELECT DISTINCT SportID
			FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
			WHERE GroupID = a.GroupID
				AND gh.MonthDate = a.MonthDate

			UNION 
			SELECT DISTINCT SportID
			FROM dbo.GroupSetting WHITH(NOLOCK)
			WHERE GroupID = a.GroupID
				AND DATEDIFF(m, a.MonthDate, @CurrentDay) = 0
		)
				
	SELECT AffId
		,GroupID
		,SportID
		,MonthDate
		,TotalQM
		,commission AS CommRate
		,sum((NetWinlost - isnull(a.MemBonus, 0) * isnull(a.BonusPercent, 1)) * isnull(Commission, 0)) AS Commission
		,SUM(ISNULL(a.MemDeposit, 0)) AS Deposit
		,SUM(ISNULL(a.MemTurnover, 0)) AS TurnOver
		,SUM(ISNULL(a.MemWinlost, 0)) AS Winlost
		,SUM(ISNULL(a.NetWinlost, 0)) AS NetWinlost
	FROM #AffSummary a
	WHERE (@SportId IS NULL OR SportID = @SportId)
	GROUP BY AffId
		,GroupID
		,SportID
		,MonthDate
		,TotalQM
		,commission
	ORDER BY MonthDate
		,AffID
		,SportID
	
	RETURN;
END
GO