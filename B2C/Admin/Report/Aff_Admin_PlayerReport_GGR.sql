/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_PlayerReport_GGR]
	@AffUsername	VARCHAR(50) = ''
	,@Username		VARCHAR(50) = ''
	,@ProductIds	VARCHAR(MAX) = ''
	,@FromDate		SMALLDATETIME
	,@ToDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
	,@IsExportExcel	BIT = 0
	,@PageIndex		INT = 1
	,@PageSize		INT = 50
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20210916@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin site - Report - Player Report

	Revisions:
		- 20210916@Percy: Initialize SP [RedmineID: #161540]
		- 20220629@Malcolm: Support an Affiliate remove player [RedmineID: #173640]

	Param's Explanation:
		- @ProductIds: list of products, '' = no product
*/

BEGIN
	SET NOCOUNT ON

	SELECT @AffUsername = ISNULL(@AffUsername, ''), @Username = ISNULL(@Username, '')

	DECLARE @LastDayOfToDate SMALLDATETIME = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0))

	-- Get Affiliate Info
	DECLARE @AffInfo TABLE (AffId INT PRIMARY KEY, AffUsername VARCHAR(50))
	INSERT INTO @AffInfo (AffId, AffUsername)
	SELECT AffId, Username
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE Username LIKE '%' + @AffUsername + '%'
		AND Status NOT IN ('Pending', 'Disapproved')

	-- Get Product List
	DECLARE @Products TABLE (ProductId INT)
	INSERT INTO @Products (ProductId)
	SELECT ProductId FROM dbo.Products WITH (NOLOCK) WHERE ProductId IN (SELECT val FROM dbo.Aff_f_StringSplit(@ProductIds, ','))

	CREATE TABLE #ProductSetting (AffId INT, AffUsername VARCHAR(50), ProductId INT, FromDate SMALLDATETIME, ToDate SMALLDATETIME, IsStraightSetting BIT)
	INSERT INTO #ProductSetting (AffId, AffUsername, ProductId, FromDate, ToDate, IsStraightSetting)
	SELECT a.AffId, a.AffUsername, dsh.ProductId, DATEADD(MONTH, DATEDIFF(MONTH, 0, dsh.MonthDate), 0), dsh.MonthDate, 0
	FROM @AffInfo a
		INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON a.AffId = agh.AffId
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId AND agh.MonthDate = dsh.MonthDate
		INNER JOIN @Products p ON dsh.ProductId = p.ProductId
	WHERE agh.MonthDate BETWEEN @FromDate AND @LastDayOfToDate

	INSERT INTO #ProductSetting (AffId, AffUsername, ProductId, FromDate, ToDate, IsStraightSetting)
	SELECT a.AffId, a.AffUsername, ssh.ProductId, DATEADD(MONTH, DATEDIFF(MONTH, 0, ssh.MonthDate), 0), ssh.MonthDate, 1
	FROM @AffInfo a
		INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON a.AffId = agh.AffId
		INNER JOIN dbo.StraightSettingHistory ssh WITH (NOLOCK) ON agh.GroupId = ssh.GroupId AND agh.MonthDate = ssh.MonthDate
		INNER JOIN @Products p ON ssh.ProductId = p.ProductId
	WHERE agh.MonthDate BETWEEN @FromDate AND @LastDayOfToDate

	-- Get player TO/WL data
	CREATE TABLE #tmpData
	(
		WinlostDate SMALLDATETIME, AffId INT, AffUsername VARCHAR(50), CustId INT, Currency INT, ProductId INT, Turnover MONEY, GGR MONEY
		,PRIMARY KEY (WinlostDate, AffId, CustId, Currency, ProductId)
	)
	INSERT INTO #tmpData (WinlostDate, AffId, AffUsername, CustId, Currency, ProductId, Turnover, GGR)
	SELECT r.WinlostDate, r.AffId, a.AffUsername, r.CustId, r.Currency, r.ProductId
		,SUM(CASE WHEN a.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END)
		,SUM(CASE WHEN a.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0) ELSE -(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0) END)
	FROM dbo.rptMemberDaily r WITH (NOLOCK)
		INNER JOIN #ProductSetting a ON r.AffId = a.AffId AND r.ProductId = a.ProductId AND r.WinlostDate BETWEEN a.FromDate AND a.ToDate
	WHERE r.WinlostDate BETWEEN @FromDate AND @ToDate
		AND NOT EXISTS (
			SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
			WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate 
		)
	GROUP BY r.WinlostDate, r.AffId, a.AffUsername, r.CustId, r.Currency, r.ProductId

	CREATE TABLE #Result (AffId INT, AffUsername VARCHAR(50), CustId INT, UserName VARCHAR(50), RegisteredDate DATETIME, FirstDepositDate DATETIME
		,ProductId INT, Turnover MONEY, GGR MONEY)
	INSERT INTO #Result (AffId, AffUsername, CustId, ProductId, Turnover, GGR)
	SELECT d.AffId, d.AffUsername, d.CustId, d.ProductId, SUM(d.Turnover * e.Rate), SUM(d.GGR * e.Rate)
	FROM #tmpData d
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(d.WinlostDate, d.Currency, @BaseCurrency) e
	GROUP BY d.AffId, d.AffUsername, d.CustId, d.ProductId

	IF @Username <> ''
		DELETE r
		FROM #Result r
			LEFT JOIN dbo.MemberInfo m WITH (NOLOCK) ON r.CustId = m.CustId AND m.UserName LIKE '%' + @Username + '%'
		WHERE m.CustId IS NULL

	SELECT @NRows = COUNT(DISTINCT CustId) FROM #Result
	IF @NRows = 0
		RETURN

	-- Total row
	CREATE TABLE #Total (ProductId INT, Turnover MONEY, GGR MONEY)
	INSERT INTO #Total (ProductId, Turnover, GGR)
	SELECT ProductId, SUM(Turnover), SUM(GGR)
	FROM #Result
	GROUP BY ProductId

	IF @IsExportExcel = 0
	BEGIN
		DECLARE @RowStart INT, @RowEnd INT
		SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1

		DELETE r
		FROM (
			SELECT AffId, CustId, DENSE_RANK() OVER(ORDER BY AffId, CustId) AS RN
			FROM #Result
		) r
		WHERE r.RN NOT BETWEEN @RowStart AND @RowEnd
	END

	UPDATE r
	SET r.UserName = m.UserName, r.RegisteredDate = m.RegisteredDate, r.FirstDepositDate = m.FirstDepositDate
	FROM #Result r
		INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON r.CustId = m.CustId

	-- Total TO, WL columns
	INSERT INTO #Result (AffId, AffUsername, CustId, UserName, RegisteredDate, FirstDepositDate, ProductId, Turnover, GGR)
	SELECT AffId, AffUsername, CustId, UserName, RegisteredDate, FirstDepositDate, 0 AS ProductId, SUM(Turnover), SUM(GGR)
	FROM #Result
	GROUP BY AffId, AffUsername, CustId, UserName, RegisteredDate, FirstDepositDate

	INSERT INTO #Total (ProductId, Turnover, GGR)
	SELECT 0 AS ProductId, SUM(Turnover), SUM(GGR)
	FROM #Total

	DECLARE @OutputColumns VARCHAR(MAX)
	SELECT  @OutputColumns = COALESCE(@OutputColumns + ', ', '')
		+ '[' + CONVERT(VARCHAR(20), ProductId) + '_Turnover]'
		+ ', [' + CONVERT(VARCHAR(20), ProductId) + '_GGR]'
	FROM @Products

	SELECT @OutputColumns = '[Total_Turnover], [Total_GGR]' + ISNULL(', ' + @OutputColumns, '')

	-- Return result
	DECLARE @SQL VARCHAR(MAX)
	SET @SQL = '
	;WITH CTE_Result AS (
		SELECT r.AffId, r.AffUsername, r.CustId, r.UserName, r.RegisteredDate, r.FirstDepositDate, ISNULL(t.Value, 0) AS Value
			,CASE WHEN r.ProductId = 0 THEN ''Total'' ELSE CONVERT(VARCHAR(20), r.ProductId) END + ''_'' + t.Figure AS Figure
		FROM #Result r
			CROSS APPLY (
				SELECT ''Turnover'' AS Figure, Turnover AS Value
				UNION ALL SELECT ''GGR'', r.GGR
			) t
	)
	SELECT AffId, AffUsername, CustId, UserName, RegisteredDate, FirstDepositDate, ' + @OutputColumns + '
	FROM CTE_Result r
	PIVOT (
		MAX (Value)
		FOR Figure IN (' + @OutputColumns + ')
	) p'

	EXEC (@SQL)

	-- Total row
	SET @SQL = '
	;WITH CTE_Result AS (
		SELECT ISNULL(t.Value, 0) AS Value
			,CASE WHEN r.ProductId = 0 THEN ''Total'' ELSE CONVERT(VARCHAR(20), r.ProductId) END + ''_'' + t.Figure AS Figure
		FROM #Total r
			CROSS APPLY (
				SELECT ''Turnover'' AS Figure, Turnover AS Value
				UNION ALL SELECT ''GGR'', r.GGR
			) t
	)
	SELECT ' + @OutputColumns + '
	FROM CTE_Result r
	PIVOT (
		MAX (Value)
		FOR Figure IN (' + @OutputColumns + ')
	) p'

	EXEC (@SQL)

	DROP TABLE #ProductSetting
	DROP TABLE #Result
	DROP TABLE #tmpData
	DROP TABLE #Total
END
GO