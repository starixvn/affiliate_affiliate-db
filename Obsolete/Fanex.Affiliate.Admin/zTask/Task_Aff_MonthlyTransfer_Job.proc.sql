ALTER PROCEDURE [dbo].[Task_Aff_MonthlyTransfer_Job] 
	@Month INT
	,@Year INT
AS
/*  
Created: 20090812@DungTong  
Task : Monthly transfer for all Affiliate  
DB: Affiliate_Licensee  
Original:  
  
Revisions:      
    - 200900217@Dung:   
            + Use Tier Commission to calculate monthly earning for each Affiliate based on Aff's member winlosts.  
               To get commission value on what tier we do 3 phases:  
                 .Calculate Number Of Qualified members on this month (member that have the turn over for this month is greater than or equal to 100$)  
                 .Calculate winlost for each member on this month.  
                 .Calculate Deductions (based on deduction setting from affiliate's Group)  
                 .we have NetWinlost=WinLost-Deduction, TotalQMs  
                 .For each Affiliate we get commission value by this way:  
                      When TotalWinlost>0  
                           Commission=Commission by Net Winlost  
                      When TotalWinlost<=0                              
                        Commission=Min(Commission got by |NetWinlost| between MiAmount and MaxAmount, Commission got by TotalQMs between MinQM and MaxQMs)    
                 . Aff's Earning=NetWinlost * Commission  
            + We have only one place to get Winlost and Other Data from MemberDaily. and the day excute this task must greater than the last day of selected month                  
            + Qualifying member: Get Setting AFF_QMTurnOver from SystemSettings. Each member has  TurnOver>AFF_QMTurnOver --> qualified member  
            + All the transactions have the status=completed  
     - 20091203@Peter: Add Auto deduct transactions for Marketing fee  
                        Deduction=Affiliate Net Earning * 20%  
     - 20100115@Peter : Remove Auto deduct transactions for Marketing fee  
                        http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890&sid=58e8c31d51dac7ddbef907a7a258c6cf&p=14064#p14064  
                          
     -20100211@Peter: #381 IRP - AffSite - Revise the calculations of the tier commission and PSP charge fee    
                      http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890        
                        
                     CNW=sum[(your total member's lost- your total member's won- bonus  - adjustment -  Marketing Fee)  * ExRate2].              
                     AComm= Min(commission get by |CNW|, commission get by TQM)  
                     MF= |Total Member's Lost-Total Member's Won| *  5%  
                     AE = CNW * Acomm  
                     AFE = AE -  PSP * 50%  
                       
                     Reupdate table AffDaily.   
                       
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
         
  - 20131029@Peter : Add more columns to DB https://redmine.nexcel.vn/issues/5280  
                    - Calculate Affiliate BF in AffInfo table                     
  - 20140212@Bobby.Nguyen: Update amount of AffTrans based on aff currency        
  - 20140418@Bobby.Nguyen: Validate amount of NoCommission group
  - 20140429@Bobby.Nguyen: Update calculating amount of NoCommission group
  - 20140520@Bobby.Nguyen: Update calculating TotalQM by comparing MemberTurnover_Aff value
  - 20140610@Bobby: Add PShare & PWin columns
  - 20140702@Bobby.Nguyen: Force to update Commission when Company Net Win is negative
  - 20140821@Bobby: Support PlayerComm

Param's Explanation:  
• @Month: The month to transfer  
• @Year :  The year to transfer       
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @FirstDay 					SMALLDATETIME
		,@LastDay 						SMALLDATETIME
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
		,@Status 		= 'Approved'

	IF @LastDay > Current_TimeStamp
	BEGIN
		SELECT 'The month is not completed yet. So you cannot transfer!' Result

		SELECT @FirstDay AS FirstDay
			,@LastDay AS LastDay

		RETURN
	END

	--Check group History data is inserted  
	IF (
			NOT EXISTS (
				SELECT TOP (1) 1
				FROM dbo.CommGroupHistory(NOLOCK)
				WHERE monthdate = @LastDay
				)
			OR NOT EXISTS (
				SELECT TOP (1) 1
				FROM dbo.GroupSettingHistory(NOLOCK)
				WHERE monthdate = @LastDay
				)
			--  or not exists(select top(1) 1 from DeductionSettingHistory (nolock) where monthdate=@LastDay)  
			OR NOT EXISTS (
				SELECT TOP (1) 1
				FROM dbo.AffGroupHistory(NOLOCK)
				WHERE monthdate = @LastDay
				)
			)
	BEGIN
		SELECT 'All group setting history data for selected month have not been updated yet. Please update data first by executing Task_Aff_GroupSettingBackup @Month,@Year!' Result

		SELECT @FirstDay AS FirstDay
			,@LastDay AS LastDay

		RETURN
	END

	IF EXISTS (
			SELECT TOP (1) 1
			FROM dbo.AffCommission WITH (NOLOCK)
			WHERE WinlostDate = @LastDay
			)
	BEGIN
		SELECT 'Please check the data. Transfers have been done for this month!' Result

		SELECT @FirstDay AS FirstDay
			,@LastDay AS LastDay

		RETURN
	END
	
	--Create temp table to get summary data for each affiliate  
	CREATE TABLE #MemberSummary (
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
		,MemPlayerComm 			MONEY
		,MemPlayerComm_aff 		MONEY
	)

	INSERT INTO #MemberSummary (
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
		,MemPlayerComm
		,MemPlayerComm_aff
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
		,SUM(ISNULL(PlayerComm, 0) * ISNULL(SysExRate, 1)) AS MemPlayerComm
		,SUM(ISNULL(PlayerComm, 0) * ISNULL(AffExRate, 1)) AS MemPlayerComm_aff
	FROM dbo.MemberDaily md WITH(NOLOCK)
	WHERE WinlostDate BETWEEN @FirstDay AND @LastDay
	GROUP BY username
		,ProductID
		,AffID

	IF (@@ROWCOUNT = 0)
	BEGIN
		SELECT 'There was no data for selected month to transfer!' AS Result

		SELECT @FirstDay AS FirstDay
			,@LastDay AS LastDay

		DROP TABLE #MemberSummary

		RETURN
	END

	--Create temp table to get summary data for each affiliate  
	CREATE TABLE #AffSummary (
		AffID 						INT
		,Currency 					SMALLINT
		,GroupID 					INT
		,ProductID 					INT
		,MemWinlost 				MONEY
		,MemBonus 					MONEY
		,MemAdjustment 				MONEY
		,MemPSP 					MONEY
		,Marketing 					MONEY
		,OddsFee 					MONEY
		,MemDeposit 				MONEY
		,MemTurnover 				MONEY
		,NetWinlost 				MONEY
		,MemWinlost_aff 			MONEY
		,MemBonus_aff 				MONEY
		,MemAdjustment_aff 			MONEY
		,MemPSP_aff 				MONEY
		,Marketing_aff 				MONEY
		,OddsFee_aff 				MONEY
		,MemDeposit_aff 			MONEY
		,MemTurnover_aff 			MONEY
		,NetWinlost_aff 			MONEY
		,Commission 				DECIMAL(9, 8)
		,TotalQM 					INT
		,TotalActivePlayer 			INT
		,HasBonus 					BIT
		,HasMarketing 				BIT
		,HasAdjustment 				BIT
		,HasPSP 					BIT
		,HasOddsFee 				BIT
		,HasPlayerComm 				BIT
		,BonusPercent 				FLOAT
		,MarketingPercent 			FLOAT
		,AdjustmentPercent 			FLOAT
		,PSPPercent 				FLOAT
		,OddsFeePercent 			FLOAT
		,PlayerCommPercent 			FLOAT
		,[MemBetCount] 				INT
		,[MemTurnoverNoDraw] 		MONEY
		,[MemBetCountNoDraw] 		INT
		,[MemTurnoverNoDraw_aff] 	MONEY
		,[MemWithdrawal] 			MONEY
		,[MemWithdrawal_aff] 		MONEY
		,[MemTurnoverDraw] 			MONEY
		,[MemTurnoverDraw_aff] 		MONEY
		,ZeroCommission 			INT
		,PShare 					MONEY
		,PWin 						MONEY
		,PShare_aff 				MONEY
		,PWin_aff 					MONEY
		,PlayerComm 				MONEY
		,PlayerComm_aff 			MONEY
		)

	INSERT INTO #AffSummary (
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
	SELECT ai.AffID AS AffID
		,ai.Currency AS Currency
		,gh.GroupID AS GroupID
		,r.ProductID AS ProductID
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
		,SUM(CASE 
				WHEN ISNULL(r.MemTurnover_aff, 0) >= ch.QualifiedAmount THEN 1
				ELSE 0
				END) AS TotalQM
		,dbo.AffAdmin_f_HasDeduction(gh.GroupID, r.ProductID, 'Bonus', @LastDay) AS HasBonus
		,dbo.AffAdmin_f_HasDeduction(gh.GroupID, r.ProductID, 'Marketing', @LastDay) AS HasMarketing
		,dbo.AffAdmin_f_HasDeduction(gh.GroupID, r.ProductID, 'Adjustment', @LastDay) AS HasAdjustment
		,dbo.AffAdmin_f_HasDeduction(gh.GroupID, r.ProductID, 'PSP', @LastDay) AS HasPSP
		,dbo.AffAdmin_f_HasDeduction(gh.GroupID, r.ProductID, 'Odds Fee', @LastDay) AS HasOddsFee
		,dbo.AffAdmin_f_HasDeduction(gh.GroupID, r.ProductID, 'PlayerComm', @LastDay) AS HasPlayerComm
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
		,dbo.IsZeroCommissionGroup(gh.GroupID, @LastDay)
		,SUM(ISNULL(PShare, 0)) PShare
		,SUM(ISNULL(PWin, 0)) PWin
		,SUM(ISNULL(PShare_aff, 0)) PShare_aff
		,SUM(ISNULL(PWin_aff, 0)) PWin_aff
		,SUM(ISNULL(MemPlayerComm, 0)) PlayerComm
		,SUM(ISNULL(MemPlayerComm_aff, 0)) PlayerComm_aff
	FROM #MemberSummary r
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK)
		ON r.AffID = ai.AffID
		INNER JOIN dbo.AffGroupHistory gh WITH (NOLOCK)
		ON gh.AffID = ai.AffID
			AND gh.MonthDate = @LastDay
		INNER JOIN dbo.CommGroupHistory ch WITH (NOLOCK)
		ON ch.groupid = gh.groupid
			AND ch.MonthDate = @LastDay
	WHERE ai.STATUS = @Status
	GROUP BY ai.AffID
		,ai.Currency
		,gh.GroupID
		,r.ProductID

	DELETE
	FROM #AffSummary
	WHERE ProductID IS NULL

	UPDATE a
	SET a.TotalActivePlayer = ISNULL(t.TotalActivePlayer, 0)
	FROM #AffSummary a WITH (NOLOCK)
		LEFT JOIN (
			SELECT m.AffID
				,m.ProductID
				,COUNT(DISTINCT m.username) AS TotalActivePlayer
			FROM #MemberSummary m
			WHERE m.MemTurnover > 0 --or m.MemDeposit>0  
			GROUP BY m.AffID
				,m.ProductID
		) t
		ON a.AffID = t.AffID
			AND a.ProductID = t.ProductID

	--Update Sharing fees
	UPDATE a
	SET a.MemPSP 			= CAST(a.HasPSP AS INT) * ISNULL(a.MemPSP, 0) * ISNULL(a.PSPPercent, 1)
		,a.MemPSP_aff 		= CAST(a.HasPSP AS INT) * ISNULL(a.MemPSP_aff, 0) * ISNULL(a.PSPPercent, 1)
		,a.Marketing 		= CAST(a.HasMarketing AS INT) * ABS(ISNULL(a.MemWinlost, 0)) * ISNULL(a.MarketingPercent, 1)
		,a.Marketing_aff 	= CAST(a.HasMarketing AS INT) * ABS(ISNULL(a.MemWinlost_aff, 0)) * ISNULL(a.MarketingPercent, 1)
		,a.OddsFee 			= CAST(a.HasOddsFee AS INT) * ABS(ISNULL(a.MemWinlost, 0)) * ISNULL(a.OddsFeePercent, 1)
		,a.OddsFee_aff 		= CAST(a.HasOddsFee AS INT) * ABS(ISNULL(a.MemWinlost_aff, 0)) * ISNULL(a.OddsFeePercent, 1)
		,a.PlayerComm 		= CAST(a.HasPlayerComm AS INT) * ABS(ISNULL(a.PlayerComm, 0)) * ISNULL(a.PlayerCommPercent, 1)
		,a.PlayerComm_aff 	= CAST(a.HasPlayerComm AS INT) * ABS(ISNULL(a.PlayerComm_aff, 0)) * ISNULL(a.PlayerCommPercent, 1)
	FROM #AffSummary a
	
	-- Update NetWinLoss
	UPDATE a
	SET a.NetWinlost 		= (- ISNULL(a.MemWinlost, 0) 
								- ISNULL(a.MemPSP, 0)
								- ISNULL(a.Marketing, 0) 
								- ISNULL(a.OddsFee, 0)
								- ISNULL(a.PlayerComm, 0))
		,a.NetWinlost_aff 	= (- ISNULL(a.MemWinlost_aff, 0) 
								- ISNULL(a.MemPSP_aff, 0)
								- ISNULL(a.Marketing_aff, 0) 
								- ISNULL(a.OddsFee_aff, 0)
								- ISNULL(a.PlayerComm_aff, 0))
	FROM #AffSummary a

	--Update Commission percent
	UPDATE a
	SET a.commission 		= ISNULL((
				SELECT TOP (1) Commission
				FROM (
					SELECT ISNULL((
								SELECT Commission
								FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
								WHERE gh.GroupID 		= a.GroupID
									AND gh.ProductID 	= a.ProductID
									AND gh.MonthDate 	= @LastDay
									AND FLOOR(ABS(a.NetWinlost_aff)) BETWEEN gh.MinAmount AND gh.MaxAmount
								), 0) AS Commission
					
					UNION ALL
					SELECT ISNULL((
								SELECT TOP (1) Commission
								FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
								WHERE gh.GroupID 		= a.GroupID
									AND gh.ProductID 	= a.ProductID
									AND gh.MonthDate 	= @LastDay
									AND a.TotalQM BETWEEN gh.MinQM AND gh.MaxQM
								), 0) AS Commission
					) t
				ORDER BY t.Commission ASC
				), 0)
	FROM #AffSummary a
	/*
	-- check/update Negative Commission
	-- force update min comm (inorge tier rule ITCBET[OR @IsForceMinNegativeCommission = 1])
	*/
	UPDATE a
	SET a.Commission = @MinimumNegativeCommission
	FROM #AffSummary a
	WHERE a.NetWinlost_aff < 0
		AND (a.Commission = 0 OR @IsForceMinNegativeCommission = 1) 
		AND a.ZeroCommission = 0
		AND a.ProductID IN (
			SELECT DISTINCT gh.ProductID
			FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
			WHERE gh.GroupID = a.GroupID
				AND gh.MonthDate BETWEEN @FirstDay AND @LastDay
		)

	--Insert transaction to AffTrans and AffCommission  
	DECLARE @WinlostDate SMALLDATETIME

	SELECT @WinlostDate = current_timestamp

	DECLARE @SystemCurrency SMALLINT

	SET @SystemCurrency = dbo.Aff_GetSystemCurrencyID()

	BEGIN TRANSACTION

	BEGIN TRY
		DECLARE @Temp TABLE (
			RefID INT
			,AffID INT
			,ProductID TINYINT
			)

		-- Insert transaction to AffCommission  
		INSERT INTO [AffCommission] (
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
			,[PShare]
			,[PWin]
			,[PShare_aff]
			,[PWin_aff]
			,PlayerComm
			,PlayerComm_aff
			)
		OUTPUT inserted.RefID
			,inserted.AffID
			,inserted.ProductID
		INTO @Temp
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
			,(a.NetWinlost - CAST(a.HasBonus AS INT) * ISNULL(a.MemBonus, 0) * ISNULL(a.BonusPercent, 1)) * ISNULL(Commission, 0) * CASE 
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
			,((a.NetWinlost_aff - CAST(a.HasBonus AS INT) * ISNULL(a.MemBonus_aff, 0) * ISNULL(a.BonusPercent, 1)) * ISNULL(Commission, 0)) * CASE 
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
			,[PShare]
			,[PWin]
			,[PShare_aff]
			,[PWin_aff]
			,PlayerComm
			,PlayerComm_aff
		FROM #AffSummary a(NOLOCK)

		UPDATE d
		SET d.RelNo = (
				SELECT TOP (1) RefID
				FROM @Temp d1
				WHERE d1.AffID = d.AffID
					AND d1.RefID > 0
				)
		FROM dbo.AffCommission d WITH (ROWLOCK, UPDLOCK)
		WHERE d.WinlostDate = @LastDay

		-- Insert to AffTrans  
		-- Peter@20131205 : Add deduction overal to monthly transfer transaction  
		INSERT INTO dbo.AffTrans (
			AffID
			,TransDate
			,CompletedDate
			,Amount
			,STATUS
			,Description
			,Creator
			,AffCurrency
			,SysCurrency
			,SysExRate
			,TransType
			)
		SELECT a.AffID
			,@LastDay
			,@WinlostDate
			,(SUM((NetWinlost_aff - CAST(a.HasBonus AS INT) * ISNULL(a.MemBonus_aff, 0) * ISNULL(a.BonusPercent, 1)) * ISNULL(Commission, 0)) - [dbo].[Aff_GetAffDeductionAll](AffID, @LastDay)) * CASE 
				WHEN MAX(a.ZeroCommission) = 1 THEN 0
				ELSE 1
				END
			,@Status
			,'Monthly Earning'
			,9999
			,a.Currency
			,@SystemCurrency
			,dbo.Aff_GetExchangeRate(a.Currency, @SystemCurrency, @LastDay)
			,@TransType
		FROM #AffSummary a(NOLOCK)
		GROUP BY a.AffID
			,a.Currency

		UPDATE d
		SET d.RefID = (
				SELECT TOP (1) RefID
				FROM @Temp d1
				WHERE d1.AffID = d.AffID
					AND d1.RefID > 0
				)
		FROM dbo.AffTrans d WITH (ROWLOCK, UPDLOCK)
		WHERE d.TransDate = @LastDay
			AND d.TransType = @TransType
		
		--update AffDaily
		UPDATE ad
		SET ad.AffWinlost 		= - ISNULL(ad.MemWinlost, 0) * ISNULL(a.commission, 0)
			,ad.HouseWinlost 	= - ISNULL(ad.MemWinlost, 0) * (1 - ISNULL(a.commission, 0))
			,ad.AffNetWinlost 	= (ISNULL(a.NetWinlost, 0) - CAST(ISNULL(a.HasBonus, 0) AS INT) * ISNULL(ad.MemBonus, 0) * ISNULL(a.BonusPercent, 1)) * ISNULL(a.commission, 0)
			,ad.HouseNetWinlost = (ISNULL(a.NetWinlost, 0) - CAST(ISNULL(a.HasBonus, 0) AS INT) * ISNULL(ad.MemBonus, 0) * ISNULL(a.BonusPercent, 1)) * (1 - ISNULL(a.commission, 0))
		FROM dbo.AffDaily ad WITH (ROWLOCK, UPDLOCK)
			LEFT JOIN #AffSummary a WITH (NOLOCK)
			ON a.AffID = ad.AffID
				AND a.ProductID = ad.ProductID
		WHERE ad.Winlostdate BETWEEN @FirstDay AND @LastDay

		--update AffDailySummary
		UPDATE ad
		SET ad.AffWinlost 			= - ISNULL(ad.MemWinlost, 0) * ISNULL(a.commission, 0)
			,ad.HouseWinlost 		= - ISNULL(ad.MemWinlost, 0) * (1 - ISNULL(a.commission, 0))
			,ad.AffNetWinlost 		= (ISNULL(a.NetWinlost, 0) - CAST(ISNULL(a.HasBonus, 0) AS INT) * ISNULL(ad.MemBonus, 0) * ISNULL(a.BonusPercent, 1)) * ISNULL(a.commission, 0)
			,ad.HouseNetWinlost 	= (ISNULL(a.NetWinlost, 0) - CAST(ISNULL(a.HasBonus, 0) AS INT) * ISNULL(ad.MemBonus, 0) * ISNULL(a.BonusPercent, 1)) * (1 - ISNULL(a.commission, 0))
			,ad.AffWinlost_aff 		= - ISNULL(ad.MemWinlost_aff, 0) * ISNULL(a.commission, 0)
			,ad.HouseWinlost_aff 	= - ISNULL(ad.MemWinlost_aff, 0) * (1 - ISNULL(a.commission, 0))
			,ad.AffNetWinlost_aff 	= (ISNULL(a.NetWinlost_aff, 0) - CAST(ISNULL(a.HasBonus, 0) AS INT) * ISNULL(ad.MemBonus_aff, 0) * ISNULL(a.BonusPercent, 1)) * ISNULL(a.commission, 0)
			,ad.HouseNetWinlost_aff = (ISNULL(a.NetWinlost_aff, 0) - CAST(ISNULL(a.HasBonus, 0) AS INT) * ISNULL(ad.MemBonus_aff, 0) * ISNULL(a.BonusPercent, 1)) * (1 - ISNULL(a.commission, 0))
		FROM dbo.AffDailySummary ad WITH (ROWLOCK, UPDLOCK)
			LEFT JOIN #AffSummary a WITH (NOLOCK)
			ON a.AffID = ad.AffID
				AND a.ProductID = ad.ProductID
		WHERE ad.Winlostdate BETWEEN @FirstDay AND @LastDay

		-- Update BF for AffInfo  
		UPDATE ai
		SET ai.BF = dbo.[Aff_GetAffBalance](ad.AffID)
		FROM dbo.AffInfo ai WITH (ROWLOCK, UPDLOCK)
			INNER JOIN #AffSummary ad(NOLOCK)
			ON ad.AffID = ai.AffID
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION

		DROP TABLE #AffSummary

		DROP TABLE #MemberSummary

		PRINT ERROR_MESSAGE()

		RETURN
	END CATCH

	COMMIT TRANSACTION

	DECLARE @TaskID INT
		,@LogID INT
		,@RunDate DATETIME

	SELECT @RunDate = getdate()
		,@Status = 'completed'

	SELECT @TaskID = TaskID
	FROM TaskManager(NOLOCK)
	WHERE TaskName = 'Commission Monthly Transfer'

	EXEC [dbo].[Aff_TaskLogIns] @TaskID
		,@RunDate
		,@Status
		,@LogID OUTPUT

	DROP TABLE #AffSummary

	DROP TABLE #MemberSummary
END
GO