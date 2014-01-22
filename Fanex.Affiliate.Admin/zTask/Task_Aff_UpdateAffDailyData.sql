ALTER PROCEDURE dbo.Task_Aff_UpdateAffDailyData 
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
  
Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;

	SELECT AffID
		,WinlostDate
		,ProductID
		,Currency AS MemCurrency
		,AffCurrency
		,AffExRate
		,SysCurrency
		,SysExRate
		,SUM(ISNULL(Deposit, 0)) AS MemDeposit
		,SUM(ISNULL(Withdrawal, 0)) AS MemWithdrawal
		,SUM(ISNULL(Turnover, 0)) AS MemTurnover
		,SUM(ISNULL(Bonus, 0)) AS MemBonus
		,SUM(ISNULL(Adjustment, 0)) AS MemAdjustment
		,SUM(ISNULL(Marketing, 0)) AS MemMarketing	
		,SUM(ISNULL(PSP, 0)) AS MemPSP
		,SUM(ISNULL(Winlost, 0)) AS MemWinlost
		,-SUM(ISNULL(Winlost, 0))  AS HouseWinlost
		,SUM(ISNULL(MemWinlostFake, 0)) AS MemWinlostFake
		,SUM(ISNULL(MemOddsFee, 0)) AS MemOddsFee          		   
		,SUM(ISNULL(MemPLayTechFee, 0)) AS MemPLayTechFee
		,SUM(ISNULL(AffTransfer, 0)) AS MemAffTransfer
		,SUM(ISNULL(Transfer3rd, 0)) AS MemTransfer3rd
		,SUM(ISNULL(BetCount, 0)) AS MemBetCount
		,SUM(ISNULL(PlayerComm, 0)) AS MemPlayerComm
		,SUM(CASE WHEN turnover > 0 THEN 1 ELSE 0 END) AS ActivePlayer
		,SUM(ISNULL(TurnoverNoDraw, 0)) AS MemTurnoverNoDraw
		,SUM(ISNULL(BetCountNoDraw, 0)) AS MemBetCountNoDraw
		,SUM(ISNULL(TurnoverDraw, 0)) AS MemTurnoverDraw
	INTO #srcMemberSum
	FROM dbo.MemberDaily WITH(NOLOCK)
	WHERE AffId = @AffId
		AND WinlostDate >= @FromDate AND WinlostDate < @ToDate
	GROUP BY AffID
		,WinlostDate
		,ProductID
		,Currency
		,AffCurrency
		,AffExRate
		,SysCurrency
		,SysExRate

	IF(EXISTS(SELECT TOP 1 1 FROM #srcMemberSum))
	BEGIN
		--update AffDaily
		MERGE INTO dbo.AffDaily AS tar
		USING #srcMemberSum AS src
			ON tar.AffID = src.AffID 
				AND tar.WinlostDate = src.WinlostDate
				AND tar.ProductID	= src.ProductID
				AND tar.MemCurrency = src.MemCurrency
				AND tar.AffCurrency = src.AffCurrency
				AND tar.SysCurrency = src.SysCurrency
		WHEN MATCHED THEN
			UPDATE 
			SET MemDeposit		= src.MemDeposit
				,MemWithdrawal	= src.MemWithdrawal
				,MemTurnover	= src.MemTurnover
				,MemBonus		= src.MemBonus
				,MemAdjustment	= src.MemAdjustment
				,MemMarketing	= src.MemMarketing
				,MemPSP			= src.MemPSP
				,MemWinlost		= src.MemWinlost
				,AffWinlost		= src.AffWinlost
				,HouseWinlost	= src.HouseWinlost
				,AffNetWinlost	= src.AffNetWinlost
				,HouseNetWinlost= src.HouseNetWinlost
				,MemWinlostFake	= src.MemWinlostFake
				,MemOddsFee		= src.MemOddsFee
				,MemPLayTechFee	= src.MemPLayTechFee
				,MemAffTransfer	= src.MemAffTransfer
				,MemTransfer3rd	= src.MemTransfer3rd
				,MemBetCount	= src.MemBetCount
				,MemPlayerComm	= src.MemPlayerComm
				,ActivePlayer	= src.ActivePlayer
				,MemTurnoverNoDraw	= src.MemTurnoverNoDraw
				,MemBetCountNoDraw	= src.MemBetCountNoDraw
				,MemTurnoverDraw	= src.MemTurnoverDraw

		WHEN NOT MATCHED BY TARGET THEN
			INSERT (
				AffID
				,MemCurrency
				,Winlostdate
				,ProductID
				,AffCurrency
				,AffExRate
				,SysCurrency
				,SysExRate
				,MemDeposit
				,MemWithdrawal
				,MemTurnover
				,MemBonus
				,MemAdjustment
				,MemMarketing
				,MemPSP
				,MemWinlost
				,AffWinlost
				,HouseWinlost
				,AffNetWinlost
				,HouseNetWinlost
				,MemWinlostFake
				,MemOddsFee
				,MemPLayTechFee
				,MemAffTransfer
				,MemTransfer3rd
				,MemBetCount
				,MemPlayerComm
				,ActivePlayer
				,MemTurnoverNoDraw
				,MemBetCountNoDraw
				,MemTurnoverDraw)
			VALUES(
				src.AffID
				,src.MemCurrency
				,src.Winlostdate
				,src.ProductID
				,src.AffCurrency
				,src.AffExRate
				,src.SysCurrency
				,src.SysExRate
				,src.MemDeposit
				,src.MemWithdrawal
				,src.MemTurnover
				,src.MemBonus
				,src.MemAdjustment
				,src.MemMarketing
				,src.MemPSP
				,src.MemWinlost
				,src.AffWinlost
				,src.HouseWinlost
				,src.AffNetWinlost
				,src.HouseNetWinlost
				,src.MemWinlostFake
				,src.MemOddsFee
				,src.MemPLayTechFee
				,src.MemAffTransfer
				,src.MemTransfer3rd
				,src.MemBetCount
				,src.MemPlayerComm
				,src.ActivePlayer
				,src.MemTurnoverNoDraw
				,src.MemBetCountNoDraw
				,src.MemTurnoverDraw)
		--OUTPUT $action
		;

		--update AffDailySummary
		;WITH tmpAffSumm AS 
		(
			SELECT [AffID]  
				,[Winlostdate]  
				,[ProductID]
				,[AffCurrency]
				,[SysCurrency]  
				,SUM([MemDeposit] * SysExRate) AS [MemDeposit]
				,SUM([MemWithdrawal] * SysExRate) AS [MemWithdrawal]
				,SUM([MemTurnover] * SysExRate) AS [MemTurnover]
				,SUM([MemBonus] * SysExRate) AS   [MemBonus]
				,SUM([MemAdjustment] * SysExRate) AS   [MemAdjustment]
				,SUM([MemMarketing] * SysExRate) AS  [MemMarketing] 
				,SUM([MemPSP] * SysExRate) AS   [MemPSP]
				,SUM([MemWinlost] * SysExRate) AS   [MemWinlost]
				,SUM([AffWinlost] * SysExRate) AS [AffWinlost]  
				,-SUM([MemWinlost] * SysExRate) AS  [HouseWinlost] --negative balance
				,0 AS  [AffNetWinlost] 
				,0 AS  [HouseNetWinlost] 
				,SUM([MemOddsFee] * SysExRate) AS   [MemOddsFee]
				,SUM([MemPLayTechFee] * SysExRate) AS [MemPLayTechFee]
				,0 AS [MemWinlostFake]
				,SUM([MemDeposit] * AffExRate) AS [MemDeposit_aff]
				,SUM([MemWithdrawal] * AffExRate) AS [MemWithdrawal_aff]
				,SUM([MemTurnover] * AffExRate) AS [MemTurnover_aff]
				,SUM([MemBonus] * AffExRate) AS [MemBonus_aff]
				,SUM([MemAdjustment] * AffExRate) AS [MemAdjustment_aff]
				,SUM([MemMarketing] * AffExRate) AS [MemMarketing_aff]
				,SUM([MemPSP] * AffExRate) AS [MemPSP_aff]
				,SUM([MemWinlost] * AffExRate) AS [MemWinlost_aff]
				,0 AS [AffWinlost_aff]
				,-SUM([MemWinlost] * AffExRate) AS [HouseWinlost_aff] --negative balance
				,0 AS [AffNetWinlost_aff]
				,0 AS [HouseNetWinlost_aff]
				,SUM([MemOddsFee] * AffExRate) AS [MemOddsFee_aff]
				,SUM([MemWinlostFake] * AffExRate) AS [MemWinlostFake_aff]
				,SUM([MemPLayTechFee] * AffExRate) AS [MemPLayTechFee_aff]
				,SUM(ISNULL([MemAffTransfer], 0) * SysExRate)  AS MemAffTransfer
				,SUM(ISNULL([MemTransfer3rd], 0) * SysExRate) AS MemTransfer3rd
				,SUM([MemBetCount]) AS MemBetCount
				,SUM([MemPlayerComm]* SysExRate) AS MemPlayerComm
				,SUM(ISNULL([MemAffTransfer], 0) * AffExRate) AS MemAffTransfer_aff
				,SUM(ISNULL([MemTransfer3rd], 0) * AffExRate) AS MemTransfer3rd_aff
				,SUM([MemPlayerComm]* AffExRate) AS MemPlayerComm_aff
				,SUM([MemTurnoverNoDraw]* SysExRate) AS MemTurnoverNoDraw
				,SUM([MemBetCountNoDraw]) AS MemBetCountNoDraw
				,SUM([MemTurnoverNoDraw]* AffExRate) AS MemTurnoverNoDraw_aff
				,SUM([MemTurnoverDraw]* SysExRate) AS MemTurnoverDraw
				,SUM([MemTurnoverDraw]* AffExRate) AS MemTurnoverDraw_aff

			FROM dbo.AffDaily WITH(NOLOCK)
			WHERE AffId = @AffId
				AND winlostdate >= @FromDate AND winlostdate < @ToDate
			GROUP BY AffID
				, Winlostdate
				, ProductID
				, AffCurrency
				, SysCurrency
		)
		MERGE INTO dbo.AffDailySummary AS tar
		USING tmpAffSumm AS src
			ON tar.AffID			= src.AffID
				AND tar.Winlostdate = src.Winlostdate
				AND tar.ProductID	= src.ProductID
				AND tar.AffCurrency = src.AffCurrency
				AND tar.SysCurrency = src.SysCurrency
		WHEN MATCHED THEN
			UPDATE 
			SET MemDeposit			= src.MemDeposit
				, MemWithdrawal		= src.MemWithdrawal
				, MemTurnover		= src.MemTurnover
				, MemBonus			= src.MemBonus
				, MemAdjustment		= src.MemAdjustment
				, MemMarketing		= src.MemMarketing
				, MemPSP			= src.MemPSP
				, MemWinlost		= src.MemWinlost
				, AffWinlost		= src.AffWinlost
				, HouseWinlost		= src.HouseWinlost 
				, AffNetWinlost		= src.AffNetWinlost
				, MemOddsFee		= src.MemOddsFee
				, MemPLayTechFee	= src.MemPLayTechFee
				, MemWinlostFake	= src.MemWinlostFake
				, MemDeposit_aff	= src.MemDeposit_aff
				, MemWithdrawal_aff	= src.MemWithdrawal_aff
				, MemTurnover_aff	= src.MemTurnover_aff
				, MemBonus_aff		= src.MemBonus_aff
				, MemAdjustment_aff	= src.MemAdjustment_aff
				, MemMarketing_aff	= src.MemMarketing_aff
				, MemPSP_aff		= src.MemPSP_aff
				, MemWinlost_aff	= src.MemWinlost_aff
				, AffWinlost_aff	= src.AffWinlost_aff
				, HouseWinlost_aff	= src.HouseWinlost_aff
				, AffNetWinlost_aff	= src.AffNetWinlost_aff
				, MemOddsFee_aff		= src.MemOddsFee_aff
				, MemWinlostFake_aff	= src.MemWinlostFake_aff
				, MemPLayTechFee_aff	= src.MemPLayTechFee_aff
				, MemAffTransfer		= src.MemAffTransfer
				, MemTransfer3rd		= src.MemTransfer3rd
				, MemBetCount			= src.MemBetCount
				, MemPlayerComm			= src.MemPlayerComm
				, MemAffTransfer_aff	= src.MemAffTransfer_aff
				, MemTransfer3rd_aff	= src.MemTransfer3rd_aff
				, MemPlayerComm_aff		= src.MemPlayerComm_aff
				, MemTurnoverNoDraw		= src.MemTurnoverNoDraw
				, MemBetCountNoDraw		= src.MemBetCountNoDraw
				, MemTurnoverNoDraw_aff	= src.MemTurnoverNoDraw_aff
				, MemTurnoverDraw		= src.MemTurnoverDraw
				, MemTurnoverDraw_aff	= src.MemTurnoverDraw_aff
				, HouseNetWinlost		= (-src.MemWinlost  
											-src.MemBonus * dbo.Aff_GetDeductionPercent(src.AffID, src.ProductID,'Bonus', src.WinlostDate)  
											-src.MemAdjustment  
											-src.MemPSP * dbo.Aff_GetDeductionPercent(src.AffID, src.ProductID, 'PSP', src.WinlostDate)  
											- ABS(src.MemWinlost) * dbo.Aff_GetDeductionPercent(src.AffID, src.ProductID, 'Marketing', src.WinlostDate)  
											- ABS(src.MemWinlost) * dbo.Aff_GetDeductionPercent(src.AffID, src.ProductID, 'Odds Fee', src.WinlostDate)  
											- ABS(src.MemWinlost) * dbo.Aff_GetDeductionPercent(src.AffID, src.ProductID, 'PlayTech Royalties', src.WinlostDate)  
										)
				, HouseNetWinlost_aff	= (-src.MemWinlost_aff  
											-src.MemBonus_aff * dbo.Aff_GetDeductionPercent(src.AffID, src.ProductID,'Bonus', src.WinlostDate)  
											-src.MemAdjustment_aff  
											-src.MemPSP_aff * dbo.Aff_GetDeductionPercent(src.AffID, src.ProductID,'PSP', src.WinlostDate)  
											- ABS(src.MemWinlost_aff) * dbo.Aff_GetDeductionPercent(src.AffID, src.ProductID,'Marketing', src.WinlostDate)  
											- ABS(src.MemWinlost_aff) * dbo.Aff_GetDeductionPercent(src.AffID, src.ProductID,'Odds Fee', src.WinlostDate)  
											- ABS(src.MemWinlost_aff) * dbo.Aff_GetDeductionPercent(src.AffID, src.ProductID,'PlayTech Royalties', src.WinlostDate)  
									)   
		WHEN NOT MATCHED BY TARGET THEN
			INSERT
			   ([AffID]
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
			   ,[MemPLayTechFee]
			   ,[MemPLayTechFee_aff]
			   ,[MemWinlostFake]
			   ,[MemAffTransfer]
			   ,[MemTransfer3rd]
			   ,[MemBetCount]
			   ,[MemPlayerComm]
			   ,[MemAffTransfer_aff]
			   ,[MemTransfer3rd_aff]
			   ,[MemPlayerComm_aff]
			   ,[MemTurnoverNoDraw]
			   ,[MemBetCountNoDraw]
			   ,[MemTurnoverNoDraw_aff]
			   ,[MemTurnoverDraw]
			   ,[MemTurnoverDraw_aff])
		 VALUES
			   (src.AffID
			   ,src.Winlostdate
			   ,src.ProductID
			   ,src.AffCurrency
			   ,src.SysCurrency
			   ,src.[MemDeposit]
			   ,src.[MemWithdrawal]
			   ,src.[MemTurnover]
			   ,src.[MemBonus]
			   ,src.[MemAdjustment]
			   ,src.[MemMarketing]
			   ,src.[MemPSP]
			   ,src.[MemWinlost]
			   ,src.[AffWinlost]
			   ,src.[HouseWinlost]
			   ,src.[AffNetWinlost]
			   ,src.[HouseNetWinlost]
			   ,src.[MemOddsFee]
			   ,src.[MemDeposit_aff]
			   ,src.[MemWithdrawal_aff]
			   ,src.[MemTurnover_aff]
			   ,src.[MemBonus_aff]
			   ,src.[MemAdjustment_aff]
			   ,src.[MemMarketing_aff]
			   ,src.[MemPSP_aff]
			   ,src.[MemWinlost_aff]
			   ,src.[AffWinlost_aff]
			   ,src.[HouseWinlost_aff]
			   ,src.[AffNetWinlost_aff]
			   ,src.[HouseNetWinlost_aff]
			   ,src.[MemOddsFee_aff]
			   ,src.[MemWinlostFake_aff]
			   ,src.[MemPLayTechFee]
			   ,src.[MemPLayTechFee_aff]
			   ,src.[MemWinlostFake]
			   ,src.[MemAffTransfer]
			   ,src.[MemTransfer3rd]
			   ,src.[MemBetCount]
			   ,src.[MemPlayerComm]
			   ,src.[MemAffTransfer_aff]
			   ,src.[MemTransfer3rd_aff]
			   ,src.[MemPlayerComm_aff]
			   ,src.[MemTurnoverNoDraw]
			   ,src.[MemBetCountNoDraw]
			   ,src.[MemTurnoverNoDraw_aff]
			   ,src.[MemTurnoverDraw]
			   ,src.[MemTurnoverDraw_aff])
		--OUTPUT $action
		;
	END

	DROP TABLE #srcMemberSum;

END
GO

GRANT EXECUTE ON dbo.Task_Aff_UpdateAffDailyData TO bodbAdminNet
