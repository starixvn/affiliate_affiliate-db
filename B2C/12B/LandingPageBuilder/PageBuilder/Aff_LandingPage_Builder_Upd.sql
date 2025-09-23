/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Builder_Upd]
	@PageId INT,
	@PageName VARCHAR(200) = NULL,
	@CampaignId INT = NULL,
	@TargetCountryCode VARCHAR(50) = NULL,
	@MarketId VARCHAR(50) = NULL,
	@DealIds VARCHAR(2000) = NULL,
	@ComponentStructure NVARCHAR(MAX) = NULL,--- Json format
	@StatusId TINYINT = NULL,
	@IsUpdStatus BIT = 0, -- 1: Only update StatusId, 0: Update all provided columns
	@UserId INT,
	@IP VARCHAR(50) = '',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
	/*
	Created: 20250910@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Update Landing Page builder
	Revisions:
		- 20250910@Sophia: Initial version [RedmineID: #236797]
		- 20250917@Sophia: Added LandingPage checks and integration with Aff_Admin_LandingPage_Upd [RedmineID: #236797]
		
	Explain:	
		- @IsUpdStatus: When true, only updates StatusId regardless of other parameters
		- NULL: no change will be made to the existing value
		- '': sets the value to an empty string
		- 'value': updates the field with the provided input
*/
BEGIN
	SET NOCOUNT ON;

	-- =========================
	-- Validate required parameters
	-- =========================
	IF @PageId IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.LandingPage_Builder WITH (NOLOCK) WHERE PageId = @PageId)
	BEGIN
		SELECT @ErrCode = 1000, @ErrMsg = N'Invalid PageId!';
		RETURN;
	END

	IF @UserId IS NULL
	BEGIN
		SELECT @ErrCode = 1006, @ErrMsg = N'UserId is required!';
		RETURN;
	END

	DECLARE @Language NVARCHAR(5) = 'en-US';
	DECLARE @Duration INT;
	DECLARE @StartTime DATETIME = GETDATE();
	DECLARE @PageCode VARCHAR(100);

	-- Get PageCode from the existing record
	SELECT @PageCode = PageCode
	FROM dbo.LandingPage_Builder WITH (NOLOCK)
	WHERE PageId = @PageId;

	CREATE TABLE #ComponentStructure (
		OrderId INT,
		ModuleId INT,
		MediaId INT,
		ExtraInfo VARCHAR(8000)
	);

	-- =========================
	-- Check permission
	-- =========================
	EXEC dbo.Aff_Con_CheckPermission
		@CustId     = @UserId,
		@FuncName   = '[PageBuilder]',
		@ErrCode    = @ErrCode OUTPUT,
		@ErrMsg     = @ErrMsg OUTPUT;
	IF @ErrCode <> 0
	BEGIN
		RETURN;
	END

	-- Get PageId from LandingPage table for validation and update
	DECLARE @LandingPageId INT;		
	SELECT @LandingPageId = PageId
	FROM dbo.LandingPage WITH (NOLOCK)
	WHERE PageCode = @PageCode


	IF @IsUpdStatus = 0
	BEGIN	

		-- =========================
		-- Check duplicate PageName
		-- =========================
		IF @PageName IS NOT NULL AND EXISTS (
			SELECT 1 
			FROM dbo.LandingPage_Builder WITH (NOLOCK)
			WHERE PageName = @PageName
			AND PageId <> @PageId
		)
		BEGIN
			SELECT @ErrCode = 1002, @ErrMsg = N'Page name already exists. Please enter a different name.';
			RETURN;
		END

		-- =========================
		-- Check duplicate in LandingPage table
		-- =========================	

		IF @PageName IS NOT NULL AND EXISTS (
			SELECT 1 
			FROM dbo.LandingPage WITH (NOLOCK) 
			WHERE PageName = @PageName 
			AND PageId <> @LandingPageId
		)
		BEGIN
			SELECT @ErrCode = 1008, @ErrMsg = N'Page name already exists. Please enter a different name.';
			RETURN;
		END		
	END
	-- Get all reference names for old data
	DECLARE @OldLanguageName NVARCHAR(100), 
			@OldCountryName NVARCHAR(100),
			@OldCampaignName NVARCHAR(500),
			@OldDealNames NVARCHAR(2000),
			@OldStatusName NVARCHAR(50),
			@OldData NVARCHAR(MAX);

	-- Declare variables for old values
	DECLARE @OldPageId INT,
			@OldPageName VARCHAR(200),
			@OldPageCode VARCHAR(100);

	-- Get old data for logging
	SELECT 
		@OldPageId = b.PageId,
		@OldPageName = b.PageName,
		@OldPageCode = b.PageCode,
		@OldLanguageName = m.MarketName,
		@OldCountryName = tc.CountryName,
		@OldCampaignName = c.CampaignName,
		@OldStatusName = s.Status
	FROM dbo.LandingPage_Builder b WITH (NOLOCK)
	LEFT JOIN dbo.Market m WITH (NOLOCK) ON m.MarketId = b.MarketId
	LEFT JOIN dbo.TargetCountry tc WITH (NOLOCK) ON tc.CountryCode = b.TargetCountryCode AND tc.MarketId = b.MarketId
	LEFT JOIN dbo.LandingPage_Campaign c WITH (NOLOCK) ON c.CampaignId = b.CampaignId
	LEFT JOIN dbo.Aff_f_LandingPage_Status() s ON s.StatusId = b.StatusId
	WHERE b.PageId = @PageId;

	-- Get old deal names
	SELECT @OldDealNames = STUFF((
		SELECT ', ' + GroupName
		FROM dbo.CommGroup WITH (NOLOCK)
		WHERE GroupId IN (
			SELECT value 
			FROM dbo.LandingPage_Builder b WITH (NOLOCK)
			CROSS APPLY STRING_SPLIT(b.DealIds, ',')
			WHERE b.PageId = @PageId
		)
		AND IsDeleted = 0
		FOR XML PATH('')), 1, 1, '');

	-- Create @OldData JSON
	SELECT @OldData = ISNULL((
		SELECT 
			JSON_QUERY(ISNULL((
				SELECT 
					@OldPageId AS 'pid',
					@OldPageName AS 'pn',
					@OldPageCode AS 'pc',
					@OldCountryName AS 'tc',
					@OldLanguageName AS 'l',
					@OldCampaignName AS 'cn',
					@OldDealNames AS 'dn',
					@OldStatusName AS 'st'
				FROM dbo.LandingPage_Builder b WITH (NOLOCK)
				WHERE b.PageId = @PageId
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
			), '{}')) AS 'page',
			JSON_QUERY(ISNULL((
				SELECT 
					d.OrderId AS 'oid',
					ISNULL(m.ModuleName, '') AS 'mn',
					ISNULL(m.ModuleType, 0) AS 'mt',
					JSON_QUERY(
						CASE WHEN mg.MediaId IS NOT NULL
							THEN (
								SELECT 
									mg.MediaId AS 'mid',
									ISNULL(mg.FileName, '') AS 'fn',
									ISNULL(mg.MediaName, '') AS 'mn',
									ISNULL(mg.Dimension, '') AS 'dim'
								FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
							)
							ELSE NULL
						END
					) AS 'media',
					JSON_QUERY(
						CASE 
							WHEN ISJSON(d.ExtraInfo) = 1 THEN d.ExtraInfo
							WHEN d.ExtraInfo IS NOT NULL THEN CONCAT('{"value":"', REPLACE(d.ExtraInfo, '"', '\"'), '"}')
							ELSE NULL
						END
					) AS 'ei'
				FROM dbo.LandingPage_BuilderDetail d WITH (NOLOCK)
				LEFT JOIN dbo.LandingPage_Module m WITH (NOLOCK)
					ON d.ModuleId = m.ModuleId
				LEFT JOIN dbo.LandingPage_MediaGallery mg WITH (NOLOCK)
					ON d.MediaId = mg.MediaId
				WHERE d.PageId = @PageId
				ORDER BY d.OrderId
				FOR JSON PATH
			), '[]')) AS 'comp'
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
	), '{}');


	IF @IsUpdStatus = 1
	BEGIN
		-- Only update StatusId when @IsUpdStatus is true
		UPDATE dbo.LandingPage_Builder WITH (ROWLOCK)
		SET StatusId = ISNULL(@StatusId, StatusId),
			UpdatedBy = @UserId,
			UpdatedDate = DATEADD(HOUR, 8, GETUTCDATE()) -- GMT+8
		WHERE PageId = @PageId;
	END
	ELSE
	BEGIN
		-- Update all provided columns when @IsUpdStatus is false
		UPDATE dbo.LandingPage_Builder WITH (ROWLOCK)
		SET PageName = ISNULL(@PageName, PageName),
			CampaignId = ISNULL(@CampaignId, CampaignId),
			TargetCountryCode = ISNULL(@TargetCountryCode, TargetCountryCode),
			MarketId = ISNULL(@MarketId, MarketId),
			DealIds = ISNULL(@DealIds, DealIds),
			StatusId = ISNULL(@StatusId, StatusId),
			UpdatedBy = @UserId,
			UpdatedDate = DATEADD(HOUR, 8, GETUTCDATE()) -- GMT+8
		WHERE PageId = @PageId;
	
		IF @ComponentStructure IS NOT NULL
		BEGIN
			-- Delete existing components
			DELETE FROM dbo.LandingPage_BuilderDetail WITH (ROWLOCK)
			WHERE PageId = @PageId;

			-- Insert new components
			INSERT INTO #ComponentStructure (OrderId, ModuleId, MediaId, ExtraInfo)
			SELECT 
				JSON_VALUE(detail.value, '$.OrderId') AS OrderId,
				JSON_VALUE(detail.value, '$.ModuleId') AS ModuleId,
				JSON_VALUE(detail.value, '$.MediaId') AS MediaId,
				JSON_VALUE(detail.value, '$.ExtraInfo') AS ExtraInfo
			FROM OPENJSON(@ComponentStructure) detail;

			INSERT INTO dbo.LandingPage_BuilderDetail (
				PageId,
				OrderId,
				ModuleId,
				MediaId,
				ExtraInfo
			)
			SELECT
				@PageId,
				OrderId,
				ModuleId,
				MediaId,
				ExtraInfo
			FROM #ComponentStructure
			ORDER BY OrderId ASC;
		END
	END
	DROP TABLE #ComponentStructure;

	-- =========================
	-- Update LandingPage table through Aff_Admin_LandingPage_Upd
	-- =========================
		BEGIN
			DECLARE @BlockedCountries VARCHAR(500);
			SELECT @BlockedCountries = STUFF((
				SELECT DISTINCT ',' + CountryCode
				FROM dbo.TargetCountry WITH (NOLOCK)
				WHERE CountryCode <> ISNULL(@TargetCountryCode, 
					(SELECT TargetCountryCode FROM dbo.LandingPage_Builder WHERE PageId = @PageId))
				FOR XML PATH('')
			), 1, 1, '');

			-- Check if any values are different from the current values in LandingPage
			DECLARE @CurrentPageName VARCHAR(200),
					@CurrentBlockTargetCountry VARCHAR(500),
					@CurrentDealIds VARCHAR(2000),
					@CurrentStatusId TINYINT,
					@NeedsUpdate BIT = 0;

			SELECT @CurrentPageName = PageName,
					@CurrentBlockTargetCountry = BlockTargetCountry,
					@CurrentDealIds = DealIds,
					@CurrentStatusId = StatusId
			FROM dbo.LandingPage WITH (NOLOCK)
			WHERE PageId = @LandingPageId;

			IF (@PageName IS NOT NULL AND @PageName <> @CurrentPageName)
				OR (@BlockedCountries IS NOT NULL AND @BlockedCountries <> @CurrentBlockTargetCountry)
				OR (@DealIds IS NOT NULL AND @DealIds <> @CurrentDealIds)
				OR (@StatusId IS NOT NULL AND @StatusId <> @CurrentStatusId)
			BEGIN
				SET @NeedsUpdate = 1;
			END

			-- Only call Aff_Admin_LandingPage_Upd if there are changes
			IF @NeedsUpdate = 1
			BEGIN
				DECLARE @AdminErrCode INT = 0;
				DECLARE @AdminErrMsg NVARCHAR(4000) = '';

				IF @IsUpdStatus = 1
				BEGIN
					EXEC dbo.Aff_Admin_LandingPage_Upd
						@PageId = @LandingPageId,
						@PageCode = @PageCode,
						@PageName = @CurrentPageName,
						@BlockTargetCountry = @CurrentBlockTargetCountry,
						@IsMobile = 1,
						@IsExcluded = 0,
						@DealIds = @CurrentDealIds,
						@StatusId = @StatusId, --- Just Update StatusId
						@UserId = @UserId,
						@IP = @IP,
						@ErrCode = @AdminErrCode OUTPUT,
						@ErrMsg = @AdminErrMsg OUTPUT;
				END
				ELSE
				BEGIN
					EXEC dbo.Aff_Admin_LandingPage_Upd
						@PageId = @LandingPageId,
						@PageCode = @PageCode,
						@PageName = @PageName,
						@BlockTargetCountry = @BlockedCountries,
						@IsMobile = 1,
						@IsExcluded = 0,
						@DealIds = @DealIds,
						@StatusId = @StatusId,
						@UserId = @UserId,
						@IP = @IP,
						@ErrCode = @AdminErrCode OUTPUT,
						@ErrMsg = @AdminErrMsg OUTPUT;
				END

				IF @AdminErrCode <> 0
				BEGIN
					SELECT @ErrCode = @AdminErrCode, @ErrMsg = @AdminErrMsg;
					RETURN;
				END
			END -- End of @NeedsUpdate = 1
		END

	-- =========================
	-- Write log
	-- =========================
	DECLARE @EndTime DATETIME = GETDATE();
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime);

	-- Get all reference names for new data
	DECLARE @NewLanguageName NVARCHAR(100), 
			@NewCountryName NVARCHAR(100),
			@NewCampaignName NVARCHAR(500),
			@NewDealNames NVARCHAR(2000),
			@NewStatusName NVARCHAR(50),
			@NewData NVARCHAR(MAX);

	-- Declare variables for new values
	DECLARE @NewPageId INT,
			@NewPageName VARCHAR(200),
			@NewPageCode VARCHAR(100);

	-- Get new data for logging
	SELECT 
		@NewPageId = b.PageId,
		@NewPageName = b.PageName,
		@NewPageCode = b.PageCode,
		@NewLanguageName = m.MarketName,
		@NewCountryName = tc.CountryName,
		@NewCampaignName = c.CampaignName,
		@NewStatusName = s.Status
	FROM dbo.LandingPage_Builder b WITH (NOLOCK)
	LEFT JOIN dbo.Market m WITH (NOLOCK) ON m.MarketId = b.MarketId
	LEFT JOIN dbo.TargetCountry tc WITH (NOLOCK) ON tc.CountryCode = b.TargetCountryCode AND tc.MarketId = b.MarketId
	LEFT JOIN dbo.LandingPage_Campaign c WITH (NOLOCK) ON c.CampaignId = b.CampaignId
	LEFT JOIN dbo.Aff_f_LandingPage_Status() s ON s.StatusId = b.StatusId
	WHERE b.PageId = @PageId;

	-- Get Deal names for new data
	SELECT @NewDealNames = STUFF((
		SELECT ', ' + GroupName
		FROM dbo.CommGroup WITH (NOLOCK)
		WHERE GroupId IN (
			SELECT value 
			FROM STRING_SPLIT(ISNULL(@DealIds, (SELECT DealIds FROM dbo.LandingPage_Builder WHERE PageId = @PageId)), ',')
		)
		AND IsDeleted = 0
		FOR XML PATH('')), 1, 1, '');

	-- Create @NewData JSON
	SELECT @NewData = ISNULL((
		SELECT 
			JSON_QUERY(ISNULL((
				SELECT 
					@NewPageId AS 'pid',
					@NewPageName AS 'pn',
					@NewPageCode AS 'pc',
					@NewCountryName AS 'tc',
					@NewLanguageName AS 'l',
					@NewCampaignName AS 'cn',
					@NewDealNames AS 'dn',
					@NewStatusName AS 'st'
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
			), '{}')) AS 'page',
			JSON_QUERY(
				CASE 
					WHEN @ComponentStructure IS NOT NULL THEN @ComponentStructure
					ELSE (
						SELECT 
							d.OrderId AS 'oid',
							ISNULL(m.ModuleName, '') AS 'mn',
							ISNULL(m.ModuleType, 0) AS 'mt',
							JSON_QUERY(
								CASE WHEN mg.MediaId IS NOT NULL
									THEN (
										SELECT 
											mg.MediaId AS 'mid',
											ISNULL(mg.FileName, '') AS 'fn',
											ISNULL(mg.MediaName, '') AS 'mn',
											ISNULL(mg.Dimension, '') AS 'dim'
										FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
									)
									ELSE NULL
								END
							) AS 'media',
							JSON_QUERY(
								CASE 
									WHEN ISJSON(d.ExtraInfo) = 1 THEN d.ExtraInfo
									WHEN d.ExtraInfo IS NOT NULL THEN CONCAT('{"value":"', REPLACE(d.ExtraInfo, '"', '\"'), '"}')
									ELSE NULL
								END
							) AS 'ei'
						FROM dbo.LandingPage_BuilderDetail d WITH (NOLOCK)
						LEFT JOIN dbo.LandingPage_Module m WITH (NOLOCK)
							ON d.ModuleId = m.ModuleId
						LEFT JOIN dbo.LandingPage_MediaGallery mg WITH (NOLOCK)
							ON d.MediaId = mg.MediaId
						WHERE d.PageId = @PageId
						ORDER BY d.OrderId
						FOR JSON PATH
					)
				END
			) AS 'comp'
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
	), '{}');

	-- Write log
	DECLARE @SPName VARCHAR(200);
	SELECT @SPName = OBJECT_NAME(@@PROCID);
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language,
		@Duration	= @Duration;
END;
GO
