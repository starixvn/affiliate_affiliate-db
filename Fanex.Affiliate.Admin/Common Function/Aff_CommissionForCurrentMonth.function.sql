ALTER FUNCTION [dbo].[Aff_CommissionForCurrentMonth] (@AffID INT)
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

	Revisions:
		- 20120514@Peter : Apply new formula according to Joycee's request
			 IF Winloss in SPORTSBOOK > winloss in Casino then 
				   CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee - PSP Fe
					Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee
			 else
				   CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee
				   Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee - PSP Fee
		- 20140425@Bobby: fixing NoCommision group

*/
BEGIN
	DECLARE @FirstDay SMALLDATETIME
		,@LastDay SMALLDATETIME
		,@Today SMALLDATETIME
		,@MinimumNegativeCommission FLOAT

	SELECT @MinimumNegativeCommission = 0.1

	SELECT @FirstDay = cast(cast(year(getdate()) AS VARCHAR(5)) + '-' + cast(Month(getdate()) AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)

	--Get last day of inputted month
	SELECT @Today = convert(VARCHAR(12), current_timestamp)

	SELECT @LastDay = @Today

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
	DECLARE @GroupID INT
		,@ZeroCommission INT

	SELECT @GroupID = GroupID
	FROM AffInfo(NOLOCK)
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
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'Bonus', NULL) AS HasBonus
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'Marketing', NULL) AS HasMarketing
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'PSP', NULL) AS HasPSP
		,dbo.Aff_HasDeduction(@GroupID, r.ProductID, 'Odds Fee', NULL) AS HasOddsFee
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Bonus', NULL) AS BonusPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Marketing', NULL) AS MarketingPercent
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'PSP', NULL) AS PercentPSP
		,dbo.Aff_GetDeductionPercent(@AffID, r.ProductID, 'Odds Fee', NULL) AS OddsFeePercent
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
		-- and (@ProductID=0 or md.ProductID=@ProductID)   
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
								FROM GroupSetting(NOLOCK)
								WHERE GroupID = @GroupID
									AND ProductID = a.ProductID
									AND floor(abs(- isnull(a.MemWinlost, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1))) BETWEEN MinAmount AND MaxAmount
								), 0) AS Commission
					
					UNION ALL
					SELECT isnull((
								SELECT TOP (1) Commission
								FROM GroupSetting(NOLOCK)
								WHERE GroupID = @GroupID
									AND ProductID = a.ProductID
									AND a.TotalQM BETWEEN MinQM AND MaxQM
								), 0) AS Commission
					) t
				ORDER BY t.Commission ASC
				), 0)
	FROM @AffSummary a

	SET @ZeroCommission = CAST([dbo].[IsZeroCommissionGroup](@GroupID, @LastDay) AS INT)

	IF @ZeroCommission = 0
	BEGIN
		UPDATE a
		SET a.Commission = @MinimumNegativeCommission
		FROM @AffSummary a
		WHERE a.NetWinlost < 0
			AND a.Commission = 0
			AND a.ProductID IN (
				SELECT DISTINCT ProductID
				FROM GroupSetting(NOLOCK)
				WHERE GroupID = @GroupID
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
