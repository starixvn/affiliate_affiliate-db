ALTER PROCEDURE [dbo].[Task_Aff_MonthlyTransfer_Job_xtest] 
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

	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME
	SELECT  @FromDate = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(5), @Year) + '-' + CONVERT(VARCHAR(5), @Month) + '-01')
	SELECT  @ToDate = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FromDate))

	-- Only run history month
	IF @ToDate > GETDATE()
	BEGIN
		SELECT 'The month is not completed yet. So you cannot transfer!' AS Result

		SELECT @FromDate AS FirstDay, @ToDate AS LastDay

		RETURN
	END

	-- Check setting history
	IF NOT EXISTS (SELECT 1 FROM dbo.CommGroupHistory WITH (NOLOCK) WHERE MonthDate = @ToDate)
		OR NOT EXISTS (SELECT 1 FROM dbo.GroupSettingHistory WITH (NOLOCK) WHERE MonthDate = @ToDate)
		OR NOT EXISTS (SELECT 1 FROM dbo.AffGroupHistory WITH (NOLOCK) WHERE MonthDate = @ToDate)
	BEGIN
		SELECT 'All group setting history data for selected month have not been updated yet. Please update data first by executing Task_Aff_GroupSettingBackup @Month, @Year!' AS Result

		SELECT @FromDate AS FirstDay, @ToDate AS LastDay

		RETURN
	END

	-- Check job run yet
	IF EXISTS (SELECT 1 FROM dbo.AffCommission WITH (NOLOCK) WHERE WinlostDate = @ToDate)
	BEGIN
		SELECT 'Please check the data. Transfers have been done for this month!' AS Result

		SELECT @FromDate AS FirstDay, @ToDate AS LastDay

		RETURN
	END

	-- Get data
	CREATE TABLE #MemberSummary
	(
		UserName 				VARCHAR(100)
		,AffId 					INT
		,ProductId 				INT
		,MemBetCount 			INT
		,MemBetCountNoDraw 		INT
		-- for member
		,MemWinlost 			MONEY
		,MemBonus 				MONEY
		,MemAdjustment 			MONEY
		,MemPSP 				MONEY
		,MemDeposit 			MONEY
		,MemTurnover 			MONEY
		,MemWithdrawal 			MONEY
		,MemTurnoverDraw 		MONEY
		,MemTurnoverNoDraw 		MONEY
		,PShare 				MONEY
		,PWin 					MONEY
		,MemPlayerComm 			MONEY
		-- for AFF
		,MemWinlost_aff 		MONEY
		,MemBonus_aff 			MONEY
		,MemAdjustment_aff 		MONEY
		,MemPSP_aff 			MONEY
		,MemDeposit_aff 		MONEY
		,MemTurnover_aff 		MONEY
		,MemWithdrawal_aff 		MONEY
		,MemTurnoverDraw_aff 	MONEY
		,MemTurnoverNoDraw_aff 	MONEY
		,PShare_aff 			MONEY
		,PWin_aff 				MONEY
		,MemPlayerComm_aff 		MONEY
	)

	INSERT INTO #MemberSummary
	(
		UserName
		,AffId
		,ProductId
		,MemBetCount
		,MemBetCountNoDraw
		,MemWinlost
		,MemBonus
		,MemAdjustment
		,MemPSP
		,MemDeposit
		,MemTurnover
		,MemWithdrawal
		,MemTurnoverDraw
		,MemTurnoverNoDraw
		,PShare
		,PWin
		,MemPlayerComm
		,MemWinlost_aff
		,MemBonus_aff
		,MemAdjustment_aff
		,MemPSP_aff
		,MemDeposit_aff
		,MemTurnover_aff
		,MemWithdrawal_aff
		,MemTurnoverDraw_aff
		,MemTurnoverNoDraw_aff
		,PShare_aff
		,PWin_aff
		,MemPlayerComm_aff
	)
	SELECT UserName, AffId, ProductId
		,SUM(ISNULL(BetCount, 0)) AS BetCount
		,SUM(ISNULL(BetCountNoDraw, 0)) AS BetCountNoDraw
		,SUM(ISNULL(Winlost, 0) * ISNULL(SysExRate, 1)) AS Winlost
		,SUM(ISNULL(Bonus, 0) * ISNULL(SysExRate, 1)) AS Bonus
		,SUM(ISNULL(Adjustment, 0) * ISNULL(SysExRate, 1)) AS Adjustment
		,SUM(ISNULL(PSP, 0) * ISNULL(SysExRate, 1)) AS PSP
		,SUM(ISNULL(Deposit, 0) * ISNULL(SysExRate, 1)) AS Deposit
		,SUM(ISNULL(TurnOver, 0) * ISNULL(SysExRate, 1)) AS TurnOver
		,SUM(ISNULL(Withdrawal, 0) * ISNULL(SysExRate, 1)) AS Withdrawal
		,SUM(ISNULL(TurnOverDraw, 0) * ISNULL(SysExRate, 1)) AS TurnOverDraw
		,SUM(ISNULL(TurnOverNoDraw, 0) * ISNULL(SysExRate, 1)) AS TurnOverNoDraw
		,SUM(ISNULL(PShare, 0) * ISNULL(SysExRate, 1)) AS PShare
		,SUM(ISNULL(PWin, 0) * ISNULL(SysExRate, 1)) AS PWin
		,SUM(ISNULL(PlayerComm, 0) * ISNULL(SysExRate, 1)) AS MemPlayerComm
		,SUM(ISNULL(Winlost, 0) * ISNULL(AffExRate, 1)) AS Winlost_aff
		,SUM(ISNULL(Bonus, 0) * ISNULL(AffExRate, 1)) AS Bonus_aff
		,SUM(ISNULL(Adjustment, 0) * ISNULL(AffExRate, 1)) AS Adjustment_aff
		,SUM(ISNULL(PSP, 0) * ISNULL(AffExRate, 1)) AS PSP_aff
		,SUM(ISNULL(Deposit, 0) * ISNULL(AffExRate, 1)) AS Deposit_aff
		,SUM(ISNULL(TurnOver, 0) * ISNULL(AffExRate, 1)) AS TurnOver_aff
		,SUM(ISNULL(Withdrawal, 0) * ISNULL(AffExRate, 1)) AS Withdrawal_aff
		,SUM(ISNULL(TurnOverDraw, 0) * ISNULL(AffExRate, 1)) AS TurnOverDraw_aff
		,SUM(ISNULL(TurnOverNoDraw, 0) * ISNULL(AffExRate, 1)) AS TurnOverNoDraw_aff
		,SUM(ISNULL(PShare, 0) * ISNULL(AffExRate, 1)) AS PShare_aff
		,SUM(ISNULL(PWin, 0) * ISNULL(AffExRate, 1)) AS PWin_aff
		,SUM(ISNULL(PlayerComm, 0) * ISNULL(AffExRate, 1)) AS MemPlayerComm_aff
	FROM dbo.MemberDaily WITH (NOLOCK)
	WHERE WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY UserName, AffId, ProductId

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT 'There was no data for selected month to transfer!' AS Result

		SELECT @FromDate AS FirstDay, @ToDate AS LastDay

		RETURN
	END

	-- Group Setting
	CREATE TABLE #GroupSetting (AffId INT, Currency INT, GroupId INT, QMTurnover MONEY)
	INSERT INTO #GroupSetting (AffId, Currency, GroupId, QMTurnover)
	SELECT a.AffId, ai.Currency, cgh.GroupId, cgh.QualifiedAmount
	FROM (SELECT DISTINCT AffId FROM #MemberSummary) a
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON a.AffId = ai.AffId AND ai.Status = 'Approved'
		INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON a.AffId = agh.AffId AND agh.MonthDate = @ToDate
		INNER JOIN dbo.CommGroupHistory cgh WITH (NOLOCK) ON agh.GroupId = cgh.GroupId AND cgh.MonthDate = @ToDate

	-- Deduction Setting
	CREATE TABLE #DeductionSetting (GroupId INT, ProductId TINYINT
		,HasBonus BIT, HasMarketing BIT, HasAdjustment BIT, HasPSP BIT, HasOddsFee BIT, HasPlayerComm BIT
		,Bonus DECIMAL(9,8), Marketing DECIMAL(9,8), Adjustment DECIMAL(9,8), PSP DECIMAL(9,8), OddsFee DECIMAL(9,8), PlayerComm DECIMAL(9,8))
	INSERT INTO #DeductionSetting (GroupId, ProductId
		,HasBonus, HasMarketing, HasAdjustment, HasPSP, HasOddsFee, HasPlayerComm
		, Bonus, Marketing, Adjustment, PSP, OddsFee, PlayerComm)
	SELECT t.GroupId, dt.ProductId
		,MAX(CASE WHEN dt.DTypeName = 'Bonus'		THEN 1 ELSE 0 END) AS HasBonus
		,MAX(CASE WHEN dt.DTypeName = 'Marketing'	THEN 1 ELSE 0 END) AS HasMarketing
		,MAX(CASE WHEN dt.DTypeName = 'Adjustment'	THEN 1 ELSE 0 END) AS HasAdjustment
		,MAX(CASE WHEN dt.DTypeName = 'PSP'			THEN 1 ELSE 0 END) AS HasPSP
		,MAX(CASE WHEN dt.DTypeName = 'Odds Fee'	THEN 1 ELSE 0 END) AS HasOddsFee
		,MAX(CASE WHEN dt.DTypeName = 'PlayerComm'	THEN 1 ELSE 0 END) AS HasPlayerComm
		,SUM(CASE WHEN dt.DTypeName = 'Bonus'		THEN t.DeductedPercentage ELSE 0 END) AS Bonus
		,SUM(CASE WHEN dt.DTypeName = 'Marketing'	THEN t.DeductedPercentage ELSE 0 END) AS Marketing
		,SUM(CASE WHEN dt.DTypeName = 'Adjustment'	THEN t.DeductedPercentage ELSE 0 END) AS Adjustment
		,SUM(CASE WHEN dt.DTypeName = 'PSP'			THEN t.DeductedPercentage ELSE 0 END) AS PSP
		,SUM(CASE WHEN dt.DTypeName = 'Odds Fee'	THEN t.DeductedPercentage ELSE 0 END) AS OddsFee
		,SUM(CASE WHEN dt.DTypeName = 'PlayerComm'	THEN t.DeductedPercentage ELSE 0 END) AS PlayerComm
	FROM (
		SELECT dsh.GroupId, dsh.DeductionId, dsh.DeductedPercentage
		FROM #GroupSetting gs
			INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON gs.GroupId = dsh.GroupId AND dsh.MonthDate = @ToDate
	) t
		INNER JOIN dbo.DeductionType dt WITH (NOLOCK) ON t.DeductionId = dt.DTypeId
	GROUP BY t.GroupId, dt.ProductId

	--Create temp table to get summary data for each affiliate  
	CREATE TABLE #AffSummary
	(
		AffId 						INT
		,Currency 					SMALLINT
		,GroupId 					INT
		,ProductId 					INT
		,ZeroCommission 			BIT
		,MemBetCount 				INT
		,MemBetCountNoDraw 			INT
		-- for member
		,MemWinlost 				MONEY
		,MemBonus 					MONEY
		,MemAdjustment 				MONEY
		,MemPSP 					MONEY
		,Marketing 					MONEY
		,OddsFee 					MONEY
		,MemDeposit 				MONEY
		,MemWithdrawal 				MONEY
		,MemTurnover 				MONEY
		,MemTurnoverDraw 			MONEY
		,MemTurnoverNoDraw 			MONEY
		,NetWinlost 				MONEY
		,PShare 					MONEY
		,PWin 						MONEY
		,PlayerComm 				MONEY
		-- for AFF
		,MemWinlost_aff 			MONEY
		,MemBonus_aff 				MONEY
		,MemAdjustment_aff 			MONEY
		,MemPSP_aff 				MONEY
		,Marketing_aff 				MONEY
		,OddsFee_aff 				MONEY
		,MemDeposit_aff 			MONEY
		,MemWithdrawal_aff 			MONEY
		,MemTurnover_aff 			MONEY
		,MemTurnoverDraw_aff 		MONEY
		,MemTurnoverNoDraw_aff 		MONEY
		,NetWinlost_aff 			MONEY
		,PShare_aff 				MONEY
		,PWin_aff 					MONEY
		,PlayerComm_aff 			MONEY
		-- Commission Calculation
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
	)

	;WITH CTE_MemberSummary AS
	(
		SELECT s.AffId, ISNULL(g.GroupProductId, s.ProductId) AS ProductId, s.UserName
			,SUM(ISNULL(s.MemBetCount, 0))				AS MemBetCount
			,SUM(ISNULL(s.MemBetCountNoDraw, 0))		AS MemBetCountNoDraw
			,SUM(ISNULL(s.MemWinlost, 0))				AS MemWinlost
			,SUM(ISNULL(s.MemBonus, 0))					AS MemBonus
			,SUM(ISNULL(s.MemAdjustment, 0))			AS MemAdjustment
			,SUM(ISNULL(s.MemPSP, 0))					AS MemPSP
			,SUM(ISNULL(s.MemDeposit, 0))				AS MemDeposit
			,SUM(ISNULL(s.MemWithdrawal, 0))			AS MemWithdrawal
			,SUM(ISNULL(s.MemTurnover, 0))				AS MemTurnover
			,SUM(ISNULL(s.MemTurnoverDraw, 0))			AS MemTurnoverDraw
			,SUM(ISNULL(s.MemTurnoverNoDraw, 0))		AS MemTurnoverNoDraw
			,SUM(ISNULL(s.PShare, 0))					AS PShare
			,SUM(ISNULL(s.PWin, 0))						AS PWin
			,SUM(ISNULL(s.MemPlayerComm, 0))			AS MemPlayerComm
			,SUM(ISNULL(s.MemWinlost_aff, 0))			AS MemWinlost_aff
			,SUM(ISNULL(s.MemBonus_aff, 0))				AS MemBonus_aff
			,SUM(ISNULL(s.MemAdjustment_aff, 0))		AS MemAdjustment_aff
			,SUM(ISNULL(s.MemPSP_aff, 0))				AS MemPSP_aff
			,SUM(ISNULL(s.MemDeposit_aff, 0))			AS MemDeposit_aff
			,SUM(ISNULL(s.MemWithdrawal_aff, 0))		AS MemWithdrawal_aff
			,SUM(ISNULL(s.MemTurnover_aff, 0))			AS MemTurnover_aff
			,SUM(ISNULL(s.MemTurnoverDraw_aff, 0))		AS MemTurnoverDraw_aff
			,SUM(ISNULL(s.MemTurnoverNoDraw_aff, 0))	AS MemTurnoverNoDraw_aff
			,SUM(ISNULL(s.PShare_aff, 0))				AS PShare_aff
			,SUM(ISNULL(s.PWin_aff, 0))					AS PWin_aff
			,SUM(ISNULL(s.MemPlayerComm_aff, 0))		AS MemPlayerComm_aff
		FROM #MemberSummary s
			LEFT JOIN dbo.Aff_f_GroupProduct() g ON s.ProductId = g.ProductId
		GROUP BY s.AffId, ISNULL(g.GroupProductId, s.ProductId), s.UserName
	)
	INSERT INTO #AffSummary
	(
		AffId, Currency, GroupId, ProductId, TotalQM, TotalActivePlayer, MemBetCount, MemBetCountNoDraw
		,MemWinlost, MemBonus, MemAdjustment, MemPSP, MemDeposit, MemWithdrawal, MemTurnover, MemTurnoverDraw, MemTurnoverNoDraw, PShare, PWin
		,MemWinlost_aff, MemBonus_aff, MemAdjustment_aff, MemPSP_aff, MemDeposit_aff, MemWithdrawal_aff, MemTurnover_aff, MemTurnoverDraw_aff, MemTurnoverNoDraw_aff, PShare_aff, PWin_aff
		,HasBonus, HasMarketing, HasAdjustment, HasPSP, HasOddsFee, HasPlayerComm
		,BonusPercent, MarketingPercent, AdjustmentPercent, PSPPercent, OddsFeePercent, PlayerCommPercent
		,Marketing, OddsFee, PlayerComm, Marketing_aff, PlayerComm_aff, OddsFee_aff, NetWinlost, NetWinlost_aff
	)
	SELECT r.AffId, r.Currency, r.GroupId, r.ProductId, r.TotalQM, r.TotalActivePlayer
		,r.MemBetCount, r.MemBetCountNoDraw, r.MemWinlost, r.MemBonus, r.MemAdjustment, r.MemPSP * ds.PSP AS MemPSP, r.MemDeposit, r.MemWithdrawal, r.MemTurnover, r.MemTurnoverDraw, r.MemTurnoverNoDraw, r.PShare, r.PWin
		,r.MemWinlost_aff, r.MemBonus_aff, r.MemAdjustment_aff, r.MemPSP_aff * ds.PSP AS MemPSP_aff, r.MemDeposit_aff, r.MemWithdrawal_aff, r.MemTurnover_aff, r.MemTurnoverDraw_aff, r.MemTurnoverNoDraw_aff, r.PShare_aff, r.PWin_aff
		,ds.HasBonus, ds.HasMarketing, ds.HasAdjustment, ds.HasPSP, ds.HasOddsFee, ds.HasPlayerComm
		,ds.Bonus		AS BonusPercent
		,ds.Marketing	AS MarketingPercent
		,ds.Adjustment	AS AdjustmentPercent
		,ds.PSP			AS PSPPercent
		,ds.OddsFee		AS OddsFeePercent
		,ds.PlayerComm	AS PlayerCommPercent
		,ABS(r.MemWinlost) * ds.Marketing		AS Marketing
		,ABS(r.MemWinlost) * ds.OddsFee			AS OddsFee
		,ABS(r.MemPlayerComm) * ds.PlayerComm	AS PlayerComm
		,ABS(r.MemWinlost_aff) * ds.Marketing		AS Marketing_aff
		,ABS(r.MemPlayerComm_aff) * ds.PlayerComm	AS PlayerComm_aff
		,ABS(r.MemWinlost_aff) * ds.OddsFee			AS OddsFee_aff
		-- Net Winlost
		,-r.MemWinlost
			- r.MemPSP * ds.PSP
			- ABS(r.MemWinlost) * ds.Marketing
			- ABS(r.MemWinlost) * ds.OddsFee
			- ABS(r.MemPlayerComm) * ds.PlayerComm AS NetWinlost
		,-r.MemWinlost_aff
			- r.MemPSP_aff * ds.PSP
			- ABS(r.MemWinlost_aff) * ds.Marketing
			- ABS(r.MemWinlost_aff) * ds.OddsFee
			- ABS(r.MemPlayerComm_aff) * ds.PlayerComm AS NetWinlost_aff
	FROM (
		SELECT s.AffId, g.Currency, g.GroupId, s.ProductId
			,SUM(CASE WHEN ISNULL(s.MemTurnover_aff, 0) > g.QMTurnover THEN 1 ELSE 0 END) AS TotalQM
			,SUM(CASE WHEN ISNULL(s.MemTurnover, 0) > 0 THEN 1 ELSE 0 END) AS TotalActivePlayer
			,SUM(ISNULL(s.MemBetCount, 0))				AS MemBetCount
			,SUM(ISNULL(s.MemBetCountNoDraw, 0))		AS MemBetCountNoDraw
			,SUM(ISNULL(s.MemWinlost, 0))				AS MemWinlost
			,SUM(ISNULL(s.MemBonus, 0))					AS MemBonus
			,SUM(ISNULL(s.MemAdjustment, 0))			AS MemAdjustment
			,SUM(ISNULL(s.MemPSP, 0))					AS MemPSP
			,SUM(ISNULL(s.MemDeposit, 0))				AS MemDeposit
			,SUM(ISNULL(s.MemWithdrawal, 0))			AS MemWithdrawal
			,SUM(ISNULL(s.MemTurnover, 0))				AS MemTurnover
			,SUM(ISNULL(s.MemTurnoverDraw, 0))			AS MemTurnoverDraw
			,SUM(ISNULL(s.MemTurnoverNoDraw, 0))		AS MemTurnoverNoDraw
			,SUM(ISNULL(s.PShare, 0))					AS PShare
			,SUM(ISNULL(s.PWin, 0))						AS PWin
			,SUM(ISNULL(s.MemPlayerComm, 0))			AS MemPlayerComm
			,SUM(ISNULL(s.MemWinlost_aff, 0))			AS MemWinlost_aff
			,SUM(ISNULL(s.MemBonus_aff, 0))				AS MemBonus_aff
			,SUM(ISNULL(s.MemAdjustment_aff, 0))		AS MemAdjustment_aff
			,SUM(ISNULL(s.MemPSP_aff, 0))				AS MemPSP_aff
			,SUM(ISNULL(s.MemDeposit_aff, 0))			AS MemDeposit_aff
			,SUM(ISNULL(s.MemWithdrawal_aff, 0))		AS MemWithdrawal_aff
			,SUM(ISNULL(s.MemTurnover_aff, 0))			AS MemTurnover_aff
			,SUM(ISNULL(s.MemTurnoverDraw_aff, 0))		AS MemTurnoverDraw_aff
			,SUM(ISNULL(s.MemTurnoverNoDraw_aff, 0))	AS MemTurnoverNoDraw_aff
			,SUM(ISNULL(s.PShare_aff, 0))				AS PShare_aff
			,SUM(ISNULL(s.PWin_aff, 0))					AS PWin_aff
			,SUM(ISNULL(s.MemPlayerComm_aff, 0))		AS MemPlayerComm_aff
		FROM CTE_MemberSummary s
			INNER JOIN #GroupSetting g ON s.AffId = g.AffId
		GROUP BY s.AffId, g.Currency, g.GroupId, s.ProductId
	) r
		INNER JOIN #DeductionSetting ds ON r.GroupId = ds.GroupId AND r.ProductId = ds.ProductId

	UPDATE t
	SET t.Commission = ISNULL(b.Commission, 0)
	FROM #AffSummary t
		OUTER APPLY (
			SELECT TOP 1 gsh.Commission
			FROM dbo.GroupSettingHistory gsh WITH (NOLOCK)
			WHERE t.GroupId = gsh.GroupId
				AND t.ProductId = gsh.ProductId
				AND gsh.MonthDate = @ToDate
				AND (
					FLOOR(ABS(t.NetWinlost_aff)) BETWEEN gsh.MinAmount AND gsh.MaxAmount
					OR t.TotalQM BETWEEN gsh.MinQM AND gsh.MaxQM
				)
			ORDER BY gsh.Commission
		) b
	
	-- Default Setting
	DECLARE @NoCommissionGroupId INT = 0
	SELECT  @NoCommissionGroupId = ISNULL(GroupId, 0) FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupName = 'NoCommission'
	
	DECLARE @IsForceMinNegativeCommission BIT = 0, @MinimumNegativeCommission FLOAT = 0.1
	SELECT  @MinimumNegativeCommission 	= CASE WHEN SName = 'AFF_MinNegativeCommission' THEN ISNULL(SValue, @MinimumNegativeCommission) ELSE @MinimumNegativeCommission END
		,@IsForceMinNegativeCommission 	= CASE WHEN SName = 'AFF_ForceMinNegativeCommission' THEN ISNULL(SValue, @IsForceMinNegativeCommission) ELSE @IsForceMinNegativeCommission END
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName IN ('AFF_ForceMinNegativeCommission', 'AFF_MinNegativeCommission')
	
	IF @IsForceMinNegativeCommission = 1
	BEGIN
		UPDATE t
		SET t.Commission = @MinimumNegativeCommission
		FROM #AffSummary t
			CROSS APPLY (
				SELECT gsh.ProductId
				FROM dbo.GroupSettingHistory gsh WITH (NOLOCK)
				WHERE t.GroupId = gsh.GroupId AND t.ProductId = gsh.ProductId AND gsh.MonthDate = @ToDate
			) g
		WHERE t.GroupId IN (0, @NoCommissionGroupId)
			AND t.NetWinlost_aff < 0 AND t.Commission = 0 AND g.ProductId IS NOT NULL
	END

	-- Insert transaction
	DECLARE @Temp TABLE (RefId BIGINT, AffId INT, ProductId TINYINT)
	
	DECLARE @SystemCurrency SMALLINT = dbo.Aff_GetSystemCurrencyID()
	
	INSERT INTO dbo.AffCommission
	(
		AffId, GroupId, ProductId, WinlostDate, AffCurrency, SysCurrency
		,MemberBetCount, MemberBetCountNoDraw
		,MemberBonus, MemberAdjustment, MemberDeposit, MemberWithdrawal, PShare, PWin, PlayerComm
		,MemberBonus_aff, MemberAdjustment_aff, MemberDeposit_aff, MemberWithdrawal_aff, PShare_Aff, PWin_Aff, PlayerComm_aff
		,MemberWinlost, MemberPSP, MemberSum, MemberTurnover, MemberTurnoverDraw, MemberTurnoverNoDraw, Marketing, MemOddsFee
		,MemberWinlost_aff, MemberPSP_aff, MemberSum_aff, MemberTurnover_aff, MemberTurnoverDraw_aff, MemberTurnoverNoDraw_aff, Marketing_aff, MemOddsFee_aff
		,HasBonus, HasAdjustment, HasMarketing, HasPSP, HasOddsFee, HasPlayerComm
		,QualifiedMember, ActivePlayer, Commission, Status
		,AffWinlost, AffWinlost_aff
	)
	OUTPUT INSERTED.RefId, INSERTED.AffId, INSERTED.ProductId INTO @Temp (RefId, AffId, ProductId)
	SELECT
		AffId, GroupId, ProductId, @ToDate, Currency, @SystemCurrency
		,MemBetCount, MemBetCountNoDraw
		,MemBonus, MemAdjustment, MemDeposit, MemWithdrawal, PShare, PWin, PlayerComm
		,MemBonus_aff, MemAdjustment_aff, MemDeposit_aff, MemWithdrawal_aff, PShare_Aff, PWin_Aff, PlayerComm_aff
		,MemWinlost, MemPSP, -NetWinlost, MemTurnover, MemTurnoverDraw, MemTurnoverNoDraw, Marketing, OddsFee
		,MemWinlost_aff, MemPSP_aff, -NetWinlost_aff, MemTurnover_aff, MemTurnoverDraw_aff, MemTurnoverNoDraw_aff, Marketing_aff, OddsFee_aff
		,HasBonus, HasAdjustment, HasMarketing, HasPSP, HasOddsFee, HasPlayerComm
		,TotalQM, TotalActivePlayer, Commission, 'Approved' AS Status
		,(NetWinlost - MemBonus * BonusPercent) * Commission * CASE WHEN GroupId IN (0, @NoCommissionGroupId) THEN 0 ELSE 1 END AS AffWinlost
		,(NetWinlost_aff - MemBonus_aff * BonusPercent) * Commission * CASE WHEN GroupId IN (0, @NoCommissionGroupId) THEN 0 ELSE 1 END AS AffWinlost
	FROM #AffSummary

	UPDATE d
	SET d.RelNo = t.RefId
	FROM dbo.AffCommission d WITH (ROWLOCK, UPDLOCK)
		INNER JOIN (SELECT AffId, RefId, ROW_NUMBER() OVER(PARTITION BY AffId ORDER BY RefId) AS RN FROM @Temp) t ON d.AffId = t.AffId
	WHERE d.WinlostDate = @ToDate AND t.RN = 1

	INSERT INTO dbo.AffTrans (AffId, TransDate, CompletedDate, STATUS, Description, Creator, AffCurrency, SysCurrency, SysExRate, TransType, Amount)
	SELECT AffId, @ToDate, GETDATE(), 'Approved', 'Monthly Earning', 9999, Currency, @SystemCurrency, dbo.Aff_GetExchangeRate(Currency, @SystemCurrency, @ToDate), 201
		,SUM(
			(ISNULL((NetWinlost_aff - MemBonus_aff * BonusPercent) * Commission, 0) - dbo.Aff_GetAffDeductionAll(AffId, @ToDate))
			* CASE WHEN GroupId IN (0, @NoCommissionGroupId) THEN 0 ELSE 1 END) AS Amount
	FROM #AffSummary
	GROUP BY AffId, Currency
	
	-- Update raw data: AffDaily/AffDailySummary
	UPDATE ad
	SET ad.AffWinlost 		= - ISNULL(ad.MemWinlost * a.Commission, 0)
		,ad.HouseWinlost 	= - ISNULL(ad.MemWinlost * (1 - a.Commission), 0)
		,ad.AffNetWinlost 	= ISNULL((a.NetWinlost - a.MemBonus * a.BonusPercent) * a.Commission, 0)
		,ad.HouseNetWinlost = ISNULL((a.NetWinlost - a.MemBonus * a.BonusPercent) * (1 - a.Commission), 0)
	FROM dbo.AffDaily ad WITH (ROWLOCK, UPDLOCK)
		LEFT JOIN #AffSummary a ON a.AffId = ad.AffId AND a.ProductId = ad.ProductId
	WHERE ad.Winlostdate BETWEEN @FromDate AND @ToDate

	UPDATE ad
	SET ad.AffWinlost 			= - ISNULL(ad.MemWinlost * a.Commission, 0)
		,ad.HouseWinlost 		= - ISNULL(ad.MemWinlost * (1 - a.Commission), 0)
		,ad.AffNetWinlost 		= ISNULL((a.NetWinlost - a.MemBonus * a.BonusPercent) * a.Commission, 0)
		,ad.HouseNetWinlost 	= ISNULL((a.NetWinlost - a.MemBonus * a.BonusPercent) * (1 - a.Commission), 0)
		,ad.AffWinlost_aff 		= - ISNULL(ad.MemWinlost_aff * a.Commission, 0)
		,ad.HouseWinlost_aff 	= - ISNULL(ad.MemWinlost_aff * (1 - a.Commission), 0)
		,ad.AffNetWinlost_aff 	= ISNULL((a.NetWinlost_aff - a.MemBonus_aff * a.BonusPercent) * a.Commission, 0)
		,ad.HouseNetWinlost_aff = ISNULL((a.NetWinlost_aff - a.MemBonus_aff * a.BonusPercent) * (1 - a.Commission), 0)
	FROM dbo.AffDailySummary ad WITH (ROWLOCK, UPDLOCK)
		LEFT JOIN #AffSummary a ON a.AffId = ad.AffId AND a.ProductId = ad.ProductId
	WHERE ad.Winlostdate BETWEEN @FromDate AND @ToDate

	-- Update BF for AffInfo  
	UPDATE ai
	SET ai.BF = dbo.[Aff_GetAffBalance](ad.AffID)
	FROM dbo.AffInfo ai WITH (ROWLOCK, UPDLOCK)
		INNER JOIN (SELECT DISTINCT AffId FROM #AffSummary) ad ON ad.AffId = ai.AffId

	DECLARE @TaskId INT, @LogId INT, @RunDate DATETIME = GETDATE(), @Status VARCHAR(30) = 'Completed'
	SELECT  @TaskId = TaskId FROM dbo.TaskManager WITH (NOLOCK)
	WHERE TaskName = 'Commission Monthly Transfer'

	EXEC dbo.Aff_TaskLogIns @TaskId, @RunDate, @Status, @LogId OUTPUT

	DROP TABLE #AffSummary
	DROP TABLE #DeductionSetting
	DROP TABLE #GroupSetting
	DROP TABLE #MemberSummary
END
GO