/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_AssetUploader_Upd]
	@UserId			INT
    ,@MediaId		INT
	,@Files			XML
	,@ModuleId		INT
	,@TargetCountrycode VARCHAR(50) = ''
	,@MarketId  		VARCHAR(50) = ''
	,@FunctionName      VARCHAR(50) = '[AssetUploader]'
	,@IP			    VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20250826@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Landing Page - Asset Uploader - Add Assets    
		  Admin - Marketing Tools - Registration Form Management - Update Registration

    Revisions:
		- 20250826@Sally: Initialize SP [RedmineID: #236797]

    Param's Explanation:
        Input: 
            - @UserId	-- UserId of the user who is performing this action
            - @Files	-- XML format, contains FileName, Dimension and MediaName of each file
			- @ModuleId	-- TargetId in MediaGallery table
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

            - @IP		-- IP address of the user who is performing this action
			- @MediaId	-- MediaId to be updated
			- @TargetCountrycode -- Target country code for the media assets
			- @MarketId	-- Market identifier for the media assets
			- @FunctionName -- Function name for permission check, default is [AssetUploader]
				+ [AssetUploader]
				+ [RegistrationFormUploader]

        Output:
            - @ErrCode	-- 0: Success; <>0: Failed (Error Code)
            - @ErrMsg	-- Error message

    Sample Execution:
        DECLARE @ErrCode INT = 0 
            ,@ErrMsg VARCHAR(4000) = '' 
        EXEC dbo.Aff_LandingPage_AssetUploader_Upd
            @UserId = 1000000003
			,@MediaId = 1
			,@ModuleId = 2
            ,@Files = N'<root>
                            <row MediaName="983258e4-20ac-4666-98fc-e507f830bc1b" FileName="Asset/LogoSponsorship/983258e4-20ac-4666-98fc-e507f830bc1b.jpg" Dimension="676x1200"/>
                        </root>'
			,@TargetCountrycode = 'VN'
			,@MarketId  		= 'vi-VN'
            ,@IP        = '10.0.0.112'
            ,@ErrCode   = @ErrCode OUTPUT
            ,@ErrMsg    = @ErrMsg OUTPUT

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Duration INT
	DECLARE @StartTime DATETIME = GETDATE()

	DECLARE @OldData NVARCHAR(MAX)
		,@OldTargetCountryMarket VARCHAR(100) 	= NULL
		,@DependentMediaNames   VARCHAR(200) 	= NULL
		,@CurentDateTime DATETIME				= NULL

	SELECT @CurentDateTime = DATEADD(HOUR, 8, GETUTCDATE()) -- GMT+8

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId
		,@FuncName	= @FunctionName
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.LandingPage_MediaGallery m WITH (NOLOCK) WHERE m.MediaId = @MediaId)
		OR (@MediaId IS NULL)
	BEGIN
		SELECT @ErrCode = 407, @ErrMsg = 'Sorry, your input media id is invalid. Please recheck it again.'
		RETURN
	END

	-- Check input params
	IF NOT EXISTS (SELECT 1 FROM dbo.TargetCountry WITH (NOLOCK) WHERE CountryCode = @TargetCountrycode AND MarketId = @MarketId)
	BEGIN
		SELECT @ErrCode = 412, @ErrMsg = 'The selected language is not valid for the chosen country. Please select a supported language.'
		RETURN
	END

	-- Parse input XML
	DECLARE @tblMediaInfo TABLE (MediaName VARCHAR(200), FileName VARCHAR(200), Dimension VARCHAR(20), FileNameNoPath VARCHAR(200))

	BEGIN TRY
		INSERT INTO @tblMediaInfo (MediaName, FileName, Dimension)
		SELECT
            MediaName	=  t.c.value('@MediaName', 'VARCHAR(200)')
			,FileName	=  t.c.value('@FileName' , 'VARCHAR(200)')
			,Dimension	=  t.c.value('@Dimension', 'VARCHAR(20)')
		FROM @Files.nodes('root/row') AS t(c)
		OPTION (OPTIMIZE FOR (@Files = NULL))
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 401, @ErrMsg = 'Error occurs. Invalid input params.'
		RETURN
	END CATCH

	-- Get FileName without path
	UPDATE t
	SET t.FileNameNoPath = f.FileNameNoPath
	FROM @tblMediaInfo t
	CROSS APPLY (
		SELECT TOP 1 val AS FileNameNoPath FROM dbo.Aff_f_StringSplit(t.FileName, '/')
		ORDER BY Id DESC
	) f

    -- Check if FileName or MediaName already exists
	IF EXISTS(
		SELECT 1 
		FROM dbo.LandingPage_MediaGallery m WITH (NOLOCK)
			CROSS APPLY (
				SELECT TOP 1 val AS FileNameNoPath FROM dbo.Aff_f_StringSplit(m.FileName, '/')
				ORDER BY Id DESC
			) f
			INNER JOIN @tblMediaInfo b ON b.FileNameNoPath = f.FileNameNoPath
		WHERE m.MediaId <> @MediaId
	)
	BEGIN
		SELECT @ErrCode = 409, @ErrMsg =  'File name already exists. Please use another name.'
		RETURN
	END

	IF EXISTS(
		SELECT 1 
		FROM dbo.LandingPage_MediaGallery m WITH (NOLOCK)
			INNER JOIN @tblMediaInfo b ON b.MediaName = m.MediaName
		WHERE m.MediaId <> @MediaId
	)
	BEGIN
		SELECT @ErrCode = 410, @ErrMsg = 'Form name already exists. Please use another name.'
		RETURN
	END	

    SELECT @OldData = (
		SELECT (
			SELECT 
				m.MediaName	  AS fn,
				m.FileName	  AS f,
				ISNULL(lpm.ModuleName, '') AS m,	
				m.Dimension	  AS d,
				ISNULL(tc.CountryName, '') AS tc,
				ISNULL(tc.MarketName, '') AS l,
				CASE m.StatusId 
					WHEN 1 THEN 'Active'
					WHEN 2 THEN 'Inactive'
				END AS st
			FROM dbo.LandingPage_MediaGallery m WITH (NOLOCK)
				LEFT JOIN dbo.LandingPage_Module lpm WITH (NOLOCK) ON m.ModuleId = lpm.ModuleId
				LEFT JOIN dbo.TargetCountry tc WITH (NOLOCK) ON m.TargetCountryCode = tc.CountryCode AND m.MarketId = tc.MarketId
			WHERE m.MediaId = @MediaId
			FOR JSON PATH
		) AS ai
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	)
		,@OldTargetCountryMarket = CONCAT(m.ModuleId, '-', m.TargetCountryCode, '-', m.MarketId)
    FROM dbo.LandingPage_MediaGallery m WITH (NOLOCK)
	WHERE m.MediaId = @MediaId

    ;WITH MediaIdsInUse AS (
        SELECT DISTINCT lbd.MediaId AS MediaId
        FROM LandingPage_Builder lb WITH (NOLOCK)
            INNER JOIN LandingPage_BuilderDetail lbd WITH (NOLOCK) ON lb.PageId = lbd.PageId
		WHERE lbd.MediaId = @MediaId  
    )
    SELECT TOP 1 @DependentMediaNames = mg.MediaName
    FROM MediaIdsInUse miu
        INNER JOIN LandingPage_MediaGallery mg WITH (NOLOCK) ON miu.MediaId = mg.MediaId

    IF (@DependentMediaNames IS NOT NULL 
		AND (
			@OldTargetCountryMarket <> CONCAT(@ModuleId, '-', @TargetCountrycode, '-', @MarketId) 
		)
	)
    BEGIN
        SELECT @ErrCode = 411, @ErrMsg = 'This image has already been used in an existing landing page(s). You cannot update the Module, Target Country, or Language.'
        RETURN
    END

	BEGIN TRY
		UPDATE m
		SET MediaName		= t.MediaName
			,FileName		= t.FileName
			,Dimension		= t.Dimension
			,TargetCountryCode = @TargetCountrycode
			,MarketId		= @MarketId
			,ModuleId		= @ModuleId
			,UpdatedBy		= @UserId
			,UpdatedDate	= @CurentDateTime
		FROM dbo.LandingPage_MediaGallery m WITH (ROWLOCK, UPDLOCK)
			CROSS JOIN @tblMediaInfo t
		WHERE m.MediaId		= @MediaId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 408, @ErrMsg = 'Error occurs. Update unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @EndTime DATETIME = GETDATE()
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime)

	DECLARE @SPName VARCHAR(200)
		,@ModuleName VARCHAR(200)  = ''
		,@CountryName VARCHAR(100) = ''
		,@MarketName VARCHAR(100)  = ''

	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT @ModuleName = ModuleName 
	FROM dbo.LandingPage_Module WITH (NOLOCK) 
	WHERE ModuleId = @ModuleId
	
	SELECT @CountryName = CountryName, @MarketName = MarketName
	FROM dbo.TargetCountry WITH (NOLOCK) 
	WHERE CountryCode = @TargetCountrycode AND MarketId = @MarketId

	DECLARE @NewData NVARCHAR(MAX)
	SET @NewData = (
		SELECT (
				SELECT 
					s.MediaName	  AS fn,
					s.FileName	  AS f,
					@ModuleName	  AS m,	
					s.Dimension	  AS d,
					@CountryName  AS tc,
					@MarketName	  AS l,
					'Active' 	  AS st
				FROM @tblMediaInfo s 		
				FOR JSON PATH
		) AS ai
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= 'en-US',
		@Duration	= @Duration
	
	-- Update RowVersion of LandingPage_Builder
	DECLARE @PageIds VARCHAR(MAX) = NULL

	;WITH CTE_PageIds AS (
		SELECT DISTINCT lb.PageId
		FROM dbo.LandingPage_Builder lb WITH (NOLOCK)
			INNER JOIN dbo.LandingPage_BuilderDetail lbd WITH (NOLOCK) ON lb.PageId = lbd.PageId
		WHERE lbd.MediaId = @MediaId
	)
	SELECT @PageIds = STRING_AGG(CAST(lb.PageId AS VARCHAR(MAX)), ',')
	FROM CTE_PageIds lb

	IF (ISNULL(@PageIds, '') <>'')
	BEGIN
		EXEC dbo.Aff_LandingPage_Builder_RowVersion_Upd 
			@PageIds = @PageIds,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg  = @ErrMsg OUTPUT
			
		IF @ErrCode <> 0
		BEGIN
			SELECT @ErrCode = @ErrCode, @ErrMsg = 'Failed to update the version-referenced landing page. Please try again.'
			RETURN
		END
			
	END
END
GO