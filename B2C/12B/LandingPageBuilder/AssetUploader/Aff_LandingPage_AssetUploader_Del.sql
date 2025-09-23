/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_AssetUploader_Del]
	@UserId			INT
	,@MediaIds		VARCHAR(MAX)
	,@IP			VARCHAR(50) = ''
    ,@FunctionName  VARCHAR(50) = '[AssetUploader]'
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20250826@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Landing Page - Asset Uploader - Delete Assets (Delete records from LandingPage_MediaGallery table)        
          Admin - Marketing Tools - Registration Form Management - Delete Registration  
          
    Revisions:
		- 20250826@Sally: Initialize SP [RedmineID: #236797]

    Param's Explanation:
        Input: 
            - @UserId	-- UserId of the user who is performing this action
            - @MediaIds	-- Comma separated MediaId list to be deleted
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
        EXEC dbo.Aff_LandingPage_AssetUploader_Del
            @UserId     = 1000000003
            ,@MediaIds  = '1,2,3'
            ,@FunctionName = '[AssetUploader]'
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

	DECLARE @tblMediaInfo TABLE (MediaId INT, IsValid BIT)

	BEGIN TRY
		INSERT INTO @tblMediaInfo (MediaId, IsValid)
		SELECT CONVERT(INT, s.value), CASE WHEN m.MediaId IS NULL THEN 0 ELSE 1 END
		FROM STRING_SPLIT (@MediaIds, ',') s
			LEFT JOIN dbo.LandingPage_MediaGallery m WITH (NOLOCK) ON CONVERT(INT, s.value) = m.MediaId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 407, @ErrMsg = 'Sorry, your input media id is invalid. Please recheck it again.'
		RETURN
	END CATCH

    IF NOT EXISTS (SELECT 1 FROM @tblMediaInfo)
        OR EXISTS (SELECT 1 FROM @tblMediaInfo WHERE IsValid = 0)
        BEGIN
            SELECT @ErrCode = 407, @ErrMsg = 'Sorry, your input media id is invalid. Please recheck it again.'
            RETURN
        END

    -- Check if any MediaId exists in LandingPage_BuilderDetail
    DECLARE @DependentMediaNames NVARCHAR(MAX) = NULL
    
    ;WITH MediaIdsInUse AS (
        SELECT DISTINCT lbd.MediaId AS MediaId
        FROM LandingPage_Builder lb WITH (NOLOCK)
            INNER JOIN LandingPage_BuilderDetail lbd WITH (NOLOCK) ON lb.PageId = lbd.PageId
            INNER JOIN @tblMediaInfo mi ON lbd.MediaId = mi.MediaId
    )
    SELECT @DependentMediaNames = STRING_AGG(CAST(mg.MediaName AS VARCHAR(MAX)), ', ')
    FROM @tblMediaInfo mi
        INNER JOIN MediaIdsInUse miu ON mi.MediaId = miu.MediaId
        INNER JOIN LandingPage_MediaGallery mg WITH (NOLOCK) ON mi.MediaId = mg.MediaId

    IF @DependentMediaNames IS NOT NULL
    BEGIN
        SELECT @ErrCode = 411, @ErrMsg = CONCAT('Cannot delete media file(s) as they are currently being used in landing page settings: ', @DependentMediaNames, '. Please remove them from the landing page configuration first.')
        RETURN
    END

    -- Capture detailed old data in JSON format
    DECLARE @OldData NVARCHAR(MAX)
    
    SELECT @OldData = (
        SELECT (
            SELECT 
                m.MediaName AS fn,
                m.FileName AS f,
                ISNULL(lpm.ModuleName, '') AS m,
                m.Dimension AS d,
                ISNULL(tc.CountryName, '') AS tc,
                ISNULL(tc.MarketName, '') AS l,
                CASE m.StatusId 
                    WHEN 1 THEN 'Active'
                    WHEN 2 THEN 'Inactive'
                END AS st
            FROM dbo.LandingPage_MediaGallery m WITH (NOLOCK)
                LEFT JOIN dbo.LandingPage_Module lpm WITH (NOLOCK) ON m.ModuleId = lpm.ModuleId
                LEFT JOIN dbo.TargetCountry tc WITH (NOLOCK) ON m.TargetCountryCode = tc.CountryCode AND m.MarketId = tc.MarketId
                INNER JOIN @tblMediaInfo tmp ON tmp.MediaId = m.MediaId
            FOR JSON PATH
        ) AS ai
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    )

    BEGIN TRY
        DELETE m WITH (ROWLOCK, UPDLOCK)
        FROM dbo.LandingPage_MediaGallery m
        WHERE EXISTS (SELECT 1 FROM @tblMediaInfo tmp WHERE tmp.MediaId = m.MediaId)
    END TRY
    BEGIN CATCH
        SELECT @ErrCode = 412, @ErrMsg = 'Error occurs. Delete unsuccessfully.'
        RETURN
    END CATCH

	-- Write log
	DECLARE @EndTime DATETIME = GETDATE()
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime)

	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@IP		= @IP
		,@Language	= 'en-US'
		,@Duration	= @Duration
END
GO