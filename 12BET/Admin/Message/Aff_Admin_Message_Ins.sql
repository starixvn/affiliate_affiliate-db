/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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
	,@MsgKh			NVARCHAR(4000)
	,@MsgBn			NVARCHAR(4000)
	,@IsImportant	BIT
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Message - Insert

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20220811@Malcolm: Add Cambodian Language [RedminID: #176429]
		- 20230323@Eddie: Add Bangladesh Language [RedminID: #185446]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MessageId INT

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[HotNews]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	BEGIN TRY
		INSERT INTO dbo.News
		(
			Message_En,Message_Cn,Message_Tw,Message_Es,Message_Th,Message_Id,Message_Vi,Message_Kr,Message_Jp,Message_Kh,Message_Bn
			,Creator,PostedDate,Important
		)
		VALUES
		(
			@MsgEn,@MsgCn,@MsgTw,@MsgEs,@MsgTh,@MsgId,@MsgVi,@MsgKr,@MsgJp,@MsgKh,@MsgBn
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
	SELECT  @NewData = CONVERT(NVARCHAR(MAX),
					   (
							SELECT   @MessageId AS '@MessageId'
									 ,@MsgEn AS '@Message_En'
									 ,@MsgCn AS '@Message_Cn'
									 ,@MsgTw AS  '@Message_Tw'
									 ,@MsgEs AS  '@Message_Es'
									 ,@MsgTh AS  '@Message_Th'
									 ,@MsgId AS  '@Message_Id'
									 ,@MsgVi AS  '@Message_Vi'
									 ,@MsgKr AS  '@Message_Kr'
									 ,@MsgJp AS  '@Message_Jp'
									 ,@MsgKh AS  '@Message_Kh'
									 ,@MsgBn AS  '@Message_Bn'
									 ,@IsImportant AS '@IsImportant'
							FOR XML PATH('row'), ROOT('root')
						))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= 'en-US'
END
GO