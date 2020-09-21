/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateAffType_Upd]
	@UserID		INT
	,@AffID		INT
	,@AffType	TINYINT
	,@IP		NVARCHAR(15) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20160614@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Admin - Customer - Left menu - Update Affiliate's Type

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
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

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffID = @AffID)
	BEGIN
		-- Invalid Affiliate!
		SELECT @ErrCode = 13, @ErrMsg = dbo.Aff_f_GetMessageById(304, @Language)
		RETURN
	END

	-- For Log
	DECLARE @OldData NVARCHAR(4000), @NewData NVARCHAR(4000), @SPName VARCHAR(50)
	SELECT  @OldData	= 'AffType=' + ISNULL(CONVERT(VARCHAR(5), AffType), '')
			,@NewData	= 'AffType=' + ISNULL(CONVERT(VARCHAR(5), @AffType), '')
			,@SPName	= OBJECT_NAME(@@PROCID)
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE AffID = @AffID

	IF @OldData = @NewData
		RETURN

	BEGIN TRY
		UPDATE dbo.AffInfo WITH (ROWLOCK)
		SET AffType = @AffType
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