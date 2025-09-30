ALTER PROCEDURE [dbo].[Task_CheckSum_WinlostByProduct]
	@Date SMALLDATETIME
AS
/*
Created: 20140529@bobby
Task : #1052 -  Create a daily checksum data service
DB: DBAFF.Affiliate_Licensee
Original : [Task_CheckSum_WinlostByProduct]
Revisions:  
	-20140820@Bobby: Add checking enable Product
	-20160120@Bobby: #51170 - Add ordering by product Id
	-20160331@Bobby: #53169 - Update for check sum per Product Id
	
Param's Explanation:  
	
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @tblMember AS TABLE (UserName VARCHAR(30));
	
	SET @Date = CAST(@Date AS DATE)

	;WITH MemberList
	AS (
		SELECT m.username
		FROM dbo.MemberInfo m(NOLOCK)
		WHERE m.IsRemoved = 0
			AND datediff(d, m.RegisteredDate, cast(@Date AS VARCHAR(50))) >= - 1
			AND m.CreatedDate IS NOT NULL
			AND datediff(d, m.AffAffectedDate, @Date) >= 0
		
		UNION
		SELECT rm.UserName
		FROM dbo.MemberRemoval rm WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK)
			ON rm.username = m.username
		WHERE m.IsRemoved = 1
			AND datediff(d, m.RegisteredDate, cast(@Date AS VARCHAR(50))) >= - 1
			AND m.CreatedDate IS NOT NULL
			AND datediff(d, m.AffAffectedDate, @Date) >= 0
			AND datediff(m, cast(@Date AS VARCHAR(50)), isnull(rm.RemovedDate, GetDate())) > 0
		GROUP BY rm.UserName
	)
	INSERT INTO @tblMember(UserName)
	SELECT UserName
	FROM MemberList
	GROUP BY UserName

	SELECT Winlostdate
		,md.ProductID
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
		INNER JOIN @tblMember m 
		ON md.UserName = m.UserName
		INNER JOIN dbo.Product p WITH(NOLOCK)
		ON md.ProductID = p.ProductID
	WHERE Winlostdate = @Date
		AND p.IsEnabled = 1
		AND p.EffectiveDate <= @Date
	GROUP BY Winlostdate
		,md.ProductID

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
	ORDER BY p.API_ProductID ASC
	
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
	;WITH CTE_ProductRpt AS (
		SELECT DISTINCT ProductID
		FROM #rptData
	)
	SELECT p.API_ProductID AS ProductID
		, p.ProductName
	FROM dbo.Product p WITH(NOLOCK)
		INNER JOIN CTE_ProductRpt rpt ON p.ProductID = rpt.ProductID
	WHERE p.IsEnabled = 1
		AND p.EffectiveDate <= @Date
	ORDER BY p.API_ProductID ASC
	
	DROP TABLE #rptData
END
