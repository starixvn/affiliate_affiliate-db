/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_AssetUploader_ManageSel]
	@UserId			INT
	,@MediaId		INT	= 0
	,@ModuleIds		 	 VARCHAR(MAX) = NULL
	,@MediaName			 VARCHAR(200) = NULL
	,@TargetCountrycodes VARCHAR(MAX) = 'all'
	,@MarketIds  		 VARCHAR(MAX) = 'all'
	,@StatusId		INT = -1
	,@FunctionName	VARCHAR(50)	   = '[AssetUploader]'
	,@PageIndex		INT = 1
	,@PageSize		INT = 20
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20250826@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Marketing Tools - Asset Uploader - Select
		  Admin - Marketing Tools - Registration Form Management - Select
		  
    Revisions:
		- 20250826@Sally: Initialize SP [RedmineID: #236797]

    Param's Explanation:
        Input: 
            - @ModuleIds	-- TargetId in MediaGallery table,	'0': means all modules
                1	Background
                2	Logo & Sponsorship
                3	Logo Sponsorship & Register
                4	Hero Image
                5	CTA Button
                6	Promo List
                7	Favorite Games
                8	Youtube
                9	Registration Form
                10	Payment Method
                11	Provider
                12	Contact Us
                13	License & Awards
                14	Login

            - @TargetCountrycodes -- Target country code for the media assets,  'all': means all markets
            - @MarketIds	-- Market identifier for the media assets,  'all': means all markets
            - @FunctionName -- Function name for permission check, default is [AssetUploader]
                + [AssetUploader]
                + [RegistrationFormUploader]
            - @StatusId	-- StatusId to be filtered, -1: All, 0: Inactive, 1: Active
			- @ModuleId	-- ModuleId to be filtered
			- @PageIndex	-- Page index for pagination, default is 1
			- @PageSize	-- Page size for pagination, default is 20
        Output:
            - @ErrCode	-- 0: Success; <>0: Failed (Error Code)
            - @ErrMsg	-- Error message

    Sample Execution:
		DECLARE @ErrCode INT = 0 
			,@ErrMsg VARCHAR(4000) = '' 
			,@NRows INT = 0
		EXEC dbo.Aff_LandingPage_AssetUploader_ManageSel
			@UserId = 1000000003
			,@MediaId			= 0
			,@ModuleIds  		= '1,2,3,4,5,6,7,10,11,12,13,14'
			,@TargetCountrycodes = 'all'
			,@MarketIds  		= 'all'
			,@StatusId	= 1
			,@FunctionName = '[AssetUploader]'
			,@PageIndex	= 1
			,@PageSize	= 20
			,@NRows		= @NRows OUTPUT

	SELECT @NRows AS NRows

*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #TempLandingPage_MediaGallery
	(
		MediaId			INT PRIMARY KEY,
		MediaName		VARCHAR(200),
		FileName		VARCHAR(200),
		ModuleId		INT,
		Dimension		VARCHAR(20),
		StatusId		TINYINT,
		TargetCountrycode VARCHAR(50),
		MarketId  		VARCHAR(50),
		UpdatedDate		DATETIME,
		RowNum			INT
	)
	INSERT INTO #TempLandingPage_MediaGallery
		(MediaId, MediaName, FileName, ModuleId, Dimension, StatusId, TargetCountrycode, MarketId, UpdatedDate, RowNum)
	SELECT MediaId
		,MediaName
		,FileName
		,ModuleId
		,Dimension
		,StatusId
		,TargetCountryCode
		,MarketId
		,ISNULL(UpdatedDate, CreatedDate) AS UpdatedDate
		,ROW_NUMBER() OVER (ORDER BY MediaId DESC) AS RowNum
	FROM dbo.LandingPage_MediaGallery m WITH (NOLOCK)
	WHERE (@MediaId = 0 OR m.MediaId = @MediaId)
		AND (@ModuleIds IS NULL OR ',' + @ModuleIds + ',' LIKE '%,' + CAST(ModuleId AS VARCHAR(10)) + ',%' )
		AND (@TargetCountrycodes = 'all' OR ',' + @TargetCountryCodes + ',' LIKE '%,' + m.TargetCountryCode + ',%')
		AND (@MarketIds = 'all'  OR ',' + @MarketIds + ',' LIKE '%,' + m.MarketId + ',%')
		AND (@StatusId = -1 OR m.StatusId = @StatusId)
		AND (@MediaName IS NULL OR m.MediaName LIKE '%' + @MediaName + '%')
	SELECT @NRows = COUNT(1) FROM #TempLandingPage_MediaGallery

	-- Pagination
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1
		,@RowEnd = @RowStart + @PageSize - 1

	;WITH CTE AS (
		SELECT MediaId
		FROM #TempLandingPage_MediaGallery
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	)
	SELECT m.MediaId
		,m.MediaName
		,m.FileName
		,m.ModuleId
		,lm.ModuleName
		,m.Dimension
		,m.StatusId
		,m.TargetCountrycode
		,tc.CountryName AS TargetCountryName
		,m.MarketId
		,tc.MarketName
		,m.UpdatedDate
		,ISNULL(f.IsMediaIdInUse, 0) AS IsMediaIdInUse
	FROM #TempLandingPage_MediaGallery m
		INNER JOIN CTE c ON m.MediaId = c.MediaId
		INNER JOIN dbo.TargetCountry tc WITH (NOLOCK) ON m.TargetCountryCode = tc.CountryCode AND m.MarketID = tc.MarketID
		INNER JOIN dbo.LandingPage_Module lm WITH (NOLOCK) ON m.ModuleId = lm.ModuleId
		OUTER APPLY (
			SELECT TOP 1 1 AS IsMediaIdInUse 
			FROM dbo.LandingPage_BuilderDetail fbd WITH (NOLOCK)
			INNER JOIN dbo.LandingPage_Builder lb WITH (NOLOCK) ON fbd.PageId = lb.PageId
			WHERE fbd.MediaId = m.MediaId
		) f
	ORDER BY RowNum
	
	DROP TABLE #TempLandingPage_MediaGallery
END
GO