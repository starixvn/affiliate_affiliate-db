/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateDomain_Upd]
	@UserId				 INT
	,@DomainId			 INT
	,@DomainName		 NVARCHAR(50)
	,@IsSSL				 BIT = 0
	,@IP				 VARCHAR(50) = ''
	,@BlockTargetCountry VARCHAR(100)
	,@ErrCode			 INT = 0 OUTPUT
	,@ErrMsg			 NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Affiliate Domain - Update

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20221103@Eddie: Support Block Market [RedmineID: #179537]
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

	IF EXISTS (SELECT 1 FROM dbo.AffDomain WITH (NOLOCK) WHERE DomainId <> @DomainID AND DomainName = @DomainName AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This Affiliate domain has been existed!'
		RETURN
	END
	
	IF EXISTS (SELECT 1 FROM dbo.AffDomainControl WITH (NOLOCK) WHERE AffDomainId = @DomainId AND IsDeleted = 0 AND TargetCountryCode IN (SELECT value FROM STRING_SPLIT(@BlockTargetCountry, ',')))
	BEGIN
		SELECT @ErrCode = 105, @ErrMsg = 'Please reload. Update unsuccessfully.'
		RETURN
	END

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData = CONVERT(NVARCHAR(MAX), 
					   (
						  SELECT DomainId 	  		 AS '@DomainId'
								,DomainName   		 AS '@DomainName'
								,IsSSL 		  		 AS '@IsSSL'
								,BlockTargetCountry  AS '@BlockTargetCountry'
						  FROM dbo.AffDomain WITH (NOLOCK)
						  WHERE DomainId = @DomainId AND IsDeleted = 0
						  FOR XML PATH('row'), ROOT('root')
					   ))

	SELECT @NewData = CONVERT(NVARCHAR(MAX), 
					  (
						  SELECT @DomainId     		  AS '@DomainId'
								 ,@DomainName  		  AS '@DomainName'
								 ,@IsSSL 	   		  AS '@IsSSL' 
								 ,@BlockTargetCountry AS '@BlockTargetCountry'
						  FOR XML PATH('row'), ROOT('root')
					  ))

	IF ISNULL(@OldData, '') = ISNULL(@NewData, '')
		RETURN

	BEGIN TRY

		UPDATE dbo.AffDomain WITH (ROWLOCK)
		SET ModifyDate	 		= GETDATE()
			,DomainName  		= @DomainName
			,Creator	 		= @UserId
			,IsSSL		 		= @IsSSL
			,BlockTargetCountry = @BlockTargetCountry
		WHERE DomainId	 = @DomainId

		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @ErrCode = 103, @ErrMsg = 'This Affiliate domain does not exists!'
			RETURN
		END

	END TRY
	BEGIN CATCH
		SELECT @Errcode = 104, @ErrMsg = N'Error occurs. Update unsuccessfully.'
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