ALTER PROCEDURE [dbo].[Aff_CalMonthlyEarningCurrent] (
	@AffID INT
	,@ProductID INT = 0
	,@Amount MONEY OUTPUT
	)
AS
/*
	Task : Calculate monthy earning for affiliate current month
	DB: DB052.Affiliate_MYM
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
	- 20140418@Bobby: Check NoCommission group
	- 20140702@Bobby.Nguyen: Force to update Commission  when Company Net Win is negative
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @FirstDay SMALLDATETIME
		,@LastDay SMALLDATETIME
		,@Today SMALLDATETIME
		,@IsForceMinNegativeCommission BIT = 0
		,@MinimumNegativeCommission FLOAT = 0.1

	SELECT @MinimumNegativeCommission = CASE WHEN SName = 'AFF_MinNegativeCommission' THEN ISNULL(SValue, @MinimumNegativeCommission) ELSE @MinimumNegativeCommission END
		,@IsForceMinNegativeCommission = CASE WHEN SName = 'AFF_ForceMinNegativeCommission' THEN ISNULL(SValue, @IsForceMinNegativeCommission) ELSE @IsForceMinNegativeCommission END
	FROM dbo.SystemSettings with(nolock)
	WHERE SName IN ('AFF_ForceMinNegativeCommission', 'AFF_MinNegativeCommission')

	SELECT @FirstDay = cast(cast(year(getdate()) AS VARCHAR(5)) + '-' + cast(Month(getdate()) AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)

	--Get last day of inputted month
	SELECT @Today = convert(VARCHAR(12), current_timestamp)

	SELECT @LastDay = @Today

	SELECT @Amount = 0

	DECLARE @AffSummary TABLE (
		ProductID INT
		,MemWinlost MONEY
		,MemBonus MONEY
		,MemPSP MONEY
		,MemTurnover MONEY
		,Commission DECIMAL(9, 8)
		,TotalQM INT
		,NetWinlost MONEY
		,HasBonus BIT
		,HasMarketing BIT
		,HasPSP BIT
		,HasOddsFee BIT
		,BonusPercent FLOAT
		,MarketingPercent FLOAT
		,PSPPercent FLOAT
		,OddsFeePercent FLOAT
		)
	DECLARE @GroupID INT
		,@ZeroCommission INT


	SELECT @GroupID = a.GroupID
	FROM AffInfo a WITH(NOLOCK)
	WHERE AffID = @AffID

	INSERT INTO @AffSummary (
		ProductID
		,MemWinlost
		,MemBonus
		,MemPSP
		,MemTurnover
		,TotalQM
		,HasBonus
		,HasMarketing
		,HasPSP
		,HasOddsFee
		,BonusPercent
		,MarketingPercent
		,PSPPercent
		,OddsFeePercent
		)
	SELECT r.ProductID AS ProductID
		,sum(isnull(r.Winlost, 0)) AS MemWinlost
		,sum(isnull(r.Bonus, 0)) AS MemBonus
		,sum(isnull(r.PSP, 0)) AS MemPSP
		,sum(isnull(r.Turnover, 0)) AS MemTurnover
		,sum(CASE 
				WHEN r.TurnOver >= dbo.[Aff_GetQMTurnOver](@AffID, current_timestamp) THEN 1
				ELSE 0
				END) AS TotalQM
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'Bonus', NULL) AS HasBonus
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'Marketing', NULL) AS HasMarketing
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'PSP', NULL) AS HasPSP
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'Odds Fee', NULL) AS HasOddsFee
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Bonus', NULL) AS BonusPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Marketing', NULL) AS MarketingPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'PSP', NULL) AS PercentPSP
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Odds Fee', NULL) AS OddsFeePercent
	FROM (
		SELECT md.username
			,md.ProductID
			,sum(isnull(md.Winlost, 0) * isnull(md.AffExRate, 1)) AS Winlost
			,sum(isnull(md.Bonus, 0) * isnull(md.AffExRate, 1)) AS Bonus
			,sum(isnull(PSP, 0) * isnull(AffExRate, 1)) AS PSP
			,sum(isnull(Marketing, 0) * isnull(AffExRate, 1)) AS Marketing
			,sum(isnull(TurnOver, 0) * isnull(AffExRate, 1)) AS TurnOver
		FROM MemberDaily md(NOLOCK)
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
	UPDATE a
	SET a.NetWinlost = (- isnull(a.MemWinlost, 0) - Cast(isnull(a.HasPSP, 0) AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1) - Cast(isnull(a.HasOddsFee, 0) AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1) - Cast(isnull(a.HasMarketing, 0) AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1))
		,a.commission = isnull((
				SELECT TOP (1) Commission
				FROM (
					SELECT isnull((
								SELECT isnull(Commission, 0) AS Commission
								FROM GroupSetting(NOLOCK)
								WHERE GroupID = @GroupID
									AND ProductID = a.ProductID
									AND floor(abs(- isnull(a.MemWinlost, 0) - Cast(isnull(a.HasPSP, 0) AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1) - Cast(isnull(a.HasOddsFee, 0) AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1) - Cast(isnull(a.HasMarketing, 0) AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1))) BETWEEN MinAmount AND MaxAmount
								), 0) AS Commission
					
					UNION ALL
					SELECT isnull((
								SELECT TOP (1) isnull(Commission, 0) AS Commission
								FROM GroupSetting(NOLOCK)
								WHERE GroupID = @GroupID
									AND ProductID = a.ProductID
									AND a.TotalQM BETWEEN MinQM AND MaxQM
								), 0) AS Commission
					) t
				ORDER BY t.Commission ASC
				), 0)
	FROM @AffSummary a

	SET @ZeroCommission = CAST([dbo].[IsZeroCommissionGroup](@GroupID, @Today) AS INT)

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
				SELECT DISTINCT ProductID
				FROM GroupSetting(NOLOCK)
				WHERE GroupID = @GroupID
				)
	END

	SELECT @Amount = sum((a.NetWinlost - Cast(a.HasBonus AS INT) * isnull(a.MemBonus, 0) * isnull(a.BonusPercent, 1)) * isnull(a.Commission, 0))
	FROM @AffSummary a

	IF @ProductID = 0
	BEGIN
		SELECT @Amount = (isnull(@Amount, 0) - [dbo].[Aff_GetAffDeductionAll](@AffID, @Today)) * CASE 
				WHEN @ZeroCommission = 1 THEN 0
				ELSE 1
				END
	END
END
GO

GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbAdminNet]
GO

GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbDownlineNetView]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [vnteam]
