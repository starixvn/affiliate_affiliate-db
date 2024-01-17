/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliatePreferredLanguage_Upd]
	@AffID				INT
	,@UserID			INT
	,@PreferredLanguage	VARCHAR(5)
	,@IP				VARCHAR(20)
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Customer - Left menu - Update Affiliate's Preferred Language

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'

	SELECT @ErrCode = 0, @ErrMsg = ''

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	='[Affiliate]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	-- End check permission

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffID = @AffID)
	BEGIN
		-- Invalid Affiliate!
		SELECT @ErrCode = 1005, @ErrMsg = dbo.Aff_f_GetMessageById(304, @Language)
		RETURN
	END

	-- For Log
	DECLARE @OldData NVARCHAR(4000), @NewData NVARCHAR(4000), @SPName VARCHAR(50)
	SELECT  @OldData	= 'PreferredLanguage=' + ISNULL(PreferredLanguage, '')
			,@NewData	= 'PreferredLanguage=' + ISNULL(@PreferredLanguage, '')
			,@SPName	= OBJECT_NAME(@@PROCID)
	FROM dbo.AffDetail WITH (NOLOCK)
	WHERE AffID = @AffID

	IF @OldData = @NewData
		RETURN
	
	BEGIN TRY
		UPDATE dbo.AffDetail WITH (ROWLOCK)
		SET PreferredLanguage = @PreferredLanguage
		WHERE AffID = @AffID
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 1005, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
		RETURN
	END CATCH

	-- Write Log
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