/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_RecoverPassword]
	@AffId			INT,
	@ValidCode		NVARCHAR(30),
	@NewPassword	VARCHAR(40),
	@IP				VARCHAR(50),
	@Language		VARCHAR(10),
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Recover Password (Case forgot password)
	
	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	-- Check ValidCode
	IF NOT EXISTS (
		SELECT 1 FROM dbo.AffDetail WITH (NOLOCK)
		WHERE AffId = @AffId AND ValidCode = @ValidCode
			AND DATEDIFF(HOUR, CodeExpiry, CURRENT_TIMESTAMP) < 24
	)
	BEGIN
		-- The address that you have used to request a new password is not valid.
		SELECT @ErrCode = 1001, @ErrMsg = dbo.Aff_f_GetMessageById(204, @Language)

		RETURN
	END

	-- Reset Password
	DECLARE @tblOldPassword TABLE (Password VARCHAR(40))
	DECLARE @OldPassword VARCHAR(40)

	BEGIN TRY
		UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
		SET Password = @NewPassword
		OUTPUT DELETED.Password
		INTO @tblOldPassword (Password)
		WHERE AffId = @AffId
	END TRY
	BEGIN CATCH
		-- Recover password failed. Please try again!
		SELECT @ErrCode = 1002, @ErrMsg = dbo.Aff_f_GetMessageById(205, @Language)

		RETURN
	END CATCH

	SELECT @OldPassword = Password FROM @tblOldPassword

	-- Reset ValidCode
	BEGIN TRY
		UPDATE dbo.AffDetail WITH (ROWLOCK, UPDLOCK)
		SET ValidCode = '',
			CodeExpiry = NULL
		WHERE AffId = @AffId
	END TRY
	BEGIN CATCH
		-- Rollback manually
		UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
		SET Password = @OldPassword
		WHERE AffId = @AffId

		-- Recover password failed. Please try again!
		SELECT @ErrCode = 1002, @ErrMsg = dbo.Aff_f_GetMessageById(205, @Language)

		RETURN
	END CATCH

	-- Return information
	SELECT ai.AffId, ai.Username, ai.Firstname, ai.Email, ad.PreferredLanguage, ad.MailOption
	FROM AffInfo ai WITH (NOLOCK)
		INNER JOIN AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId 
	WHERE ai.AffId = @AffId

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData = 'Password=' + ISNULL(@OldPassword, ''),
			@NewData = 'Password=' + ISNULL(@NewPassword, '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO