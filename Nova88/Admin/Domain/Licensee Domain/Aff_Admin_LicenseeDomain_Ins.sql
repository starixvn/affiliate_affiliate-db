/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LicenseeDomain_Ins]
	@UserId			INT
	,@DomainName	NVARCHAR(50)
	,@IsSSL			BIT = 0
	,@IP			NVARCHAR(15) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Admin - Domain - 12BET Domain - Insert

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	SET @DomainName = RTRIM(LTRIM(ISNULL(@DomainName, '')))
	SET @IsSSL = ISNULL(@IsSSL, 0)

	IF @DomainName = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid 12Bet domain name!'
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
	
	IF EXISTS (SELECT 1 FROM dbo.LicenseeDomain WITH (NOLOCK) WHERE DomainName = @DomainName AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This 12Bet domain has been existed!'
		RETURN
	END

	DECLARE @DomainId INT

	BEGIN TRY
		INSERT INTO dbo.LicenseeDomain
		(
			DomainName
			,CreateDate
			,ModifyDate
			,Creator
			,W3Prefix
			,IsSSL
		)
		VALUES
		(
			@DomainName
			,GETDATE()
			,GETDATE()
			,@UserId
			,@W3Prefix
			,@IsSSL
		)

		SELECT @DomainId = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = N'Error occurs. Insert unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200), @NewData NVARCHAR(MAX)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @NewData = 'DomainId=' + CONVERT(VARCHAR(10), @DomainId)
					+ ',DomainName=' + @DomainName
					+ ',IsSSL=' + CONVERT(VARCHAR(1), @IsSSL)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
END
GO