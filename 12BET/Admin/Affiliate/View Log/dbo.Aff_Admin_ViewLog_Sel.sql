/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_ViewLog_Sel]
	@UserId 		INT
	,@AffName		NVARCHAR(200) = ''
	,@LogActionIds	NVARCHAR(2000) = ''
	,@FromDate		DATETIME
	,@ToDate		DATETIME
	,@PageSize 		INT = 20
	,@PageIndex 	INT = 1
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20210303@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Affiliate - View log

	Revisions:
		- 20210303@Malcolm: Initialize SP [RedmineID: #147902]
	Param's Explanation

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @RowStart INT, @RowEnd INT

	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageIndex * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #Log (Id INT, AffId INT, NumberOfAction INT, LogDate DATETIME, [Type] INT, LogId INT, OrderId INT)
	
	DECLARE @Result TABLE (AffId INT, NumberOfAction INT, LogDate DATETIME, ActionId INT, UserId INT, [Type] INT, LogId INT)

	INSERT INTO #Log (AffId, NumberOfAction, LogDate, LogId, [Type])
	SELECT d.AffId, COUNT(1) AS NumberOfAction, MAX(d.LogDate), MAX(d.LogId),1
	FROM UserLog_RunSP_Detail d WITH(NOLOCK)
	WHERE d.LogDate BETWEEN @FromDate AND @ToDate
		AND (d.LogActionId IN (SELECT val FROM dbo.strSplit(@LogActionIds, ',')) OR (@LogActionIds = '')) AND d.AffId <> 0
	GROUP BY d.AffId

	INSERT INTO #Log (AffId, NumberOfAction, LogDate, LogId, [Type])
	SELECT d.AffId, COUNT(1) AS NumberOfAction, MAX(d.LoggedDate), MAX(d.RefNo),2
	FROM UserLog d WITH(NOLOCK)
	WHERE d.LoggedDate BETWEEN @FromDate AND @ToDate
		AND (@LogActionIds = '') AND d.AffId <> 0
	GROUP BY d.AffId	

	CREATE INDEX IX_affId ON #Log(AffId)

	DELETE l
	FROM #Log l
	WHERE NOT EXISTS(
		SELECT 1 
		FROM dbo.AffDetail ai WITH(NOLOCK)		
			INNER JOIN dbo.UserMarket m WITH(NOLOCK) ON m.MarketId = ai.PreferredLanguage
		WHERE ai.AffID = l.AffId AND m.CustId = @UserId		
	) 

	UPDATE x
		SET x.Id = x.NewRowNum, x.OrderId = x.NewOrderId
	FROM
	(
		SELECT r.Id, r.OrderId
			,DENSE_RANK() OVER(ORDER BY af.username ASC) AS NewRowNum
			,ROW_NUMBER() OVER(PARTITION BY af.username ORDER BY r.LogDate DESC, r.LogID DESC) AS NewOrderId
		FROM #Log r
			INNER JOIN dbo.AffInfo af WITH(NOLOCK) ON af.AffID = r.AffId
		WHERE af.UserName LIKE '%' + @AffName + '%' OR @AffName = ''
	) x

	SELECT @NRows = MAX(Id) FROM #Log

	DELETE #Log WHERE Id < @RowStart OR Id > @RowEnd 

	;WITH CTE AS
	(
		SELECT l.AffId, SUM(NumberOfAction) AS NumberOfAction, MAX(l.LogDate) AS LogDate FROM #Log l GROUP BY l.AffId
	)
	INSERT INTO @Result (AffId, NumberOfAction, LogId, [Type], LogDate)
	SELECT e.AffId, e.NumberOfAction, l.LogId, l.[Type], e.LogDate
	FROM CTE e
		INNER JOIN #Log l ON e.AffId = l.AffId
	WHERE l.OrderId = 1

	UPDATE  r
		SET r.ActionId = ISNULL(m.LogActionId, u.TypeID)
			,r.UserId = ISNULL(m.UserId, u.Creator)
			,r.[Type] = ISNULL(m.[Type], u.[Type])
	FROM @Result r
	OUTER APPLY(
		SELECT d.LogActionId, d.UserId, 1 AS [Type]
		FROM UserLog_RunSP_Detail d WITH(NOLOCK)
		WHERE d.LogId = r.LogId AND r.[Type] = 1
	) AS m
	OUTER APPLY(
		SELECT ul.TypeID, ul.Creator, 2 AS [Type]
		FROM UserLog ul WITH(NOLOCK)
		WHERE ul.RefNo = r.LogId AND r.[Type] = 2
	) AS u

	SELECT r.AffId, ai.UserName AS AffName, r.NumberOfAction, ISNULL(la.Description, lt.Description) AS LastAction, u.UserName AS Actor, r.LogDate AS [DateTime]
	FROM @Result r
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ai.AffID = r.AffId
		LEFT JOIN dbo.Users u WITH(NOLOCK) ON  u.CustId = r.UserId
		LEFT JOIN dbo.LogAction la WITH(NOLOCK) ON la.ActionId = r.ActionId AND r.[Type] = 1
		LEFT JOIN dbo.LogType lt WITH(NOLOCK) ON lt.TypeID = r.ActionId AND r.[Type] = 2
	ORDER BY ai.UserName ASC

	DROP TABLE #Log
END
GO