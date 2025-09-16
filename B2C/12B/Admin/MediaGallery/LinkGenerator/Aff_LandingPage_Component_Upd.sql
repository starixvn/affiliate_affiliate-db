/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_LandingPage_Component_Upd]
	@CreatorId   	INT
	,@ComponentId	INT
	,@ComponentType	INT
	,@ComponentName	VARCHAR(200)
	,@StatusId		TINYINT = 1 -- 1: Active, 2: Inactive
	,@IP 			VARCHAR(50) = ''
	,@ErrCode 		INT = 0 OUTPUT
	,@ErrMsg  		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20250916@Danny
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Marketing tools - All Campaign - Edit campaign

	Revisions:
		- 20250916@Danny: Initialize SP [RedmineID: #238498]

	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TimeZone 	 	TINYINT
		  , @CurrentDate 	DATETIME
		  , @Status 		NVARCHAR(50)
		  , @Language 	 	NVARCHAR(5) = 'en-US'
		  , @StartTime 	 	DATETIME = GETDATE()
		  , @EndTime 	 	DATETIME
		  , @Duration 		INT
		  , @SPName 	 	VARCHAR(200) = OBJECT_NAME(@@PROCID)
		  , @OldData 	 	NVARCHAR(MAX)
		  , @NewData 	 	NVARCHAR(MAX);
	
	--Check permission
	EXEC dbo.Aff_Con_CheckPermission @CustID = @CreatorId
									,@FuncName = '[AllComponents]'
									,@ErrCode = @ErrCode OUTPUT
									,@ErrMsg = @ErrMsg OUTPUT;
	
	IF @ErrCode <> 0
		RETURN;
	
	-- Validate input
	BEGIN
		SELECT @ComponentName = LTRIM(RTRIM(@ComponentName));

		IF @ComponentName = ''
		BEGIN
			SELECT @ErrCode = 1001
			     , @ErrMsg = N'Component name is required.';
			RETURN;
		END
		
		IF EXISTS ( 
			SELECT 1 
			FROM dbo.LandingPage_Component WITH (NOLOCK) 
			WHERE ComponentName = @ComponentName AND ComponentId <> @ComponentId AND ComponentType = @ComponentType 
		)
		BEGIN
			SELECT @ErrCode = 1002
			     , @ErrMsg = N'This component name already exists. Please enter a different name.';
			RETURN;
		END
	END
	
	-- Old data for writing log
	SELECT @OldData = (
		SELECT lc.ComponentId AS 'ci',
				lc.ComponentName  AS 'cn',
				lct.ComponentTypeName AS 'ctn',
				CASE WHEN lc.StatusId = 1 THEN 'Active' ELSE 'Inactive' END AS 's'
		FROM LandingPage_Component lc WITH(NOLOCK)
		INNER JOIN LandingPage_ComponentType lct  WITH(NOLOCK) ON lc.ComponentType = lct.ComponentTypeId
		WHERE ComponentId = @ComponentId
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
	);

	-- Get timezone
	SELECT @TimeZone = CONVERT(TINYINT, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'TimeZone';

	SELECT @CurrentDate = DATEADD(HOUR, @TimeZone, GETUTCDATE());
	
	BEGIN TRY

		UPDATE cp WITH (ROWLOCK, UPDLOCK)
		SET 
			cp.ComponentName = @ComponentName
		   ,cp.ComponentType = @ComponentType
		   ,cp.UpdatedBy  	= @CreatorId
		   ,cp.UpdatedDate  = @CurrentDate
		   ,cp.StatusId     = IIF(@StatusId IS NULL, cp.StatusId, @StatusId)
		FROM dbo.LandingPage_Component cp
		WHERE cp.ComponentId = @ComponentId;

	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 1011
			 , @ErrMsg = N'Error occurs. Update unsuccessfully.';
		RETURN;
	END CATCH
	
	-- Write log
	SELECT @EndTime = GETDATE();
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime);

	SELECT @NewData = (
		SELECT lc.ComponentId AS 'ci',
			lc.ComponentName  AS 'cn',
			lct.ComponentTypeName AS 'ctn',
			CASE WHEN lc.StatusId = 1 THEN 'Active' ELSE 'Inactive' END AS 's'
		FROM LandingPage_Component lc WITH(NOLOCK)
		INNER JOIN LandingPage_ComponentType lct  WITH(NOLOCK) ON lc.ComponentType = lct.ComponentTypeId
		WHERE ComponentId = @ComponentId
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
	);
   
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId    = @CreatorId
		,@AffId    = 0
		,@SPName   = @SPName
		,@OldData  = @OldData
		,@NewData  = @NewData
		,@IP   	   = @IP
		,@Language = @Language
		,@Duration = @Duration;

END
GO
