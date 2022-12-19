/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_12BETDomain_Ins]
	@UserId			INT
	,@DomainName	NVARCHAR(50)
	,@IsSSL			BIT = 0
	,@IP			NVARCHAR(15) = ''
	,@BlockMarket	VARCHAR(400)
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - 12BET Domain - Insert

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20221108@Eddie: Support Block Market for 12Bet Domains [RedmineId : #179537]
	Param's Explanation:
		- @BlockMarket = 'en-GB,en-US,es-ES,hi-IN,id-ID,ja-JP,km-KH,ko-KR,th-TH,vi-VN,zh-CN,zh-TW'
*/
BEGIN
	SET NOCOUNT ON

	SET @DomainName  = RTRIM(LTRIM(ISNULL(@DomainName, '')))
	SET @IsSSL 		 = ISNULL(@IsSSL, 0)
	SET @BlockMarket = ISNULL(@BlockMarket, '')

	IF @DomainName = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid 12Bet domain name!'
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

	-- get W3Prefix
	DECLARE @W3Prefix VARCHAR(50) = ''
	
	IF @DomainName LIKE 'www.%' OR @DomainName LIKE 'www_.%'
		SELECT @W3Prefix = SUBSTRING(@domainName, 0, CHARINDEX('.', @domainName))
	
	IF EXISTS (SELECT 1 FROM dbo.[12BetDomain] WITH (NOLOCK) WHERE DomainName = @DomainName AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This 12Bet domain has been existed!'
		RETURN
	END

	DECLARE @DomainId INT

	BEGIN TRY
		INSERT INTO dbo.[12BetDomain]
		(
			DomainName
			,CreateDate
			,ModifyDate
			,Creator
			,W3Prefix
			,IsSSL
			,BlockMarket
		)
		VALUES
		(
			@DomainName
			,GETDATE()
			,GETDATE()
			,@UserId
			,@W3Prefix
			,@IsSSL
			,@BlockMarket
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

	SELECT @NewData = CONVERT(NVARCHAR(MAX),(SELECT @DomainId AS '@DomainId', @DomainName AS '@DomainName', @IsSSL AS '@IsSSL', @BlockMarket AS '@BlockMarket' FOR XML PATH('row'), ROOT('root')))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
END
GO