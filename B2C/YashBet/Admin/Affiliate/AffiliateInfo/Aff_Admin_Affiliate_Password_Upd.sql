/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Affiliate_Password_Upd]
	@UserId			INT,
	@AffId			INT,
	@Password		VARCHAR(40),
	@IP				NVARCHAR(15) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task:
		Admin Site - Affiliate - Affiliate Info - Update password on an affiliate
		Admin Site - Customer - Left menu - Update password on an affiliate

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
		- 20240829@Sally: Add new permission for approve new affiliate [RedmineID: #209858]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'

	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	='[Affiliate]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT
    
	IF @ErrCode <> 0
	BEGIN
		-- Check permission Edit Affiliate Status
		EXEC dbo.Aff_Con_CheckPermission
			@CustId		= @UserID,
			@FuncName	= '[EditAffiliateDetails]',
			@ErrCode	= @ErrCode OUTPUT,
			@ErrMsg		= @ErrMsg OUTPUT

		IF (@ErrCode <> 0)
		RETURN

	END

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId)
	BEGIN
		-- Invalid Affiliate!
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(304, @Language)
		RETURN
	END

	DECLARE @OldPassword VARCHAR(40)
	SELECT  @OldPassword = Password FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId

	IF @OldPassword = @Password
		RETURN
	
	BEGIN TRY
		UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
		SET Password = @Password
		WHERE AffId = @AffId
	END TRY
	BEGIN CATCH
		-- Error! Change password unsuccessfully!
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(308, @Language)
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData = 'Password=' + @OldPassword,
			@NewData = 'Password=' + @Password
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO