USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_PerformanceReportByAff] 
	@AffId INT
	,@SportId INT = 1
AS
/*  
	Created: @VinhTrinh  
	Task: Get performance report for affiliate in range of time.  
	DB: DBAFF12BET.Affiliate_12BET  
	Original: [Aff_PerformanceReportByAff]  
	Revisions:  
		- 20110811@Johnny: Get last 6 months of affiliate performance report  
		- 20111031@Peter: Exclude Number Game from Sportsbook commission (bettype from [81-120])  
		- 20120606@Peter: Exclude waiting tickets  
		- 20150108@Bobby: Update Withdrawal for casino product
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Fromdate DATETIME
		,@SportBookId INT
		,@CurrentDate SMALLDATETIME
		,@LastMonthlydate SMALLDATETIME
		,@FirstDate SMALLDATETIME
		,@Date_Prev SMALLDATETIME
		,@TmpToDate SMALLDATETIME

	SELECT @CurrentDate = dateadd(d, 0, datediff(d, 0, current_timestamp))

	SELECT @FromDate = dateadd(m, - 5, @CurrentDate) --Last 6 months  

	--@FromDate equal 1st date of @fromdate  
	SELECT @FromDate = DateAdd(m, datediff(m, 0, @FromDate), 0) --1st date of from date  
		,@Date_Prev = DateAdd(m, - 1, @CurrentDate)
		,@TmpToDate = DateAdd(d, - 1, @CurrentDate) --To Exclude current date for calculating affdaily table  
		,@SportBookId = 1

	SELECT @LastMonthlydate = max(WinlostDate)
	FROM AffCommission

	SELECT @FirstDate = dateadd(d, 1, @LastMonthlydate)

	SELECT dateadd(m, datediff(m, 0, t.Winlostdate), 0) AS WinLostDate
		,Sum(isnull(QualifiedMember, 0)) AS QualifiedMember
		,Sum(isnull(ActivePlayer, 0)) AS ActivePlayer
		,Sum(isnull(MemberDeposit, 0)) AS MemberDeposit
		,Sum(isnull(Withdrawal, 0)) AS MemberWithdrawal --Affiliate withdrawal  
		,Sum(isnull(MemberTurnover, 0)) AS MemberTurnover
		,Sum(isnull(MemberWinlost, 0)) AS MemberWinlost
		,Sum(isnull(Commission, 0)) AS Commission
	FROM (
		--Calculate for the months are transferred  
		SELECT @SportId AS SportId
			,WinlostDate
			,QualifiedMember
			,0 AS ActivePlayer
			,MemberDeposit
			,0 AS Withdrawal
			,MemberTurnover
			,MemberWinlost
			,AffWinlost AS Commission
		FROM AffCommission WITH(NOLOCK)
		WHERE WinlostDate BETWEEN @Fromdate AND @LastMonthlydate
			AND AffID = @AffId
			AND SportId = @SportId
		
		UNION ALL
		--Calculate Withdrawal  
		SELECT @SportId AS SportId
			,CompletedDate
			,0 AS QualifiedMember
			,0 AS ActivePlayer
			,0 AS MemberDeposit
			,Sum(isnull(Amount, 0))
			,0 AS MemberTurnover
			,0 AS MemberWinlost
			,0 AS Commission
		FROM AffTrans WITH (NOLOCK)
		WHERE AffId = @AffId
			AND CompletedDate BETWEEN @FromDate AND @CurrentDate
			AND transtype = 202
			AND STATUS = 'Approved' --For withdrawal   
		GROUP BY CompletedDate
		
		UNION ALL
		SELECT c.SportID
			,dateadd(m, datediff(m, 0, @CurrentDate), 0) AS Winlostdate
			,c.TotalQM
			,0 AS ActivePlayer
			,c.MemDeposit
			,0 AS Withdrawal
			,c.MemTurnOver
			,c.MemWinlost
			,c.Amount
		FROM [Aff_CommissionForCurrentMonth](@AffId) AS c
		WHERE c.SportID = @SportId
		
		UNION ALL
		SELECT c.SportID
			,dateadd(m, datediff(m, 0, @Date_Prev), 0) AS Winlostdate
			,c.TotalQM
			,0 AS ActivePlayer
			,c.MemDeposit
			,0 AS Withdrawal
			,c.MemTurnOver
			,c.MemWinlost
			,c.Amount
		FROM [Aff_CommissionForMonth](@AffId, MONTH(@Date_Prev), YEAR(@Date_Prev)) AS c
		WHERE DATEDIFF(m, @LastMonthlydate, @Date_Prev) > 0
			AND c.SportID = @SportId
			AND @Date_Prev > @LastMonthlydate
		
		UNION ALL --Get total active players in previous month and current month  
		SELECT @SportId AS SportId
			,dateadd(m, datediff(m, 0, Winlostdate), 0)
			,0 AS QualifiedMember
			,count(DISTINCT IBCCustID) AS ActivePlayer
			,0 AS Deposit
			,0 AS Withdrawal
			,0 AS Turnover
			,0 AS WinLost
			,0 AS Commission
		FROM Memberdaily WITH(NOLOCK)
		WHERE AffId = @AffId
			AND winlostdate BETWEEN @FromDate AND @CurrentDate
			AND (
				isnull(TurnOver, 0) > 0
				OR isnull(Deposit, 0) > 0
				)
			AND SportType = @SportId
		GROUP BY dateadd(m, datediff(m, 0, Winlostdate), 0)
		) AS t
	WHERE SportId = @SportId
	GROUP BY dateadd(m, datediff(m, 0, Winlostdate), 0)
END
GO

GRANT EXECUTE ON [dbo].[Aff_PerformanceReportByAff] TO [bodbAdminNet]
GO



