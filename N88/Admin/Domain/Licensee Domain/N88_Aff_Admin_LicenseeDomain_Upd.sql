/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LicenseeDomain_Upd]
	@UserId			INT
	,@DomainId		INT
	,@DomainName	NVARCHAR(50)
	,@IsSSL			BIT = 0
	,@IP			NVARCHAR(15) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Admin - Domain - 12BET Domain - Update

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	SET @DomainName = RTRIM(LTRIM(ISNULL(@DomainName, '')))
	SET @IsSSL = ISNULL(@IsSSL, 0)

	IF @DomainName = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Licensee domain name!'
		RETURN
	END

	-- Check permission
	EXEC [dbo].[Aff_Con_CheckPermission]
		@CustId		= @UserId
		,@funcname	= '[Domain]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- get W3Prefix
	DECLARE @W3Prefix VARCHAR(50) = ''
	
	IF @DomainName LIKE 'www.%' OR @DomainName LIKE 'www_.%'
		SELECT @W3Prefix = SUBSTRING(@domainName, 0, CHARINDEX('.', @domainName))
	
	IF EXISTS (SELECT 1 FROM dbo.LicenseeDomain WITH (NOLOCK) WHERE DomainId <> @DomainId AND DomainName = @DomainName AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This Licensee domain has been existed!'
		RETURN
	END

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData = 'DomainId=' + CONVERT(VARCHAR(10), DomainId)
						+ ',DomainName=' + DomainName
						+ ',IsSSL=' + CONVERT(VARCHAR(1), IsSSL)
			,@NewData = 'DomainId=' + CONVERT(VARCHAR(10), @DomainId)
						+ ',DomainName=' + @DomainName
						+ ',IsSSL=' + CONVERT(VARCHAR(1), @IsSSL)
	FROM dbo.LicenseeDomain WITH (NOLOCK) WHERE DomainId = @DomainId AND IsDeleted = 0

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This Licensee domain does not exists!'
		RETURN
	END
	
	BEGIN TRY
		UPDATE dbo.LicenseeDomain WITH (ROWLOCK)
		SET ModifyDate	= GETDATE()
			,DomainName	= @DomainName
			,Creator	= @UserId
			,W3Prefix	= @W3Prefix
			,IsSSL		= @IsSSL
		WHERE DomainID  = @DomainID
	END TRY
	BEGIN CATCH
		SELECT @Errcode = 103, @ErrMsg = N'Error occurs. Update unsuccessfully.'
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