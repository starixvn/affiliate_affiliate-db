/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateLog_Sel]
	@AffID		INT,
	@LogType	INT = 0,
	@FromDate	DATETIME,
	@ToDate		DATETIME,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20190614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Affiliate - View Log

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @LogType = ISNULL(@LogType, 0), @NRows = 0

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1
			,@RowEnd = @RowStart + @PageSize - 1

	SELECT @NRows = SUM([RowCount])
	FROM (
		SELECT COUNT(1) AS [RowCount]
		FROM dbo.UserLog WITH (NOLOCK)
		WHERE LoggedDate >= @FromDate AND LoggedDate < DATEADD(DAY, 1, @ToDate)
			AND AffID = @AffID
			AND (@LogType = 0 OR TypeID = @LogType)

		UNION ALL
		SELECT COUNT(1) AS [RowCount]
		FROM dbo.UserLog_RunSP_Detail WITH (NOLOCK)
		WHERE LogDate >= @FromDate AND LogDate < DATEADD(DAY, 1, @ToDate)
			AND AffID = @AffID
			AND (@LogType = 0 OR LogTypeID = @LogType)
	) AS t

	IF @NRows = 0
		RETURN

	CREATE TABLE #Logs (LogId BIGINT, [Date] DATETIME, UpdatedName NVARCHAR(50), [Action] NVARCHAR(100), [Description] NVARCHAR(MAX), [IP] VARCHAR(40))

	INSERT INTO #Logs (LogId, [Date], UpdatedName, [Action], [Description], [IP])
	SELECT LogId,[Date],UpdatedName,[Action],[Description],[IP]
	FROM (
		SELECT
			ROW_NUMBER() OVER (ORDER BY ul.LoggedDate DESC, ul.RefNo DESC) AS RowNum
			,ul.RefNo			AS LogId
			,ul.LoggedDate		AS [Date]
			,au.Username		AS UpdatedName
			,lt.[Description]	AS [Action]
			,ul.Details			AS [Description]
			,ul.[IP]
		FROM dbo.UserLog ul WITH (NOLOCK)
			INNER JOIN dbo.LogType lt WITH (NOLOCK) ON ul.TypeID = lt.TypeID
			LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON ul.Creator = au.custid
		WHERE ul.LoggedDate >= @FromDate AND ul.LoggedDate < DATEADD(DAY, 1, @ToDate)
			AND ul.AffID = @AffID
			AND (@LogType = 0 OR ul.TypeID = @LogType)
	) AS l
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

	INSERT INTO #Logs (LogId, [Date], UpdatedName, [Action], [Description], [IP])
	SELECT LogId,[Date],UpdatedName,[Action],[Description],[IP]
	FROM (
		SELECT
			ROW_NUMBER() OVER (ORDER BY ul.LogDate DESC, ul.LogId DESC) AS RowNum
			,ul.LogId
			,ul.LogDate			AS [Date]
			,au.Username		AS UpdatedName
			,lt.[Description]	AS [Action]
			,ISNULL(ul.OldData, '') + ISNULL(ul.NewData, '') AS [Description]
			,ul.[IP]
		FROM dbo.UserLog_RunSP_Detail ul WITH (NOLOCK)
			INNER JOIN dbo.LogType lt WITH (NOLOCK) ON ul.LogTypeID = lt.TypeID
			LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON ul.UserId = au.custid
		WHERE ul.LogDate >= @FromDate AND ul.LogDate < DATEADD(DAY, 1, @ToDate)
			AND ul.AffID = @AffID
			AND (@LogType = 0 OR ul.LogTypeID = @LogType)
	) AS l
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

	SELECT RowNum,LogId,[Date],UpdatedName,[Action],[Description],[IP]
	FROM (
		SELECT
			ROW_NUMBER() OVER (ORDER BY ul.LogDate DESC, ul.LogId DESC) AS RowNum
			,LogId,[Date],UpdatedName,[Action],[Description],[IP]
		FROM #Logs
	) AS result
	WHERE RowNum BETWEEN @RowStart AND @RowEnd
	ORDER BY RowNum

	DROP TABLE #Logs
END
GO