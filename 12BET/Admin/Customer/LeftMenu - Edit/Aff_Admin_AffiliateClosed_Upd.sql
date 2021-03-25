/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateClosed_Upd]
	@AffID		INT
	,@UserID	INT
	,@IsClosed	BIT
	,@IP		VARCHAR(20) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000)	= '' OUTPUT
AS

/*
	Created: 20160614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Customer - Left menu - Update Affiliate's Close

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210223@Percy: Change permission function [RedmineID: #149213]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'
	DECLARE @LastDayOfMonth DATETIME = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

	SELECT @ErrCode = 0, @ErrMsg = ''

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Affiliate]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffID = @AffID)
	BEGIN
		-- Invalid Affiliate!
		SELECT @ErrCode = 13, @ErrMsg = dbo.Aff_f_GetMessageById(304, @Language)
		RETURN
	END

	DECLARE @LoginCount INT, @Old_IsClosed BIT, @Refno BIGINT
	SELECT  @LoginCount = LoginCount FROM dbo.AffDetail WITH (NOLOCK) WHERE AffID = @AffID
	SELECT  @Old_IsClosed = IsClosed FROM dbo.AffInfo WITH (NOLOCK) WHERE AffID = @AffID

	IF @Old_IsClosed = @IsClosed AND @LoginCount > 5
		RETURN

	BEGIN TRY
		UPDATE dbo.AffInfo WITH (ROWLOCK)
		SET IsClosed = @IsClosed
		WHERE AffID = @AffID

		UPDATE dbo.AffGroupHistory WITH (ROWLOCK)
		SET IsClosed = @IsClosed
		WHERE AffID = @AffID AND MonthDate = @LastDayOfMonth
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 1005, @ErrMsg = dbo.Aff_f_GetMessageById(1006, @Language)
		RETURN
	END CATCH

	IF @IsClosed = 1
	BEGIN
		DECLARE @NoCommGroupID INT
		SELECT  @NoCommGroupID = GroupID FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupName = 'NoCommission'
		
		EXEC dbo.Aff_Admin_CommGroup_Assign
			@UserID		= @UserID
			,@AffID		= @AffID
			,@GroupID	= @NoCommGroupID
			,@IP		= @IP
			,@ErrCode	= @ErrCode
			,@ErrMsg	= @ErrMsg

		IF @ErrCode <> 0
			RETURN
	END
	
	IF @Old_IsClosed = 1 AND @IsClosed = 0 AND @LoginCount > 5
	BEGIN
		UPDATE dbo.AffDetail WITH (ROWLOCK)
		SET LoginCount = 0
		WHERE AffID = @AffID
	END

	-- Write Log
	DECLARE @OldData NVARCHAR(4000), @NewData NVARCHAR(4000), @SPName VARCHAR(50)

	SELECT  @OldData	= '<root><row IsClosed="'+ ISNULL(CONVERT(VARCHAR(5), @Old_IsClosed), '') +'"></row></root>'
			,@NewData	= '<root><row IsClosed="'+ ISNULL(CONVERT(VARCHAR(5), @IsClosed), '') +'"></row></root>'
			,@SPName	= OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffID,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO