ALTER PROCEDURE [dbo].[Task_Aff_MonthlyTransfer] 
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
        - 20140212@Bobby.Nguyen: Update amount by aff currency

Param's Explanation:
• @Month: The month to transfer
• @Year :  The year to transfer     
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @FirstDay SMALLDATETIME
		,@LastDay SMALLDATETIME
		,@TransType INT
		,@MinimumNegativeCommission FLOAT

	SELECT @MinimumNegativeCommission = 0.1

	SELECT @FirstDay = cast(cast(@Year AS VARCHAR(5)) + '-' + cast(@Month AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)

	--Get last day of inputted month
	SELECT @LastDay = DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @FirstDay) + 1, 0))
		,@TransType = 201

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
				FROM CommGroupHistory(NOLOCK)
				WHERE monthdate = @LastDay
				) OR NOT EXISTS (
				SELECT TOP (1) 1
				FROM GroupSettingHistory(NOLOCK)
				WHERE monthdate = @LastDay
				)
			--  or not exists(select top(1) 1 from DeductionSettingHistory (nolock) where monthdate=@LastDay)
			OR NOT EXISTS (
				SELECT TOP (1) 1
				FROM AffGroupHistory(NOLOCK)
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
			FROM AffCommission WITH (NOLOCK)
			WHERE WinlostDate = @LastDay
			)
	BEGIN
		SELECT 'Please check the data. Transfers have been done for this month!' Result

		SELECT @FirstDay AS FirstDay
			,@LastDay AS LastDay

		RETURN
	END

	--Get all Affiliates that is approved and IsClosed=false
	DECLARE @Status VARCHAR(30)

	SELECT @Status = 'Approved'

	--Check the currency is matched
	IF (
			EXISTS (
				SELECT 1
				FROM AffInfo ai WITH (NOLOCK)
					INNER JOIN AffGroupHistory gh(NOLOCK) ON gh.AffID = ai.AffID AND MonthDate = @LastDay
					INNER JOIN CommGroupHistory ch(NOLOCK) ON ch.groupid = gh.groupid
				WHERE ai.currency <> ch.currency AND ai.STATUS = @Status AND ch.GroupName <> 'NoCommission'
				)
			)
	BEGIN
		SELECT 'The currency of Affiliate and his group does not match. Please check!' Result

		SELECT @FirstDay AS FirstDay
			,@LastDay AS LastDay

		RETURN
	END

	--Create temp table to get summary data for each affiliate
	CREATE TABLE #MemberSummary (
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
		,
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
	FROM MemberDaily md(NOLOCK)
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
				WHEN isnull(r.MemTurnover, 0) >= ch.QualifiedAmount THEN 1
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
	FROM AffInfo ai WITH (NOLOCK)
		INNER JOIN AffGroupHistory gh(NOLOCK) ON gh.AffID = ai.AffID AND gh.MonthDate = @LastDay
		INNER JOIN CommGroupHistory ch(NOLOCK) ON ch.groupid = gh.groupid AND ch.MonthDate = @LastDay
		INNER JOIN #MemberSummary r ON r.AffID = ai.AffID
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
			,COUNT(DISTINCT m.username) AS TotalActivePlayer
		FROM #MemberSummary m
		WHERE m.MemTurnover > 0 --or m.MemDeposit>0
		GROUP BY m.AffID
		) t ON a.AffID = t.AffID

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
								WHERE GroupID = a.GroupID AND ProductID = a.ProductID AND MonthDate = @LastDay AND floor(abs(- isnull(a.MemWinlost_aff, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP_aff, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.MarketingPercent, 1))) BETWEEN MinAmount AND MaxAmount
								), 0) AS Commission
					
					UNION ALL
					SELECT isnull((
								SELECT TOP (1) Commission
								FROM GroupSettingHistory(NOLOCK)
								WHERE GroupID = a.GroupID AND ProductID = a.ProductID AND MonthDate = @LastDay AND a.TotalQM BETWEEN MinQM AND MaxQM
								), 0) AS Commission
					) t
				ORDER BY t.Commission ASC
				), 0)
	FROM #AffSummary a

	UPDATE a
	SET a.Commission = @MinimumNegativeCommission
	FROM #AffSummary a
	WHERE a.NetWinlost_aff < 0 AND a.Commission = 0 AND a.GroupID NOT IN (
			SELECT groupId
			FROM CommGroup WITH (NOLOCK)
			WHERE GroupName = 'NoCommission'
			) AND a.ProductID IN (
			SELECT DISTINCT ProductID
			FROM GroupSettingHistory(NOLOCK)
			WHERE GroupID = a.GroupID AND DATEDIFF(m, MonthDate, @LastDay) = 0
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
			,(NetWinlost_aff - Cast(a.HasBonus AS INT) * isnull(a.MemBonus_aff, 0) * isnull(a.BonusPercent, 1)) * isnull(Commission, 0)
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
		FROM #AffSummary a(NOLOCK)

		UPDATE d
		SET d.RelNo = (
				SELECT TOP (1) RefID
				FROM @Temp d1
				WHERE d1.AffID = d.AffID AND d1.RefID > 0
				)
		FROM AffCommission d WITH (ROWLOCK, UPDLOCK)
		WHERE d.WinlostDate = @LastDay

		-- Insert to AffTrans
		INSERT INTO AffTrans (
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
			,sum((NetWinlost_aff - Cast(a.HasBonus AS INT) * isnull(a.MemBonus_aff, 0) * isnull(a.BonusPercent, 1)) * isnull(Commission, 0))
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
				WHERE d1.AffID = d.AffID AND d1.RefID > 0
				)
		FROM AffTrans d WITH (ROWLOCK, UPDLOCK)
		WHERE d.TransDate = @LastDay AND d.TransType = @TransType

		UPDATE ad
		SET ad.AffWinlost = - isnull(ad.MemWinlost, 0) * isnull(a.commission, 0)
			,ad.HouseWinlost = - isnull(ad.MemWinlost, 0) * (1 - isnull(a.commission, 0))
			,ad.AffNetWinlost = (
				- isnull(ad.MemWinlost, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1) - Cast(isnull(a.HasBonus, 0) AS INT) * isnull(ad.MemBonus, 0) * isnull(a.BonusPercent, 1)
				/*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */
				) * isnull(a.commission, 0)
			,ad.HouseNetWinlost = (
				- isnull(ad.MemWinlost, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1) - Cast(isnull(a.HasBonus, 0) AS INT) * isnull(ad.MemBonus, 0) * isnull(a.BonusPercent, 1)
				/*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */
				) * (1 - isnull(a.commission, 0))
		FROM AffDaily ad WITH (ROWLOCK, UPDLOCK)
			LEFT JOIN #AffSummary a WITH (NOLOCK) ON a.AffID = ad.AffID AND a.ProductID = ad.ProductID
		WHERE datediff(mm, ad.Winlostdate, @FirstDay) = 0

		UPDATE ad
		SET /*ad.MemMarketing=Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost,0)) * isnull(a.MarketingPercent,0) ,
         ad.MemOddsFee=Cast(isnull(a.HasOddsFee,0) as int) *  abs(isnull(ad.MemWinlost,0)) * isnull(a.OddsFeePercent,0) ,         */
			ad.AffWinlost = - isnull(ad.MemWinlost, 0) * isnull(a.commission, 0)
			,ad.HouseWinlost = - isnull(ad.MemWinlost, 0) * (1 - isnull(a.commission, 0))
			,ad.AffNetWinlost = (
				- isnull(ad.MemWinlost, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1) - Cast(isnull(a.HasBonus, 0) AS INT) * isnull(ad.MemBonus, 0) * isnull(a.BonusPercent, 1)
				/*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */
				) * isnull(a.commission, 0)
			,ad.HouseNetWinlost = (
				- isnull(ad.MemWinlost, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost, 0)) * isnull(a.MarketingPercent, 1) - Cast(isnull(a.HasBonus, 0) AS INT) * isnull(ad.MemBonus, 0) * isnull(a.BonusPercent, 1)
				/*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */
				) * (1 - isnull(a.commission, 0))
			,ad.AffWinlost_aff = - isnull(ad.MemWinlost_aff, 0) * isnull(a.commission, 0)
			,ad.HouseWinlost_aff = - isnull(ad.MemWinlost_aff, 0) * (1 - isnull(a.commission, 0))
			,ad.AffNetWinlost_aff = (
				- isnull(ad.MemWinlost_aff, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP_aff, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.MarketingPercent, 1) - Cast(isnull(a.HasBonus, 0) AS INT) * isnull(ad.MemBonus_aff, 0) * isnull(a.BonusPercent, 1)
				/*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment_aff,0) * isnull(a.AdjustmentPercent,1) */
				) * isnull(a.commission, 0)
			,ad.HouseNetWinlost_aff = (
				- isnull(ad.MemWinlost_aff, 0) - Cast(a.HasPSP AS INT) * isnull(a.MemPSP_aff, 0) * isnull(a.PSPPercent, 1) - Cast(a.HasOddsFee AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.OddsFeePercent, 1) - Cast(a.HasMarketing AS INT) * abs(isnull(a.MemWinlost_aff, 0)) * isnull(a.MarketingPercent, 1) - Cast(isnull(a.HasBonus, 0) AS INT) * isnull(ad.MemBonus_aff, 0) * isnull(a.BonusPercent, 1)
				/*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment_aff,0) * isnull(a.AdjustmentPercent,1) */
				) * (1 - isnull(a.commission, 0))
		FROM AffDailySummary ad WITH (ROWLOCK, UPDLOCK)
			LEFT JOIN #AffSummary a WITH (NOLOCK) ON a.AffID = ad.AffID AND a.ProductID = ad.ProductID
		WHERE datediff(mm, ad.Winlostdate, @FirstDay) = 0

		-- Update BF for AffInfo
		UPDATE ai
		SET ai.BF = dbo.[Aff_GetAffBalance](ad.AffID)
		FROM AffInfo ai WITH (ROWLOCK, UPDLOCK)
			INNER JOIN #AffSummary ad(NOLOCK) ON ad.AffID = ai.AffID
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

GRANT EXECUTE ON [dbo].[Task_Aff_MonthlyTransfer] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MonthlyTransfer] TO [vnteam]
