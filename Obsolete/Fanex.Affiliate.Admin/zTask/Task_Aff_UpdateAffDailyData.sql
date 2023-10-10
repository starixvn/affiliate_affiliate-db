CREATE PROCEDURE dbo.Task_Aff_UpdateAffDailyData 
	@UserId INT
	,@AffID INT
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
	INTO #tmpMemberSum
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

	IF(EXISTS(SELECT TOP 1 1 FROM #tmpMemberSum))
	BEGIN
		MERGE INTO dbo.AffDaily AS tar
		USING #tmpMemberSum AS src
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
		OUTPUT $action;
	END

	DROP TABLE #tmpMemberSum;

END
GO

GRANT EXECUTE ON dbo.Task_Aff_UpdateAffDailyData TO bodbAdminNet
