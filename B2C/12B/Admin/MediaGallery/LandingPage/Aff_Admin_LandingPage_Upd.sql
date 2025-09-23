/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_LandingPage_Upd]
	@UserId				 INT
	,@PageId			 SMALLINT
	,@PageName			 NVARCHAR(200)
	,@PageCode			 NVARCHAR(100)
	,@IP				 VARCHAR(50) = ''
	,@BlockTargetCountry VARCHAR(200) = ''
	,@IsMobile	 		 BIT
	,@IsExcluded 		 BIT
	,@DealIds 			 NVARCHAR(MAX)
	,@StatusId			 TINYINT = NULL
	,@ErrCode			 INT = 0 OUTPUT
	,@ErrMsg			 NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin Site - Media Gallery - Landing Page - Update

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250417@Lewis: Add BlockTargetCountry [RedmineID: #223644]
		- 20250721@Eddie: Add new condition [RedmineID: #233219]
		- 20250918@Sophia: Add StatusId parameter with NULL handling [RedmineID: #236797]
		
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language 			   VARCHAR(10) = 'en-US'
		  , @OldPageName 		   NVARCHAR(200)
		  , @OldPageCode 		   VARCHAR(100)
		  , @OldBlockTargetCountry VARCHAR(200)
		  , @OldIsMobile 		   BIT
		  , @OldIsExcluded 		   BIT
		  , @OldDealIds 		   NVARCHAR(MAX)
		  , @OldStatusId		   TINYINT
		  , @Default_PageId 	   SMALLINT

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[MEDIA]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Default pagecode
	SELECT @Default_PageId = CONVERT(SMALLINT, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'LandingPage'

	SELECT @PageName = ISNULL(LTRIM(LTRIM(@PageName)), ''), @PageCode = ISNULL(LTRIM(LTRIM(@PageCode)), '')

	IF @PageName = '' OR @PageCode = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid input'
		RETURN
	END

	SELECT @OldPageName = PageName
		 , @OldPageCode = PageCode 
		 , @OldBlockTargetCountry = BlockTargetCountry
		 , @OldIsMobile = IsMobile
		 , @OldIsExcluded = IsExcluded
		 , @OldDealIds = DealIds
		 , @OldStatusId = StatusId
	FROM dbo.LandingPage WITH (NOLOCK) 
	WHERE PageId = @PageId
	  AND IsDeleted = 0

	IF ISNULL(@OldPageName, '') = ''
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This landing page does not exists';
		RETURN;
	END

	IF ( @OldPageName = @PageName
	 AND @OldPageCode = @PageCode
	 AND NOT EXISTS(
		SELECT 1
		FROM STRING_SPLIT(@BlockTargetCountry, ',') AS t
			FULL OUTER JOIN STRING_SPLIT(@OldBlockTargetCountry, ',') AS s ON s.value = t.value
		WHERE t.value IS NULL 
		   OR s.value IS NULL
	 )
	 AND @OldIsMobile = @IsMobile
	 AND @OldIsExcluded = @IsExcluded
	 AND (@StatusId IS NULL OR @OldStatusId = @StatusId)
	 AND NOT EXISTS(
		SELECT 1
		FROM STRING_SPLIT(@DealIds, ',') AS t
			FULL OUTER JOIN STRING_SPLIT(@OldDealIds, ',') AS s ON s.value = t.value
		WHERE t.value IS NULL 
		   OR s.value IS NULL
	 )
	)
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'This landing page does not changes';
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM dbo.LandingPage WITH (NOLOCK) WHERE PageName = @PageName AND PageCode = @PageCode AND IsDeleted = 0 AND PageId <> @PageId)
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'The landing page is already exists';
		RETURN;
	END

	IF (@IsExcluded = 0 AND ISNULL(@DealIds, '') = '')
	BEGIN
		SELECT @ErrCode = 106, @ErrMsg = 'Please select at least a deal.';
		RETURN;
	END
	
	IF (@IsExcluded = 1 AND @DealIds = '0')
	BEGIN
		SELECT @ErrCode = 107, @ErrMsg = 'Please select at least a deal.';
		RETURN;
	END

	-- Validate StatusId if provided
	IF @StatusId IS NOT NULL AND @StatusId NOT IN (0, 1, 2)
	BEGIN
		SELECT @ErrCode = 109, @ErrMsg = 'Invalid StatusId. Must be 0 (Draft), 1 (Active) or 2 (InActive).';
		RETURN;
	END
	
	BEGIN TRY
		UPDATE dbo.LandingPage WITH (ROWLOCK, UPDLOCK)
		SET PageName 		   = @PageName
		   ,PageCode 		   = @PageCode
		   ,BlockTargetCountry = IIF(PageId = @Default_PageId, BlockTargetCountry, @BlockTargetCountry)
		   ,IsMobile 		   = IIF(PageId = @Default_PageId, IsMobile, @IsMobile)
		   ,IsExcluded 		   = IIF(PageId = @Default_PageId, IsExcluded, @IsExcluded)
		   ,DealIds 		   = IIF(PageId = @Default_PageId, DealIds, @DealIds)
		   ,StatusId 		   = IIF(@StatusId IS NULL, StatusId, 
								 IIF(PageId = @Default_PageId, StatusId, @StatusId))
		WHERE PageId = @PageId; -- 'join' must not be updated for BlockTargetCountry, IsMobile, IsExcluded, and DealIds
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 105, @ErrMsg = 'Error occurs. Update unsuccessfully.';
		RETURN;
	END CATCH;

	-- Write log
	DECLARE @SPName VARCHAR(200);
	SELECT  @SPName = OBJECT_NAME(@@PROCID);

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX);

	SELECT @OldData = CONCAT_WS(',', 'PageName=' + @OldPageName,
									 'PageCode=' + @OldPageCode,
									 'BlockTargetCountry=' + @OldBlockTargetCountry,
									 'IsMobile=' + CONVERT(VARCHAR(2), @OldIsMobile),
									 'IsExcluded=' + CONVERT(VARCHAR(2), @OldIsExcluded),
									 'DealIds=' + @OldDealIds)
		  ,@NewData = CONCAT_WS(',', 'PageName=' + @PageName,
								     'PageCode=' + @PageCode,
								     'BlockTargetCountry=' + @BlockTargetCountry,
								     'IsMobile=' + CONVERT(VARCHAR(2), @IsMobile),
								     'IsExcluded=' + CONVERT(VARCHAR(2), @IsExcluded),
								     'DealIds=' + @DealIds);
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language;
END;
GO