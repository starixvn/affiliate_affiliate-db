/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_SpecificDomainControl_Del]
	@SpecificDomainControlID INT
	,@UserId INT
	,@IP VARCHAR(50) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20250402@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Domain - Specific Domain Control - Delete

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
	DECLARE @OldData NVARCHAR(MAX)

	SELECT  @OldData = 'AffId=' + CONVERT(VARCHAR(10), AffId)
					+ ',AffDomainName=' + CONVERT(VARCHAR(200), AffDomainName)
					+ ',AffDomainIsSSL=' + CONVERT(VARCHAR(10), AffDomainIsSSL)
					+ ',LicenseeDomainName=' + CONVERT(VARCHAR(200), LicenseeDomainName)
					+ ',LicenseeDomainIsSSL=' + CONVERT(VARCHAR(10), LicenseeDomainIsSSL)
					+ ',Status=' + CONVERT(VARCHAR(10), Status)
	FROM dbo.SpecificDomainControl s WITH (NOLOCK) 
	WHERE Id = @SpecificDomainControlID

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This specific domain setting is not existed!'
		RETURN
	END
	
	-- =================
	-- Delete SpecificDomainControl
	-- =================
	BEGIN TRY
		DELETE 
		FROM SpecificDomainControl WITH (ROWLOCK)
		WHERE Id = @SpecificDomainControlID
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = N'Error occurs. Delete unsuccessfully.'
		RETURN
	END CATCH

	-- =================
	-- Write log
	-- ================
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@IP		= @IP
END
GO