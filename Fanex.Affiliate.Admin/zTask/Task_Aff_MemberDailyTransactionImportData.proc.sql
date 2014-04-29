ALTER PROCEDURE [dbo].[Task_Aff_MemberDailyTransactionImportData] 
	@AdminID INT
	,@XmlData XML
	,@WinlostDate SMALLDATETIME
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(500) = '' OUTPUT
AS
/*
	Task : Import member daily (deposit, withdrawal, Bonus,....) from xml into table MemberDaily
	Author : Joseph@20130114
	DB: DB052.Affiliate_MYM
	Original: [Aff_MemberDailyImportData]
	Revisions: 		
		- Johnny@20130402: Fix the way import transfer transaction
		- Peter@20131028 : Add more DB columns https://redmine.nexcel.vn/issues/5280
*/
BEGIN
	SET NOCOUNT ON

	-- check data is calculated for this month?
	IF EXISTS (
			SELECT TOP (1) 1
			FROM AffCommission(NOLOCK)
			WHERE DATEDIFF(m, @WinlostDate, Winlostdate) = 0
			) RETURN

	DECLARE @SportsBookID TINYINT
		,@SystemCurrency SMALLINT --Deposit, withdraw,... is assigned to sportbook

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')

	EXEC Aff_GetSystemCurrency @SystemCurrency = @SystemCurrency OUTPUT

	DECLARE @TmpTable TABLE (
		UserName VARCHAR(30)
		,WinlostDate SMALLDATETIME
		)
	--Import new Data here
	DECLARE @TempTrans TABLE (
		UserName VARCHAR(30)
		,WinlostDate SMALLDATETIME
		,Currency VARCHAR(5)
		,Deposit MONEY
		,Withdrawal MONEY
		,Bonus MONEY
		,Adjustment MONEY
		,AffTransfer MONEY
		,Transfer3rd MONEY
		);

	INSERT INTO @TempTrans --Convert xml to table
	SELECT [Table].[Column].value('./@username', 'varchar(30)') AS [UserName]
		,[Table].[Column].value('./@winlostdate', 'smalldatetime') AS [WinlostDate]
		,[Table].[Column].value('./@currency', 'varchar(5)') AS [Currency]
		,[Table].[Column].value('./@deposit', 'money') AS [Deposit]
		,[Table].[Column].value('./@withdrawal', 'money') AS [Withdrawal]
		,[Table].[Column].value('./@bonus', 'money') AS [Bonus]
		,[Table].[Column].value('./@adjustment', 'money') AS [Adjustment]
		,[Table].[Column].value('./@afftransfer', 'money') AS [AffTransfer]
		,[Table].[Column].value('./@transfer3rd', 'money') AS [Transfer3rd]
	FROM @XmlData.nodes('/root/trans') AS [Table]([Column]);

	DELETE @TempTrans
	WHERE isnull(UserName, '') = ''
		OR ISNULL(Currency, '') = ''
		OR WinlostDate <> @WinlostDate

	UPDATE m WITH (ROWLOCK, UPDLOCK)
	SET m.[Deposit] = TEMP.Deposit
		,m.[Withdrawal] = TEMP.Withdrawal
		,m.[Bonus] = TEMP.Bonus
		,m.[Adjustment] = TEMP.Adjustment
		,m.[AffTransfer] = TEMP.AffTransfer
		,m.[Transfer3rd] = TEMP.Transfer3rd
	OUTPUT Inserted.UserName
		,Inserted.WinlostDate
	INTO @TmpTable
	FROM MemberDaily AS m
		INNER JOIN @TempTrans AS TEMP
		ON m.UserName = TEMP.UserName
			AND m.WinlostDate = TEMP.WinlostDate
	WHERE m.ProductID = @SportsBookID
		AND m.WinlostDate = @WinlostDate

	INSERT INTO MemberDaily (
		[UserName]
		,[WinlostDate]
		,[ProductID]
		,[AffID]
		,[Currency]
		,[AffCurrency]
		,[AffExRate]
		,[SysCurrency]
		,[SysExrate]
		,[Deposit]
		,[Withdrawal]
		,[Bonus]
		,[Adjustment]
		,AffTransfer
		,Transfer3rd
		,[Turnover]
		,[Outstanding]
		,[Winlost]
		,[DrawGame]
		,[PSP]
		,[Marketing]
		,[MemWinlostFake]
		,[MemOddsFee]
		,[MemPLayTechFee]
		,[BetCount]
		,[PlayerComm]
		,[TurnoverNoDraw]
		,[BetCountNoDraw]
		,[TurnoverDraw]
		)
	SELECT t1.UserName
		,WinlostDate
		,@SportsBookID
		,--is not bet transaction -> productid = sportbook ID
		mi.AffId
		,mi.Currency
		,ai.Currency
		,dbo.Aff_GetExchangeRate(mi.Currency, ai.Currency, @WinlostDate) AS AffExRate
		,@SystemCurrency
		,dbo.Aff_GetExchangeRate(mi.Currency, @SystemCurrency, @WinlostDate) AS SysExRate
		,Deposit
		,Withdrawal
		,Bonus
		,Adjustment
		,t1.AffTransfer
		,t1.Transfer3rd
		,0 AS Turnover
		,0 AS [Outstanding]
		,0 AS [Winlost]
		,0 AS [DrawGame]
		,0 AS [PSP]
		,0 AS [Marketing]
		,0 AS [MemWinlostFake]
		,0 AS [MemOddsFee]
		,0 AS [MemPLayTechFee]
		,0 AS [BetCount]
		,0 AS [PlayerComm]
		,0 AS [TurnoverNoDraw]
		,0 AS [BetCountNoDraw]
		,0 AS [TurnoverDraw]
	FROM @TempTrans t1
		INNER JOIN MemberInfo AS mi(NOLOCK)
		ON t1.UserName = mi.UserName
		INNER JOIN affinfo AS ai WITH (NOLOCK)
		ON mi.AffId = ai.AffId
	WHERE t1.UserName NOT IN (
			SELECT UserName
			FROM @TmpTable
			)
		AND mi.IsRemoved = 0

	--Update MemberDaily PSP, Marketting fee,...
	UPDATE m WITH (UPDLOCK, ROWLOCK)
	SET PSP = abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent
		,Marketing = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Marketing', @WinlostDate), 0)
		,MemOddsFee = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Odds Fee', @WinlostDate), 0)
		,MemPLayTechFee = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'PlayTech Royalties', @WinlostDate), 0)
		,MemWinlostFake = - (- Winlost - ((abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent)) * isnull(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'PSP', @WinlostDate), 0) - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Marketing', @WinlostDate), 0) - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Odds Fee', @WinlostDate), 0) - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'PlayTech Royalties', @WinlostDate), 0))
	FROM MemberDaily AS m
		INNER JOIN Exchange AS e(NOLOCK)
		ON m.Currency = e.ExchangeId
	WHERE m.WinlostDate = @WinlostDate

	------------Update others field MemberDaily, insert data for AffDaily, AffDailySummary table
	--Delete data and re-import AffDaily, AffDailySummary
	DELETE
	FROM AffDaily
	WHERE WinlostDate = @WinlostDate

	DELETE
	FROM [AffDailySummary]
	WHERE WinlostDate = @WinlostDate

	INSERT INTO AffDaily (
		[AffID]
		,[MemCurrency]
		,[Winlostdate]
		,[ProductID]
		,[AffCurrency]
		,[AffExRate]
		,[SysCurrency]
		,[SysExRate]
		,[MemDeposit]
		,[MemWithdrawal]
		,[MemTurnover]
		,[MemBonus]
		,[MemAdjustment]
		,[MemMarketing]
		,[MemPSP]
		,[MemWinlost]
		,[AffWinlost]
		,[HouseWinlost]
		,[AffNetWinlost]
		,[HouseNetWinlost]
		,[MemWinlostFake]
		,[MemOddsFee]
		,[MemPLayTechFee]
		,[MemAffTransfer]
		,[MemTransfer3rd]
		,[MemBetCount]
		,[MemPlayerComm]
		,[ActivePlayer]
		,[MemTurnoverNoDraw]
		,[MemBetCountNoDraw]
		,[MemTurnoverDraw]
		)
	SELECT m.[AffID]
		,m.[Currency] AS [MemCurrency]
		,m.[WinlostDate]
		,m.[ProductID]
		,m.[AffCurrency]
		,m.[AffExRate]
		,m.[SysCurrency]
		,m.[SysExRate]
		,Sum(Deposit) AS MemDeposit
		,Sum(Withdrawal) AS MemWithdrawal
		,Sum(Turnover) AS MemTurnover
		,Sum(Bonus) AS MemBonus
		,Sum(Adjustment) AS MemAdjustment
		,Sum(Marketing) AS MemMarketing
		,Sum(PSP) AS MemPSP
		,Sum(Winlost) AS MemWinlost
		,0 AS AffWinlost
		,- Sum(Winlost) AS HouseWinlost
		,0 AS AffNetWinlost
		,0 AS HouseNetWinlost
		,Sum(MemWinlostFake) AS MemWinlostFake
		,Sum(MemOddsFee) AS MemOddsFee
		,Sum(MemPLayTechFee) AS MemPLayTechFee
		,Sum([AffTransfer])
		,Sum([Transfer3rd])
		,Sum([BetCount])
		,Sum([PlayerComm])
		,SUM(CASE 
				WHEN Turnover > 0 THEN 1
				ELSE 0
				END) AS ActivePlayer
		,SUM(TurnoverNoDraw)
		,SUM(BetCountNoDraw)
		,SUM(TurnoverDraw)
	FROM MemberDaily(NOLOCK) AS m
	WHERE m.WinlostDate = @WinlostDate
	GROUP BY m.AffID
		,m.Winlostdate
		,m.ProductID
		,m.Currency
		,m.[AffCurrency]
		,m.[AffExRate]
		,m.[SysCurrency]
		,m.[SysExRate]

	UPDATE AffDaily WITH (ROWLOCK, UPDLOCK)
	SET HouseNetWinLost = HouseWinLost - isnull(MemPSP, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PSP', Winlostdate), 0)) - isnull(MemBonus, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Bonus', Winlostdate), 0)) - isnull(MemAdjustment, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Adjustment', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Marketing', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Odds Fee', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PlayTech Royalties', Winlostdate), 0))
	WHERE WinlostDate = @winlostdate

	--Update [AffDailySummary] table
	INSERT INTO [dbo].[AffDailySummary] (
		[AffID]
		,[Winlostdate]
		,[ProductID]
		,[AffCurrency]
		,[SysCurrency]
		,[MemDeposit]
		,[MemWithdrawal]
		,[MemTurnover]
		,[MemBonus]
		,[MemAdjustment]
		,[MemMarketing]
		,[MemPSP]
		,[MemWinlost]
		,[AffWinlost]
		,[HouseWinlost]
		,[AffNetWinlost]
		,[HouseNetWinlost]
		,[MemOddsFee]
		,[MemPLayTechFee]
		,[MemWinlostFake]
		,[MemAffTransfer]
		,[MemTransfer3rd]
		,[MemBetCount]
		,[MemPlayerComm]
		,[MemDeposit_aff]
		,[MemWithdrawal_aff]
		,[MemTurnover_aff]
		,[MemBonus_aff]
		,[MemAdjustment_aff]
		,[MemMarketing_aff]
		,[MemPSP_aff]
		,[MemWinlost_aff]
		,[AffWinlost_aff]
		,[HouseWinlost_aff]
		,[AffNetWinlost_aff]
		,[HouseNetWinlost_aff]
		,[MemOddsFee_aff]
		,[MemWinlostFake_aff]
		,[MemPLayTechFee_aff]
		,[MemAffTransfer_aff]
		,[MemTransfer3rd_aff]
		,[MemPlayerComm_aff]
		,[MemTurnoverNoDraw]
		,[MemBetCountNoDraw]
		,[MemTurnoverNoDraw_aff]
		,[MemTurnoverDraw]
		,[MemTurnoverDraw_aff]
		)
	SELECT [AffID]
		,[Winlostdate]
		,[ProductID]
		,[AffCurrency]
		,[SysCurrency]
		,Sum([MemDeposit] * SysExRate) AS [MemWithdrawal]
		,Sum([MemWithdrawal] * SysExRate) AS [MemWithdrawal]
		,Sum([MemTurnover] * SysExRate) AS [MemTurnover]
		,Sum([MemBonus] * SysExRate) AS [MemBonus]
		,Sum([MemAdjustment] * SysExRate) AS [MemAdjustment]
		,Sum([MemMarketing] * SysExRate) AS [MemMarketing]
		,Sum([MemPSP] * SysExRate) AS [MemPSP]
		,Sum([MemWinlost] * SysExRate) AS [MemWinlost]
		,Sum([AffWinlost] * SysExRate) AS [AffWinlost]
		,- Sum([MemWinlost] * SysExRate) AS [HouseWinlost]
		,0 AS [AffNetWinlost]
		,0 AS [HouseNetWinlost]
		,Sum([MemOddsFee] * SysExRate) AS [MemOddsFee]
		,Sum([MemPLayTechFee] * SysExRate) AS [MemPLayTechFee]
		,0 AS [MemWinlostFake]
		,Sum([MemAffTransfer] * SysExRate)
		,Sum([MemTransfer3rd] * SysExRate)
		,Sum([MemBetCount])
		,Sum([MemPlayerComm] * SysExRate)
		,Sum([MemDeposit] * AffExRate) AS [MemDeposit_aff]
		,Sum([MemWithdrawal] * AffExRate) AS [MemWithdrawal_aff]
		,Sum([MemTurnover] * AffExRate) AS [MemTurnover_aff]
		,Sum([MemBonus] * AffExRate) AS [MemBonus_aff]
		,Sum([MemAdjustment] * AffExRate) AS [MemAdjustment_aff]
		,Sum([MemMarketing] * AffExRate) AS [MemMarketing_aff]
		,Sum([MemPSP] * AffExRate) AS [MemPSP_aff]
		,Sum([MemWinlost] * AffExRate) AS [MemWinlost_aff]
		,0 AS [AffWinlost_aff]
		,- Sum([MemWinlost] * AffExRate) AS [HouseWinlost_aff]
		,0 AS [AffNetWinlost_aff]
		,0 AS [HouseNetWinlost_aff]
		,Sum([MemOddsFee] * AffExRate) AS [MemOddsFee_aff]
		,Sum([MemWinlostFake] * AffExRate) AS [MemWinlostFake_aff]
		,Sum([MemPLayTechFee] * AffExRate) AS [MemPLayTechFee_aff]
		,Sum([MemAffTransfer] * AffExRate)
		,Sum([MemTransfer3rd] * AffExRate)
		,Sum([MemPlayerComm] * AffExRate)
		,SUM([MemTurnoverNoDraw] * SysExRate) AS MemTurnoverNoDraw
		,SUM([MemBetCountNoDraw])
		,SUM([MemTurnoverNoDraw] * AffExRate) AS MemTurnoverNoDraw_aff
		,SUM([MemTurnoverDraw] * SysExRate) AS MemTurnoverDraw
		,SUM([MemTurnoverDraw] * AffExRate) AS MemTurnoverDraw_aff
	FROM AffDaily(NOLOCK)
	WHERE WinlostDate = @winlostdate
	GROUP BY AffID
		,Winlostdate
		,ProductID
		,AffCurrency
		,SysCurrency

	UPDATE AffDailySummary WITH (ROWLOCK, UPDLOCK)
	SET HouseNetWinlost = (- MemWinlost - isnull(MemPSP, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PSP', Winlostdate), 0)) - isnull(MemBonus, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Bonus', Winlostdate), 0)) - isnull(MemAdjustment, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Adjustment', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Marketing', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Odds Fee', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PlayTech Royalties', Winlostdate), 0)))
		,HouseNetWinlost_aff = (- MemWinlost_aff - isnull(MemPSP_aff, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PSP', Winlostdate), 0)) - isnull(MemBonus_aff, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Bonus', Winlostdate), 0)) - isnull(MemAdjustment_aff, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Adjustment', Winlostdate), 0)) - abs(isnull(MemWinlost_aff, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Marketing', Winlostdate), 0)) - abs(isnull(MemWinlost_aff, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Odds Fee', Winlostdate), 0)) - abs(isnull(MemWinlost_aff, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PlayTech Royalties', Winlostdate), 0)))
	WHERE WinlostDate = @winlostdate

	-----------Update MemwinlostFake for last date (forex winlost for previous date) of each account
	DECLARE @temp TABLE (
		affid INT
		,ProductID INT
		,totalWinlost MONEY
		,oddsFeePercent FLOAT
		,marketingPercent FLOAT
		,PSPPercent FLOAT
		,PlaytechPercent FLOAT
		,WLFake MONEY
		,totalPSP MONEY
		,maxWinlostDate SMALLDATETIME
		,previousMaxWinlostDate SMALLDATETIME
		,firstday SMALLDATETIME
		)

	INSERT INTO @temp (
		Affid
		,maxWinlostDate
		,ProductID
		)
	SELECT affid
		,max(winlostdate)
		,ProductID
	FROM AffDailySummary(NOLOCK)
	WHERE datediff(m, @winlostdate, WinlostDate) = 0 --  and ProductID = @SportsBookID      
	GROUP BY affid
		,ProductID
		,month(winlostdate)
		,year(winlostdate)

	UPDATE t
	SET t.previousMaxWinlostDate = isnull((
				SELECT max(winlostdate)
				FROM AffDailySummary(NOLOCK)
				WHERE ProductID = t.ProductID
					AND winlostdate < t.maxWinlostDate
					AND datediff(m, winlostdate, t.maxWinlostDate) = 0
					AND affid = t.affid
				), t.maxWinlostDate)
		,t.firstday = [dbo].[Aff_GetFirstDayOfMonth](t.maxWinlostDate)
		,t.oddsFeePercent = dbo.Aff_GetDeductionPercent(AffID, t.ProductID, 'Odds Fee', [dbo].[Aff_GetLastDayOfMonth](t.maxWinlostDate))
		,t.marketingPercent = dbo.Aff_GetDeductionPercent(AffID, t.ProductID, 'Marketing', [dbo].[Aff_GetLastDayOfMonth](t.maxWinlostDate))
		,t.PSPPercent = dbo.Aff_GetDeductionPercent(AffID, t.ProductID, 'PSP', [dbo].[Aff_GetLastDayOfMonth](t.maxWinlostDate))
		,t.PlaytechPercent = dbo.Aff_GetDeductionPercent(AffID, t.ProductID, 'PlayTech Royalties', [dbo].[Aff_GetLastDayOfMonth](t.maxWinlostDate))
	FROM @temp t

	--reupdate WinlostFake of previous MaxWinlostDate for AffDailySummary    
	UPDATE ad
	SET ad.MemWinlostFake = - (- isnull(ad.MemWinlost, 0) - abs(isnull(ad.MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID, t.ProductID, 'Odds Fee', ad.Winlostdate), 0) - abs(isnull(ad.MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID, t.ProductID, 'Marketing', ad.Winlostdate), 0) - abs(isnull(ad.MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID, t.ProductID, 'PlayTech Royalties', ad.Winlostdate), 0) - isnull(ad.MemPSP, 0) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID, t.ProductID, 'PSP', ad.Winlostdate), 0))
	FROM AffDailySummary ad WITH (ROWLOCK, UPDLOCK)
		INNER JOIN @temp t
		ON t.affid = ad.AffID
			AND t.previousMaxWinlostDate = ad.WinlostDate
			AND t.ProductID = ad.ProductID

	--don so tien winlostFake tat ca vao ngay cuoi cung cua thang nay 
	UPDATE d
	SET d.totalWinlost = isnull(c.totalwinlost, 0)
		,d.WLFake = isnull(c.memWinlostFake, 0)
		,d.totalPSP = isnull(c.memPSP, 0)
	FROM @temp d
		LEFT JOIN (
		SELECT t.affid
			,t.ProductID
			,sum(ad.memwinlost) totalwinlost
			,sum(ad.memWinlostFake) memWinlostFake
			,sum(ad.MemPSP) AS memPSP
		FROM AffDailySummary ad(NOLOCK)
			INNER JOIN @temp t
			ON t.AffID = ad.AffID
				AND t.ProductID = ad.ProductID
		WHERE ad.WinlostDate BETWEEN t.firstday AND t.previousMaxWinlostDate
		--and ad.ProductID = @SportsBookID  
		GROUP BY t.Affid
			,t.ProductID
		) c
		ON c.AffID = d.AffID
			AND c.ProductID = d.ProductID

	--Member Winlost - All Fee - Winlost fake from first date of month to yesterday
	UPDATE d
	SET MemWinlostFake = - (- (d1.totalwinlost + d.memwinlost) - abs(d1.totalwinlost + d.memwinlost) * (d1.oddsFeePercent + d1.marketingPercent + d1.PlaytechPercent) - (d1.totalPSP + d.MemPSP) * d1.PSPPercent) - d1.WLFake
	FROM AffDailySummary d WITH (ROWLOCK, UPDLOCK)
		INNER JOIN @temp d1
		ON d1.affid = d.affid
			AND d1.maxWinlostDate = d.winlostdate
			AND d1.ProductID = d.ProductID
	WHERE d1.previousMaxWinlostDate < d1.maxWinlostDate
		--and d.ProductID = @SportsBookID
END
