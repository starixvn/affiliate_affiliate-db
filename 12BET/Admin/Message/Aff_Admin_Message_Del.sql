/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Message_Del]
	@UserId			INT
	,@MessageIds	VARCHAR(MAX)
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Message - Delete

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20220811@Malcolm: Add Cambodian Language [RedminID: #176429]
		- 20230323@Eddie: Add Bangladesh Language [RedminID: #185446]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_CheckPermission
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
		FROM dbo.strSplit (@MessageIds, ',') s
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
	SELECT  @OldData = CONVERT(NVARCHAR(MAX), 
					   (
							SELECT m.MsgId AS '@MessageId',
								   m.Message_En AS '@Message_En',
								   m.Message_Cn AS '@Message_Cn',
								   m.Message_Tw AS '@Message_Tw',
								   m.Message_Es AS '@Message_Es',
								   m.Message_Th AS '@Message_Th',
								   m.Message_Id AS '@Message_Id',
								   m.Message_Vi AS '@Message_Vi',
								   m.Message_Kr AS '@Message_Kr',
								   m.Message_Jp	AS '@Message_Jp',
								   m.Message_Kh	AS '@Message_Kh',
								   m.Message_Bn	AS '@Message_Bn',
								   m.Important AS '@Important'
								   
							FROM dbo.News m WITH (NOLOCK)
								INNER JOIN @Messages tmp ON m.MsgId = tmp.MessageId
							FOR XML PATH('row'), ROOT('root')
					   ))

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