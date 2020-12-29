/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_DomainControl_Upd]
	@UserId				INT
	,@DomainControlId	INT
	,@AffDomainId		INT
	,@12BetDomainId		INT
	,@MarketId			NVARCHAR(10)
	,@Status			BIT
	,@IP				NVARCHAR(40) = ''
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
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Domain]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData = 'AffDomainId=' + CONVERT(VARCHAR(10), AffDomainId)
						+ ',12BetDomainId=' + CONVERT(VARCHAR(10), [12BetDomainId])
						+ ',MarketId=' + ISNULL(MarketId, '')
						+ ',Status=' + CONVERT(VARCHAR(2), Status)
			,@NewData = 'AffDomainId=' + CONVERT(VARCHAR(10), @AffDomainId)
						+ ',12BetDomainId=' + CONVERT(VARCHAR(10), @12BetDomainId)
						+ ',MarketId=' + ISNULL(@MarketId, '')
						+ ',Status=' + CONVERT(VARCHAR(2), @Status)
	FROM dbo.AffDomainControl WITH (NOLOCK) WHERE Id = @DomainControlId AND IsDeleted = 0

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This domain setting does not exists!'
		RETURN
	END

	IF ISNULL(@OldData, '') = ISNULL(@NewData, '')
		RETURN -- no change

	IF EXISTS (
		SELECT 1 FROM dbo.AffDomainControl WITH (NOLOCK)
		WHERE Id <> @DomainControlId AND AffDomainId = @AffDomainId AND [12BetDomainId] = @12BetDomainId AND MarketId = @MarketId AND IsDeleted = 0
	)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This domain setting has been existed!'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.AffDomainControl WITH (ROWLOCK)
		SET AffDomainId			= @AffDomainID
			,[12BetDomainId]	= @12BetDomainId
			,MarketId			= @MarketId
			,ModifyDate			= GETDATE()
			,Status				= @Status
		WHERE Id = @DomainControlId
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