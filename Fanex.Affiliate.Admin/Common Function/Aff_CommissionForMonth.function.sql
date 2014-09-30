ALTER FUNCTION [dbo].[Aff_CommissionForMonth] (
	@AffID INT
	,@Month INT
	,@Year INT
)
RETURNS @AffComm TABLE (
	ProductID 		INT
	,TotalQM 		INT
	,Commission 	DECIMAL(9, 8)
	,Amount 		MONEY
	,MemDeposit 	MONEY
	,MemTurnOver 	MONEY
	,MemWinlost 	MONEY
	,NetWinlost 	MONEY
	)
AS
/*
	Task : Calculate monthy earning for affiliate
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

	- 20140425@Bobby: fixing NoCommision group
	- 20140702@Bobby.Nguyen: Force to update Commission  when Company Net Win is negative
    - 20140909@Bobby.Nguyen: Apply  Sharing fee - PlayerComm     
	
*/
BEGIN
	DECLARE @FirstDay 					SMALLDATETIME
		,@LastDay 						SMALLDATETIME
		,@IsForceMinNegativeCommission 	BIT = 0
		,@MinimumNegativeCommission 	FLOAT = 0.1
		,@CurrentDate 					SMALLDATETIME
		,@GroupID 						INT
		,@ZeroCommission 				INT

	SELECT @MinimumNegativeCommission 	= CASE WHEN SName = 'AFF_MinNegativeCommission' THEN ISNULL(SValue, @MinimumNegativeCommission) ELSE @MinimumNegativeCommission END
		,@IsForceMinNegativeCommission 	= CASE WHEN SName = 'AFF_ForceMinNegativeCommission' THEN ISNULL(SValue, @IsForceMinNegativeCommission) ELSE @IsForceMinNegativeCommission END
	FROM dbo.SystemSettings with(nolock)
	WHERE SName IN ('AFF_ForceMinNegativeCommission', 'AFF_MinNegativeCommission')

	SELECT @FirstDay 	= CAST(CAST(@Year AS VARCHAR(5)) + '-' + CAST(@Month AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)
		,@LastDay 		= DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @FirstDay) + 1, 0))
		,@CurrentDate	= CAST(GETDATE() AS DATE)

	-- select Group info
	SELECT @GroupID = GroupID
	FROM (
		SELECT TOP(1) ai.GroupID
		FROM dbo.AffInfo ai WITH(NOLOCK)
		WHERE ai.AffID = @AffID
			AND DATEDIFF(M, @LastDay, @CurrentDate) = 0
			
		UNION
		SELECT TOP(1) ag.GroupID
		FROM dbo.AffGroupHistory ag WITH(NOLOCK)
		WHERE ag.AffID = @AffID
			AND ag.MonthDate = @LastDay
	) AS t

	DECLARE @AffSummary TABLE (
		ProductID 				INT
		,MemWinlost 			MONEY
		,MemBonus 				MONEY
		,MemPSP 				MONEY
		,MemTurnover 			MONEY
		,MemPlayerComm 			MONEY
		,Commission 			DECIMAL(9, 8)
		,TotalQM 				INT
		,NetWinlost 			MONEY
		,HasBonus 				BIT
		,HasMarketing 			BIT
		,HasPSP 				BIT
		,HasOddsFee 			BIT
		,HasPlayerComm 			BIT
		,BonusPercent 			FLOAT
		,MarketingPercent 		FLOAT
		,PSPPercent 			FLOAT
		,OddsFeePercent 		FLOAT
		,PlayerCommPercent 		FLOAT
		,MemDeposit 			MONEY
		)

	INSERT INTO @AffSummary (
		ProductID
		,MemWinlost
		,MemBonus
		,MemPSP
		,MemTurnover
		,MemPlayerComm
		,TotalQM
		,HasBonus
		,HasMarketing
		,HasPSP
		,HasOddsFee
		,HasPlayerComm
		,BonusPercent
		,MarketingPercent
		,PSPPercent
		,OddsFeePercent
		,PlayerCommPercent
		,MemDeposit
		)
	SELECT r.ProductID AS ProductID
		,SUM(ISNULL(r.Winlost, 0)) AS MemWinlost
		,SUM(ISNULL(r.Bonus, 0)) AS MemBonus
		,SUM(ISNULL(r.PSP, 0)) AS MemPSP
		,SUM(ISNULL(r.Turnover, 0)) AS MemTurnover
		,SUM(ISNULL(r.PlayerComm, 0)) AS MemPlayerComm
		,SUM(CASE 
				WHEN r.TurnOver >= dbo.[Aff_GetQMTurnOver](@AffID, @LastDay) THEN 1
				ELSE 0
				END) AS TotalQM
		,dbo.AffAdmin_f_HasDeduction(@GroupID, r.ProductID, 'Bonus', @LastDay) AS HasBonus
		,dbo.AffAdmin_f_HasDeduction(@GroupID, r.ProductID, 'Marketing', @LastDay) AS HasMarketing
		,dbo.AffAdmin_f_HasDeduction(@GroupID, r.ProductID, 'PSP', @LastDay) AS HasPSP
		,dbo.AffAdmin_f_HasDeduction(@GroupID, r.ProductID, 'Odds Fee', @LastDay) AS HasOddsFee
		,dbo.AffAdmin_f_HasDeduction(@GroupID, r.ProductID, 'PlayerComm', @LastDay) AS HasPlayerComm
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Bonus', @LastDay) AS BonusPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Marketing', @LastDay) AS MarketingPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'PSP', @LastDay) AS PercentPSP
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Odds Fee', @LastDay) AS OddsFeePercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'PlayerComm', @LastDay) AS PlayerCommPercent
		,SUM(ISNULL(r.Deposit, 0)) AS MemDeposit
	FROM (
		SELECT md.username
			,md.ProductID
			,SUM(ISNULL(md.Winlost, 0) * ISNULL(md.AffExRate, 1)) AS Winlost
			,SUM(ISNULL(md.Bonus, 0) * ISNULL(md.AffExRate, 1)) AS Bonus
			,SUM(ISNULL(PSP, 0) * ISNULL(AffExRate, 1)) AS PSP
			,SUM(ISNULL(Marketing, 0) * ISNULL(AffExRate, 1)) AS Marketing
			,SUM(ISNULL(TurnOver, 0) * ISNULL(AffExRate, 1)) AS TurnOver
			,SUM(ISNULL(Deposit, 0) * ISNULL(AffExRate, 1)) AS Deposit
			,SUM(ISNULL(PlayerComm, 0) * ISNULL(AffExRate, 1)) AS PlayerComm
		FROM MemberDaily md(NOLOCK)
		WHERE AffID = @AffID
			AND WinlostDate BETWEEN @FirstDay AND @LastDay
		GROUP BY md.username
			,ProductID
		) r
	GROUP BY r.ProductID

	--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID
	;WITH AffNetWinlostTmp AS (	
		SELECT a.ProductID
			,(- ISNULL(a.MemWinlost, 0) 
							- CAST(a.HasPSP AS INT) * ISNULL(a.MemPSP, 0) * ISNULL(a.PSPPercent, 1) 
							- CAST(a.HasOddsFee AS INT) * ABS(ISNULL(a.MemWinlost, 0)) * ISNULL(a.OddsFeePercent, 1) 
							- CAST(a.HasMarketing AS INT) * ABS(ISNULL(a.MemWinlost, 0)) * ISNULL(a.MarketingPercent, 1)
							- CAST(a.HasPlayerComm AS INT) * ABS(ISNULL(a.MemPlayerComm, 0)) * ISNULL(a.PlayerCommPercent, 1))
							AS AffNetWinlost
		FROM @AffSummary a
	)
	,ProductComm AS (
		SELECT a.ProductID
			,ISNULL((
				SELECT TOP (1) Commission
				FROM (
					SELECT ISNULL((
								SELECT ISNULL(gs.Commission, 0) AS Commission
								FROM dbo.GroupSetting gs WITH(NOLOCK)
								WHERE gs.GroupID = @GroupID
									AND gs.ProductID = a.ProductID
									AND FLOOR(ABS(wl.AffNetWinlost)) BETWEEN gs.MinAmount AND gs.MaxAmount
								), 0) AS Commission
						WHERE DATEDIFF(m, @LastDay, @CurrentDate) = 0
					
					UNION ALL
					SELECT ISNULL((
								SELECT TOP (1) ISNULL(gs.Commission, 0) AS Commission
								FROM dbo.GroupSetting gs WITH(NOLOCK)
								WHERE gs.GroupID = @GroupID
									AND gs.ProductID = a.ProductID
									AND a.TotalQM BETWEEN gs.MinQM AND gs.MaxQM
									
								), 0) AS Commission
						WHERE DATEDIFF(m, @LastDay, @CurrentDate) = 0
								
					UNION ALL	
					SELECT ISNULL((
								SELECT gh.Commission
								FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
								WHERE gh.GroupID = @GroupID
									AND gh.ProductID = a.ProductID
									AND FLOOR(ABS(wl.AffNetWinlost)) BETWEEN gh.MinAmount AND gh.MaxAmount
									AND gh.MonthDate = @LastDay
								), 0) AS Commission
					
					UNION ALL
					SELECT ISNULL((
								SELECT TOP (1) gh.Commission
								FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
								WHERE gh.GroupID = @GroupID
									AND gh.ProductID = a.ProductID
									AND gh.MonthDate = @LastDay
									AND a.TotalQM BETWEEN gh.MinQM AND gh.MaxQM
								), 0) AS Commission
					) t
				ORDER BY t.Commission ASC
				), 0) AS CommPercent
		FROM @AffSummary a
		INNER JOIN AffNetWinlostTmp wl
			ON a.ProductID = wl.ProductID
	)
	UPDATE a
	SET a.NetWinlost	= ISNULL(wl.AffNetWinlost, 0)
		,a.commission	= ISNULL(pc.CommPercent, 0)
	FROM @AffSummary a
		LEFT JOIN AffNetWinlostTmp wl
		ON a.ProductID = wl.ProductID
		LEFT JOIN ProductComm pc
		ON a.ProductID = pc.ProductID

	SET @ZeroCommission = CAST([dbo].[IsZeroCommissionGroup](@GroupID, @LastDay) AS INT)

	/* 
	-- HotFix #18485:
	-- check/update Negative Commission
	-- force update min comm (inorge tier rule ITCBET[OR @IsForceMinNegativeCommission = 1])
	*/
	IF @ZeroCommission = 0
	BEGIN
		UPDATE a
		SET a.Commission = @MinimumNegativeCommission
		FROM @AffSummary a
		WHERE a.NetWinlost < 0
			AND (a.Commission = 0 OR @IsForceMinNegativeCommission = 1) 
			AND a.ProductID IN (
				SELECT DISTINCT gs.ProductID
				FROM dbo.GroupSetting gs WITH(NOLOCK)
				WHERE gs.GroupID = @GroupID
					AND DATEDIFF(m, @LastDay, @CurrentDate) = 0
					
				UNION 
				SELECT DISTINCT gh.ProductID
				FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
				WHERE gh.GroupID = @GroupID
					AND DATEDIFF(m, gh.MonthDate, @LastDay) = 0
				)
	END

	INSERT INTO @AffComm (
		ProductID
		,TotalQM
		,commission
		,amount
		,MemDeposit
		,MemTurnOver
		,MemWinlost
		,NetWinlost
		)
	SELECT ProductID
		,TotalQM
		,commission
		,SUM((NetWinlost - ISNULL(a.MemBonus, 0) * ISNULL(a.BonusPercent, 1)) * ISNULL(Commission, 0)) * CASE 
				WHEN @ZeroCommission = 1 THEN 0
				ELSE 1
				END
		,SUM(ISNULL(a.MemDeposit, 0))
		,SUM(ISNULL(a.MemTurnover, 0))
		,SUM(ISNULL(a.MemWinlost, 0))
		,SUM(ISNULL(a.NetWinlost, 0))
	FROM @AffSummary a
	GROUP BY ProductID
		,TotalQM
		,commission

	RETURN;
END
GO