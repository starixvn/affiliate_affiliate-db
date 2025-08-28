/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_DomainControl_Del]
	@UserId				INT
	,@DomainControlId	INT
	,@IP				VARCHAR(50) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Domain - Domain Control - Delete

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250417@Lewis: Add BlockTargetCountry [RedmineID: #223644]
		- 20250721@Eddie: Add Device and Deal Name [RedmineID: #233219]
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

	DECLARE @OldData NVARCHAR(MAX)

	SELECT  @OldData = 'AffDomainId=' + CONVERT(VARCHAR(10), AffDomainId)
					 + ',LicenseeDomainId=' + CONVERT(VARCHAR(10), LicenseeDomainId)
					 + ',MarketId=' + ISNULL(MarketId, '')
					 + ',TargetCountryCode=' + ISNULL(TargetCountryCode, '')
					 + ',Status=' + CONVERT(VARCHAR(2), Status)
					 + ',IsMobile=' + CONVERT(VARCHAR(2), IsMobile)
					 + ',IsExcluded=' + CONVERT(VARCHAR(2), IsExcluded)
					 + ',DealIds=' + ISNULL(DealIds, '')
	FROM dbo.DomainControl WITH (NOLOCK) WHERE Id = @DomainControlId AND IsDeleted = 0

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 111, @ErrMsg = 'This domain setting does not exists!'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.DomainControl WITH (ROWLOCK)
		SET IsDeleted = 1
		WHERE Id = @DomainControlId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 122, @ErrMsg = N'Error occurs. Delete unsuccessfully.'
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
END
GO