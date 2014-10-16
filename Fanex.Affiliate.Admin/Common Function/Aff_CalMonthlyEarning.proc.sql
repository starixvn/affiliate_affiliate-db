ALTER PROCEDURE [dbo].[Aff_CalMonthlyEarning] (
	@AffID 				INT
	,@Month 			INT
	,@Year 				INT
	,@ProductID 		INT = 0
	,@Amount 			MONEY OUTPUT
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

	- 20140418@Bobby: Check NoCommission group
	- 20140702@Bobby.Nguyen: Force to update Commission  when Company Net Win is negative
	- 20140909@Bobby.Nguyen: Apply  Sharing fee - PlayerComm 
	
*/
BEGIN
	
	SET NOCOUNT ON

	DECLARE @FirstDay 					SMALLDATETIME
		,@LastDay 						SMALLDATETIME
		,@CurrentDate					SMALLDATETIME
		,@IsForceMinNegativeCommission 	BIT = 0
		,@MinimumNegativeCommission 	FLOAT = 0.1
		,@GroupID 						INT
		,@ZeroCommission 				INT

	SELECT @MinimumNegativeCommission 	= CASE 
											WHEN SName = 'AFF_MinNegativeCommission' THEN ISNULL(SValue, @MinimumNegativeCommission) 
											ELSE @MinimumNegativeCommission 
										END
		,@IsForceMinNegativeCommission 	= CASE 
											WHEN SName = 'AFF_ForceMinNegativeCommission' 	THEN ISNULL(SValue, @IsForceMinNegativeCommission) 
											ELSE @IsForceMinNegativeCommission 
										END
	FROM dbo.SystemSettings with(nolock)
	WHERE SName IN ('AFF_ForceMinNegativeCommission', 'AFF_MinNegativeCommission')

	SELECT @FirstDay		= CAST(CAST(@Year AS VARCHAR(5)) + '-' + CAST(@Month AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)
			, @LastDay		= DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @FirstDay) + 1, 0))
			, @CurrentDate	= CAST(GETDATE() AS DATE)

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
		,NetWinlost				MONEY
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
		,dbo.AffAdmin_f_GetDeductionPercent(@AffID, r.ProductID, 'Bonus', @LastDay) AS BonusPercent
		,dbo.AffAdmin_f_GetDeductionPercent(@AffID, r.ProductID, 'Marketing', @LastDay) AS MarketingPercent
		,dbo.AffAdmin_f_GetDeductionPercent(@AffID, r.ProductID, 'PSP', @LastDay) AS PercentPSP
		,dbo.AffAdmin_f_GetDeductionPercent(@AffID, r.ProductID, 'Odds Fee', @LastDay) AS OddsFeePercent
		,dbo.AffAdmin_f_GetDeductionPercent(@AffID, r.ProductID, 'PlayerComm', @LastDay) AS PlayerCommPercent
	FROM (
		SELECT md.username
			,md.ProductID
			,SUM(ISNULL(md.Winlost, 0) * ISNULL(md.AffExRate, 1)) AS Winlost
			,SUM(ISNULL(md.Bonus, 0) * ISNULL(md.AffExRate, 1)) AS Bonus
			,SUM(ISNULL(PSP, 0) * ISNULL(AffExRate, 1)) AS PSP
			,SUM(ISNULL(Marketing, 0) * ISNULL(AffExRate, 1)) AS Marketing
			,SUM(ISNULL(TurnOver, 0) * ISNULL(AffExRate, 1)) AS TurnOver
			,SUM(ISNULL(PlayerComm, 0) * ISNULL(AffExRate, 1)) AS PlayerComm
		FROM dbo.MemberDaily md(NOLOCK)
		WHERE AffID = @AffID
			AND WinlostDate BETWEEN @FirstDay AND @LastDay
			AND (
				@ProductID = 0
				OR md.ProductID = @ProductID
				)
		GROUP BY md.username
			,ProductID
		) r
	--left join Product s (nolock) on s.ProductID=r.ProductID 
	GROUP BY r.ProductID

	
	--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID
	;WITH AffNetWinlostTmp AS (	
		SELECT a.ProductID
			,a.TotalQM
			,(- ISNULL(a.MemWinlost, 0) 
							- CAST(a.HasPSP AS INT) * ISNULL(a.MemPSP, 0) * ISNULL(a.PSPPercent, 1) 
							- CAST(a.HasOddsFee AS INT) * ABS(ISNULL(a.MemWinlost, 0)) * ISNULL(a.OddsFeePercent, 1) 
							- CAST(a.HasMarketing AS INT) * ABS(ISNULL(a.MemWinlost, 0)) * ISNULL(a.MarketingPercent, 1)
							- CAST(a.HasPlayerComm AS INT) * ABS(ISNULL(a.MemPlayerComm, 0)) * ISNULL(a.PlayerCommPercent, 1))
							AS AffNetWinlost
		FROM @AffSummary a
	)
	,ProductComm AS (
		SELECT wl.ProductID
			,comm.Commission AS CommPercent
		FROM AffNetWinlostTmp wl
			CROSS APPLY ( 
				SELECT TOP(1) ISNULL(t.Commission, 0) AS Commission
				FROM (
					SELECT gs.Commission
					FROM dbo.GroupSetting gs WITH(NOLOCK)
					WHERE gs.GroupID = @GroupID
						AND gs.ProductID = wl.ProductID
						AND FLOOR(ABS(wl.AffNetWinlost)) BETWEEN gs.MinAmount AND gs.MaxAmount
						AND DATEDIFF(m, @LastDay, @CurrentDate) = 0
					
					UNION ALL
					SELECT TOP (1) gs.Commission
					FROM dbo.GroupSetting gs WITH(NOLOCK)
					WHERE gs.GroupID = @GroupID
						AND gs.ProductID = wl.ProductID
						AND wl.TotalQM BETWEEN gs.MinQM AND gs.MaxQM
						AND DATEDIFF(m, @LastDay, @CurrentDate) = 0
								
					UNION ALL	
					SELECT gh.Commission
					FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
					WHERE gh.GroupID = @GroupID
						AND gh.ProductID = wl.ProductID
						AND FLOOR(ABS(wl.AffNetWinlost)) BETWEEN gh.MinAmount AND gh.MaxAmount
						AND gh.MonthDate = @LastDay
					
					UNION ALL
					SELECT TOP (1) gh.Commission
					FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
					WHERE gh.GroupID = @GroupID
						AND gh.ProductID = wl.ProductID
						AND gh.MonthDate = @LastDay
						AND wl.TotalQM BETWEEN gh.MinQM AND gh.MaxQM
					) t
				ORDER BY t.Commission ASC
			) comm
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
	IF (@ZeroCommission = 0)
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

	SELECT @Amount = SUM((a.NetWinlost - CAST(a.HasBonus AS INT) * ISNULL(a.MemBonus, 0) * ISNULL(a.BonusPercent, 1)) * ISNULL(a.Commission, 0))
	FROM @AffSummary a

	IF (@ProductID = 0)
	BEGIN
		SELECT @Amount = (ISNULL(@Amount, 0) - [dbo].[Aff_GetAffDeductionAll](@AffID, @LastDay)) * CASE 
				WHEN @ZeroCommission = 1 THEN 0
				ELSE 1
				END
	END

	RETURN;
END
GO

GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarning] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CalMonthlyEarning] TO [vnteam]
GO

