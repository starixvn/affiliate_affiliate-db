ALTER FUNCTION [dbo].[Aff_CommissionForMonth] (
	@AffID INT
	,@Month INT
	,@Year INT
	)
RETURNS @AffComm TABLE (
	ProductID INT
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

	-20140425@Bobby: fixing NoCommision group
	- 20140702@Bobby.Nguyen: Force to update Commission  when Company Net Win is negative
                                
	
*/
BEGIN
	DECLARE @FirstDay SMALLDATETIME
		,@LastDay SMALLDATETIME
		,@IsForceMinNegativeCommission BIT = 0
		,@MinimumNegativeCommission FLOAT = 0.1

	SELECT @MinimumNegativeCommission = CASE WHEN SName = 'AFF_MinNegativeCommission' THEN ISNULL(SValue, @MinimumNegativeCommission) ELSE @MinimumNegativeCommission END
		,@IsForceMinNegativeCommission = CASE WHEN SName = 'AFF_ForceMinNegativeCommission' THEN ISNULL(SValue, @IsForceMinNegativeCommission) ELSE @IsForceMinNegativeCommission END
	FROM dbo.SystemSettings with(nolock)
	WHERE SName IN ('AFF_ForceMinNegativeCommission', 'AFF_MinNegativeCommission')

	SELECT @FirstDay = cast(cast(@Year AS VARCHAR(5)) + '-' + cast(@Month AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)

	--Get last day of inputted month
	SELECT @LastDay = DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @FirstDay) + 1, 0))

	DECLARE @GroupID INT
		,@ZeroCommission INT

	SELECT @GroupID = GroupID
	FROM AffGroupHistory(NOLOCK)
	WHERE AffID = @AffID
		AND MonthDate = @LastDay

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
		,MemDeposit MONEY
		)

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
		,MemDeposit
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
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'Bonus', @LastDay) AS HasBonus
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'Marketing', @LastDay) AS HasMarketing
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'PSP', @LastDay) AS HasPSP
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'Odds Fee', @LastDay) AS HasOddsFee
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Bonus', @LastDay) AS BonusPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Marketing', @LastDay) AS MarketingPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'PSP', @LastDay) AS PercentPSP
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Odds Fee', @LastDay) AS OddsFeePercent
		,sum(isnull(r.Deposit, 0)) AS MemDeposit
	FROM (
		SELECT md.username
			,md.ProductID
			,sum(isnull(md.Winlost, 0) * isnull(md.AffExRate, 1)) AS Winlost
			,sum(isnull(md.Bonus, 0) * isnull(md.AffExRate, 1)) AS Bonus
			,sum(isnull(PSP, 0) * isnull(AffExRate, 1)) AS PSP
			,sum(isnull(Marketing, 0) * isnull(AffExRate, 1)) AS Marketing
			,sum(isnull(TurnOver, 0) * isnull(AffExRate, 1)) AS TurnOver
			,sum(isnull(Deposit, 0) * isnull(AffExRate, 1)) AS Deposit
		FROM MemberDaily md(NOLOCK)
		WHERE AffID = @AffID
			AND WinlostDate BETWEEN @FirstDay AND @LastDay
		--  and (@ProductID=0 or md.ProductID=@ProductID)   
		GROUP BY md.username
			,ProductID
		) r
	--left join Product s (nolock) on s.ProductID=r.ProductID 
	GROUP BY r.ProductID

	--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID
	UPDATE a
	SET a.NetWinlost = (- isnull(a.MemWinlost, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1))
		,a.commission = isnull((
				SELECT TOP (1) Commission
				FROM (
					SELECT isnull((
								SELECT Commission
								FROM GroupSettingHistory(NOLOCK)
								WHERE GroupID = @GroupID
									AND ProductID = a.ProductID
									AND MonthDate = @LastDay
									AND floor(abs(- isnull(a.MemWinlost, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1))) BETWEEN MinAmount AND MaxAmount
								), 0) AS Commission
					
					UNION ALL
					SELECT isnull((
								SELECT TOP (1) Commission
								FROM GroupSettingHistory(NOLOCK)
								WHERE GroupID = @GroupID
									AND ProductID = a.ProductID
									AND MonthDate = @LastDay
									AND a.TotalQM BETWEEN MinQM AND MaxQM
								), 0) AS Commission
					) t
				ORDER BY t.Commission ASC
				), 0)
	FROM @AffSummary a

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
				SELECT DISTINCT ProductID
				FROM GroupSettingHistory(NOLOCK)
				WHERE GroupID = @GroupID
					AND DATEDIFF(m, MonthDate, @LastDay) = 0
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
		,sum((NetWinlost - isnull(a.MemBonus, 0) * isnull(a.BonusPercent, 1)) * isnull(Commission, 0)) * CASE 
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

	RETURN
END
