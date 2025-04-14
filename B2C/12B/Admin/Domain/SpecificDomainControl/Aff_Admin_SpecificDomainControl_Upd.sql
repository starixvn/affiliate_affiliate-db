/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_SpecificDomainControl_Upd]
	@SpecificDomainControlID INT
	,@AffUserName NVARCHAR(60)
	,@AffDomain NVARCHAR(200) = ''
	,@AffDomainIsSSL BIT
	,@RedirectDomain NVARCHAR(200) = ''
	,@RedirectDomainIsSSL BIT
	,@Status BIT
	,@UserId INT
	,@IP VARCHAR(50) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20250402@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Domain - Specific Domain Control - Update

	Revisions:
		- 20250402@Lewis: Initialize SP [RedmineID: #221035]
*/

BEGIN
	SET NOCOUNT ON
	
	-- =================
	-- Check permission
	-- =================
	EXEC [dbo].[Aff_Con_CheckPermission]
		@CustId		= @UserId
		,@funcname	= '[Domain]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- =================
	-- Validate Param
	-- =================
	DECLARE @AffId INT 
	SELECT @AffId = AffId FROM AffInfo WHERE Username = @AffUserName

	IF EXISTS (SELECT 1 FROM SpecificDomainControl WITH (NOLOCK) WHERE Id <> @SpecificDomainControlID AND AffId = @AffId AND AffDomainName = @AffDomain AND LicenseeDomainName <> @RedirectDomain)
	BEGIN
		SELECT @ErrCode = 100
			  ,@ErrMsg = 'This Affiliate and AffDomain is redirected another domain! Please check again'
		RETURN
	END

	IF @AffDomain = ''
	BEGIN
		SELECT @ErrCode = 102
			  ,@ErrMsg ='AffDomain is required!'

		RETURN
	END

	IF @RedirectDomain = ''
	BEGIN
		SELECT @ErrCode = 103
			  ,@ErrMsg ='RedirectDomain is required!'

		RETURN
	END

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	
	SELECT  @OldData = 'AffId=' + CONVERT(VARCHAR(10), AffId)
					+ ',AffDomainName=' + CONVERT(VARCHAR(200), AffDomainName)
					+ ',AffDomainIsSSL=' + CONVERT(VARCHAR(10), AffDomainIsSSL)
					+ ',LicenseeDomainName=' + CONVERT(VARCHAR(200), LicenseeDomainName)
					+ ',LicenseeDomainIsSSL=' + CONVERT(VARCHAR(10), LicenseeDomainIsSSL)
					+ ',Status=' + CONVERT(VARCHAR(10), Status)
			,@NewData = 'AffId=' + CONVERT(VARCHAR(10), AffId)
					+ ',AffDomainName=' + CONVERT(VARCHAR(200), @AffDomain)
					+ ',AffDomainIsSSL=' + CONVERT(VARCHAR(10), @AffDomainIsSSL)
					+ ',LicenseeDomainName=' + CONVERT(VARCHAR(200), @RedirectDomain)
					+ ',LicenseeDomainIsSSL=' + CONVERT(VARCHAR(10), @RedirectDomainIsSSL)
					+ ',Status=' + CONVERT(VARCHAR(10), @Status)
	FROM dbo.SpecificDomainControl s WITH (NOLOCK) 
	WHERE Id = @SpecificDomainControlID AND AffId = @AffId

	IF ISNULL(@OldData, '') = ISNULL(@NewData, '') --duplicate by itself
	BEGIN
		RETURN -- no change
	END
	ELSE  --duplicate by another
	BEGIN 
		IF EXISTS (
					SELECT 1 
					FROM SpecificDomainControl WITH (NOLOCK)
					WHERE Id <> @SpecificDomainControlID
					AND AffId = @AffId 
					AND AffDomainName = @AffDomain 
					AND LicenseeDomainName = @RedirectDomain 
					--AND Status = @Status 
					--AND AffDomainIsSSL = @AffDomainIsSSL
					--AND LicenseeDomainIsSSL = @RedirectDomainIsSSL
				)
		BEGIN
			SELECT @ErrCode = 101
				  ,@ErrMsg = 'This specific domain setting already exists!'
			RETURN
		END
	END
	
	-- =================
	-- Update SpecificDomainControl
	-- =================
	BEGIN TRY
		UPDATE dbo.SpecificDomainControl WITH (ROWLOCK)
		SET AffDomainName = @AffDomain
			,AffDomainIsSSL = @AffDomainIsSSL
			,LicenseeDomainName	= @RedirectDomain
			,LicenseeDomainIsSSL = @RedirectDomainIsSSL
			,Status	= @Status
			,UpdatedBy = @UserId
			,UpdatedDate = GETDATE()
		WHERE Id = @SpecificDomainControlID AND AffId = @AffId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = N'Error occurs. Update unsuccessfully.'
		RETURN
	END CATCH

	-- =================
	-- Write log
	-- =================
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