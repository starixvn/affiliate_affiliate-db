/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_AssetUploader_Status_Upd]
	@UserId			INT
	,@MediaIds		VARCHAR(MAX)
    ,@StatusId		INT         = 1 -- 1: Active, 2: Inactive
    ,@FunctionName   VARCHAR(50) = '[AssetUploader]'
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20250826@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Landing Page - Asset Uploader - Add Assets (Update records to LandingPage_MediaGallery table)        
		  Admin - Marketing Tools - Registration Form Management - Change Status of Registration
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
            ,@StatusId	-- 1: Active, 2: Inactive

        Output:
            - @ErrCode	-- 0: Success; <>0: Failed (Error Code)
            - @ErrMsg	-- Error message


    Sample Execution:
        DECLARE @ErrCode INT = 0 
            ,@ErrMsg VARCHAR(4000) = '' 
        EXEC dbo.Aff_LandingPage_AssetUploader_Status_Upd
            @UserId = 1000000003
			,@MediaIds  = '1'
			,@StatusId  = 2
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

	DECLARE @tmpMediaInfo TABLE (MediaId INT, IsValid BIT)
	DECLARE @CurentDateTime DATETIME = NULL

	SELECT @CurentDateTime = DATEADD(HOUR, 8, GETUTCDATE()) -- GMT+8

	BEGIN TRY
		INSERT INTO @tmpMediaInfo (MediaId, IsValid)
		SELECT CONVERT(INT, s.value), CASE WHEN m.MediaId IS NULL THEN 0 ELSE 1 END
		FROM STRING_SPLIT (@MediaIds, ',') s
			LEFT JOIN dbo.LandingPage_MediaGallery m WITH (NOLOCK) ON CONVERT(INT, s.value) = m.MediaId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 407, @ErrMsg = 'Sorry, your input media id is invalid. Please recheck it again.'
		RETURN
	END CATCH

    DECLARE @OldData NVARCHAR(MAX)
    SET @OldData = (
		SELECT (
			SELECT 
				m.MediaName	  AS fn,
				m.FileName	  AS f,
				CASE m.StatusId 
					WHEN 1 THEN 'Active'
					WHEN 2 THEN 'Inactive'
				END AS st
			FROM dbo.LandingPage_MediaGallery m WITH (NOLOCK)
				INNER JOIN @tmpMediaInfo tmp ON tmp.MediaId = m.MediaId
			FOR JSON PATH
		) AS ai
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	)

	BEGIN TRY
		UPDATE m
		SET StatusId		= @StatusId
			,UpdatedBy		= @UserId
			,UpdatedDate	= @CurentDateTime
		FROM dbo.LandingPage_MediaGallery m WITH (ROWLOCK, UPDLOCK)
			INNER JOIN @tmpMediaInfo t ON t.MediaId = m.MediaId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 408, @ErrMsg = 'Error occurs. Update unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @EndTime DATETIME = GETDATE()
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime)

	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SET @NewData = (
		SELECT (
			SELECT 
				m.MediaName	  AS fn,
				m.FileName	  AS f,
				CASE @StatusId 
					WHEN 1 THEN 'Active'
					WHEN 2 THEN 'Inactive'
					ELSE 'Unknown'
				END AS st
			FROM dbo.LandingPage_MediaGallery m WITH (NOLOCK)
				INNER JOIN @tmpMediaInfo tmp ON tmp.MediaId = m.MediaId
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
END
GO