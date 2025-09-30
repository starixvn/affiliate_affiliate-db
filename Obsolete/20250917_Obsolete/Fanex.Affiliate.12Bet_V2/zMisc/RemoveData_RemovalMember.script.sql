declare @IBCCustID INT 
	,@UserID INT
	,@IP VARCHAR(20)
	,@AffID INT = NULL 
	,@RefNo BIGINT = 0 
	,@DepositCustID INT = 0 
	,@ErrCode INT = 0 
	,@ErrMsg NVARCHAR(4000) = '' 
	, @monthDate DATE
BEGIN
	SET NOCOUNT ON

	SELECT @IBCCustID = 17202329
	, @monthDate = '20150901' 
	
	-----------------------------------------------
	--Check IBCCustID
	SELECT @AffId = AffId
		,@DepositCustID = DepositCustID
	FROM MemberInfo(NOLOCK)
	WHERE IBCCustID = @IBCCustID
		AND IsRemoved = 1

	IF (@AffID IS NULL)
	BEGIN
		SELECT @ErrMsg = 'This member does not exist or be removed before!'
			,@ErrCode = 1001

	END
	ELSE
	BEGIN
	
	DECLARE @LogData NVARCHAR(4000)
		,@SPName VARCHAR(100)
		,@FirstDayOfTheMonth SMALLDATETIME
		


	SELECT @LogData = 'Remove member. IBCCustID=' + dbo.Aff_ToString(@IBCCustID)
		,@FirstDayOfTheMonth = dateadd(m, datediff(m, 0, @monthDate), 0)


	BEGIN TRY
		
		INSERT INTO MemberDailyRemoved (
			[WinlostDate]
			,[IBCCustID]
			,[SportType]
			,[Currency]
			,[Deposit]
			,[Withdrawal]
			,[Bonus]
			,[Adjustment]
			,[Turnover]
			,[Outstanding]
			,[Winlost]
			,[AWinlost]
			,[ABonus]
			,[AffExRate]
			,[MemberExRate]
			,[DrawGame]
			,[PSP]
			,[Marketing]
			,[AffID]
			,[MemWinlostFake]
			,[MemOddsFee]
			)
		SELECT [WinlostDate]
			,[IBCCustID]
			,[SportType]
			,[Currency]
			,[Deposit]
			,[Withdrawal]
			,[Bonus]
			,[Adjustment]
			,[Turnover]
			,[Outstanding]
			,[Winlost]
			,[AWinlost]
			,[ABonus]
			,[AffExRate]
			,[MemberExRate]
			,[DrawGame]
			,[PSP]
			,[Marketing]
			,[AffID]
			,[MemWinlostFake]
			,[MemOddsFee]
		FROM MemberDaily WITH (NOLOCK)
		WHERE IBCCustID = @IBCCustID
			AND datediff(m, winlostdate, @monthDate) = 0
			AND SportType > 0

		
		DELETE MemberDaily
		WHERE IBCCustID = @IBCCustID
			AND datediff(m, winlostdate, @monthDate) = 0
			AND SportType > 0

		--Update AFFDaily here
		DELETE
		FROM AffDaily
		WHERE AffId = @AffId
			AND datediff(m, winlostdate, @monthDate) = 0

		INSERT INTO AffDaily (
			[AffID]
			,[Currency]
			,[Winlostdate]
			,[SportID]
			,[ExRate2]
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
			)
		SELECT d.AffID AS AffID
			,d.Currency AS Currency
			,d.Winlostdate AS Winlostdate
			,d.SportType AS SportID
			,d.AffExRate AS Exrate2
			,SUM(isnull(d.Deposit, 0)) AS MemDeposit
			,SUM(isnull(d.Withdrawal, 0)) AS MemWithdrawal
			,SUM(isnull(d.Turnover, 0)) AS MemTurnover
			,SUM(isnull(d.Bonus, 0)) AS MemBonus
			,SUM(isnull(d.Adjustment, 0)) AS MemAdjustment
			,0 AS MemMarketing
			,SUM(isnull(d.PSP, 0)) AS MemPSP
			,SUM(isnull(d.Winlost, 0)) AS MemWinLost
			,0 AS AffWinLost
			,- SUM(d.Winlost) AS HouseWinLost
			,0 AS AffNetWinlost
			,0 AS HouseNetWinLost
			,0 AS MemWinlostFake
			,0 AS MemOddsFee
		FROM MemberDaily d WITH (NOLOCK)
		WHERE AffId = @AffId
			--AND d.WinlostDate >= @FirstDayOfTheMonth
			AND datediff(m, winlostdate, @monthDate) = 0
		GROUP BY d.AffID
			,d.Winlostdate
			,d.Currency
			,d.SportType
			,d.AffExRate

		UPDATE AffDaily WITH (ROWLOCK, UPDLOCK)
		SET [MemMarketing] = abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0)
			,MemOddsFee = abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0)
			,HouseNetWinLost = HouseWinLost - isnull(MemBonus, 0) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Bonus', Winlostdate), 0) - isnull(MemAdjustment, 0) - isnull(MemPSP, 0) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0)
			,MemWinlostFake = - (- isnull(MemWinlost, 0) - isnull(MemPSP, 0) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0))
		WHERE AffId = @AffId
			--AND WinlostDate >= @FirstDayOfTheMonth
			AND datediff(m, winlostdate, @monthDate) = 0

		DELETE
		FROM AffDailySummary
		WHERE AffId = @AffId
			--AND WinlostDate >= @FirstDayOfTheMonth
			AND datediff(m, winlostdate, @monthDate) = 0

		INSERT INTO [dbo].[AffDailySummary] (
			[AffID]
			,[Winlostdate]
			,[SportID]
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
			,[MemWinlostFake]
			)
		SELECT [AffID]
			,[Winlostdate]
			,[SportID]
			,sum([MemDeposit] * ExRate2) AS MemDeposit
			,sum([MemWithdrawal] * ExRate2) AS MemWithdrawal
			,sum([MemTurnover] * ExRate2) AS MemTurnover
			,sum([MemBonus] * ExRate2) AS MemBonus
			,sum([MemAdjustment] * ExRate2) AS MemAdjustment
			,0 AS MemMarketing
			,sum([MemPSP] * ExRate2) AS MemPSP
			,sum([MemWinlost] * ExRate2) AS MemWinlost
			,sum([AffWinlost] * ExRate2) AS AffWinlost
			,sum([HouseWinlost] * ExRate2) AS HouseWinlost
			,sum([AffNetWinlost] * ExRate2) AS AffNetWinlost
			,sum([HouseNetWinlost] * ExRate2) AS HouseNetWinlost
			,0 AS MemOddsFee
			,0 AS MemWinlostFake
		FROM AffDaily(NOLOCK)
		WHERE AffId = @AffId
			--AND WinlostDate >= @FirstDayOfTheMonth
			AND datediff(m, winlostdate, @monthDate) = 0
		GROUP BY AffID
			,Winlostdate
			,SportID

		UPDATE AffDailySummary WITH (ROWLOCK, UPDLOCK)
		SET MemOddsFee = abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate)
			,MemMarketing = abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate)
			,MemWinlostFake = - (- MemWinlost - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate) - MemPSP * dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', WinlostDate))
			,HouseNetWinlost = (- MemWinlost - MemBonus * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Bonus', WinlostDate) - MemAdjustment - MemPSP * dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate))
		WHERE AffId = @AffId
			--AND WinlostDate >= @FirstDayOfTheMonth
			AND datediff(m, winlostdate, @monthDate) = 0

	END TRY

	BEGIN CATCH

		--manually rollback on DB02 
		/*exec [DB02].[bodb02].[dbo].[Aff_MemberUpdAffID]
			@IBCCustID =@IBCCustID,			
			@NewAffId =@AffID,				
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg =@ErrMsg OUTPUT*/
		SELECT @ErrMsg = 'Remove member failed!'
			,@ErrCode = 1002

		RETURN
	END CATCH
	END

	SELECT @ErrMsg
		,@ErrCode
	
END
GO

