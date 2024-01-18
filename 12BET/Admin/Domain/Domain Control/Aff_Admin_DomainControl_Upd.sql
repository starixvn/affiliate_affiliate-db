/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_DomainControl_Upd]
	@UserId				INT
	,@DomainControlId	INT
	,@AffDomainId		INT
	,@12BetDomainId		INT
	,@TargetCountryCode	VARCHAR(2)
	,@Status			BIT
	,@IP				VARCHAR(50) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Domain Control - Update

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20221219@Eddie: Change format code [RedmineID: #179537]
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

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData = CONVERT(NVARCHAR(MAX), 
					   (
							SELECT AffDomainId 			AS '@AffDomainId'
								  ,[12BetDomainId] 		AS '@_12BetDomainId'
								  ,TargetCountryCode	AS '@TargetCountryCode'
								  ,MarketId 			AS '@MarketId'
								  ,Status 				AS '@Status'
							FROM dbo.AffDomainControl WITH (NOLOCK)
							WHERE Id = @DomainControlId AND IsDeleted = 0
							FOR XML PATH('row'), ROOT('root')
					    ))

	SELECT  @NewData = CONVERT(NVARCHAR(MAX), 
					   (
							SELECT @AffDomainId 		AS '@AffDomainId'
								  ,@12BetDomainId 		AS '@_12BetDomainId'
								  ,@TargetCountryCode 	AS '@TargetCountryCode'
								  ,@MarketId 			AS '@MarketId'
								  ,@Status 				AS '@Status' 
							FOR XML PATH('row'), ROOT('root')
						))

	IF EXISTS( SELECT 1 FROM dbo.AffDomainControl WITH (NOLOCK)
			   WHERE Id = @DomainControlId
				 AND AffDomainId = @AffDomainId
				 AND [12BetDomainId] = @12BetDomainId
				 AND TargetCountryCode = @TargetCountryCode
				 AND Status = @Status
				 AND IsDeleted = 0 )
		RETURN -- no change

	IF EXISTS ( SELECT 1 FROM dbo.AffDomainControl WITH (NOLOCK)
				WHERE Id <> @DomainControlId
				  AND AffDomainId = @AffDomainId
				  AND [12BetDomainId] = @12BetDomainId
				  AND TargetCountryCode = @TargetCountryCode
				  AND IsDeleted = 0
	)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This domain setting has been existed!'
		RETURN
	END

	BEGIN TRY

		UPDATE dbo.AffDomainControl WITH (ROWLOCK)
		SET AffDomainId			= @AffDomainID
			,[12BetDomainId]	= @12BetDomainId
			,TargetCountryCode	= @TargetCountryCode
			,MarketId			= @MarketId
			,ModifyDate			= GETDATE()
			,Status				= @Status
		WHERE Id = @DomainControlId

		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'This domain setting does not exists!'
			RETURN
		END

	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = N'Error occurs. Update unsuccessfully.'
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