/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_StatisticsSel]
    @AffID				INT
	,@MonthDate			SMALLDATETIME
	,@TotalActivePlayer INT OUTPUT
	,@TotalPlayerDepUp	INT OUTPUT
	,@NewSignUpDep		INT OUTPUT
	,@NewSignUp			INT OUTPUT
	,@TotalPlayer		INT OUTPUT
	,@BalBroughtforward MONEY = 0 OUTPUT
	,@TotalDeposit		MONEY OUTPUT
	,@TotalDepositUp	MONEY OUTPUT
	,@TotalTurnover		MONEY OUTPUT
	,@TotalTurnoverUp	MONEY OUTPUT
	,@TotalWinlostUp	MONEY OUTPUT
	,@TotalWinlost		MONEY OUTPUT
	,@TotalUniqueClicks INT = 0 OUTPUT
	,@TotalClicks		INT = 0 OUTPUT
AS

/*
	Created: 20090325@VinhTrinh
	DB: DBAFF-Affiliate_Athena000
	Task: Get statistics for affiliate

	Revisions:
		- 20090513@VinhTrinh: return 2 more result(winlost up to now and winlos for search month).  
		- 20090827@DungTong: Convert to new DB version  
		- 20100511@Johnny: correct output params "@TotalPlayerDepUp" and "@NewSignUpDep"  
		- 20130806@Jim:  just get Turnover value from  products that have group comm
		- 20140212@Dan: optimize performance
		- 20211222@Percy: Merge SLT to SB [RedmineID: #165777]
		- 20220602@Malcolm: remove products which have IsEnable = 0 [RedmineID: #172701]
	
	Param's Explanation:  
		• @AffID : Affiliate custid  
		• @MonthDate : Date search(format:first day of the month).  
		• @TotalActivePlayer : Get Active player in Month  
		• @TotalPlayerDepUp int OUTPUT,--Get player deposited in our system  
		• @NewSignUpDep : Get new signups of the month  
		• @TotalDeposit : total deposit money for month search  
		• @TotalDepositUp money OUTPUT,--total deposit money up to now  
		• @TotalTurnover money OUTPUT,--total turnover money up to now  
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @FromDate SMALLDATETIME = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	DECLARE @ToDate SMALLDATETIME = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))
	DECLARE @EndOfCurrentMonth SMALLDATETIME = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

	-- Get signup/deposit member
	SELECT @NewSignUp = SUM(CASE WHEN DATEDIFF(MONTH, @MonthDate, mi.RegisteredDate) = 0 THEN 1 ELSE 0 END)
		,@NewSignUpDep = SUM(CASE WHEN DATEDIFF(MONTH, @MonthDate, mi.CreatedDate) = 0 THEN 1 ELSE 0 END)
		,@TotalPlayerDepUp = SUM(CASE WHEN mi.CreatedDate IS NOT NULL THEN 1 ELSE 0 END)
		,@TotalPlayer = SUM(1)
	FROM dbo.MemberInfo mi WITH (NOLOCK)
	WHERE mi.AffId = @AffId
		AND mi.UserName NOT IN (
			SELECT mr.UserName FROM dbo.MemberRemoval mr WITH (NOLOCK)
			WHERE mr.AffId = @AffId
				AND mr.RemovedDate <= @ToDate
		)

	-- Get Click Statistics  
	SELECT @TotalClicks = SUM(TotalClick), @TotalUniqueClicks = SUM(UniqueClick)
	FROM (
		SELECT SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM dbo.ClickStatisticsSum WITH (NOLOCK)
		WHERE AffID = @AffId
			AND [Date] >= @FromDate AND [Date] < DATEADD(DAY, 1, @ToDate)
		
		UNION ALL
		SELECT SUM(ClickCount) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics WITH (NOLOCK)
		WHERE AffID = @AffId
			AND [Date] >= @FromDate AND [Date] < DATEADD(DAY, 1, @ToDate)
		GROUP BY CONVERT(DATE, [Date])
			,DomainReferrer
			,SportCode
			,LanguageCode
	) t

	-- Get deposit/turnover/winlost amount
	DECLARE @MinDate SMALLDATETIME
	SELECT  @MinDate = CONVERT(DATE, ApprovedDate) FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId

	CREATE TABLE #tmpData
	(
		MonthDate			SMALLDATETIME
		,UserName			VARCHAR(30)
		,ProductId			INT
		,QualifiedMember	INT
		,ActivePlayer		INT
		,Turnover			MONEY
		,Deposit			MONEY
		,Winlost			MONEY
	)

	-- Calculated months
	INSERT INTO #tmpData (MonthDate, UserName, ProductId, QualifiedMember, ActivePlayer, Turnover, Deposit, Winlost)
	SELECT ac.WinlostDate, '', ISNULL(g.GroupProductId, ac.ProductId), SUM(ac.QualifiedMember), MAX(ac.ActivePlayer), SUM(MemberTurnover_aff), SUM(MemberDeposit_aff), SUM(MemberWinlost_aff)
	FROM dbo.AffCommission ac WITH (NOLOCK)
		INNER JOIN dbo.Product p WITH(NOLOCK) ON p.ProductID = ac.ProductID
		LEFT JOIN dbo.Aff_f_GroupProduct() g ON ac.ProductId = g.ProductId
	WHERE ac.AffId = @AffId AND p.IsEnabled = 1
		AND ac.WinlostDate >= @MinDate
	GROUP BY ac.WinlostDate, ISNULL(g.GroupProductId, ac.ProductId)

	-- Uncalculated months
	IF EXISTS (SELECT 1 FROM #tmpData)
		SELECT @MinDate = DATEADD(DAY, 1, MAX(MonthDate)) FROM #tmpData
	ELSE
		SELECT @MinDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 2, 0) -- First day of 2 previous months

	DECLARE @ProductList TABLE (GroupProductId INT, ProductId INT, MonthDate SMALLDATETIME, QMTurnover MONEY)
	INSERT INTO @ProductList (GroupProductId, ProductId, MonthDate, QMTurnover)
	SELECT DISTINCT ISNULL(g.GroupProductId, gs.ProductId), ISNULL(g.ProductId, gs.ProductId), @EndOfCurrentMonth, cg.QualifiedAmount
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupId = cg.GroupId
		INNER JOIN dbo.GroupSetting gs WITH (NOLOCK) ON ai.GroupId = gs.GroupId
		INNER JOIN dbo.Product p WITH(NOLOCK) ON p.ProductID = gs.ProductID
		LEFT JOIN dbo.Aff_f_GroupProduct() g ON gs.ProductId = g.GroupProductId
	WHERE ai.AffId = @AffId AND p.IsEnabled = 1

	INSERT INTO @ProductList (GroupProductId, ProductId, MonthDate, QMTurnover)
	SELECT DISTINCT ISNULL(g.GroupProductId, gsh.ProductId), ISNULL(g.ProductId, gsh.ProductId), gsh.MonthDate, cgh.QualifiedAmount
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.CommGroupHistory cgh WITH (NOLOCK) ON agh.GroupId = cgh.GroupId AND agh.MonthDate = cgh.MonthDate
		INNER JOIN dbo.GroupSettingHistory gsh WITH (NOLOCK) ON agh.GroupId = gsh.GroupId AND agh.MonthDate = gsh.MonthDate
		INNER JOIN dbo.Product p WITH(NOLOCK) ON p.ProductID = gsh.ProductID
		LEFT JOIN dbo.Aff_f_GroupProduct() g ON gsh.ProductId = g.GroupProductId
	WHERE gsh.MonthDate >= @MinDate AND p.IsEnabled = 1 AND agh.AffId = @AffId 
		AND gsh.MonthDate < @EndOfCurrentMonth

	INSERT INTO #tmpData (MonthDate, UserName, ProductId, QualifiedMember, ActivePlayer, Turnover, Deposit, Winlost)
	SELECT t.MonthDate, t.UserName, p.GroupProductId, MAX(CASE WHEN t.Turnover >= p.QMTurnover THEN 1 ELSE 0 END) AS QualifiedMember, 0 AS ActivePlayer, SUM(t.Turnover), SUM(t.Deposit), SUM(t.Winlost)
	FROM (
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)) AS MonthDate
			,UserName, ProductId
			,SUM(ISNULL(TurnOver, 0) * ISNULL(AffExRate, 1)) AS Turnover
			,SUM(ISNULL(Deposit, 0) * ISNULL(AffExRate, 1)) AS Deposit
			,SUM(ISNULL(Winlost, 0) * ISNULL(AffExRate, 1)) AS Winlost
		FROM dbo.MemberDaily WITH (NOLOCK)
		WHERE AffId = @AffId
			AND WinlostDate BETWEEN @MinDate AND @ToDate
		GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0))
			,UserName, ProductId
	) t
		INNER JOIN @ProductList p ON t.MonthDate = p.MonthDate AND t.ProductId = p.ProductId
	GROUP BY t.MonthDate, t.UserName, p.GroupProductId

	SELECT @TotalWinlostUp = SUM(Winlost)
		,@TotalTurnoverUp = SUM(Turnover)
		,@TotalDepositUp = SUM(Deposit)
		,@TotalWinlost = SUM(CASE WHEN MonthDate = @ToDate THEN Winlost ELSE 0 END)
		,@TotalTurnover = SUM(CASE WHEN MonthDate = @ToDate THEN Turnover ELSE 0 END)
		,@TotalDeposit = SUM(CASE WHEN MonthDate = @ToDate THEN Deposit ELSE 0 END)
	FROM #tmpData

	-- Get Active player, BFF
	SELECT @TotalActivePlayer = MAX(ActivePlayer) FROM #tmpData WHERE MonthDate = @ToDate AND UserName = ''

	IF @@ROWCOUNT = 0
		SELECT @TotalActivePlayer = COUNT(DISTINCT UserName) FROM #tmpData WHERE MonthDate = @ToDate AND (Turnover <> 0 AND Deposit <> 0)

	SELECT @BalBroughtforward = ISNULL(dbo.Aff_GetAffBalance(@AffID), 0)

	-- Return Product List
	SELECT p.ProductId, p.ProductName, ISNULL(t.TotalQualifiedMembers, 0) AS TotalQualifiedMembers
	FROM dbo.Product p WITH (NOLOCK)
		INNER JOIN @ProductList pl ON p.ProductId = pl.ProductId AND pl.ProductId = pl.GroupProductId
		LEFT JOIN (
			SELECT ProductId, SUM(QualifiedMember) AS TotalQualifiedMembers
			FROM #tmpData
			WHERE MonthDate = @ToDate
			GROUP BY ProductId
		) t ON p.ProductId = t.ProductId
	WHERE pl.MonthDate = @ToDate AND p.IsEnabled = 1

	DROP TABLE #tmpData
END
GO