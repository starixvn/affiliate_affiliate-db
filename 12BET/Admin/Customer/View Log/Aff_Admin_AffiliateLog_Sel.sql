/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: get old data and new data [RedmineId : #149209]
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
		FROM dbo.UserLog ul WITH (NOLOCK)
			INNER JOIN dbo.LogType lt WITH (NOLOCK) ON ul.TypeID = lt.TypeID
		WHERE LoggedDate >= @FromDate AND LoggedDate < DATEADD(DAY, 1, @ToDate)
			AND AffID = @AffID
			AND (@LogType = 0 OR ul.TypeID = @LogType)

		UNION ALL
		SELECT COUNT(1) AS [RowCount]
		FROM dbo.UserLog_RunSP_Detail ul WITH (NOLOCK)
			INNER JOIN dbo.LogType lt WITH (NOLOCK) ON ul.LogTypeID = lt.TypeID
		WHERE LogDate >= @FromDate AND LogDate < DATEADD(DAY, 1, @ToDate)
			AND AffID = @AffID
			AND (@LogType = 0 OR ul.LogTypeID = @LogType)
	) AS t

	IF @NRows = 0
		RETURN

	SELECT RowNum,LogId,[Date],UpdatedName,[Action],[Description],[IP], OldData, NewData
	FROM (
		SELECT LogId,[Date],UpdatedName,[Action],[Description],[IP], OldData, NewData
				, ROW_NUMBER() OVER(ORDER BY [Date] DESC, LogId DESC) AS RowNum
		FROM (
			SELECT
				ul.RefNo			AS LogId
				,ul.LoggedDate		AS [Date]
				,u.UserName			AS UpdatedName
				,lt.[Description]	AS [Action]
				,ul.Details			AS [Description]
				,ul.[IP]
				,NULL AS OldData
				,NULL AS NewData
			FROM dbo.UserLog ul WITH (NOLOCK)
				INNER JOIN dbo.LogType lt WITH (NOLOCK) ON ul.TypeID = lt.TypeID
				LEFT JOIN dbo.Users u WITH (NOLOCK) ON ul.Creator = u.CustId
			WHERE ul.LoggedDate >= @FromDate AND ul.LoggedDate < DATEADD(DAY, 1, @ToDate)
				AND ul.AffID = @AffID
				AND (@LogType = 0 OR ul.TypeID = @LogType)

			UNION ALL
			SELECT
				ul.LogId			AS LogId
				,ul.LogDate			AS [Date]
				,u.UserName			AS UpdatedName
				,lt.[Description]	AS [Action]
				,NULL AS [Description]
				,ul.[IP]
				,ul.OldData AS OldData
				,ul.NewData AS NewData
			FROM dbo.UserLog_RunSP_Detail ul WITH (NOLOCK)
				INNER JOIN dbo.LogType lt WITH (NOLOCK) ON ul.LogTypeID = lt.TypeID
				LEFT JOIN dbo.Users u WITH (NOLOCK) ON ul.UserId = u.CustId
			WHERE ul.LogDate >= @FromDate AND ul.LogDate < DATEADD(DAY, 1, @ToDate)
				AND ul.AffID = @AffID
				AND (@LogType = 0 OR ul.LogTypeID = @LogType)
		) AS l
	) AS r
	WHERE RowNum BETWEEN @RowStart AND @RowEnd
END
GO