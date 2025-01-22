/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Message_Ins]
	@UserId			INT
	,@MsgEN			NVARCHAR(4000)
	,@MsgCN			NVARCHAR(4000)
	,@MsgTH			NVARCHAR(4000)
	,@MsgVI			NVARCHAR(4000)
	,@MsgID			NVARCHAR(4000)
	,@MsgHI			NVARCHAR(4000)
	,@MsgMS			NVARCHAR(4000)
	,@MsgKh			NVARCHAR(4000)
	,@MsgBn			NVARCHAR(4000)
	,@IsImportant	BIT
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Message - Insert

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

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
			Message_En, Message_Cn, Message_Th, Message_Id, Message_Vi, Message_Hi, Message_Ms, Message_Kh, Message_Bn ,Creator, PostedDate, Important
		)
		VALUES
		(
			@MsgEn, @MsgCn, @MsgTh, @MsgId, @MsgVi, @MsgHI, @MsgMs, @MsgKh, @MsgBn, @UserId, GETDATE(), @IsImportant
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
					+ ',' + 'Message_Th=' + ISNULL(@MsgTh, '')
					+ ',' + 'Message_Id=' + ISNULL(@MsgId, '')
					+ ',' + 'Message_Vi=' + ISNULL(@MsgVi, '')
					+ ',' + 'Message_Hi=' + ISNULL(@MsgHI, '')
					+ ',' + 'Message_Ms=' + ISNULL(@MsgMS, '')
					+ ',' + 'Message_Kh=' + ISNULL(@MsgKh, '')
					+ ',' + 'Message_Bn=' + ISNULL(@MsgBn, '')
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