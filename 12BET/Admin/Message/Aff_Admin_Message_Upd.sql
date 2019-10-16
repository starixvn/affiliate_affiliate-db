/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Message_Upd]
	@UserId			INT
	,@MessageId		INT
	,@MsgEN			NVARCHAR(4000)
	,@MsgCN			NVARCHAR(4000)
	,@MsgTW			NVARCHAR(4000)
	,@MsgES			NVARCHAR(4000)
	,@MsgTH			NVARCHAR(4000)
	,@MsgVI			NVARCHAR(4000)
	,@MsgID			NVARCHAR(4000)
	,@MsgKR			NVARCHAR(4000)
	,@MsgJP			NVARCHAR(4000)
	,@IsImportant	BIT
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Message - Update

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[HotNews]'
		,@System	= 'AFFILIATE'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Check banner exists
	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	SELECT  @OldData = 'MessageId=' + ISNULL(CONVERT(VARCHAR(5), MsgId), '')
					+ ',' + 'Message_En=' + ISNULL(Message_En, '')
					+ ',' + 'Message_Cn=' + ISNULL(Message_Cn, '')
					+ ',' + 'Message_Tw=' + ISNULL(Message_Tw, '')
					+ ',' + 'Message_Es=' + ISNULL(Message_Es, '')
					+ ',' + 'Message_Th=' + ISNULL(Message_Th, '')
					+ ',' + 'Message_Id=' + ISNULL(Message_Id, '')
					+ ',' + 'Message_Vi=' + ISNULL(Message_Vi, '')
					+ ',' + 'Message_Kr=' + ISNULL(Message_Kr, '')
					+ ',' + 'Message_Jp=' + ISNULL(Message_Jp, '')
					+ ',' + 'Important=' + ISNULL(CONVERT(VARCHAR(5), Important), '')
	FROM dbo.News WITH (NOLOCK)
	WHERE MsgId = @MessageId

	IF @OldData IS NULL
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Error occurs. Message does not exist.'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.News WITH (ROWLOCK)
		SET Message_En		= @MsgEn
			,Message_Cn		= @MsgCn
			,Message_Tw		= @MsgTw
			,Message_Es		= @MsgEs
			,Message_Th		= @MsgTh
			,Message_Id		= @MsgId
			,Message_Vi		= @MsgVi
			,Message_Kr		= @MsgKr
			,Message_Jp		= @MsgJp
			,Important		= @IsImportant
			,UpdatedBy		= @UserId
			,UpdatedDate	= GETDATE()
		WHERE MsgId = @MessageId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Update unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @NewData = 'MessageId=' + ISNULL(CONVERT(VARCHAR(5), @MessageId), '')
					+ ',' + 'Message_En=' + ISNULL(@MsgEn, '')
					+ ',' + 'Message_Cn=' + ISNULL(@MsgCn, '')
					+ ',' + 'Message_Tw=' + ISNULL(@MsgTw, '')
					+ ',' + 'Message_Es=' + ISNULL(@MsgEs, '')
					+ ',' + 'Message_Th=' + ISNULL(@MsgTh, '')
					+ ',' + 'Message_Id=' + ISNULL(@MsgId, '')
					+ ',' + 'Message_Vi=' + ISNULL(@MsgVi, '')
					+ ',' + 'Message_Kr=' + ISNULL(@MsgKr, '')
					+ ',' + 'Message_Jp=' + ISNULL(@MsgJp, '')
					+ ',' + 'Important=' + ISNULL(CONVERT(VARCHAR(5), @IsImportant), '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
		,@Language	= 'en-US'
END
GO