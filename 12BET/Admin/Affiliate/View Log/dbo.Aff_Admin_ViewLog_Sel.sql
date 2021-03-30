/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_ViewLog_Sel]
	@AffName		NVARCHAR(200) = ''
	,@ActionIds		NVARCHAR(2000) = ''
	,@FromDate		DATETIME
	,@ToDate		DATETIME
	,@PageSize 		INT = 20
	,@PageIndex 	INT = 1
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

	DECLARE @Log TABLE (AffId INT, NumberOfAction INT, LogDate DATETIME, TypeId INT, LogId INT)
	
	DECLARE @Result TABLE (Id INT, AffId INT, NumberOfAction INT, LogDate DATETIME, ActionId INT, UserId INT, TypeId INT, LogId INT)

	INSERT INTO @Log (AffId, NumberOfAction, LogDate, LogId, TypeId)
	SELECT d.AffId, COUNT(1) AS NumberOfAction, MAX(d.LogDate), MAX(d.LogId),1
	FROM UserLog_RunSP_Detail d WITH(NOLOCK)
	WHERE d.LogDate BETWEEN @FromDate AND @ToDate
		AND (d.LogActionId IN (SELECT val FROM dbo.strSplit(@ActionIds, ',')) OR (@ActionIds = ''))
		AND d.AffId <> 0
	GROUP BY d.AffId

	INSERT INTO @Log (AffId, NumberOfAction, LogDate, LogId, TypeId)
	SELECT d.AffId, COUNT(1) AS NumberOfAction, MAX(d.LoggedDate), MAX(d.RefNo),2
	FROM UserLog d WITH(NOLOCK)
	WHERE d.LoggedDate BETWEEN @FromDate AND @ToDate
		AND (@ActionIds = '') AND d.AffId <> 0
	GROUP BY d.AffId

	;WITH CTE AS
	(
		SELECT l.AffId, SUM(NumberOfAction) AS NumberOfAction,MAX(l.LogDate) AS LogDate FROM @Log l GROUP BY l.AffId
	)
	INSERT INTO @Result (AffId, NumberOfAction, LogId, TypeId)
	SELECT e.AffId, e.NumberOfAction, lg.LogId, lg.TypeId
	FROM CTE e
	CROSS APPLY (SELECT TOP(1) l.LogId, l.TypeId FROM @Log l) AS lg

	UPDATE x
		SET x.Id = x.NewRowNum
	FROM
	(
		SELECT Id,
			ROW_NUMBER() OVER(ORDER BY af.Username ASC) AS NewRowNum
		FROM @Result r
			INNER JOIN dbo.AffInfo af WITH(NOLOCK) ON af.AffID = r.AffId
		WHERE af.UserName LIKE '%' + @AffName + '%' OR @AffName = ''
	) x

	DELETE @Result 
	WHERE Id < @RowStart OR Id > @RowEnd

	UPDATE  r
		SET r.ActionId = ISNULL(m.LogActionId, u.TypeID)
			,r.UserId = ISNULL(m.UserId, u.Creator)
			,r.TypeId = ISNULL(m._TypeId, u._TypeId)
	FROM @Result r
	OUTER APPLY
	(
		SELECT d.LogActionId, d.UserId, 1 AS _TypeId
		FROM UserLog_RunSP_Detail d WITH(NOLOCK)
		WHERE d.LogId = r.LogId AND r.TypeId = 1
	) AS m
	OUTER APPLY
	(
		SELECT ul.TypeID, ul.Creator, 2 AS _TypeId
		FROM UserLog ul WITH(NOLOCK)
		WHERE ul.RefNo = r.LogId AND r.TypeId = 2
	) AS u

	SELECT AI.UserName AS AffName, r.NumberOfAction, ISNULL(la.Description, lt.Description) AS LastAction, u.UserName AS Actor, r.LogDate AS [DateTime]
	FROM @Result r
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ai.AffID = r.AffId
		LEFT JOIN dbo.Users u WITH(NOLOCK) ON  u.CustId = r.UserId
		LEFT JOIN dbo.LogAction la WITH(NOLOCK) ON la.ActionId = r.ActionId AND r.TypeId = 1
		LEFT JOIN dbo.LogType lt WITH(NOLOCK) ON lt.TypeID = r.ActionId AND r.TypeId = 2
	
END
GO