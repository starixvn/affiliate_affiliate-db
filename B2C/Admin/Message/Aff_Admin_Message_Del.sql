/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Message_Del]
	@UserId			INT
	,@MessageIds	VARCHAR(MAX)
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin - Message - Delete

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20220301@Malcolm: Add Hindi Language [RedmineId: #169142]
		- 20220401@Malcolm: Add Malay Language [RedmineId: #170789]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[HotNews]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Get banner info
	DECLARE @Messages TABLE (MessageId INT, IsValid BIT)

	BEGIN TRY
		INSERT INTO @Messages (MessageId, IsValid)
		SELECT s.val, CASE WHEN m.MsgId IS NULL THEN 0 ELSE 1 END
		FROM dbo.Aff_f_StringSplit (@MessageIds, ',') s
			LEFT JOIN dbo.News m WITH (NOLOCK) ON s.val = m.MsgId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = 'Sorry, your input banner id is invalid. Please recheck it again.'
		RETURN
	END CATCH

	IF NOT EXISTS (SELECT 1 FROM @Messages)
		OR EXISTS (SELECT 1 FROM @Messages WHERE IsValid = 0)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Sorry, your input banner id is invalid. Please recheck it again.'
		RETURN
	END

	DECLARE @OldData NVARCHAR(MAX)
	SELECT  @OldData = 'MessageId=' + ISNULL(CONVERT(VARCHAR(5), m.MsgId), '')
					+ ',' + 'Message_En=' + ISNULL(m.Message_En, '')
					+ ',' + 'Message_Cn=' + ISNULL(m.Message_Cn, '')
					+ ',' + 'Message_Th=' + ISNULL(m.Message_Th, '')
					+ ',' + 'Message_Id=' + ISNULL(m.Message_Id, '')
					+ ',' + 'Message_Vi=' + ISNULL(m.Message_Vi, '')
					+ ',' + 'Message_Hi=' + ISNULL(m.Message_Hi, '')
					+ ',' + 'Message_Ms=' + ISNULL(m.Message_Ms, '')
					+ ',' + 'Important=' + ISNULL(CONVERT(VARCHAR(5), m.Important), '')
	FROM dbo.News m WITH (NOLOCK)
		INNER JOIN @Messages tmp ON m.MsgId = tmp.MessageId

	BEGIN TRY
		DELETE m WITH (ROWLOCK, UPDLOCK)
		FROM dbo.News m
		WHERE EXISTS (SELECT 1 FROM @Messages tmp WHERE m.MsgId = tmp.MessageId)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Delete unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@IP		= @IP
		,@Language	= 'en-US'
END
GO