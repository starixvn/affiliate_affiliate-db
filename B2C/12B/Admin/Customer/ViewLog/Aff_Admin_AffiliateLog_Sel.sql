/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateLog_Sel]
	@AffID		INT,
	@LogType	INT = 0,
	@FromDate	DATETIME,
	@ToDate		DATETIME,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Affiliate - View Log

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @LogType = ISNULL(@LogType, 0), @NRows = 0

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1
			,@RowEnd = @RowStart + @PageSize - 1

	SELECT @NRows = COUNT(1)
	FROM dbo.UserLog_RunSP_Detail ul WITH (NOLOCK)
		INNER JOIN dbo.LogType lt WITH (NOLOCK) ON ul.LogTypeID = lt.TypeID
	WHERE LogDate >= @FromDate AND LogDate < DATEADD(DAY, 1, @ToDate)
		AND AffID = @AffID
		AND ul.IsWebCall = 0
		AND (@LogType = 0 OR ul.LogTypeID = @LogType)

	IF @NRows = 0
		RETURN

	SELECT RowNum,LogId,[Date],UpdatedName,[Action],[Description],[IP]
	FROM (
		SELECT
			ul.LogId			AS LogId
			,ul.LogDate			AS [Date]
			,au.Username		AS UpdatedName
			,lt.[Description]	AS [Action]
			,'Old Data: ' + ISNULL(ul.OldData, '') + CHAR(10) + CHAR(13)
				+ 'New Data: ' + ISNULL(ul.NewData, '') AS [Description]
			,ul.[IP]
			,ROW_NUMBER() OVER(ORDER BY ul.LogDate DESC, ul.LogId DESC) AS RowNum
		FROM dbo.UserLog_RunSP_Detail ul WITH (NOLOCK)
			INNER JOIN dbo.LogType lt WITH (NOLOCK) ON ul.LogTypeID = lt.TypeID
			LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON ul.UserId = au.custid
		WHERE ul.LogDate >= @FromDate AND ul.LogDate < DATEADD(DAY, 1, @ToDate)
			AND ul.AffID = @AffID
			AND ul.IsWebCall = 0
			AND (@LogType = 0 OR ul.LogTypeID = @LogType)
	) AS r
	WHERE RowNum BETWEEN @RowStart AND @RowEnd
END
GO