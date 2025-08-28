/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_LandingPage_Ins]
	@UserId				 INT
	,@PageName			 NVARCHAR(200)
	,@PageCode			 NVARCHAR(100)
	,@IP				 VARCHAR(50) = ''
	,@BlockTargetCountry VARCHAR(200) = ''
	,@IsMobile	 		 BIT = 0
	,@IsExcluded 		 BIT = 1
	,@DealIds 			 NVARCHAR(MAX) = ''
	,@ErrCode			 INT = 0 OUTPUT
	,@ErrMsg			 NVARCHAR(4000) = '' OUTPUT

AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin Site - Media Gallery - Landing Page - Insert

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250417@Lewis: Add BlockTargetCountry [RedmineID: #223644]
		- 20250721@Eddie: Add new condition [RedmineID: #233219]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[MEDIA]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	
	SELECT @PageName = ISNULL(LTRIM(LTRIM(@PageName)), ''), @PageCode = ISNULL(LTRIM(LTRIM(@PageCode)), '')
	
	-- Validate
	BEGIN
		IF @PageName = '' OR @PageCode = ''
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Invalid input'
			RETURN
		END

		-- Check exists
		IF EXISTS (SELECT 1 FROM dbo.LandingPage WITH (NOLOCK) WHERE PageName = @PageName AND PageCode = @PageCode AND IsDeleted = 0)
		BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'The landing page is already exists'
			RETURN
		END
		
		IF (@IsExcluded = 0 AND ISNULL(@DealIds, '') = '')
		BEGIN
			SELECT @ErrCode = 104, @ErrMsg = 'Please select at least a deal.'
			RETURN
		END
	
		IF (@IsExcluded = 1 AND @DealIds = '0')
		BEGIN
			SELECT @ErrCode = 105, @ErrMsg = 'Please deselect at least a deal.'
			RETURN
		END
	END

	BEGIN TRY
		INSERT INTO dbo.LandingPage (PageName, PageCode, IsDeleted, BlockTargetCountry, IsMobile, IsExcluded, DealIds)
		VALUES (@PageName, @PageCode, 0, @BlockTargetCountry, @IsMobile, @IsExcluded, @DealIds)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = 'Error occurs. Insert unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @Data NVARCHAR(MAX)

	SELECT @Data = CONCAT_WS(',', 'PageName=' + @PageName,
								  'PageCode=' + @PageCode,
								  'BlockTargetCountry=' + @BlockTargetCountry,
								  'IsMobile=' + CONVERT(VARCHAR(2), @IsMobile),
								  'IsExcluded=' + CONVERT(VARCHAR(2), @IsExcluded),
								  'DealIds=' + @DealIds
				   )

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @Data,
		@IP			= @IP,
		@Language	= @Language
END
GO