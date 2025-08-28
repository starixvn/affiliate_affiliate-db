/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_DomainControl_Ins]
	@UserId				INT
	,@TargetCountryCode	VARCHAR(5)
	,@AffDomainId		INT
	,@LicenseeDomainId	INT = 0
	,@Status			BIT
	,@IP				VARCHAR(50) = ''
	,@IsMobile	 		BIT = 0
	,@IsExcluded 		BIT = 1
	,@DealIds 			NVARCHAR(MAX) = ''
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
		- 20250721@Eddie: Add new condition [RedmineID: #233219]

	Param's Explanation:
		- @IsMobile:
			+ 0: Others
			+ 1: for Mobile only
		- @IsExcluded: for Deals
			+ 0: Included Deals
			+ 1: Excluded Deals
		- @DealIds:
			+ '0'		 : All
			+ '' 		 : None
			+ '1,10,140' : group A,B,C
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MarketId NVARCHAR(10)
	SELECT TOP(1) @MarketId = tc.MarketID 
	FROM dbo.TargetCountry tc WITH (NOLOCK)
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
		WHERE TargetCountryCode = @TargetCountryCode
		  AND AffDomainId = @AffDomainId
		  AND IsDeleted = 0
	)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This domain setting has been existed!'
		RETURN
	END
	
	IF (@IsExcluded = 0 AND ISNULL(@DealIds, '') = '')
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Please select at least a deal.'
		RETURN
	END

	IF (@IsExcluded = 1 AND @DealIds = '0')
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'Please deselect at least a deal.'
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
			,IsMobile
			,IsExcluded
			,DealIds
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
			,@IsMobile
			,@IsExcluded
			,@DealIds
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
					+ ',IsMobile=' + CONVERT(VARCHAR(2), @IsMobile)
					+ ',IsExcluded=' + CONVERT(VARCHAR(2), @IsExcluded)
					+ ',DealIds=' + ISNULL(@DealIds, '')

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
END
GO