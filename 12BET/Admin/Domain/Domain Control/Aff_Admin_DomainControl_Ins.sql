/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_DomainControl_Ins]
	@UserId			INT
	,@MarketId		NVARCHAR(10)
	,@AffDomainId	INT
	,@12BetDomainId	INT
	,@Status		BIT
	,@IP			NVARCHAR(40) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Domain Control - Insert

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC [dbo].[Aff_Con_CheckPermission]
		@CustId		= @UserId
		,@funcname	= '[Domain]'
		,@System	= 'AFFILIATE'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF EXISTS (
		SELECT 1 FROM dbo.AffDomainControl WITH (NOLOCK)
		WHERE AffDomainId = @AffDomainId AND MarketId = @MarketId AND [12BetDomainId] = @12BetDomainId AND IsDeleted = 0
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

	SELECT  @NewData = 'AffDomainId=' + CONVERT(VARCHAR(10), @AffDomainId)
					+ ',12BetDomainId=' + CONVERT(VARCHAR(10), @12BetDomainId)
					+ ',MarketId=' + ISNULL(@MarketId, '')

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
END
GO