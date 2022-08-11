/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_HotNewsSel]
	@fromdate	DATETIME = NULL
	,@todate	DATETIME = NULL
	,@Important BIT = NULL
	,@language	VARCHAR(11) = NULL
	,@PageSize	INT = 50
	,@PageIndex INT = 1
	,@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20090317@DungTong
	DB: DBAFF12BET-Affiliate_12BET
	Task: Search message hot news and paging

	Revisions:
		- 20090819@DungTong : Add new Spanish language
		- 20090920@DungTong : Add new Vietnamese and Indonesia Language
		- 20130218@LongLuu : Add Korean Language
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20220811@Malcolm: Add Cambodian Language [RedminID: #176429]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @NRows = COUNT(1)
	FROM dbo.News WITH (NOLOCK)
	WHERE Important = ISNULL(@Important, Important)
		AND 1 = CASE
					WHEN @fromdate IS NULL OR @todate IS NULL THEN 1
					WHEN PostedDate BETWEEN @fromdate AND @todate THEN 1
					ELSE 0 END

	IF @NRows = 0
		RETURN

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowEnd = @PageSize * @PageIndex
	SELECT  @RowStart = @RowEnd - @PageSize + 1

	IF @language IS NULL -- all column
		SELECT
			message_en,message_cn,message_tw,message_es,message_th,message_vi,message_id,message_kr,message_kh
			,creator,posteddate,msgid,important,creatorname,updatename,updateddate
		FROM (
			SELECT
				message_en,message_cn,message_tw,message_es,message_th,message_vi,message_id,message_kr,message_kh
				,n.creator,posteddate,msgid,important,C.username AS creatorname,u.username AS updatename
				,updateddate,ROW_NUMBER() OVER(ORDER BY msgid DESC) AS RowId
			FROM News n WITH (NOLOCK)
				LEFT JOIN Users c WITH (NOLOCK) ON c.CustId = n.Creator
				LEFT JOIN Users u WITH (NOLOCK) ON u.CustId = n.UpdatedBy
			WHERE Important = ISNULL(@Important, Important)
				AND 1 = CASE
							WHEN @fromdate IS NULL OR @todate IS NULL THEN 1
							WHEN PostedDate BETWEEN @fromdate AND @todate THEN 1
							ELSE 0 END
		) n
		WHERE RowId BETWEEN @RowStart AND @RowEnd
	ELSE -- specific language
		SELECT
			[message],posteddate,msgid,important
		FROM (
			SELECT
				CASE @language
					WHEN 'en_US' THEN message_en	
					WHEN 'zh-TW' THEN ISNULL(message_tw,message_en)
					WHEN 'zh-CN' THEN ISNULL(message_cn,message_en)
					WHEN 'es-ES' THEN ISNULL(message_es,message_en)
					WHEN 'th-TH' THEN ISNULL(message_th,message_en)
					WHEN 'vi-VN' THEN ISNULL(message_vi,message_en)
					WHEN 'id-ID' THEN ISNULL(message_id,message_en)
					WHEN 'ko-KR' THEN ISNULL(message_kr,message_en)
					WHEN 'km-KH' THEN ISNULL(message_kh,message_en)
					ELSE message_en END AS [message]
				,posteddate,msgid,important
				,ROW_NUMBER() OVER(ORDER BY msgid DESC) AS RowId
			FROM News WITH (NOLOCK)
			WHERE Important = ISNULL(@Important, Important)
				AND 1 = CASE
							WHEN @fromdate IS NULL OR @todate IS NULL THEN 1
							WHEN PostedDate BETWEEN @fromdate AND @todate THEN 1
							ELSE 0 END
		) n
		WHERE RowId BETWEEN @RowStart AND @RowEnd
END
GO