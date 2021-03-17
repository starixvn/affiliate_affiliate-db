/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Message_Ins]
	@UserId			INT
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
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin - Message - Insert

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MessageId INT

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[HotNews]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	BEGIN TRY
		INSERT INTO dbo.News
		(
			Message_En,Message_Cn,Message_Tw,Message_Es,Message_Th,Message_Id,Message_Vi,Message_Kr,Message_Jp
			,Creator,PostedDate,Important
		)
		VALUES
		(
			@MsgEn,@MsgCn,@MsgTw,@MsgEs,@MsgTh,@MsgId,@MsgVi,@MsgKr,@MsgJp
			,@UserId,GETDATE(),@IsImportant
		)

		SELECT @MessageId = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = 'Error occurs. Insert unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
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
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= 'en-US'
END
GO