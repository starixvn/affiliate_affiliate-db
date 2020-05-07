/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_HotNewsSel]
	@FromDate	DATETIME = NULL,
	@ToDate		DATETIME = NULL,
	@Important	BIT = NULL,
	@Language	VARCHAR(11) = NULL,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@TotalPages INT = 0 OUTPUT,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20200220@DungTong
	DB: DBAFFN88-Affiliate_N88
	Task: User Site - Hot News

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
		SELECT	@FromDate	= CONVERT(DATE, @FromDate)
				,@ToDate	= DATEADD(DAY, 1, CONVERT(DATE, @ToDate))

	SELECT @NRows = COUNT(1)
	FROM dbo.News WITH (NOLOCK)
	WHERE
		(
			@Important IS NULL 
			OR Important = @Important
		)
		AND (
			@FromDate IS NULL OR @ToDate IS NULL
			OR (PostedDate >= @FromDate AND PostedDate < @ToDate)
		)

	IF @NRows = 0
		RETURN

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @TotalPages = @NRows/@PageSize + CASE WHEN @NRows%@PageSize > 0 THEN 1 ELSE 0 END
			,@RowStart	= @PageSize * (@PageIndex - 1) + 1
			,@RowEnd	= @RowStart + @PageSize - 1

	IF @Language IS NULL -- get all
	BEGIN
		SELECT
			msgid, creator, posteddate, important, creatorname, updatename, updateddate
			,message_en, message_cn, message_tw, message_es, message_th, message_vi, message_id, message_kr, message_jp
		FROM (
			SELECT
				n.msgid, n.creator, n.posteddate, n.important, c.username AS creatorname, u.username AS updatename, n.updateddate
				,n.message_en, n.message_cn, n.message_tw, n.message_es, n.message_th, n.message_vi, n.message_id, n.message_kr, n.message_jp
				,ROW_NUMBER() OVER(ORDER BY n.posteddate DESC) AS RowNum
			FROM dbo.News n WITH (NOLOCK)
				LEFT JOIN dbo.Affiliate_User c WITH (NOLOCK) ON n.Creator = c.custid
				LEFT JOIN dbo.Affiliate_User u WITH (NOLOCK) ON n.UpdatedBy = u.custid
			WHERE
			(
				@Important IS NULL 
				OR Important = @Important
			)
			AND (
				@FromDate IS NULL OR @ToDate IS NULL
				OR (PostedDate >= @FromDate AND PostedDate < @ToDate)
			)
		) r
		WHERE r.RowNum BETWEEN @RowStart AND @RowEnd
	END
	ELSE
	BEGIN
		SELECT msgid, posteddate, important, [message]
		FROM (
			SELECT
				CASE @language
						WHEN 'en_US' THEN message_en	
						WHEN 'zh-TW' THEN ISNULL(message_tw, message_en)
						WHEN 'zh-CN' THEN ISNULL(message_cn, message_en)
						WHEN 'es-ES' THEN ISNULL(message_es, message_en)
						WHEN 'th-TH' THEN ISNULL(message_th, message_en)
						WHEN 'vi-VN' THEN ISNULL(message_vi, message_en)
						WHEN 'id-ID' THEN ISNULL(message_id, message_en)
						WHEN 'ko-KR' THEN ISNULL(message_kr, message_en)
						WHEN 'ja-JP' THEN ISNULL(message_jp, message_en)
						ELSE message_en END AS [message]
				,posteddate
				,msgid
				,important
				,ROW_NUMBER() OVER(ORDER BY posteddate DESC) AS RowNum
			FROM dbo.News WITH (NOLOCK)
			WHERE
				(
					@Important IS NULL 
					OR Important = @Important
				)
				AND (
					@FromDate IS NULL OR @ToDate IS NULL
					OR (PostedDate >= @FromDate AND PostedDate < @ToDate)
				)
			) r
		WHERE r.RowNum BETWEEN @RowStart AND @RowEnd
	END
END
GO