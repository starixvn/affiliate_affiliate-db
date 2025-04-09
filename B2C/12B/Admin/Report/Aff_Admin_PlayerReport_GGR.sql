/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_PlayerReport_GGR]
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
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Report - Player Report

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241227@Sally: Enhance performance [RedmineID: #212201]
		- 20250409@Sally: Fix get data Virtual Sport 2 [RedmineID: #223334]

	Param's Explanation:
		- @ProductIds: list of products, '' = no product
		- @BaseCurrency : Currency of B2C
*/

BEGIN
	SET NOCOUNT ON

	SET @ProductIds = dbo.Aff_f_AddRelatedProducts(@ProductIds)

	SELECT @AffUsername = ISNULL(@AffUsername, ''), @Username = ISNULL(@Username, '')

	DECLARE @LastDayOfToDate SMALLDATETIME = EOMONTH(@ToDate)

	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	-- Get Affiliate Info
	CREATE TABLE #AffInfo (MonthDate SMALLDATETIME, AffId INT, GroupId INT, AffUsername VARCHAR(50))
	CREATE CLUSTERED INDEX IX_AffInfo_AffId_MonthDate ON #AffInfo (MonthDate, AffId)

	;WITH CTE_AffInfo AS(
		SELECT AffId, Username
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE Username LIKE '%' + @AffUsername + '%'
			AND Status NOT IN ('Pending', 'Disapproved')
	)
	INSERT INTO #AffInfo (MonthDate, AffId, GroupId, AffUsername)
		SELECT c.MonthDate, c.AffId, c.GroupId, a.Username AS AffUsername
		FROM dbo.AffGroupHistory c WITH(NOLOCK)
			INNER JOIN CTE_AffInfo a WITH(NOLOCK) ON a.AffId = c.AffId
		WHERE c.MonthDate BETWEEN @FromDate AND @LastDayOfToDate

	-- Get Product List
	DECLARE @Products TABLE (ProductId INT)
	INSERT INTO @Products (ProductId)
	SELECT ProductId FROM dbo.Products WITH (NOLOCK) WHERE ProductId IN (SELECT val FROM dbo.Aff_f_StringSplit(@ProductIds, ','))
	OPTION(MAXRECURSION 0)

	CREATE TABLE #ProductSetting (GroupId INT, ProductId INT, MonthDate SMALLDATETIME, IsStraightSetting BIT)
	CREATE CLUSTERED INDEX IX_ProductSetting_AffId_MonthDate ON #ProductSetting (MonthDate, GroupId, ProductId)

	;WITH CTE_Group AS(
		SELECT DISTINCT a.GroupId
		FROM #AffInfo a
	)
	INSERT INTO #ProductSetting (MonthDate, GroupId, ProductId, IsStraightSetting)
	SELECT DISTINCT dsh.MonthDate,dsh.GroupId, dsh.ProductId, 0
	FROM dbo.DeductionSettingHistory dsh  
	WHERE EXISTS (SELECT 1 FROM CTE_Group i WHERE dsh.GroupId = i.GroupId)
		AND dsh.MonthDate BETWEEN @FromDate AND @LastDayOfToDate
		AND ',' + @ProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(15), dsh.ProductId) + ',%'

	-- Get player TO/WL data
	CREATE TABLE #Result (AffId INT, AffUsername VARCHAR(50), CustId INT, UserName VARCHAR(50), RegisteredDate DATETIME, FirstDepositDate DATETIME
		,ProductId INT, Turnover MONEY, GGR MONEY)

	;WITH CTE_RawDataTicket AS(
		SELECT EOMONTH(r.WinlostDate) AS MonthDate, r.AffId, r.CustId, r.Currency, r.ProductId
			,SUM(r.Turnover) AS Turnover
			,SUM(ISNULL(r.Revenue, 0)) AS Revenue
			,SUM(-(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0)) AS GGR
		FROM dbo.rptMemberDaily r WITH (NOLOCK)
		WHERE r.WinlostDate BETWEEN @FromDate AND @ToDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
				WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate 
			)
		GROUP BY EOMONTH(r.WinlostDate), r.AffId, r.CustId, r.Currency, r.ProductId
	),
		CTE_DataTicket AS(
		SELECT cd.MonthDate, cd.AffId, ai.AffUsername,cd.CustId, cd.Currency, cd.ProductId
			,ISNULL(cd.Turnover,0) AS Turnover
			,ISNULL(cd.GGR,0) AS GGR
		FROM CTE_RawDataTicket cd 
			INNER JOIN #AffInfo ai WITH (NOLOCK)ON ai.AffId = cd.AffId AND cd.MonthDate = ai.MonthDate
			INNER JOIN #ProductSetting d WITH(NOLOCK) ON cd.MonthDate = d.MonthDate AND ai.GroupId = d.GroupId AND d.ProductId = cd.ProductId
		
	)
	INSERT INTO #Result (AffId, AffUsername, CustId, ProductId, Turnover, GGR)
	SELECT d.AffId, d.AffUsername, d.CustId, ISNULL(p.GroupProductId, d.ProductId) AS ProductId, SUM(d.Turnover * e.Rate), SUM(d.GGR * e.Rate)
	FROM CTE_DataTicket d
		LEFT JOIN [dbo].[Aff_f_GroupProduct]() p ON p.ProductId = d.ProductId
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON d.Currency = t.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(d.MonthDate, ISNULL(t.ExchangeId, d.Currency), @BaseExchangeId) e
	GROUP BY d.AffId, d.AffUsername, d.CustId, ISNULL(p.GroupProductId, d.ProductId)

	SELECT @NRows = COUNT(DISTINCT CustId) FROM #Result
	IF @NRows = 0
		RETURN

	-- Total row
	CREATE TABLE #Total (ProductId INT, Turnover MONEY, GGR MONEY)
	INSERT INTO #Total (ProductId, Turnover, GGR)
	SELECT r.ProductId, SUM(Turnover), SUM(GGR)
	FROM #Result r
	GROUP BY r.ProductId

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
		+ '[' + CONVERT(VARCHAR(20), p.ProductId) + '_Turnover]'
		+ ', [' + CONVERT(VARCHAR(20), p.ProductId) + '_GGR]'
	FROM @Products p
		LEFT JOIN [dbo].[Aff_f_GroupProduct]() t ON p.ProductId = t.ProductId
													AND t.ProductId <> t.GroupProductId
	WHERE t.ProductId IS NULL

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
	DROP TABLE #Total
END
GO