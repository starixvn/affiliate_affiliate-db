/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_DomainControl_Ins]
	@UserId				INT
	,@TargetCountryCode	VARCHAR(5)
	,@AffDomainId		INT
	,@LicenseeDomainId	INT = 0
	,@Status			BIT
	,@IP				VARCHAR(50) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Domain - Domain Control - Insert

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250417@Lewis: Add BlockTargetCountry [RedmineID: #223644]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MarketId NVARCHAR(10)
	SELECT TOP(1) @MarketId = tc.MarketID 
	FROM TargetCountry tc WITH (NOLOCK)
	WHERE tc.OrderNo IS NOT NULL --Default MarketID for CountryCode have more than 1 MarketID
		AND tc.CountryCode = @TargetCountryCode
		AND EXISTS (SELECT 1 FROM Market m WITH (NOLOCK) WHERE m.MarketId = tc.MarketID AND m.IsDeleted = 0)

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
		WHERE AffDomainId = @AffDomainId AND TargetCountryCode = @TargetCountryCode AND LicenseeDomainId = @LicenseeDomainId AND IsDeleted = 0
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
			,TargetCountryCode
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
			,@TargetCountryCode
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
					+ ',TargetCountryCode=' + ISNULL(@TargetCountryCode, '')

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
END
GO