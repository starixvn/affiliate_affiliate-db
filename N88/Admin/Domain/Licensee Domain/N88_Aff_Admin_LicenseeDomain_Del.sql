/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LicenseeDomain_Del]
	@UserId			INT
	,@DomainId		INT
	,@IP			NVARCHAR(15) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Admin - Domain - 12BET Domain - Delete

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
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

	IF EXISTS (SELECT 1 FROM dbo.DomainControl WITH (NOLOCK) WHERE LicenseeDomainId = @DomainId AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This Licensee domain has been used!'
		RETURN
	END

	DECLARE @OldData NVARCHAR(MAX)
	SELECT  @OldData = 'DomainId=' + CONVERT(VARCHAR(10), DomainId)
						+ ',DomainName=' + DomainName
						+ ',IsSSL=' + CONVERT(VARCHAR(1), IsSSL)
	FROM dbo.LicenseeDomain WITH (NOLOCK) WHERE DomainId = @DomainId AND IsDeleted = 0

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This Licensee domain does not exists!'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.LicenseeDomain WITH (ROWLOCK)
		SET IsDeleted = 1
		WHERE DomainId = @DomainId
	END TRY
	BEGIN CATCH
		SELECT @Errcode = 103, @ErrMsg = N'Error occurs. Delete unsuccessfully.'
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