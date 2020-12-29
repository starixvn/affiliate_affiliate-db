/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateDomain_Ins]
	@UserId			INT
	,@DomainName	NVARCHAR(50)
	,@IsSSL			BIT = 0
	,@IP			NVARCHAR(40) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Affiliate Domain - Insert

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	SET @DomainName = RTRIM(LTRIM(ISNULL(@DomainName, '')))
	SET @IsSSL = ISNULL(@IsSSL, 0)

	IF @DomainName = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Affiliate domain name!'
		RETURN
	END

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Domain]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Check exists Domain name
	IF EXISTS (SELECT 1 FROM dbo.AffDomain WITH (NOLOCK) WHERE DomainName = @DomainName AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This Affiliate domain has been existed!'
		RETURN
	END

	DECLARE @DomainId INT

	BEGIN TRY
		INSERT INTO dbo.AffDomain
		(
			DomainName
			,CreateDate
			,ModifyDate
			,Creator
			,IsSSL
		)
		VALUES
		(
			@DomainName
			,GETDATE()
			,GETDATE()
			,@UserId
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