/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_DomainControl_Ins]
	@UserId				INT
	,@TargetCountryCode	VARCHAR(2)
	,@AffDomainId		INT
	,@12BetDomainId		INT
	,@Status			BIT
	,@IP				VARCHAR(50) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Domain Control - Insert

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20221219@Eddie: Change datatype of @IP [RedmineID: #179537]
		- 20231030@Eddie: Change Market to TargetCountry [RedmineID: #181590]
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @MarketId NVARCHAR(10)
	
	SELECT TOP(1) @MarketId = CASE WHEN @TargetCountryCode = 'MY' THEN 'en-US' ELSE MarketID END -- Default language English with Malaysia targetcountry
	FROM dbo.TargetCountry WITH (NOLOCK)
	WHERE CountryCode = @TargetCountryCode

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Domain]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF EXISTS (
		SELECT 1 FROM dbo.AffDomainControl WITH (NOLOCK)
		WHERE AffDomainId = @AffDomainId AND TargetCountryCode = @TargetCountryCode AND [12BetDomainId] = @12BetDomainId AND IsDeleted = 0
	)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This domain setting has been existed!'
		RETURN
	END
	
	BEGIN TRY
		INSERT INTO dbo.AffDomainControl
		(
			AffDomainId
			,[12BetDomainId]
			,TargetCountryCode
			,MarketId
			,CreateDate
			,ModifyDate
			,Creator
			,Status
		)
		VALUES
		(
			@AffDomainId
			,@12BetDomainId
			,@TargetCountryCode
			,@MarketId
			,GETDATE()
			,GETDATE()
			,@UserId
			,@Status
		)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = N'Error occurs. Insert unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200), @NewData NVARCHAR(MAX)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @NewData = CONVERT(NVARCHAR(MAX),
					   (
								SELECT @AffDomainId 		AS '@AffDomainId'
									 , @12BetDomainId 		AS '@_12BetDomainId'
									 , @TargetCountryCode	AS '@TargetCountryCode'
									 , @MarketId 			AS '@MarketId'
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