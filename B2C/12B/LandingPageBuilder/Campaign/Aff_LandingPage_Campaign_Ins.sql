/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_LandingPage_Campaign_Ins]
	@UserId   	    INT
	,@CampaignName	VARCHAR(500)
	,@Description	VARCHAR(500) = ''
	,@StatusId		TINYINT = 0 -- Draft
	,@IP 			VARCHAR(50) = ''
	,@CampaignId    INT = 0 OUTPUT
	,@ErrCode 		INT = 0 OUTPUT
	,@ErrMsg  		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20250903@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Marketing tools - All Campaign - Add new campaign

	Revisions:
		- 20250903@Eddie: Initialize SP [RedmineID: #236797]
		- 20250917@Sophia: Added @CampaignId output parameter [RedmineID: #236797]

	Param's Explanation:
		@CampaignId: Returns the ID of the newly inserted campaign
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TimeZone 	 	TINYINT
		  , @CurrentDate 	DATETIME
		  , @Status 		NVARCHAR(50)
		  , @NewCampaignId  INT
		  , @CampaignCode   VARCHAR(100)
		  , @Language 	 	NVARCHAR(5) = 'en-US'
		  , @StartTime 	 	DATETIME = GETDATE()
		  , @EndTime 	 	DATETIME
		  , @Duration 		INT
		  , @SPName 	 	VARCHAR(200) = OBJECT_NAME(@@PROCID)
		  , @NewData 	 	NVARCHAR(MAX);
	
	--Check permission
	EXEC dbo.Aff_Con_CheckPermission @CustID = @UserId
									,@FuncName = '[AllCampaigns]'
									,@ErrCode = @ErrCode OUTPUT
									,@ErrMsg = @ErrMsg OUTPUT;
	
	IF @ErrCode <> 0
		RETURN;
	
	-- Validate input
	BEGIN
		SELECT @CampaignName = LTRIM(RTRIM(@CampaignName));

		SELECT @Description = LTRIM(RTRIM(@Description));
		
		IF ISNULL(@CampaignName, '') = ''
		BEGIN
			SELECT @ErrCode = 1001
			     , @ErrMsg = N'Campaign Name is required.';
			RETURN;
		END
		
		IF EXISTS ( SELECT 1 FROM dbo.LandingPage_Campaign WITH (NOLOCK) WHERE CampaignName = @CampaignName )
		BEGIN
			SELECT @ErrCode = 1002
			     , @ErrMsg = N'This campaign name already exists. Please enter a different name.';
			RETURN;
		END
	END
	
	-- Get status name
	SELECT @Status = Status
	FROM dbo.Aff_f_LandingPage_Campaign_Status()
	WHERE StatusId = @StatusId

	-- Get timezone
	SELECT @TimeZone = CONVERT(TINYINT, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'TimeZone';

	SELECT @CurrentDate = DATEADD(HOUR, @TimeZone, GETUTCDATE());
	
	BEGIN TRY
		INSERT INTO dbo.LandingPage_Campaign(CampaignName, Description, Creator, CreatedDate, UpdatedBy, UpdatedDate, StatusId)
		VALUES(@CampaignName, @Description, @UserId, @CurrentDate, @UserId, @CurrentDate, @StatusId);
		
		SELECT @NewCampaignId = SCOPE_IDENTITY();
		SET @CampaignId = @NewCampaignId; -- Set output parameter
		
		UPDATE cp WITH (ROWLOCK, UPDLOCK)
		SET CampaignCode = CONCAT('CAM_', FORMAT(@CurrentDate, 'yyyyMMdd'), '_', @NewCampaignId),
			@CampaignCode = CampaignCode
		FROM dbo.LandingPage_Campaign cp
		WHERE CampaignId = @NewCampaignId;
		
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 1010
			 , @ErrMsg = N'Error occurs. Insert unsuccessfully.';
		RETURN;
	END CATCH
	
	-- Write log
	SELECT @EndTime = GETDATE();
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime);

	SELECT @NewData = (
			SELECT @NewCampaignId AS 'ci'
				  ,@CampaignCode  AS 'cc'
				  ,@CampaignName  AS 'cn'
				  ,@Description   AS 'd'
				  ,@Status 		  AS 'st'
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
	);

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId    = @UserId
		,@AffId    = 0
		,@SPName   = @SPName
		,@NewData  = @NewData
		,@IP   	   = @IP
		,@Language = @Language
		,@Duration = @Duration;

END
GO