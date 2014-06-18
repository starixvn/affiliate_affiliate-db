ALTER PROCEDURE [dbo].[Task_CheckSum_WinlostByProduct]
	@Date SMALLDATETIME
AS
/*
Created: 20140529@bobby
Task : #1052 -  Create a daily checksum data service
DB: DBAFF.Affiliate_Licensee
Original : [Task_CheckSum_WinlostByProduct]
Revisions:  

Param's Explanation:  
	
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @tblMember AS TABLE (UserName VARCHAR(30));
	
	SET @Date = CAST(@Date AS DATE)

	INSERT INTO @tblMember(UserName)
	EXEC [dbo].[Aff_GetMembers] @Date = @Date

	SELECT Winlostdate
		,ProductID
		,SUM(ISNULL(Deposit, 0)) Deposit
		,SUM(ISNULL(Withdrawal, 0)) AS Withdrawal
		,SUM(ISNULL(Bonus, 0)) AS Bonus
		,SUM(ISNULL(Adjustment, 0)) AS Adjustment
		,SUM(ISNULL(Turnover, 0)) AS Turnover
		,SUM(ISNULL(Outstanding,0)) AS Outstanding
		,SUM(ISNULL(Winlost, 0)) AS Winloss
		,SUM(ISNULL(PlayerComm, 0)) AS PlayerComm
		,SUM(ISNULL(BetCount, 0)) AS BetCount
		,SUM(ISNULL(TurnoverNoDraw, 0)) AS TurnoverNoDraw
		,SUM(ISNULL(BetCountNoDraw, 0)) AS BetCountNoDraw
	INTO #rptData
	FROM dbo.MemberDaily md WITH(NOLOCK)
		INNER JOIN @tblMember m ON md.UserName = m.UserName
	WHERE Winlostdate = @Date
	GROUP BY Winlostdate
		,ProductID

	--product detail
	SELECT Winlostdate
		,p.API_ProductID AS ProductID
		,Deposit
		,Withdrawal
		,Bonus
		,Adjustment
		,Turnover
		,Outstanding
		,Winloss
		,PlayerComm
		,BetCount
		,TurnoverNoDraw
		,BetCountNoDraw
	FROM #rptData rpt
		INNER JOIN dbo.Product p WITH(NOLOCK)
		ON rpt.ProductID = p.ProductID
	
	--sum total
	SELECT  Winlostdate
		,SUM(Deposit) AS TotalDeposit
		,SUM(Withdrawal) AS TotalWithdrawal
		,SUM(Bonus) AS TotalBonus
		,SUM(Adjustment) AS TotalAdjustment
		,SUM(Turnover) AS TotalTurnover
		,SUM(Outstanding) AS TotalOutstanding
		,SUM(Winloss) AS TotalWinloss
		,SUM(PlayerComm) AS TotalPlayerComm
		,SUM(BetCount) AS TotalBetCount
		,SUM(TurnoverNoDraw) AS TotalTurnoverNoDraw
		,SUM(BetCountNoDraw) AS TotalBetCountNoDraw
	FROM #rptData
	GROUP BY Winlostdate

	--list product name
	SELECT p.API_ProductID AS ProductID
		, p.ProductName
	FROM dbo.Product p WITH(NOLOCK)

	DROP TABLE #rptData
END
GO
GRANT EXECUTE ON [dbo].[Task_CheckSum_WinlostByProduct] TO [bodbAdminNet] AS [dbo]
--exec [dbo].[Task_CheckSum_WinlostByProduct]
--	@Date = '2014-04-23 00:00:00'