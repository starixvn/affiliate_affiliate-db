ALTER FUNCTION [dbo].[Aff_CommissionForMonthAll] (
	@Month INT
	,@Year INT
	)
RETURNS @AffComm TABLE (
	[AffID] INT
	,[GroupID] INT
	,[ProductID] TINYINT
	,[WinlostDate] SMALLDATETIME
	,[AffCurrency] SMALLINT
	,[SysCurrency] SMALLINT
	,[QualifiedMember] INT
	,[ActivePlayer] INT
	,[Commission] DECIMAL(9, 8)
	,[HasBonus] BIT
	,[HasAdjustment] BIT
	,[HasMarketing] BIT
	,[HasPSP] BIT
	,[HasOddsFee] BIT
	,[Status] NVARCHAR(50)
	,[AffWinlost] MONEY
	,[MemberWinlost] MONEY
	,[MemberBonus] MONEY
	,[MemberAdjustment] MONEY
	,[MemberPSP] MONEY
	,[MemberSum] MONEY
	,[MemberTurnover] MONEY
	,[MemberDeposit] MONEY
	,[Marketing] MONEY
	,[MemOddsFee] MONEY
	,[AffWinlost_aff] MONEY
	,[MemberWinlost_aff] MONEY
	,[MemberBonus_aff] MONEY
	,[MemberAdjustment_aff] MONEY
	,[MemberPSP_aff] MONEY
	,[MemberSum_aff] MONEY
	,[MemberTurnover_aff] MONEY
	,[MemberDeposit_aff] MONEY
	,[Marketing_aff] MONEY
	,[MemOddsFee_aff] MONEY
	,[MemberBetCount] MONEY
	,[MemberTurnoverNoDraw] MONEY
	,[MemberBetCountNoDraw] MONEY
	,[MemberTurnoverNoDraw_aff] MONEY
	,[MemberWithdrawal] MONEY
	,[MemberWithdrawal_aff] MONEY
	,[MemberTurnoverDraw] MONEY
	,[MemberTurnoverDraw_aff] MONEY
	,PShare MONEY
	,PWin MONEY
	,PShare_aff MONEY
	,PWin_aff MONEY
	)
AS
/*
	Task : Calculate monthy earning for affiliate
	Author : Peter@20090909

	Revisions:
		- 20140328@Bobby: Fix bug [https://redmine.nexcel.vn/issues/13974]
		- 20140425@Bobby: fixing NoCommision group
		- 20140610@Bobby: Add ProgressiveShare & ProgressiveWin columns
		- 20140702@Bobby.Nguyen: Force to update Commission  when Company Net Win is negative
*/
BEGIN
	DECLARE @FirstDay SMALLDATETIME
		,@LastDay SMALLDATETIME
		,@Today SMALLDATETIME
		,@TransType INT
		,@IsForceMinNegativeCommission BIT = 0
		,@MinimumNegativeCommission FLOAT = 0.1

	SELECT @MinimumNegativeCommission = CASE WHEN SName = 'AFF_MinNegativeCommission' THEN ISNULL(SValue, @MinimumNegativeCommission) ELSE @MinimumNegativeCommission END
		,@IsForceMinNegativeCommission = CASE WHEN SName = 'AFF_ForceMinNegativeCommission' THEN ISNULL(SValue, 0.1) ELSE @IsForceMinNegativeCommission END
	FROM dbo.SystemSettings with(nolock)
	WHERE SName IN ('AFF_ForceMinNegativeCommission', 'AFF_MinNegativeCommission')

	SELECT @FirstDay = cast(cast(@Year AS VARCHAR(5)) + '-' + cast(@Month AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)

	--Get last day of inputted month  
	SELECT @LastDay = DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @FirstDay) + 1, 0))
		,@TransType = 201

	SELECT @Today = convert(VARCHAR(12), current_timestamp)

	IF datediff(m, @FirstDay, @Today) = 0
		SELECT @LastDay = @Today

	DECLARE @Status VARCHAR(30)

	SELECT @Status = 'Approved'

	--Create temp table to get summary data for each affiliate  
	DECLARE @MemberSummary TABLE (
		UserName VARCHAR(100)
		,AffID INT
		,ProductID INT
		,MemWinlost MONEY
		,MemBonus MONEY
		,MemAdjustment MONEY
		,MemPSP MONEY
		,MemDeposit MONEY
		,MemTurnover MONEY
		,MemWithdrawal MONEY
		,MemTurnoverDraw MONEY
		,MemTurnoverNoDraw MONEY
		,MemBetCount INT
		,MemBetCountNoDraw INT
		,MemWinlost_aff MONEY
		,MemBonus_aff MONEY
		,MemAdjustment_aff MONEY
		,MemPSP_aff MONEY
		,MemDeposit_aff MONEY
		,MemTurnover_aff MONEY
		,MemWithdrawal_aff MONEY
		,MemTurnoverDraw_aff MONEY
		,MemTurnoverNoDraw_aff MONEY
		,PShare MONEY
		,PWin MONEY
		,PShare_aff MONEY
		,PWin_aff MONEY
	)

	INSERT INTO @MemberSummary (
		UserName
		,AffID
		,ProductID
		,MemWinlost
		,MemBonus
		,MemAdjustment
		,MemPSP
		,MemDeposit
		,MemTurnover
		,MemWithdrawal
		,MemTurnoverDraw
		,MemTurnoverNoDraw
		,MemBetCount
		,MemBetCountNoDraw
		,MemWinlost_aff
		,MemBonus_aff
		,MemAdjustment_aff
		,MemPSP_aff
		,MemDeposit_aff
		,MemTurnover_aff
		,MemWithdrawal_aff
		,MemTurnoverDraw_aff
		,MemTurnoverNoDraw_aff
		,PShare
		,PWin
		,PShare_aff
		,PWin_aff
		)
	SELECT username
		,AffID
		,ProductID
		,sum(isnull(Winlost, 0) * isnull(SysExRate, 1)) AS Winlost
		,sum(isnull(Bonus, 0) * isnull(SysExRate, 1)) AS Bonus
		,sum(isnull(Adjustment, 0) * isnull(SysExRate, 1)) AS Adjustment
		,sum(isnull(PSP, 0) * isnull(SysExRate, 1)) AS PSP
		,sum(isnull(Deposit, 0) * isnull(SysExRate, 1)) AS Deposit
		,sum(isnull(TurnOver, 0) * isnull(SysExRate, 1)) AS TurnOver
		,sum(isnull(Withdrawal, 0) * isnull(SysExRate, 1)) AS Withdrawal
		,sum(isnull(TurnOverDraw, 0) * isnull(SysExRate, 1)) AS TurnOverDraw
		,sum(isnull(TurnOverNoDraw, 0) * isnull(SysExRate, 1)) AS TurnOverNoDraw
		,sum(isnull(BetCount, 0)) AS BetCount
		,sum(isnull(BetCountNoDraw, 0)) AS BetCountNoDraw
		,sum(isnull(Winlost, 0) * isnull(AffExRate, 1)) AS Winlost_aff
		,sum(isnull(Bonus, 0) * isnull(AffExRate, 1)) AS Bonus_aff
		,sum(isnull(Adjustment, 0) * isnull(AffExRate, 1)) AS Adjustment_aff
		,sum(isnull(PSP, 0) * isnull(AffExRate, 1)) AS PSP_aff
		,sum(isnull(Deposit, 0) * isnull(AffExRate, 1)) AS Deposit_aff
		,sum(isnull(TurnOver, 0) * isnull(AffExRate, 1)) AS TurnOver_aff
		,sum(isnull(Withdrawal, 0) * isnull(AffExRate, 1)) AS Withdrawal_aff
		,sum(isnull(TurnOverDraw, 0) * isnull(AffExRate, 1)) AS TurnOverDraw_aff
		,sum(isnull(TurnOverNoDraw, 0) * isnull(AffExRate, 1)) AS TurnOverNoDraw_aff
		,sum(isnull(PShare, 0) * isnull(SysExRate, 1)) AS PShare
		,sum(isnull(PWin, 0) * isnull(SysExRate, 1)) AS PWin
		,sum(isnull(PShare, 0) * isnull(AffExRate, 1)) AS PShare_aff
		,sum(isnull(PWin, 0) * isnull(AffExRate, 1)) AS PWin_aff
	FROM MemberDaily md(NOLOCK)
	WHERE WinlostDate BETWEEN @FirstDay AND @LastDay
	GROUP BY username
		,ProductID
		,AffID

	IF (@@ROWCOUNT = 0)
	BEGIN
		RETURN
	END

	--Create temp table to get summary data for each affiliate  
	DECLARE @AffSummary TABLE (
		/* [No] int IDENTITY(1,1),*/
		AffID INT
		,Currency SMALLINT
		,GroupID INT
		,ProductID INT
		,MemWinlost MONEY
		,MemBonus MONEY
		,MemAdjustment MONEY
		,MemPSP MONEY
		,Marketing MONEY
		,OddsFee MONEY
		,MemDeposit MONEY
		,MemTurnover MONEY
		,NetWinlost MONEY
		,MemWinlost_aff MONEY
		,MemBonus_aff MONEY
		,MemAdjustment_aff MONEY
		,MemPSP_aff MONEY
		,Marketing_aff MONEY
		,OddsFee_aff MONEY
		,MemDeposit_aff MONEY
		,MemTurnover_aff MONEY
		,NetWinlost_aff MONEY
		,Commission DECIMAL(9, 8)
		,TotalQM INT
		,TotalActivePlayer INT
		,HasBonus BIT
		,HasMarketing BIT
		,HasAdjustment BIT
		,HasPSP BIT
		,HasOddsFee BIT
		,BonusPercent FLOAT
		,MarketingPercent FLOAT
		,AdjustmentPercent FLOAT
		,PSPPercent FLOAT
		,OddsFeePercent FLOAT
		,[MemBetCount] INT
		,[MemTurnoverNoDraw] MONEY
		,[MemBetCountNoDraw] INT
		,[MemTurnoverNoDraw_aff] MONEY
		,[MemWithdrawal] MONEY
		,[MemWithdrawal_aff] MONEY
		,[MemTurnoverDraw] MONEY
		,[MemTurnoverDraw_aff] MONEY
		,ZeroCommission INT
		,PShare MONEY
		,PWin MONEY
		,PShare_aff MONEY
		,PWin_aff MONEY
		)

	IF datediff(m, @FirstDay, current_timestamp) = 0
	BEGIN
		INSERT INTO @AffSummary (
			AffID
			,Currency
			,GroupID
			,ProductID
			,MemWinlost
			,MemBonus
			,MemAdjustment
			,MemPSP
			,MemDeposit
			,MemTurnover
			,MemWinlost_aff
			,MemBonus_aff
			,MemAdjustment_aff
			,MemPSP_aff
			,MemDeposit_aff
			,MemTurnover_aff
			,TotalQM
			,HasBonus
			,HasMarketing
			,HasAdjustment
			,HasPSP
			,HasOddsFee
			,BonusPercent
			,AdjustmentPercent
			,MarketingPercent
			,PSPPercent
			,OddsFeePercent
			,[MemBetCount]
			,[MemTurnoverNoDraw]
			,[MemBetCountNoDraw]
			,[MemTurnoverNoDraw_aff]
			,[MemWithdrawal]
			,[MemWithdrawal_aff]
			,[MemTurnoverDraw]
			,[MemTurnoverDraw_aff]
			,ZeroCommission
			,PShare
			,PWin
			,PShare_aff
			,PWin_aff
			)
		SELECT ai.AffID AS AffID
			,ai.Currency AS Currency
			,ai.GroupID AS GroupID
			,r.ProductID AS ProductID
			,sum(isnull(r.MemWinlost, 0)) AS MemWinlost
			,sum(isnull(r.MemBonus, 0)) AS MemBonus
			,sum(isnull(r.MemAdjustment, 0)) AS MemAdjustment
			,sum(isnull(r.MemPSP, 0)) AS MemPSP
			,sum(isnull(r.MemDeposit, 0)) AS MemDeposit
			,sum(isnull(r.MemTurnover, 0)) AS MemTurnover
			,sum(isnull(r.MemWinlost_aff, 0)) AS MemWinlost_aff
			,sum(isnull(r.MemBonus_aff, 0)) AS MemBonus_aff
			,sum(isnull(r.MemAdjustment_aff, 0)) AS MemAdjustment_aff
			,sum(isnull(r.MemPSP_aff, 0)) AS MemPSP_aff
			,sum(isnull(r.MemDeposit_aff, 0)) AS MemDeposit_aff
			,sum(isnull(r.MemTurnover_aff, 0)) AS MemTurnover_aff
			,sum(CASE 
					WHEN isnull(r.MemTurnover_aff, 0) >= ch.QualifiedAmount THEN 1
					ELSE 0
					END) AS TotalQM
			,dbo.Aff_HasDeduction(ai.GroupID, r.ProductID, 'Bonus', NULL) AS HasBonus
			,dbo.Aff_HasDeduction(ai.GroupID, r.ProductID, 'Marketing', NULL) AS HasMarketing
			,dbo.Aff_HasDeduction(ai.GroupID, r.ProductID, 'Adjustment', NULL) AS HasAdjustment
			,dbo.Aff_HasDeduction(ai.GroupID, r.ProductID, 'PSP', NULL) AS HasPSP
			,dbo.Aff_HasDeduction(ai.GroupID, r.ProductID, 'Odds Fee', NULL) AS HasOddsFee
			,dbo.Aff_GetDeductionPercent(ai.AffID, r.ProductID, 'Bonus', NULL) AS BonusPercent
			,dbo.Aff_GetDeductionPercent(ai.AffID, r.ProductID, 'Adjustment', NULL) AS AdjustmentPercent
			,dbo.Aff_GetDeductionPercent(ai.AffID, r.ProductID, 'Marketing', NULL) AS MarketingPercent
			,dbo.Aff_GetDeductionPercent(ai.AffID, r.ProductID, 'PSP', NULL) AS PercentPSP
			,dbo.Aff_GetDeductionPercent(ai.AffID, r.ProductID, 'Odds Fee', NULL) AS OddsFeePercent
			,Sum(isnull([MemBetCount], 0))
			,Sum(isnull([MemTurnoverNoDraw], 0))
			,Sum(isnull([MemBetCountNoDraw], 0))
			,Sum(isnull([MemTurnoverNoDraw_aff], 0))
			,Sum(isnull([MemWithdrawal], 0))
			,Sum(isnull([MemWithdrawal_aff], 0))
			,Sum(isnull([MemTurnoverDraw], 0))
			,Sum(isnull([MemTurnoverDraw_aff], 0))
			,[dbo].[IsZeroCommissionGroup](ai.GroupID, @LastDay)
			,SUM(ISNULL(PShare, 0)) PShare
			,SUM(ISNULL(PWin, 0)) PWin
			,SUM(ISNULL(PShare_aff, 0)) PShare_aff
			,SUM(ISNULL(PWin_aff, 0)) PWin_aff
		FROM AffInfo ai WITH (NOLOCK)
			INNER JOIN CommGroup ch(NOLOCK)
			ON ch.groupid = ai.groupid
			INNER JOIN @MemberSummary r
			ON r.AffID = ai.AffID
		WHERE ai.STATUS = @Status
		GROUP BY ai.AffID
			,ai.Currency
			,ai.GroupID
			,r.ProductID
	END
	ELSE IF datediff(m, @FirstDay, current_timestamp) > 0
	BEGIN
		INSERT INTO @AffSummary (
			AffID
			,Currency
			,GroupID
			,ProductID
			,MemWinlost
			,MemBonus
			,MemAdjustment
			,MemPSP
			,MemDeposit
			,MemTurnover
			,MemWinlost_aff
			,MemBonus_aff
			,MemAdjustment_aff
			,MemPSP_aff
			,MemDeposit_aff
			,MemTurnover_aff
			,TotalQM
			,HasBonus
			,HasMarketing
			,HasAdjustment
			,HasPSP
			,HasOddsFee
			,BonusPercent
			,AdjustmentPercent
			,MarketingPercent
			,PSPPercent
			,OddsFeePercent
			,[MemBetCount]
			,[MemTurnoverNoDraw]
			,[MemBetCountNoDraw]
			,[MemTurnoverNoDraw_aff]
			,[MemWithdrawal]
			,[MemWithdrawal_aff]
			,[MemTurnoverDraw]
			,[MemTurnoverDraw_aff]
			,ZeroCommission
			,PShare
			,PWin
			,PShare_aff
			,PWin_aff
			)
		SELECT ai.AffID AS AffID
			,ai.Currency AS Currency
			,gh.GroupID AS GroupID
			,r.ProductID AS ProductID
			,sum(isnull(r.MemWinlost, 0)) AS MemWinlost
			,sum(isnull(r.MemBonus, 0)) AS MemBonus
			,sum(isnull(r.MemAdjustment, 0)) AS MemAdjustment
			,sum(isnull(r.MemPSP, 0)) AS MemPSP
			,sum(isnull(r.MemDeposit, 0)) AS MemDeposit
			,sum(isnull(r.MemTurnover, 0)) AS MemTurnover
			,sum(isnull(r.MemWinlost_aff, 0)) AS MemWinlost_aff
			,sum(isnull(r.MemBonus_aff, 0)) AS MemBonus_aff
			,sum(isnull(r.MemAdjustment_aff, 0)) AS MemAdjustment_aff
			,sum(isnull(r.MemPSP_aff, 0)) AS MemPSP_aff
			,sum(isnull(r.MemDeposit_aff, 0)) AS MemDeposit_aff
			,sum(isnull(r.MemTurnover_aff, 0)) AS MemTurnover_aff
			,sum(CASE 
					WHEN isnull(r.MemTurnover_aff, 0) >= ch.QualifiedAmount THEN 1
					ELSE 0
					END) AS TotalQM
			,dbo.Aff_HasDeduction(gh.GroupID, r.ProductID, 'Bonus', @LastDay) AS HasBonus
			,dbo.Aff_HasDeduction(gh.GroupID, r.ProductID, 'Marketing', @LastDay) AS HasMarketing
			,dbo.Aff_HasDeduction(gh.GroupID, r.ProductID, 'Adjustment', @LastDay) AS HasAdjustment
			,dbo.Aff_HasDeduction(gh.GroupID, r.ProductID, 'PSP', @LastDay) AS HasPSP
			,dbo.Aff_HasDeduction(gh.GroupID, r.ProductID, 'Odds Fee', @LastDay) AS HasOddsFee
			,dbo.Aff_GetDeductionPercent(ai.AffID, r.ProductID, 'Bonus', @LastDay) AS BonusPercent
			,dbo.Aff_GetDeductionPercent(ai.AffID, r.ProductID, 'Adjustment', @LastDay) AS AdjustmentPercent
			,dbo.Aff_GetDeductionPercent(ai.AffID, r.ProductID, 'Marketing', @LastDay) AS MarketingPercent
			,dbo.Aff_GetDeductionPercent(ai.AffID, r.ProductID, 'PSP', @LastDay) AS PercentPSP
			,dbo.Aff_GetDeductionPercent(ai.AffID, r.ProductID, 'Odds Fee', @LastDay) AS OddsFeePercent
			,Sum(isnull([MemBetCount], 0))
			,Sum(isnull([MemTurnoverNoDraw], 0))
			,Sum(isnull([MemBetCountNoDraw], 0))
			,Sum(isnull([MemTurnoverNoDraw_aff], 0))
			,Sum(isnull([MemWithdrawal], 0))
			,Sum(isnull([MemWithdrawal_aff], 0))
			,Sum(isnull([MemTurnoverDraw], 0))
			,Sum(isnull([MemTurnoverDraw_aff], 0))
			,[dbo].[IsZeroCommissionGroup](gh.GroupID, @LastDay)
			,SUM(ISNULL(PShare, 0)) PShare
			,SUM(ISNULL(PWin, 0)) PWin
			,SUM(ISNULL(PShare_aff, 0)) PShare_aff
			,SUM(ISNULL(PWin_aff, 0)) PWin_aff
		FROM AffInfo ai WITH (NOLOCK)
			INNER JOIN AffGroupHistory gh(NOLOCK)
			ON gh.AffID = ai.AffID
				AND gh.MonthDate = @LastDay
			INNER JOIN CommGroupHistory ch(NOLOCK)
			ON ch.groupid = gh.groupid
				AND ch.MonthDate = @LastDay
			INNER JOIN @MemberSummary r
			ON r.AffID = ai.AffID
		WHERE ai.STATUS = @Status
		GROUP BY ai.AffID
			,ai.Currency
			,gh.GroupID
			,r.ProductID
	END

	DELETE
	FROM @AffSummary
	WHERE ProductID IS NULL

	UPDATE a
	SET a.TotalActivePlayer = ISNULL(t.TotalActivePlayer, 0)
	FROM @AffSummary a
		LEFT JOIN (
		SELECT m.AffID
			,COUNT(DISTINCT m.username) AS TotalActivePlayer
		FROM @MemberSummary m
		WHERE m.MemTurnover > 0 --or m.MemDeposit>0  
		GROUP BY m.AffID
		) t
		ON a.AffID = t.AffID

	IF datediff(m, @FirstDay, current_timestamp) > 0
	BEGIN
		--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID  
		UPDATE a
		SET a.MemPSP = Cast(a.HasPSP AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1)
			,a.MemPSP_aff = Cast(a.HasPSP AS INT) * isnull(a.MemPSP_aff, 0) * isnull(a.PSPPercent, 1)
			,a.Marketing = Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1)
			,a.Marketing_aff = Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.MarketingPercent, 1)
			,a.OddsFee = Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1)
			,a.OddsFee_aff = Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.OddsFeePercent, 1)
			,a.NetWinlost_aff = (- isnull(a.MemWinlost_aff, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP_aff, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.MarketingPercent, 1))
			,a.NetWinlost = (- isnull(a.MemWinlost, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1))
			,a.commission = isnull((
					SELECT TOP (1) Commission
					FROM (
						SELECT isnull((
									SELECT Commission
									FROM GroupSettingHistory(NOLOCK)
									WHERE GroupID = a.GroupID
										AND ProductID = a.ProductID
										AND MonthDate = @LastDay
										AND floor(abs(- isnull(a.MemWinlost_aff, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP_aff, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.MarketingPercent, 1))) BETWEEN MinAmount AND MaxAmount
									), 0) AS Commission
						
						UNION ALL
						SELECT isnull((
									SELECT TOP (1) Commission
									FROM GroupSettingHistory(NOLOCK)
									WHERE GroupID = a.GroupID
										AND ProductID = a.ProductID
										AND MonthDate = @LastDay
										AND a.TotalQM BETWEEN MinQM AND MaxQM
									), 0) AS Commission
						) t
					ORDER BY t.Commission ASC
					), 0)
		FROM @AffSummary a

		/* 
		-- HotFix #18485:
		-- check/update Negative Commission
		-- force update min comm (inorge tier rule ITCBET[OR @IsForceMinNegativeCommission = 1])
		*/
		UPDATE a
		SET a.Commission = @MinimumNegativeCommission
		FROM @AffSummary a
		WHERE a.NetWinlost_aff < 0
			AND (a.Commission = 0 OR @IsForceMinNegativeCommission = 1) 
			AND a.ZeroCommission = 0
			AND a.ProductID IN (
				SELECT DISTINCT ProductID
				FROM GroupSettingHistory(NOLOCK)
				WHERE GroupID = a.GroupID
					AND DATEDIFF(m, MonthDate, @LastDay) = 0
				)
	END

	IF datediff(m, @FirstDay, current_timestamp) = 0
	BEGIN
		--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID  
		UPDATE a
		SET a.MemPSP = Cast(a.HasPSP AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1)
			,a.MemPSP_aff = Cast(a.HasPSP AS INT) * isnull(a.MemPSP_aff, 0) * isnull(a.PSPPercent, 1)
			,a.Marketing = Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1)
			,a.Marketing_aff = Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.MarketingPercent, 1)
			,a.OddsFee = Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1)
			,a.OddsFee_aff = Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.OddsFeePercent, 1)
			,a.NetWinlost_aff = (- isnull(a.MemWinlost_aff, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP_aff, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.MarketingPercent, 1))
			,a.NetWinlost = (- isnull(a.MemWinlost, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1))
			,a.commission = isnull((
					SELECT TOP (1) Commission
					FROM (
						SELECT isnull((
									SELECT Commission
									FROM GroupSetting(NOLOCK)
									WHERE GroupID = a.GroupID
										AND ProductID = a.ProductID
										AND floor(abs(- isnull(a.MemWinlost_aff, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP_aff, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.MarketingPercent, 1))) BETWEEN MinAmount AND MaxAmount
									), 0) AS Commission
						
						UNION ALL
						SELECT isnull((
									SELECT TOP (1) Commission
									FROM GroupSetting(NOLOCK)
									WHERE GroupID = a.GroupID
										AND ProductID = a.ProductID
										AND a.TotalQM BETWEEN MinQM AND MaxQM
									), 0) AS Commission
						) t
					ORDER BY t.Commission ASC
					), 0)
		FROM @AffSummary a
		
		/* 
		-- HotFix #18485:
		-- check/update Negative Commission
		-- force update min comm (inorge tier rule ITCBET[OR @IsForceMinNegativeCommission = 1])
		*/
		UPDATE a
		SET a.Commission = @MinimumNegativeCommission
		FROM @AffSummary a
		WHERE a.NetWinlost_aff < 0
			AND (a.Commission = 0 OR @IsForceMinNegativeCommission = 1) 
			AND a.ZeroCommission = 0
			AND a.ProductID IN (
				SELECT DISTINCT ProductID
				FROM GroupSetting(NOLOCK)
				WHERE GroupID = a.GroupID
				)
	END

	--Insert transaction to AffTrans and AffCommission  
	DECLARE @WinlostDate SMALLDATETIME

	SELECT @WinlostDate = current_timestamp

	DECLARE @SystemCurrency SMALLINT

	SET @SystemCurrency = dbo.Aff_GetSystemCurrencyID()

	INSERT INTO @AffComm (
		[AffID]
		,[GroupID]
		,[ProductID]
		,[WinlostDate]
		,[AffCurrency]
		,[SysCurrency]
		,[QualifiedMember]
		,[ActivePlayer]
		,[Commission]
		,[HasBonus]
		,[HasAdjustment]
		,[HasMarketing]
		,[HasPSP]
		,[HasOddsFee]
		,[Status]
		,[AffWinlost]
		,[MemberWinlost]
		,[MemberBonus]
		,[MemberAdjustment]
		,[MemberPSP]
		,[MemberSum]
		,[MemberTurnover]
		,[MemberDeposit]
		,[Marketing]
		,[MemOddsFee]
		,[AffWinlost_aff]
		,[MemberWinlost_aff]
		,[MemberBonus_aff]
		,[MemberAdjustment_aff]
		,[MemberPSP_aff]
		,[MemberSum_aff]
		,[MemberTurnover_aff]
		,[MemberDeposit_aff]
		,[Marketing_aff]
		,[MemOddsFee_aff]
		,[MemberBetCount]
		,[MemberTurnoverNoDraw]
		,[MemberBetCountNoDraw]
		,[MemberTurnoverNoDraw_aff]
		,[MemberWithdrawal]
		,[MemberWithdrawal_aff]
		,[MemberTurnoverDraw]
		,[MemberTurnoverDraw_aff]
		,PShare
		,PWin
		,PShare_aff
		,PWin_aff
		)
	SELECT AffID
		,GroupID
		,ProductID
		,@LastDay
		,Currency
		,@SystemCurrency
		,TotalQM
		,TotalActivePlayer
		,Commission
		,HasBonus
		,HasAdjustment
		,HasMarketing
		,HasPSP
		,HasOddsFee
		,@Status
		,(NetWinlost - Cast(a.HasBonus AS INT) * isnull(a.MemBonus, 0) * isnull(a.BonusPercent, 1)) * isnull(Commission, 0) 
		,MemWinlost
		,MemBonus
		,MemAdjustment
		,MemPSP
		,- NetWinlost
		,MemTurnover
		,MemDeposit
		,Marketing
		,OddsFee
		,((NetWinlost_aff - Cast(a.HasBonus AS INT) * isnull(a.MemBonus_aff, 0) * isnull(a.BonusPercent, 1)) * isnull(Commission, 0)) * CASE 
				WHEN a.ZeroCommission = 1 THEN 0
				ELSE 1
				END
		,MemWinlost_aff
		,MemBonus_aff
		,MemAdjustment_aff
		,MemPSP_aff
		,- NetWinlost_aff
		,MemTurnover_aff
		,MemDeposit_aff
		,Marketing_Aff
		,OddsFee_Aff
		,[MemBetCount]
		,[MemTurnoverNoDraw]
		,[MemBetCountNoDraw]
		,[MemTurnoverNoDraw_aff]
		,[MemWithdrawal]
		,[MemWithdrawal_aff]
		,[MemTurnoverDraw]
		,[MemTurnoverDraw_aff]
		,PShare
		,PWin
		,PShare_aff
		,PWin_aff
	FROM @AffSummary a

	RETURN
END
