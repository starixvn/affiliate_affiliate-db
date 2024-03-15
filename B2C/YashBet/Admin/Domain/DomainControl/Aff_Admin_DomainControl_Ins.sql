/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_DomainControl_Ins]
	@UserId				INT
	,@MarketId			NVARCHAR(10)
	,@AffDomainId		INT
	,@LicenseeDomainId	INT = 0
	,@Status			BIT
	,@IP				NVARCHAR(40) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Domain - Domain Control - Insert

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC [dbo].[Aff_Con_CheckPermission]
		@CustId		= @UserId
		,@funcname	= '[Domain]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF EXISTS (
		SELECT 1 FROM dbo.DomainControl WITH (NOLOCK)
		WHERE AffDomainId = @AffDomainId AND MarketId = @MarketId AND LicenseeDomainId = @LicenseeDomainId AND IsDeleted = 0
	)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This domain setting has been existed!'
		RETURN
	END
	
	BEGIN TRY
		INSERT INTO dbo.DomainControl
		(
			AffDomainId
			,LicenseeDomainId
			,MarketId
			,CreateDate
			,ModifyDate
			,Creator
			,Status
		)
		VALUES
		(
			@AffDomainId
			,@LicenseeDomainId
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
					+ ',LicenseeDomainId=' + CONVERT(VARCHAR(10), @LicenseeDomainId)
					+ ',MarketId=' + ISNULL(@MarketId, '')

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
END
GO