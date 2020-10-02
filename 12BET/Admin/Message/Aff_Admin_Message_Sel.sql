/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Message_Sel]
	@MessageId		INT = 0
	,@SearchById	TINYINT = 0
	,@FromDate		DATETIME = NULL
	,@ToDate		DATETIME = NULL
	,@IsGetAll		BIT = 0
	,@PageIndex		INT = 1
	,@PageSize		INT = 50
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Message - Select

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]

	Param Explanation:
		- @MessageId:
			0		: All messages
			-1		: Latest message
			Others	: Specific message
		- @SearchById
			0: All
			1: Normal
			2: Important
*/

BEGIN
	SET NOCOUNT ON

	IF @MessageId = -1 OR @MessageId <> 0
	BEGIN
		IF @MessageId = -1
			SELECT @MessageId = MAX(MsgId) FROM dbo.News m WITH (NOLOCK)
		
		SELECT
			m.MsgId AS MessageId
			,m.Message_En
			,m.Message_Cn
			,m.Message_Tw
			,m.Message_Es
			,m.Message_Th
			,m.Message_Id
			,m.Message_Vi
			,m.Message_Kr
			,m.Message_Jp
			,m.PostedDate
			,m.Important
			,m.UpdatedDate
			,ISNULL(c.UserName, '') AS CreatorName
			,ISNULL(u.UserName, '') AS UpdatedName
		FROM dbo.News m WITH (NOLOCK)
			LEFT JOIN dbo.Users c WITH (NOLOCK) ON m.Creator = c.custid
			LEFT JOIN dbo.Users u WITH (NOLOCK) ON m.UpdatedBy = u.custid
		WHERE m.MsgID = @MessageId
	END
	ELSE
	BEGIN
		DECLARE @RowStart INT, @RowEnd INT
		SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1
				,@RowEnd	= @RowStart + @PageSize - 1

		SELECT @NRows = COUNT(1)
		FROM dbo.News WITH (NOLOCK)
		WHERE
			(
				@SearchById = 0
				OR @SearchById = 1 AND Important = 0
				OR @SearchById = 2 AND Important = 1
			)
			AND
			(
				@IsGetAll = 1
				OR PostedDate >= @FromDate AND PostedDate < DATEADD(DAY, 1, @ToDate)
			)

		IF @NRows = 0
			RETURN

		SELECT
			MessageId, Message_En, Message_Cn, Message_Tw, Message_Es, Message_Th, Message_Id
			,Message_Vi, Message_Kr, Message_Jp, PostedDate, Important, UpdatedDate, CreatorName, UpdatedName
		FROM (
			SELECT
				m.MsgId AS MessageId
				,m.Message_En
				,m.Message_Cn
				,m.Message_Tw
				,m.Message_Es
				,m.Message_Th
				,m.Message_Id
				,m.Message_Vi
				,m.Message_Kr
				,m.Message_Jp
				,m.PostedDate
				,m.Important
				,m.UpdatedDate
				,ISNULL(c.UserName, '') AS CreatorName
				,ISNULL(u.UserName, '') AS UpdatedName
				,ROW_NUMBER() OVER (ORDER BY m.MsgId DESC) AS RowNum
			FROM dbo.News m WITH (NOLOCK)
				LEFT JOIN dbo.Users c WITH (NOLOCK) ON m.Creator = c.custid
				LEFT JOIN dbo.Users u WITH (NOLOCK) ON m.UpdatedBy = u.custid
			WHERE
				(
					@SearchById = 0
					OR @SearchById = 1 AND Important = 0
					OR @SearchById = 2 AND Important = 1
				)
				AND
				(
					@IsGetAll = 1
					OR PostedDate >= @FromDate AND PostedDate < DATEADD(DAY, 1, @ToDate)
				)
		) AS r
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END
END
GO