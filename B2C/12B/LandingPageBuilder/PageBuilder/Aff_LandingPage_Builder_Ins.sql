/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Builder_Ins]
	@PageName VARCHAR(200),
	@PageCode VARCHAR(100),
	@CampaignId INT,
	@TargetCountryCode VARCHAR(50),
	@MarketId VARCHAR(50),
	@DealIds VARCHAR(2000) = NULL,
	@ComponentStructure NVARCHAR(MAX) = NULL,--- Json format
	@StatusId TINYINT = 0,
	@UserId INT, 
	@IsPreview BIT,
	@IP VARCHAR(50) = '',
    @PageId INT OUTPUT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
	Created: 20250904@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Insert Landing Page builder
	Revisions:
		- 20250904@Sophia: Initial version [RedmineID: #236797]
	Example :
	@ComponentStructure =
'[
    { "orderId": "1", "moduleId": "1", "mediaId": "1", "extraInfo": "" },
    { "orderId": "2", "moduleId": "2", "mediaId": "2", "extraInfo": "" },
    { "orderId": "3", "moduleId": "3", "mediaId": "3", "extraInfo": "" },
    { "orderId": 4, "moduleId": 4, "mediaId": 4, "extraInfo": "" },
    { "orderId": 5, "moduleId": 5, "mediaId": 5, "extraInfo": "" },
	{ "orderId": 5, "moduleId": 5, "mediaId": 8, "extraInfo": "" },
    { "orderId": 6, "moduleId": 8, "mediaId": null, "extraInfo": "https://youtube.com/vip-promo" },
    { "orderId": 7, "moduleId": 9, "mediaId": 11, "extraInfo": "" },
    { "orderId": 8, "moduleId": 10, "mediaId": 8, "extraInfo": "" }
]'
*/
BEGIN
	SET NOCOUNT ON;

	-- =========================
	-- Validate required parameters
	-- =========================
	IF ISNULL(@PageName, '') = '' OR ISNULL(@PageCode, '') = ''
	BEGIN
		SELECT @ErrCode = 1001, @ErrMsg = N'PageName and PageCode are required!';
		RETURN;
	END

	IF ISNULL(@TargetCountryCode, '') = '' OR ISNULL(@MarketId, '') = ''
	BEGIN
		SELECT @ErrCode = 1002, @ErrMsg = N'TargetCountryCode and MarketId are required!';
		RETURN;
	END
	
	IF ISNULL(@CampaignId, 0) = 0
	BEGIN
		SELECT @ErrCode = 1003, @ErrMsg = N'CampaignId is required!';
		RETURN;
	END

	IF ISNULL(@DealIds, '') = ''
	BEGIN
		SELECT @ErrCode = 1004, @ErrMsg = N'DealIds is required!';
		RETURN;
	END

	IF @StatusId IS NULL
	BEGIN
		SELECT @ErrCode = 1005, @ErrMsg = N'StatusId is required!';
		RETURN;
	END

	DECLARE @Language NVARCHAR(5) = 'en-US';
	DECLARE @Duration INT;
	DECLARE @StartTime DATETIME = GETDATE();
	DECLARE @NewData NVARCHAR(MAX);

	CREATE TABLE #ComponentStructure (
		OrderId INT,
		ModuleId INT,
		MediaId INT,
		ExtraInfo VARCHAR(8000)
	);

	-- =========================
	-- Check permission
	-- =========================
	SET @ErrCode = 0;
	SET @ErrMsg = '';

	EXEC dbo.Aff_Con_CheckPermission
		@CustId     = @UserId,
		@FuncName   = '[PageBuilder]',
		@ErrCode    = @ErrCode OUTPUT,
		@ErrMsg     = @ErrMsg OUTPUT;
	IF @ErrCode <> 0
	BEGIN
		RETURN;
	END

	-- =========================
	-- Check duplicate PageCode and PageName (only for main table)
	-- =========================
	IF @IsPreview = 0
	BEGIN
		-- Check in LandingPage_Builder
		IF EXISTS (SELECT 1 FROM dbo.LandingPage_Builder WITH (NOLOCK) WHERE PageCode = @PageCode)
		BEGIN
			SELECT @ErrCode = 1006, @ErrMsg = N'Page code already exists. Please enter a different code.';
			RETURN;
		END

		IF EXISTS (SELECT 1 FROM dbo.LandingPage_Builder WITH (NOLOCK) WHERE PageName = @PageName)
		BEGIN
			SELECT @ErrCode = 1007, @ErrMsg = N'Page name already exists. Please enter a different name.';
			RETURN;
		END

		-- Check in LandingPage
		IF EXISTS (SELECT 1 FROM dbo.LandingPage WITH (NOLOCK) WHERE PageCode = @PageCode AND IsDeleted = 0)
		BEGIN
			SELECT @ErrCode = 1008, @ErrMsg = N'Page code already exists. Please enter a different code.';
			RETURN;
		END

		IF EXISTS (SELECT 1 FROM dbo.LandingPage WITH (NOLOCK) WHERE PageName = @PageName AND IsDeleted = 0)
		BEGIN
			SELECT @ErrCode = 1009, @ErrMsg = N'Page name already exists. Please enter a different name.';
			RETURN;
		END
	END

	IF @IsPreview = 1
	BEGIN
		INSERT INTO dbo.LandingPage_Builder_Preview (
			PageName,
			PageCode,
			CampaignId,
			TargetCountryCode,
			MarketId,
			DealIds, 
			StatusId,
			Creator,
			CreatedDate
		)
		VALUES (
			@PageName,
			@PageCode,
			@CampaignId,
			@TargetCountryCode,
			@MarketId,
			@DealIds, 
			@StatusId,
			@UserId,
			DATEADD(HOUR, 8, GETUTCDATE()) -- GMT+8
		);

		SET @PageId = SCOPE_IDENTITY();	 

		INSERT INTO #ComponentStructure (OrderId, ModuleId, MediaId, ExtraInfo)
		SELECT 
			JSON_VALUE(detail.value, '$.OrderId') AS OrderId,
			JSON_VALUE(detail.value, '$.ModuleId') AS ModuleId,
			JSON_VALUE(detail.value, '$.MediaId') AS MediaId,
			JSON_VALUE(detail.value, '$.ExtraInfo') AS ExtraInfo
		FROM OPENJSON(@ComponentStructure) detail;

		INSERT INTO dbo.LandingPage_BuilderDetail_Preview (
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
	ELSE
	BEGIN
		INSERT INTO dbo.LandingPage_Builder (
			PageName,
			PageCode,
			CampaignId,
			TargetCountryCode,
			MarketId,
			DealIds, 
			StatusId,
			Creator,
			CreatedDate
		)
		VALUES (
			@PageName,
			@PageCode,
			@CampaignId,
			@TargetCountryCode,
			@MarketId,
			@DealIds, 
			@StatusId,
			@UserId,
			DATEADD(HOUR, 8, GETUTCDATE()) -- GMT+8
		);

		SET @PageId = SCOPE_IDENTITY();

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


	-- =========================
	-- Write log
	-- =========================
	DECLARE @EndTime DATETIME = GETDATE();
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime);

	-- Get all reference names
	DECLARE @LanguageName NVARCHAR(100), 
			@CountryName NVARCHAR(100),
			@CampaignName NVARCHAR(500),
			@DealNames NVARCHAR(2000),
			@StatusName NVARCHAR(50);
	
	-- Get Language name
	SELECT @LanguageName = MarketName
	FROM dbo.Market WITH (NOLOCK)
	WHERE MarketId = @MarketId;

	-- Get Country name
	SELECT TOP 1 @CountryName = CountryName
	FROM dbo.TargetCountry WITH (NOLOCK)
	WHERE CountryCode = @TargetCountryCode;

	-- Get Campaign name
	SELECT @CampaignName = CampaignName
	FROM dbo.LandingPage_Campaign WITH (NOLOCK)
	WHERE CampaignId = @CampaignId;

	-- Get Deal names
	SELECT @DealNames = STUFF((
		SELECT ', ' + GroupName
		FROM dbo.CommGroup WITH (NOLOCK)
		WHERE GroupId IN (SELECT value FROM STRING_SPLIT(@DealIds, ','))
			AND IsDeleted = 0
		FOR XML PATH('')), 1, 1, '');

	-- Get Status name
	SELECT @StatusName = Status
	FROM dbo.Aff_f_LandingPage_Status() 
	WHERE StatusId = @StatusId;

	-- Compose @NewData JSON
	SELECT @NewData = ISNULL((
		SELECT 
			JSON_QUERY(ISNULL((
				SELECT 
					ISNULL(@PageId, 0) AS 'pid',
					ISNULL(@PageName, '') AS 'pn',
					ISNULL(@PageCode, '') AS 'pc',
					ISNULL(@CountryName, '') AS 'tc',
					ISNULL(@LanguageName, '') AS 'l',
					ISNULL(@CampaignName, '') AS 'cn',
					ISNULL(@DealNames, '') AS 'dn',
					ISNULL(@StatusName, '') AS 'st',
					CAST(@IsPreview AS BIT) AS 'prv'
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
				FROM #ComponentStructure d
				LEFT JOIN dbo.LandingPage_Module m WITH (NOLOCK)
					ON d.ModuleId = m.ModuleId
				LEFT JOIN dbo.LandingPage_MediaGallery mg WITH (NOLOCK)
					ON d.MediaId = mg.MediaId
				ORDER BY d.OrderId
				FOR JSON PATH
			), '[]')) AS 'comp'
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
	), '{}');

	-- Write log
	DECLARE @SPName VARCHAR(200);
	SELECT @SPName = OBJECT_NAME(@@PROCID);
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language,
		@Duration	= @Duration;

	-- Call Aff_Admin_LandingPage_Ins after successful insert
	IF @ErrCode = 0 AND @IsPreview = 0 -- Only call for main table, not preview
	BEGIN
		-- Get all target countries except the current one
		DECLARE @BlockTargetCountry VARCHAR(500);
		SELECT @BlockTargetCountry = STUFF((
			SELECT DISTINCT ',' + CountryCode
			FROM dbo.TargetCountry WITH (NOLOCK)
			WHERE CountryCode <> @TargetCountryCode
			FOR XML PATH('')
		), 1, 1, '');

		DECLARE @IsMobile BIT = 1; -- Set to mobile version
		DECLARE @IsExcluded BIT = 0;
		DECLARE @LandingPageErrCode INT = 0;
		DECLARE @LandingPageErrMsg NVARCHAR(MAX) = '';

		EXEC dbo.Aff_Admin_LandingPage_Ins
			@PageCode = @PageCode,
			@PageName = @PageName,
			@BlockTargetCountry = @BlockTargetCountry,
			@IsMobile = @IsMobile,
			@IsExcluded = @IsExcluded,
			@DealIds = @DealIds,
			@StatusId = @StatusId,
			@UserId = @UserId,
			@IP = @IP,
			@ErrCode = @LandingPageErrCode OUTPUT,
			@ErrMsg = @LandingPageErrMsg OUTPUT;

		-- If Aff_Admin_LandingPage_Ins fails, propagate the error
		IF @LandingPageErrCode <> 0
		BEGIN
			SET @ErrCode = @LandingPageErrCode;
			SET @ErrMsg = @LandingPageErrMsg;
		END
	END

    DROP TABLE #ComponentStructure;
END;
GO
