ALTER PROCEDURE dbo.Task_Aff_ReCalculateAffSumData 
	@AffID INT
	,@FromDate SMALLDATETIME
	,@ToDate SMALLDATETIME
	,@ErrCode INT = 0 OUTPUT
AS
/*  
Created: 20140122@Bobby  
Task : Update AffDaily Data
DB: Affiliate_Db
Original:  Affiliate_Athena000
  
Revisions:      
	- 20140429@Bobby.Nguyen: Validate null data
Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @WinlostDate SMALLDATETIME;

	SET @WinlostDate = CAST(GETDATE() AS SMALLDATETIME);

	-- check data is calculated for this month?
	IF EXISTS (
			SELECT TOP (1) 1
			FROM AffCommission(NOLOCK)
			WHERE winlostdate >= @FromDate
				AND winlostdate < @ToDate
				AND AffID = @AffID
			) RETURN;

	--Delete data and re-import AffDaily, AffDailySummary
	DELETE
	FROM dbo.[AffDaily]
	WHERE winlostdate >= @FromDate
		AND winlostdate < @ToDate
		AND AffID = @AffID

	DELETE
	FROM dbo.[AffDailySummary]
	WHERE winlostdate >= @FromDate
		AND winlostdate < @ToDate
		AND AffID = @AffID

	IF (
			EXISTS (
				SELECT TOP 1 1
				FROM MemberDaily(NOLOCK) AS m
				WHERE m.winlostdate >= @FromDate
					AND m.winlostdate < @ToDate
					AND AffID = @AffID
				)
			)
	BEGIN
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
			,Sum(ISNULL([AffTransfer],0)) AS MemAffTransfer
			,Sum(ISNULL([Transfer3rd],0)) AS MemAffTransfer3rd
			,Sum([BetCount]) AS MemBetCount
			,Sum([PlayerComm])
			,SUM(CASE 
					WHEN Turnover > 0 THEN 1
					ELSE 0
					END) AS ActivePlayer
			,SUM(TurnoverNoDraw) AS MemTurnoverNoDraw
			,SUM(BetCountNoDraw) AS MemBetCountNoDraw
			,SUM(TurnoverDraw) AS MemTurnoverDraw
		FROM MemberDaily(NOLOCK) AS m
		WHERE m.winlostdate >= @FromDate
			AND m.winlostdate < @ToDate
			AND AffID = @AffID
		GROUP BY m.AffID
			,m.Winlostdate
			,m.ProductID
			,m.Currency
			,m.[AffCurrency]
			,m.[AffExRate]
			,m.[SysCurrency]
			,m.[SysExRate]

		UPDATE AffDaily WITH (ROWLOCK, UPDLOCK)
		SET HouseNetWinLost = HouseWinLost - isnull(MemBonus, 0) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Bonus', Winlostdate), 0) - isnull(MemAdjustment, 0) - isnull(MemPSP, 0) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PSP', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Marketing', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Odds Fee', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PlayTech Royalties', Winlostdate), 0)
		WHERE winlostdate >= @FromDate
			AND winlostdate < @ToDate
			AND AffID = @AffID
	END

	--Update [AffDailySummary] table
	IF EXISTS (
			SELECT TOP 1 1
			FROM AffDaily(NOLOCK)
			WHERE winlostdate >= @FromDate
				AND winlostdate < @ToDate
				AND AffID = @AffID
			)
	BEGIN
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
			,Sum(ISNULL([MemAffTransfer], 0) * SysExRate) AS [MemAffTransfer]
			,Sum(ISNULL([MemTransfer3rd], 0) * SysExRate) AS [MemTransfer3rd]
			,Sum([MemBetCount]) AS [MemBetCount]
			,Sum([MemPlayerComm] * SysExRate) AS [MemPlayerComm]
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
			,Sum(ISNULL([MemAffTransfer], 0) * AffExRate) AS [MemAffTransfer_aff]
			,Sum(ISNULL([MemTransfer3rd], 0) * AffExRate) AS [MemTransfer3rd_aff]
			,Sum([MemPlayerComm] * AffExRate) AS [MemPlayerComm_aff]
			,SUM([MemTurnoverNoDraw] * SysExRate) AS MemTurnoverNoDraw
			,SUM([MemBetCountNoDraw]) AS [MemBetCountNoDraw]
			,SUM([MemTurnoverNoDraw] * AffExRate) AS MemTurnoverNoDraw_aff
			,SUM([MemTurnoverDraw] * SysExRate) AS MemTurnoverDraw
			,SUM([MemTurnoverDraw] * AffExRate) AS MemTurnoverDraw_aff
		FROM AffDaily(NOLOCK)
		WHERE winlostdate >= @FromDate
			AND winlostdate < @ToDate
			AND AffID = @AffID
		GROUP BY AffID
			,Winlostdate
			,ProductID
			,AffCurrency
			,SysCurrency

		UPDATE AffDailySummary WITH (ROWLOCK, UPDLOCK)
		SET HouseNetWinlost = (- MemWinlost - MemBonus * dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Bonus', WinlostDate) - MemAdjustment - MemPSP * dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PSP', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Marketing', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Odds Fee', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PlayTech Royalties', WinlostDate))
			,HouseNetWinlost_aff = (- MemWinlost_aff - MemBonus_aff * dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Bonus', WinlostDate) - MemAdjustment_aff - MemPSP_aff * dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PSP', WinlostDate) - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Marketing', WinlostDate) - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID, ProductID, 'Odds Fee', WinlostDate) - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID, ProductID, 'PlayTech Royalties', WinlostDate))
		WHERE winlostdate >= @FromDate
			AND winlostdate < @ToDate
			AND AffID = @AffID
	END

	RETURN;
END
GO


