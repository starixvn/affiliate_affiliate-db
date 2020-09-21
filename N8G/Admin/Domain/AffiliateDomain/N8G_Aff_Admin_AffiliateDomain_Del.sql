/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateDomain_Del]
	@UserId			INT
	,@DomainId		INT
	,@IP			NVARCHAR(40) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Admin - Domain - Affiliate Domain - Delete

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

	IF EXISTS (SELECT 1 FROM dbo.DomainControl WITH (NOLOCK) WHERE AffDomainId = @DomainId AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This Affiliate domain has been used!'
		RETURN
	END

	DECLARE @OldData NVARCHAR(MAX)
	SELECT  @OldData = 'DomainId=' + CONVERT(VARCHAR(10), DomainId)
						+ ',DomainName=' + DomainName
						+ ',IsSSL=' + CONVERT(VARCHAR(1), IsSSL)
	FROM dbo.AffDomain WITH (NOLOCK) WHERE DomainId = @DomainId AND IsDeleted = 0

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This Affiliate domain does not exists!'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.AffDomain WITH (ROWLOCK)
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