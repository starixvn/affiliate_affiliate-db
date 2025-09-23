/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_AssetUploader_Ins]
	@UserId			INT
	,@Files			XML
	,@ModuleId		INT
	,@TargetCountrycode VARCHAR(50) = ''
	,@MarketId  		VARCHAR(50) = ''
	,@FunctionName	VARCHAR(50) = '[AssetUploader]'
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20250826@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Marketing Tools - Asset Uploader - Add
		  Admin - Marketing Tools - Registration Form Management - Add Registration  

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
            - @TargetCountrycode -- Target country code for the media assets
            - @MarketId	-- Market identifier for the media assets
            - @IP		-- IP address of the user who is performing this action
            - @FunctionName -- Function name for permission check, default is [AssetUploader]
                + [AssetUploader]
                + [RegistrationFormUploader]
            
        Output:
            - @ErrCode	-- 0: Success; <>0: Failed (Error Code)
            - @ErrMsg	-- Error message

    Sample Execution:
        DECLARE @ErrCode INT = 0 
            ,@ErrMsg VARCHAR(4000) = '' 
        EXEC dbo.Aff_LandingPage_AssetUploader_Ins
            @UserId = 1000000003
            ,@Files = N'<root>
                            <row MediaName="983258e4-20ac-4666-98fc-e507f830bc1b" FileName="Asset/LogoSponsorship/983258e4-20ac-4666-98fc-e507f830bc1b.jpg" Dimension="676x1200"/>
                            <row MediaName="84fa053d-0bd0-4971-b0ce-aa64f3d880f9" FileName="Asset/LogoSponsorship/84fa053d-0bd0-4971-b0ce-aa64f3d880f9.jpg" Dimension="735x776"/>
                        </root>'
            ,@ModuleId  		= 2
            ,@TargetCountrycode = 'VN'
            ,@MarketId 			= 'vi-VN'
            ,@IP        = '10.0.0.112'
            ,@ErrCode   = @ErrCode OUTPUT
            ,@ErrMsg    = @ErrMsg OUTPUT

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Duration INT
	DECLARE @StartTime DATETIME = GETDATE()

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId
		,@FuncName	= @FunctionName
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE @tblMediaInfo TABLE (MediaName VARCHAR(200), FileName VARCHAR(200), Dimension VARCHAR(20), FileNameNoPath VARCHAR(200))
    DECLARE @tblMediaCode TABLE (RowNum INT IDENTITY(1,1), MediaId INT, MediaCode VARCHAR(10))

	DECLARE @DuplicateImages VARCHAR(MAX)  = NULL
        ,@DuplicateMediaNames VARCHAR(MAX) = NULL
		,@StatusId TINYINT 				   = 1 -- Default to Active
		,@CurentDateTime DATETIME		   = NULL
		,@ModuleName VARCHAR(200)		   = ''
		,@CountryName VARCHAR(100)		   = ''
		,@MarketName VARCHAR(100)		   = ''
		,@batchSize INT				   	   = 0

	SELECT @CurentDateTime = DATEADD(HOUR, 8, GETUTCDATE()) -- GMT+8

	SELECT @ModuleName = ModuleName 
	FROM dbo.LandingPage_Module WITH (NOLOCK) 
	WHERE ModuleId = @ModuleId
	
	SELECT @CountryName = CountryName, @MarketName = MarketName
	FROM dbo.TargetCountry WITH (NOLOCK) 
	WHERE CountryCode = @TargetCountrycode AND MarketId = @MarketId

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

	-- Check input params	
	IF NOT EXISTS (SELECT 1 FROM dbo.TargetCountry WITH (NOLOCK) WHERE CountryCode = @TargetCountrycode AND MarketId = @MarketId)
	BEGIN
		SELECT @ErrCode = 412, @ErrMsg = 'The selected language is not valid for the chosen country. Please select a supported language.'
		RETURN
	END

	IF (SELECT COUNT(1) FROM @tblMediaInfo) > 50
	BEGIN
		SELECT @ErrCode = 402, @ErrMsg = 'Upload limit exceeded. You can only upload up to 50 files at a time.'
		RETURN
	END

    -- Check Duplicate FileName
    ;WITH CTE_FileNames AS (
        SELECT FileNameNoPath, COUNT(1) AS Cnt
        FROM @tblMediaInfo
        GROUP BY FileNameNoPath
        HAVING COUNT(1) > 1
    )
    SELECT @DuplicateImages = STRING_AGG(CAST(FileNameNoPath AS VARCHAR(MAX)), ', ')
    FROM CTE_FileNames
    OPTION (MAXRECURSION 0);

	IF ISNULL(@DuplicateImages, '') <> ''
	BEGIN
		SELECT @ErrCode = 403, @ErrMsg = CONCAT('Duplicate file name(s) detected: ', @DuplicateImages,'. Please rename or remove the file (s). before uploading.')
		RETURN
	END

    -- Check Duplicate MediaName
    ;WITH CTE_MediaNames AS (
        SELECT MediaName, COUNT(1) AS Cnt
        FROM @tblMediaInfo
        GROUP BY MediaName
        HAVING COUNT(1) > 1
    )
    SELECT @DuplicateMediaNames = STRING_AGG(CAST(MediaName AS VARCHAR(MAX)), ', ')
    FROM CTE_MediaNames
    OPTION (MAXRECURSION 0);

	IF ISNULL(@DuplicateMediaNames, '') <> ''
	BEGIN
		SELECT @ErrCode = 404, @ErrMsg = CONCAT('Duplicate Form name(s) detected: ', @DuplicateMediaNames,'. Please rename or remove the file(s). before uploading.')
		RETURN
	END

    -- Check if FileName or MediaName already exists
	DECLARE @ExistedFileName NVARCHAR(MAX)
        ,@ExistedMediaName   NVARCHAR(MAX)

	;WITH CTE_ExistedFileName AS(
		SELECT DISTINCT f.FileNameNoPath
		FROM dbo.LandingPage_MediaGallery m WITH (NOLOCK)			
			CROSS APPLY (
				SELECT TOP 1 val AS FileNameNoPath FROM dbo.Aff_f_StringSplit(m.FileName, '/')
				ORDER BY Id DESC
			) f
			INNER JOIN @tblMediaInfo b ON b.FileNameNoPath = f.FileNameNoPath
	) 
	SELECT @ExistedFileName = STRING_AGG(CAST(FileNameNoPath AS VARCHAR(MAX)), ', ') 
	FROM CTE_ExistedFileName
	OPTION (MAXRECURSION 0);

	IF ISNULL(@ExistedFileName, '') <> ''
	BEGIN
		SELECT @ErrCode = 405, @ErrMsg =  CONCAT('File name(s) already exists: ', @ExistedFileName, '. Please rename or remove the file(s). before uploading.')
		RETURN
	END

	;WITH CTE_ExistedMediaName AS(
		SELECT DISTINCT b.MediaName
		FROM dbo.LandingPage_MediaGallery m WITH (NOLOCK)
			INNER JOIN @tblMediaInfo b ON b.MediaName = m.MediaName
	)
	SELECT @ExistedMediaName = STRING_AGG(CAST(MediaName AS VARCHAR(MAX)), ', ')
	FROM CTE_ExistedMediaName
	OPTION (MAXRECURSION 0);

	IF ISNULL(@ExistedMediaName, '') <> ''
	BEGIN
		SELECT @ErrCode = 406, @ErrMsg = CONCAT('Form name(s) already exists: ', @ExistedMediaName, '. Please rename or remove the file(s). before uploading.')
		RETURN
	END

	-- Insert data
	BEGIN TRY
		INSERT INTO dbo.LandingPage_MediaGallery (MediaName, FileName, ModuleId, Dimension, TargetCountryCode, MarketId, StatusId, Creator, CreatedDate)
		OUTPUT INSERTED.MediaId INTO @tblMediaCode (MediaId)
		SELECT MediaName, FileName, @ModuleId, Dimension, @TargetCountrycode, @MarketId, @StatusId, @UserId, @CurentDateTime
		FROM @tblMediaInfo t

		IF (@ModuleId = 9) -- Registration Form
		BEGIN
			-- Get MediaCode
			SET @batchSize = (SELECT COUNT(1) FROM @tblMediaCode)

			;WITH CTE_GenerateMediaCode AS (
				SELECT TOP(@batchSize) 
				   	MediaCodeId,			
					MediaCode,
					MediaId,
					ROW_NUMBER() OVER (ORDER BY MediaCodeId ASC) AS RowNumm
				FROM dbo.LandingPage_MediaCode WITH (NOLOCK)
				WHERE MediaId IS NULL
				ORDER BY MediaCodeId ASC
			)
			UPDATE t 
			SET t.MediaId = mc.MediaId
			FROM dbo.LandingPage_MediaCode t WITH (ROWLOCK, UPDLOCK)
				INNER JOIN CTE_GenerateMediaCode ct ON ct.MediaCodeId = t.MediaCodeId
				INNER JOIN @tblMediaCode mc ON ct.RowNumm = mc.RowNum

			-- Update MediaCode in LandingPage_MediaGallery
			UPDATE mg
			SET mg.MediaCode = mc.MediaCode
			FROM dbo.LandingPage_MediaGallery mg WITH (ROWLOCK, UPDLOCK)
				INNER JOIN LandingPage_MediaCode mc WITH (NOLOCK) ON mg.MediaId = mc.MediaId
			WHERE EXISTS (SELECT 1 FROM @tblMediaCode t WHERE mg.MediaId = t.MediaId)

		END
	END TRY
	BEGIN CATCH
		-- Rollback data
		DELETE m 
		FROM dbo.LandingPage_MediaGallery m WITH (ROWLOCK)
		WHERE EXISTS (SELECT 1 FROM @tblMediaCode t WHERE m.MediaId = t.MediaId)

		IF (@ModuleId = 9) -- Registration Form
		BEGIN
			UPDATE mc
			SET mc.MediaId = NULL
			FROM dbo.LandingPage_MediaCode mc WITH (ROWLOCK, UPDLOCK)
			WHERE EXISTS (SELECT 1 FROM @tblMediaCode t WHERE mc.MediaId = t.MediaId)
		END

		SELECT @ErrCode = 105, @ErrMsg = 'Error occurs. Insert unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @EndTime DATETIME = GETDATE()
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime)

	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX) = NULL
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
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= 'en-US',
		@Duration	= @Duration
END
GO