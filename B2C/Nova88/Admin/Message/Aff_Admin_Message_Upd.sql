/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Message_Upd]
	@UserId			INT
	,@MessageId		INT
	,@MsgEN			NVARCHAR(4000)
	,@MsgCN			NVARCHAR(4000)
	,@MsgTH			NVARCHAR(4000)
	,@MsgVI			NVARCHAR(4000)
	,@MsgID			NVARCHAR(4000)
	,@MsgHi			NVARCHAR(4000)
	,@MsgMs			NVARCHAR(4000)
	,@MsgKh			NVARCHAR(4000)
    ,@MsgBn			NVARCHAR(4000)
	,@IsImportant	BIT
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin - Message - Update

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20220301@Malcolm: Add Hindi Language [RedmineId: #169142]
		- 20220401@Malcolm: Add Malay Language [RedmineId: #170789]
		- 20230801@Sally: Support 3 more Languages Cambodian, Bangladeshi and Vietnamese [RedmineId: #191310]

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

	-- Check banner exists
	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	SELECT  @OldData = 'MessageId=' + ISNULL(CONVERT(VARCHAR(5), MsgId), '')
					+ ',' + 'Message_En=' + ISNULL(Message_En, '')
					+ ',' + 'Message_Cn=' + ISNULL(Message_Cn, '')
					+ ',' + 'Message_Th=' + ISNULL(Message_Th, '')
					+ ',' + 'Message_Id=' + ISNULL(Message_Id, '')
					+ ',' + 'Message_Vi=' + ISNULL(Message_Vi, '')
					+ ',' + 'Message_Hi=' + ISNULL(Message_Hi, '')
					+ ',' + 'Message_Ms=' + ISNULL(Message_Ms, '')
					+ ',' + 'Message_Kh=' + ISNULL(Message_Kh, '')
					+ ',' + 'Message_Bn=' + ISNULL(Message_Bn, '')
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
			,Message_Th		= @MsgTh
			,Message_Id		= @MsgId
			,Message_Vi		= @MsgVi
			,Message_Hi     = @MsgHi
			,Message_Ms     = @MsgMs
			,Message_Kh		= @MsgKh
			,Message_Bn		= @MsgBn
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
					+ ',' + 'Message_Th=' + ISNULL(@MsgTh, '')
					+ ',' + 'Message_Id=' + ISNULL(@MsgId, '')
					+ ',' + 'Message_Vi=' + ISNULL(@MsgVi, '')
					+ ',' + 'Message_Hi=' + ISNULL(@MsgHi, '')
					+ ',' + 'Message_Ms=' + ISNULL(@MsgMs, '')
					+ ',' + 'Message_Kh=' + ISNULL(@MsgKh, '')
					+ ',' + 'Message_Bn=' + ISNULL(@MsgBn, '')
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