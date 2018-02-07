USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_StatisticsSel] 
	@AffID 				INT
	,@MonthDate 		SMALLDATETIME
	,@TotalActivePlayer	INT 				OUTPUT
	,@TotalPlayerDepUp 	INT 				OUTPUT
	,@NewSignUpDep 		INT 				OUTPUT
	,@NewSignUp 		INT 				OUTPUT
	,@TotalPlayer 		INT 				OUTPUT
	,@BalBroughtforward MONEY			= 0 OUTPUT
	,@TotalDeposit 		MONEY 				OUTPUT
	,@TotalDepositUp 	MONEY 				OUTPUT
	,@TotalTurnover 	MONEY 				OUTPUT
	,@TotalTurnoverUp 	MONEY 				OUTPUT
	,@TotalWinlostUp 	MONEY 				OUTPUT
	,@TotalWinlost 		MONEY 				OUTPUT
	,@TotalUniqueClicks INT 			= 0 OUTPUT
	,@TotalClicks 		INT 			= 0 OUTPUT
AS

/*
	Created: 20090325@VinhTrinh  
	Task: Get statistics for affiliate  
	DB: DBAFF.Affiliate_Athena000  
	Original : [Aff_StatisticsSel]

	Revisions:  
		- 20090513@VinhTrinh: return 2 more result(winlost up to now and winlos for search month).  
		- 20090827@DungTong: Convert to new DB version  
		- 20100511@Johnny: correct output params "@TotalPlayerDepUp" and "@NewSignUpDep"  
		- 20140520@Bobby: add filtering product by commgroup
		- 20140819@Bobby: Apply SQL style scope
		- 20180507@Percy: Enhance Performance

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

	DECLARE @ProductFilter TABLE (ProductId INT)

	IF DATEDIFF(MONTH, @MonthDate, CURRENT_TIMESTAMP) = 0
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT p.ProductID
		FROM dbo.Product p WITH (NOLOCK)
		WHERE EXISTS (
			SELECT 1 FROM dbo.AffInfo ai WITH (NOLOCK)
				INNER JOIN dbo.GroupSetting gs WITH (NOLOCK) ON ai.GroupID = gs.GroupID
			WHERE ai.AffID = @AffId AND gs.ProductID = p.ProductID
		)
	END
	ELSE
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT p.ProductID
		FROM dbo.Product p WITH (NOLOCK)
		WHERE EXISTS (
			SELECT 1 FROM dbo.AffGroupHistory agh WITH (NOLOCK)
				INNER JOIN dbo.GroupSettingHistory gsh WITH (NOLOCK) ON agh.GroupID = gsh.GroupID
			WHERE agh.AffID = @AffId AND gsh.ProductID = p.ProductID AND gsh.MonthDate = CONVERT(DATE, dbo.Aff_GetLastDayOfMonth(@MonthDate))
		)
	END

	INSERT INTO @ProductFilter
	SELECT p.ProductID
	FROM dbo.Product p WITH (NOLOCK)
	WHERE [dbo].[Aff_IsProductInGroupOfAff](@AffID, p.ProductID, @MonthDate) > 0

	SELECT @NewSignUp = sum(CASE 
				WHEN DATEDIFF(MONTH, @MonthDate, RegisteredDate) = 0 THEN 1
				ELSE 0
				END)
		,@NewSignUpDep = sum(CASE 
				WHEN CreatedDate IS NOT NULL
					AND datediff(m, CreatedDate, @MonthDate) = 0 THEN 1
				ELSE 0
				END)
		,@TotalPlayerDepUp = sum(CASE 
				WHEN CreatedDate IS NOT NULL
					AND IsRemoved = 0 THEN 1
				ELSE 0
				END)
		,@TotalPlayer = sum(CASE 
				WHEN IsRemoved = 0 THEN 1
				ELSE 0
				END)
	FROM dbo.MemberInfo WITH (NOLOCK)
	WHERE AffID = @AffID
		AND username NOT IN (
			SELECT username
			FROM MemberRemoval WITH (NOLOCK)
			WHERE datediff(m, RemovedDate, @MonthDate) = 0
			)

	CREATE TABLE #TblStatistics (
		username VARCHAR(30)
		,ProductID INT
		,QualifiedMember INT
		,ActivePlayer INT
		,Turnover MONEY
		,Deposit MONEY
		,Winlost MONEY
		,MonthDate SMALLDATETIME
		)

	INSERT INTO #TblStatistics
	SELECT ''
		,a.ProductID
		,QualifiedMember
		,ActivePlayer
		,MemberTurnover_aff
		,--Turnover has been change to AffExRate  
		MemberDeposit_aff
		,--Deposit has been change to AffExRate  
		MemberWinlost_aff AS MemberWinlost
		,--Winlost has been change to AffExRate  
		WinlostDate
	FROM dbo.AffCommission a WITH (NOLOCK)
		INNER JOIN @ProductFilter p ON a.ProductId = p.ProductId
	WHERE AffId = @AffId

	DECLARE @MaxTransDate DATETIME
		,@FromDate DATETIME
		,@CurrentDate DATETIME
		,@QMTurnover MONEY

	SELECT @QMTurnover = dbo.[Aff_GetQMTurnOver](@AffID, @MonthDate)
		,@CurrentDate = CURRENT_TIMESTAMP

	SELECT @MaxTransDate = MAX(MonthDate)
	FROM #TblStatistics WITH (NOLOCK)

	IF @MaxTransDate IS NOT NULL
		SELECT @FromDate = DATEADD(d, 1, @MaxTransDate)
	ELSE
		SELECT @FromDate = MIN(WinlostDate)
		FROM AffDailySummary(NOLOCK)

	INSERT INTO #TblStatistics
	SELECT ci.username
		,b.ProductID
		,0 AS QualifiedMember
		,0 AS ActivePlayer
		,SUM(ISNULL(TurnOver, 0) * ISNULL(AffExRate, 1)) AS Turnover
		,SUM(ISNULL(Deposit, 0) * ISNULL(AffExRate, 1)) AS Deposit
		,SUM(ISNULL(Winlost, 0) * ISNULL(AffExRate, 1)) AS Winlost
		,DATEADD(mm, DATEDIFF(m, 0, b.WinlostDate), 0)
	FROM dbo.MemberDaily b WITH (NOLOCK)
		INNER JOIN dbo.MemberInfo ci WITH (NOLOCK) ON ci.username = b.username
		INNER JOIN @ProductFilter p ON b.ProductId = p.ProductId
	WHERE ci.AffID = @AffID
		AND b.winlostdate BETWEEN @FromDate AND @CurrentDate --this condition use up index on winlostdate      
		and [dbo].[Aff_IsProductInGroupOfAff](@AffID, b.ProductID ,@MonthDate) >0    
	GROUP BY ci.username
		,b.ProductID
		,DATEADD(mm, DATEDIFF(m, 0, b.winlostdate), 0)

	UPDATE #TblStatistics
	SET QualifiedMember = (CASE WHEN Turnover >= @QMTurnover THEN 1 ELSE 0 END)
	WHERE username <> ''

	SELECT @TotalWinlostUp = Sum(a.Winlost)
		,@TotalTurnoverUp = Sum(a.Turnover)
		,@TotalDepositUp = Sum(a.Deposit)
		,@TotalWinlost = Sum(CASE 
				WHEN DATEDIFF(m, a.MonthDate, @MonthDate) = 0 THEN a.Winlost
				ELSE 0
				END)
		,@TotalTurnover = Sum(CASE 
				WHEN DATEDIFF(m, a.MonthDate, @MonthDate) = 0 THEN a.Turnover
				ELSE 0
				END)
		,@TotalDeposit = SUM(CASE 
				WHEN DATEDIFF(m, a.MonthDate, @MonthDate) = 0 THEN a.Deposit
				ELSE 0
				END)
	--,@TotalActivePlayer=sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0  then ISNULL(a.ActivePlayer,0) else 0 end)   
	FROM #TblStatistics a WITH (NOLOCK)

	DECLARE @DateTemp DATETIME

	SET @DateTemp = dbo.Date_Only(dbo.Aff_GetLastDayOfMonth(@MonthDate))

	IF EXISTS (SELECT TOP (1) 1 FROM dbo.AffCommission(NOLOCK) WHERE winlostdate = @DateTemp)
	BEGIN
		SELECT @TotalActivePlayer = MAX(ActivePlayer)
		FROM #TblStatistics a WITH (NOLOCK)
		WHERE DATEDIFF(m, a.MonthDate, @MonthDate) = 0
			AND username = ''
	END
	ELSE
	BEGIN
		SELECT @TotalActivePlayer = COUNT(DISTINCT username)
		FROM #TblStatistics a WITH (NOLOCK)
		WHERE DATEDIFF(m, a.MonthDate, @MonthDate) = 0
			AND username <> ''
			AND (a.Turnover > 0 OR a.Deposit > 0)
	END

	--Get Click Statistics  
	SELECT @TotalClicks = sum(TotalClick)
		,@TotalUniqueClicks = sum(UniqueClick)
	FROM (
		SELECT sum(TotalClick) AS TotalClick
			,Sum(UniqueClick) AS UniqueClick
		FROM dbo.ClickStatisticsSum(NOLOCK)
		WHERE AffID = @AffID
			AND datediff(mm, @MonthDate, [date]) = 0
		
		UNION ALL
		SELECT sum(ClickCount) AS TotalClick
			,count(DISTINCT s.IP) AS UniqueClick
		FROM dbo.ClickStatistics s(NOLOCK)
		WHERE datediff(mm, @MonthDate, s.DATE) = 0
			AND s.AffID = @AffID
		GROUP BY dbo.Date_Only(DATE)
			,DomainReferrer
			,SportCode
			,LanguageCode
		) t

	SELECT @BalBroughtforward = ISNULL(dbo.Aff_GetAffBalance(@AffID), 0)

	IF (DATEDIFF(m, current_timestamp, @MonthDate) > 0)
	BEGIN
		SELECT p.ProductID
			,p.ProductName
			,0 AS TotalQualifiedMembers
		FROM dbo.Product p WITH (NOLOCK)
			INNER JOIN @ProductFilter f ON p.ProductId = f.ProductId
		ORDER BY p.ProductID
	END
	ELSE
	BEGIN
		SELECT p.ProductID
			,p.ProductName
			,ISNULL(t.TotalQualifiedMembers, 0) AS TotalQualifiedMembers
		FROM dbo.Product p WITH (NOLOCK)
			LEFT JOIN (
				SELECT a.ProductID
					,sum(a.QualifiedMember) AS TotalQualifiedMembers
				FROM #TblStatistics a(NOLOCK)
				WHERE DATEDIFF(m, a.MonthDate, @MonthDate) = 0
				GROUP BY a.ProductID
			) t ON t.ProductID = p.ProductID
		INNER JOIN @ProductFilter f ON p.ProductId = f.ProductId
		ORDER BY p.ProductID
	END

	-- get commgroup information
	IF (DATEDIFF(m, current_timestamp, @MonthDate) >= 0)
	BEGIN
		SELECT a.GroupId, g.GroupName AS CommGroupName
		FROM dbo.AffInfo a (NOLOCK)
			INNER JOIN dbo.CommGroup g (NOLOCK) ON a.GroupId = g.GroupId
		WHERE AffId = @AffID
	END
	ELSE
	BEGIN
		SELECT ag.GroupId, sg.GroupName AS CommGroupName
		FROM dbo.AffGroupHistory ag (NOLOCK)
			INNER JOIN dbo.CommGroupHistory sg (NOLOCK) ON ag.GroupId = sg.GroupId AND DATEDIFF(m, ag.MonthDate, sg.MonthDate) = 0
		WHERE ag.AffId = @AffId 
			AND DATEDIFF(m, ag.MonthDate, @MonthDate) = 0
	END
	
	DROP TABLE #TblStatistics
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_StatisticsSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_StatisticsSel] TO [vnteam] AS [dbo]
GO