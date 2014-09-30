ALTER FUNCTION [dbo].[Aff_CommissionForMonthAll] (
	@Month INT
	,@Year INT
	)
RETURNS @AffComm TABLE (
	[AffID] 						INT
	,[GroupID] 						INT
	,[ProductID] 					TINYINT
	,[WinlostDate] 					SMALLDATETIME
	,[AffCurrency] 					SMALLINT
	,[SysCurrency] 					SMALLINT
	,[QualifiedMember] 				INT
	,[ActivePlayer] 				INT
	,[Commission] 					DECIMAL(9, 8)
	,[HasBonus] 					BIT
	,[HasAdjustment] 				BIT
	,[HasMarketing] 				BIT
	,[HasPSP] 						BIT
	,[HasOddsFee] 					BIT
	,[HasPlayerComm] 				BIT
	,[Status] 						NVARCHAR(50)
	,[AffWinlost] 					MONEY
	,[MemberWinlost] 				MONEY
	,[MemberBonus] 					MONEY
	,[MemberAdjustment] 			MONEY
	,[MemberPSP] 					MONEY
	,[MemberSum] 					MONEY
	,[MemberTurnover] 				MONEY
	,[MemberDeposit] 				MONEY
	,[Marketing] 					MONEY
	,[MemOddsFee] 					MONEY
	,[AffWinlost_aff] 				MONEY
	,[MemberWinlost_aff] 			MONEY
	,[MemberBonus_aff] 				MONEY
	,[MemberAdjustment_aff] 		MONEY
	,[MemberPSP_aff] 				MONEY
	,[MemberSum_aff] 				MONEY
	,[MemberTurnover_aff] 			MONEY
	,[MemberDeposit_aff] 			MONEY
	,[Marketing_aff] 				MONEY
	,[MemOddsFee_aff] 				MONEY
	,[MemberBetCount] 				INT
	,[MemberTurnoverNoDraw] 		MONEY
	,[MemberBetCountNoDraw] 		MONEY
	,[MemberTurnoverNoDraw_aff] 	MONEY
	,[MemberWithdrawal] 			MONEY
	,[MemberWithdrawal_aff] 		MONEY
	,[MemberTurnoverDraw] 			MONEY
	,[MemberTurnoverDraw_aff] 		MONEY
	,PShare 						MONEY
	,PWin 							MONEY
	,PShare_aff 					MONEY
	,PWin_aff 						MONEY
	,PlayerComm 					MONEY 
	,PlayerComm_aff 				MONEY 
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
		- 20140811@Bobby Apply ZeroCommission for calculating commission base on system currency
		- 20140821@Bobby: Add new Virtual Sport product & Apply PlayerComm
*/
BEGIN
	DECLARE @FirstDay 					SMALLDATETIME
		,@LastDay 						SMALLDATETIME
		,@Today 						SMALLDATETIME
		,@TransType 					INT
		,@IsForceMinNegativeCommission 	BIT = 0
		,@MinimumNegativeCommission 	FLOAT = 0.1
		,@Status 						VARCHAR(30)

	SELECT @MinimumNegativeCommission 	= CASE WHEN SName = 'AFF_MinNegativeCommission' THEN ISNULL(SValue, @MinimumNegativeCommission) ELSE @MinimumNegativeCommission END
		,@IsForceMinNegativeCommission 	= CASE WHEN SName = 'AFF_ForceMinNegativeCommission' THEN ISNULL(SValue, 0.1) ELSE @IsForceMinNegativeCommission END
	FROM dbo.SystemSettings with(nolock)
	WHERE SName IN ('AFF_ForceMinNegativeCommission', 'AFF_MinNegativeCommission')

	SELECT @FirstDay 	= CAST(CAST(@Year AS VARCHAR(5)) + '-' + CAST(@Month AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)
		,@LastDay 		= DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @FirstDay) + 1, 0))
		,@TransType 	= 201
		,@Today 		= CONVERT(VARCHAR(12), CURRENT_TIMESTAMP)
		,@LastDay 		= CASE WHEN DATEDIFF(m, @FirstDay, @Today) = 0 THEN @Today ELSE @LastDay END
		,@Status 		= 'Approved'

	--Create temp table to get summary data for each affiliate  
	DECLARE @MemberSummary TABLE (
		UserName 				VARCHAR(100)
		,AffID 					INT
		,ProductID 				INT
		,MemWinlost 			MONEY
		,MemBonus 				MONEY
		,MemAdjustment 			MONEY
		,MemPSP 				MONEY
		,MemDeposit 			MONEY
		,MemTurnover 			MONEY
		,MemWithdrawal 			MONEY
		,MemTurnoverDraw 		MONEY
		,MemTurnoverNoDraw 		MONEY
		,MemBetCount 			INT
		,MemBetCountNoDraw 		INT
		,MemWinlost_aff 		MONEY
		,MemBonus_aff 			MONEY
		,MemAdjustment_aff 		MONEY
		,MemPSP_aff 			MONEY
		,MemDeposit_aff 		MONEY
		,MemTurnover_aff 		MONEY
		,MemWithdrawal_aff 		MONEY
		,MemTurnoverDraw_aff 	MONEY
		,MemTurnoverNoDraw_aff 	MONEY
		,PShare 				MONEY
		,PWin 					MONEY
		,PShare_aff 			MONEY
		,PWin_aff 				MONEY
		,MemberPlayerComm 		MONEY 
		,MemberPlayerComm_aff 	MONEY 
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
		,MemberPlayerComm
		,MemberPlayerComm_aff
		)
	SELECT username
		,AffID
		,ProductID
		,SUM(ISNULL(Winlost, 0) * ISNULL(SysExRate, 1)) AS Winlost
		,SUM(ISNULL(Bonus, 0) * ISNULL(SysExRate, 1)) AS Bonus
		,SUM(ISNULL(Adjustment, 0) * ISNULL(SysExRate, 1)) AS Adjustment
		,SUM(ISNULL(PSP, 0) * ISNULL(SysExRate, 1)) AS PSP
		,SUM(ISNULL(Deposit, 0) * ISNULL(SysExRate, 1)) AS Deposit
		,SUM(ISNULL(TurnOver, 0) * ISNULL(SysExRate, 1)) AS TurnOver
		,SUM(ISNULL(Withdrawal, 0) * ISNULL(SysExRate, 1)) AS Withdrawal
		,SUM(ISNULL(TurnOverDraw, 0) * ISNULL(SysExRate, 1)) AS TurnOverDraw
		,SUM(ISNULL(TurnOverNoDraw, 0) * ISNULL(SysExRate, 1)) AS TurnOverNoDraw
		,SUM(ISNULL(BetCount, 0)) AS BetCount
		,SUM(ISNULL(BetCountNoDraw, 0)) AS BetCountNoDraw
		,SUM(ISNULL(Winlost, 0) * ISNULL(AffExRate, 1)) AS Winlost_aff
		,SUM(ISNULL(Bonus, 0) * ISNULL(AffExRate, 1)) AS Bonus_aff
		,SUM(ISNULL(Adjustment, 0) * ISNULL(AffExRate, 1)) AS Adjustment_aff
		,SUM(ISNULL(PSP, 0) * ISNULL(AffExRate, 1)) AS PSP_aff
		,SUM(ISNULL(Deposit, 0) * ISNULL(AffExRate, 1)) AS Deposit_aff
		,SUM(ISNULL(TurnOver, 0) * ISNULL(AffExRate, 1)) AS TurnOver_aff
		,SUM(ISNULL(Withdrawal, 0) * ISNULL(AffExRate, 1)) AS Withdrawal_aff
		,SUM(ISNULL(TurnOverDraw, 0) * ISNULL(AffExRate, 1)) AS TurnOverDraw_aff
		,SUM(ISNULL(TurnOverNoDraw, 0) * ISNULL(AffExRate, 1)) AS TurnOverNoDraw_aff
		,SUM(ISNULL(PShare, 0) * ISNULL(SysExRate, 1)) AS PShare
		,SUM(ISNULL(PWin, 0) * ISNULL(SysExRate, 1)) AS PWin
		,SUM(ISNULL(PShare, 0) * ISNULL(AffExRate, 1)) AS PShare_aff
		,SUM(ISNULL(PWin, 0) * ISNULL(AffExRate, 1)) AS PWin_aff
		,SUM(ISNULL(PlayerComm, 0) * ISNULL(SysExRate, 1)) AS MemberPlayerComm
		,SUM(ISNULL(PlayerComm, 0) * ISNULL(AffExRate, 1)) AS MemberPlayerComm_aff
	FROM dbo.MemberDaily md WITH(NOLOCK)
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
		,HasPlayerComm BIT
		,BonusPercent FLOAT
		,MarketingPercent FLOAT
		,AdjustmentPercent FLOAT
		,PSPPercent FLOAT
		,OddsFeePercent FLOAT
		,PlayerCommPercent FLOAT
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
		,PlayerComm MONEY 
		,PlayerComm_aff MONEY 
		)

	;WITH AffList AS(
		SELECT r.AffID
		FROM @MemberSummary r
		GROUP BY r.AffID
	)
	,AffCommGroupInfo AS
	(	
		SELECT r.AffId
			,ai.Currency
			,ISNULL(cg.GroupID, ch.GroupID) AS GroupID
			,ISNULL(cg.QualifiedAmount, ch.QualifiedAmount) AS QualifiedAmount
		FROM AffList r
			INNER JOIN dbo.AffInfo ai WITH(NOLOCK)
			ON r.AffID = ai.AffID
			------------current comm group --------------
			LEFT JOIN dbo.CommGroup cg WITH(NOLOCK)
			ON ai.GroupID = cg.GroupID 
				AND @LastDay = @ToDay
			------------history comm group --------------
			LEFT JOIN dbo.AffGroupHistory ah WITH(NOLOCK)
			ON ai.AffID = ah.AffID 
				AND ah.MonthDate = @LastDay
			LEFT JOIN dbo.CommGroupHistory ch WITH(NOLOCK)
			ON ah.GroupID = ch.GroupID
				AND ah.MonthDate = ch.MonthDate
		WHERE ai.STATUS = @Status 
	)
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
		,HasPlayerComm
		,BonusPercent
		,AdjustmentPercent
		,MarketingPercent
		,PSPPercent
		,OddsFeePercent
		,PlayerCommPercent
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
		,PlayerComm
		,PlayerComm_aff
		)
	SELECT ai.AffID
		,ai.Currency
		,ai.GroupID
		,r.ProductID
		,SUM(ISNULL(r.MemWinlost, 0)) AS MemWinlost
		,SUM(ISNULL(r.MemBonus, 0)) AS MemBonus
		,SUM(ISNULL(r.MemAdjustment, 0)) AS MemAdjustment
		,SUM(ISNULL(r.MemPSP, 0)) AS MemPSP
		,SUM(ISNULL(r.MemDeposit, 0)) AS MemDeposit
		,SUM(ISNULL(r.MemTurnover, 0)) AS MemTurnover
		,SUM(ISNULL(r.MemWinlost_aff, 0)) AS MemWinlost_aff
		,SUM(ISNULL(r.MemBonus_aff, 0)) AS MemBonus_aff
		,SUM(ISNULL(r.MemAdjustment_aff, 0)) AS MemAdjustment_aff
		,SUM(ISNULL(r.MemPSP_aff, 0)) AS MemPSP_aff
		,SUM(ISNULL(r.MemDeposit_aff, 0)) AS MemDeposit_aff
		,SUM(ISNULL(r.MemTurnover_aff, 0)) AS MemTurnover_aff
		,sum(CASE 
				WHEN ISNULL(r.MemTurnover_aff, 0) >= ai.QualifiedAmount THEN 1
				ELSE 0
				END) AS TotalQM
		,dbo.AffAdmin_f_HasDeduction(ai.GroupID, r.ProductID, 'Bonus', @LastDay) AS HasBonus
		,dbo.AffAdmin_f_HasDeduction(ai.GroupID, r.ProductID, 'Marketing', @LastDay) AS HasMarketing
		,dbo.AffAdmin_f_HasDeduction(ai.GroupID, r.ProductID, 'Adjustment', @LastDay) AS HasAdjustment
		,dbo.AffAdmin_f_HasDeduction(ai.GroupID, r.ProductID, 'PSP', @LastDay) AS HasPSP
		,dbo.AffAdmin_f_HasDeduction(ai.GroupID, r.ProductID, 'Odds Fee', @LastDay) AS HasOddsFee
		,dbo.AffAdmin_f_HasDeduction(ai.GroupID, r.ProductID, 'PlayerComm', @LastDay) AS HasPlayerComm
		,dbo.AffAdmin_f_GetDeductionPercent(ai.AffID, r.ProductID, 'Bonus', @LastDay) AS BonusPercent
		,dbo.AffAdmin_f_GetDeductionPercent(ai.AffID, r.ProductID, 'Adjustment', @LastDay) AS AdjustmentPercent
		,dbo.AffAdmin_f_GetDeductionPercent(ai.AffID, r.ProductID, 'Marketing', @LastDay) AS MarketingPercent
		,dbo.AffAdmin_f_GetDeductionPercent(ai.AffID, r.ProductID, 'PSP', @LastDay) AS PercentPSP
		,dbo.AffAdmin_f_GetDeductionPercent(ai.AffID, r.ProductID, 'Odds Fee', @LastDay) AS OddsFeePercent
		,dbo.AffAdmin_f_GetDeductionPercent(ai.AffID, r.ProductID, 'PlayerComm', @LastDay) AS PlayerCommPercent
		,SUM(ISNULL([MemBetCount], 0))
		,SUM(ISNULL([MemTurnoverNoDraw], 0))
		,SUM(ISNULL([MemBetCountNoDraw], 0))
		,SUM(ISNULL([MemTurnoverNoDraw_aff], 0))
		,SUM(ISNULL([MemWithdrawal], 0))
		,SUM(ISNULL([MemWithdrawal_aff], 0))
		,SUM(ISNULL([MemTurnoverDraw], 0))
		,SUM(ISNULL([MemTurnoverDraw_aff], 0))
		,[dbo].[IsZeroCommissionGroup](ai.GroupID, @LastDay)
		,SUM(ISNULL(PShare, 0)) PShare
		,SUM(ISNULL(PWin, 0)) PWin
		,SUM(ISNULL(PShare_aff, 0)) PShare_aff
		,SUM(ISNULL(PWin_aff, 0)) PWin_aff
		,SUM(ISNULL(MemberPlayerComm, 0)) MemberPlayerComm
		,SUM(ISNULL(MemberPlayerComm_aff, 0)) MemberPlayerComm_aff
	FROM @MemberSummary r	
		INNER JOIN AffCommGroupInfo ai
		ON r.AffID 	= ai.AffID
	GROUP BY ai.AffID
		,ai.Currency
		,ai.GroupID
		,r.ProductID
	
	--Update TotalActivePlayer
	UPDATE a
	SET a.TotalActivePlayer = ISNULL(t.TotalActivePlayer, 0)
	FROM @AffSummary a
		LEFT JOIN (
			SELECT m.AffID
				,m.ProductID
				,COUNT(DISTINCT m.username) AS TotalActivePlayer
			FROM @MemberSummary m
			WHERE m.MemTurnover > 0 --or m.MemDeposit>0  
			GROUP BY m.AffID
				,m.ProductID
		) t
		ON a.AffID 			= t.AffID
			AND a.ProductID = t.ProductID
	
	-- update netwinlost & sharing fees
	UPDATE a
	SET a.MemPSP 			= CAST(a.HasPSP AS INT) * ISNULL(a.MemPSP, 0) * ISNULL(a.PSPPercent, 1)
		,a.MemPSP_aff 		= CAST(a.HasPSP AS INT) * ISNULL(a.MemPSP_aff, 0) * ISNULL(a.PSPPercent, 1)
		,a.Marketing 		= CAST(a.HasMarketing AS INT) * ABS(ISNULL(a.MemWinlost, 0)) * ISNULL(a.MarketingPercent, 1)
		,a.Marketing_aff 	= CAST(a.HasMarketing AS INT) * ABS(ISNULL(a.MemWinlost_aff, 0)) * ISNULL(a.MarketingPercent, 1)
		,a.OddsFee 			= CAST(a.HasOddsFee AS INT) * ABS(ISNULL(a.MemWinlost, 0)) * ISNULL(a.OddsFeePercent, 1)
		,a.OddsFee_aff 		= CAST(a.HasOddsFee AS INT) * ABS(ISNULL(a.MemWinlost_aff, 0)) * ISNULL(a.OddsFeePercent, 1)
		,a.PlayerComm 		= CAST(a.HasPlayerComm AS INT) * ABS(ISNULL(a.PlayerComm, 0)) * ISNULL(a.PlayerCommPercent, 1)
		,a.PlayerComm_aff 	= CAST(a.HasPlayerComm AS INT) * ABS(ISNULL(a.PlayerComm_aff, 0)) * ISNULL(a.PlayerCommPercent, 1)
		,a.NetWinlost 		= (- ISNULL(a.MemWinlost, 0) 
								- CAST(a.HasPSP AS INT) * ISNULL(a.MemPSP, 0) * ISNULL(a.PSPPercent, 1) 
								- CAST(a.HasOddsFee AS INT) * ABS(ISNULL(a.MemWinlost, 0)) * ISNULL(a.OddsFeePercent, 1) 
								- CAST(a.HasMarketing AS INT) * ABS(ISNULL(a.MemWinlost, 0)) * ISNULL(a.MarketingPercent, 1) 
								- CAST(a.HasPlayerComm AS INT) * ISNULL(a.PlayerComm, 0) * ISNULL(a.PlayerCommPercent, 1))
		,a.NetWinlost_aff 	= (- ISNULL(a.MemWinlost_aff, 0) 
								- CAST(a.HasPSP AS INT) * ISNULL(a.MemPSP_aff, 0) * ISNULL(a.PSPPercent, 1) 
								- CAST(a.HasOddsFee AS INT) * ABS(ISNULL(a.MemWinlost_aff, 0)) * ISNULL(a.OddsFeePercent, 1) 
								- CAST(a.HasMarketing AS INT) * ABS(ISNULL(a.MemWinlost_aff, 0)) * ISNULL(a.MarketingPercent, 1) 
								- CAST(a.HasPlayerComm AS INT) * ISNULL(a.PlayerComm_aff, 0) * ISNULL(a.PlayerCommPercent, 1))
	FROM @AffSummary a
	
	--- UPDATE commission percent
	UPDATE a
	SET a.commission 	= ISNULL((
					SELECT TOP (1) c.Commission
					FROM (
							------------current group setting --------------
							SELECT ISNULL((
									SELECT ISNULL(gs.Commission, 0) AS Commission
									FROM dbo.GroupSetting gs WITH(NOLOCK)
									WHERE gs.GroupID 		= a.GroupID
										AND gs.ProductID 	= a.ProductID
										AND FLOOR(ABS(a.NetWinlost_aff)) BETWEEN gs.MinAmount AND gs.MaxAmount
									), 0) AS Commission
							WHERE DATEDIFF(m, @LastDay, @ToDay) = 0
						
							UNION ALL
							SELECT ISNULL((
										SELECT TOP (1) ISNULL(gs.Commission, 0) AS Commission
										FROM dbo.GroupSetting gs WITH(NOLOCK)
										WHERE gs.GroupID 		= a.GroupID
											AND gs.ProductID 	= a.ProductID
											AND a.TotalQM BETWEEN gs.MinQM AND gs.MaxQM
											
										), 0) AS Commission
							WHERE DATEDIFF(m, @LastDay, @ToDay) = 0
							
							------------history group setting --------------							
							UNION ALL
							SELECT ISNULL((
										SELECT gh.Commission
										FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
										WHERE gh.GroupID 		= a.GroupID
											AND gh.ProductID 	= a.ProductID
											AND gh.MonthDate 	= @LastDay
											AND FLOOR(ABS(a.NetWinlost_aff)) BETWEEN gh.MinAmount AND gh.MaxAmount
										), 0) AS Commission
							
							UNION ALL
							SELECT ISNULL((
										SELECT TOP (1) gh.Commission
										FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
										WHERE gh.GroupID 		= a.GroupID
											AND gh.ProductID 	= a.ProductID
											AND gh.MonthDate 	= @LastDay
											AND a.TotalQM BETWEEN gh.MinQM AND gh.MaxQM
										), 0) AS Commission
						) c
						ORDER BY c.Commission ASC
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
				SELECT DISTINCT gs.ProductID
				FROM dbo.GroupSetting gs WITH(NOLOCK)
				WHERE gs.GroupID = a.GroupID
					AND DATEDIFF(m, @LastDay, @ToDay) = 0
					
				UNION 
				SELECT DISTINCT gh.ProductID
				FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
				WHERE gh.GroupID = a.GroupID
					AND DATEDIFF(m, gh.MonthDate, @LastDay) = 0
			)
	--Insert transaction to AffTrans and AffCommission  
	DECLARE @WinlostDate SMALLDATETIME

	SELECT @WinlostDate = CURRENT_TIMESTAMP

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
		,[HasPlayerComm]
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
		,PlayerComm
		,PlayerComm_aff
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
		,HasPlayerComm
		,@Status
		,((NetWinlost - CAST(a.HasBonus AS INT) * ISNULL(a.MemBonus, 0) * ISNULL(a.BonusPercent, 1)) * ISNULL(Commission, 0) ) * CASE 
				WHEN a.ZeroCommission = 1 THEN 0
				ELSE 1
				END
		,MemWinlost
		,MemBonus
		,MemAdjustment
		,MemPSP
		,- NetWinlost
		,MemTurnover
		,MemDeposit
		,Marketing
		,OddsFee
		,((NetWinlost_aff - CAST(a.HasBonus AS INT) * ISNULL(a.MemBonus_aff, 0) * ISNULL(a.BonusPercent, 1)) * ISNULL(Commission, 0)) * CASE 
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
		,PlayerComm
		,PlayerComm_aff
	FROM @AffSummary a

	RETURN;
END
GO
