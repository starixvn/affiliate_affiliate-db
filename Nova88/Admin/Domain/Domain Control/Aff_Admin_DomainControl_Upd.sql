/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_DomainControl_Upd]
	@UserId				INT
	,@DomainControlId	INT
	,@AffDomainId		INT
	,@LicenseeDomainId	INT = 0
	,@MarketId			NVARCHAR(10)
	,@Status			BIT
	,@IP				NVARCHAR(40) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20191010@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Admin - Domain - Domain Control - Update

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC [dbo].[Aff_Con_CheckPermission]
		@CustId		= @UserId
		,@funcname	= '[Domain]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData = 'AffDomainId=' + CONVERT(VARCHAR(10), AffDomainId)
						+ ',LicenseeDomainId=' + CONVERT(VARCHAR(10), LicenseeDomainId)
						+ ',MarketId=' + ISNULL(MarketId, '')
						+ ',Status=' + CONVERT(VARCHAR(2), Status)
			,@NewData = 'AffDomainId=' + CONVERT(VARCHAR(10), @AffDomainId)
						+ ',LicenseeDomainId=' + CONVERT(VARCHAR(10), @LicenseeDomainId)
						+ ',MarketId=' + ISNULL(@MarketId, '')
						+ ',Status=' + CONVERT(VARCHAR(2), @Status)
	FROM dbo.DomainControl WITH (NOLOCK) WHERE Id = @DomainControlId AND IsDeleted = 0

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This domain setting does not exists!'
		RETURN
	END

	IF ISNULL(@OldData, '') = ISNULL(@NewData, '')
		RETURN -- no change

	IF EXISTS (
		SELECT 1 FROM dbo.DomainControl WITH (NOLOCK)
		WHERE Id <> @DomainControlId AND AffDomainId = @AffDomainId AND LicenseeDomainId = @LicenseeDomainId AND MarketId = @MarketId AND IsDeleted = 0
	)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This domain setting has been existed!'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.DomainControl WITH (ROWLOCK)
		SET AffDomainId			= @AffDomainId
			,LicenseeDomainId	= @LicenseeDomainId
			,MarketId			= @MarketId
			,ModifyDate			= GETDATE()
			,Status				= @Status
		WHERE Id = @DomainControlId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = N'Error occurs. Update unsuccessfully.'
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
		,@NewData	= @NewData
		,@IP		= @IP
END
GO