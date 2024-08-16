/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateDomain_Ins]
	@UserId					INT
	,@DomainName			NVARCHAR(50)
	,@IsSSL					BIT = 0
	,@IP					VARCHAR(50) = ''
	,@BlockTargetCountry	VARCHAR(100)
	,@ErrCode				INT = 0 OUTPUT
	,@ErrMsg				NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Affiliate Domain - Insert

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20221101@Eddie: Support Block Market for Affiliate Domain [RedmineId : #179537]
		- 20231101@Eddie: Change BlockMarket to BlockTargetCountry [RedmineID: #181590]
		- 20240820@Eddie: Change metadata "bodbAdminNet" [RedmineID: #209409]
	Param's Explanation:
		- @BlockMarket = 'en-GB,en-US,es-ES,hi-IN,id-ID,ja-JP,km-KH,ko-KR,th-TH,vi-VN,zh-CN,zh-TW' >>> Removed
		- @BlockTargetCountry = 'MY,BD,IN,ID,JP,KH,KR,TH,VN,CN'
*/

BEGIN
	SET NOCOUNT ON

	SET @DomainName  		= RTRIM(LTRIM(ISNULL(@DomainName, '')))
	SET @IsSSL 		 		= ISNULL(@IsSSL, 0)
	SET @BlockTargetCountry = ISNULL(@BlockTargetCountry, '')

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
			,BlockTargetCountry
		)
		VALUES
		(
			@DomainName
			,GETDATE()
			,GETDATE()
			,@UserId
			,@IsSSL
			,@BlockTargetCountry
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

	SELECT @NewData = CONVERT(NVARCHAR(MAX), 
					 (	
						SELECT @DomainId 			AS '@DomainId'
							 , @DomainName 			AS '@DomainName'
							 , @IsSSL 				AS '@IsSSL'
							 , @BlockTargetCountry 	AS '@BlockTargetCountry' 
						FOR XML PATH('row'), ROOT('root')
					  ))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
END
GO