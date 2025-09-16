/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_LandingPage_Component_Ins]
	@CreatorId   	INT
	,@ComponentName	VARCHAR(200)
	,@ComponentType	INT
	,@StatusId		TINYINT = 1 -- 1: Active, 2: Inactive
	,@IP 			VARCHAR(50) = ''
	,@ErrCode 		INT = 0 OUTPUT
	,@ErrMsg  		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20250916@Danny
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Marketing tools - Link generator

	Revisions:
		- 20250916@Danny: Initialize SP [RedmineID: #238498]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TimeZone 	 	TINYINT
		  , @CurrentDate 	DATETIME
		  , @Status 		NVARCHAR(50)
		  , @NewComponentId  INT
		  , @Language 	 	NVARCHAR(5) = 'en-US'
		  , @StartTime 	 	DATETIME = GETDATE()
		  , @EndTime 	 	DATETIME
		  , @Duration 		INT
		  , @SPName 	 	VARCHAR(200) = OBJECT_NAME(@@PROCID)
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
		
		IF ISNULL(@ComponentName, '') = ''
		BEGIN
			SELECT @ErrCode = 1001
			     , @ErrMsg = N'Component Name is required.';
			RETURN;
		END
		
		IF EXISTS ( SELECT 1 
					FROM dbo.LandingPage_Component WITH (NOLOCK) 
					WHERE ComponentName = @ComponentName AND ComponentType = @ComponentType )
		BEGIN
			SELECT @ErrCode = 1002
			     , @ErrMsg = N'This component name already exists. Please enter a different name.';
			RETURN;
		END
	END
	
	-- Get timezone
	SELECT @TimeZone = CONVERT(TINYINT, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'TimeZone';

	SELECT @CurrentDate = DATEADD(HOUR, @TimeZone, GETUTCDATE());
	
	BEGIN TRY
		INSERT INTO dbo.LandingPage_Component(ComponentName,  ComponentType, Creator, CreatedDate, UpdatedBy, UpdatedDate, StatusId)
		VALUES(@ComponentName, @ComponentType, @CreatorId, @CurrentDate, @CreatorId, @CurrentDate, @StatusId);
		
		SELECT @NewComponentId = SCOPE_IDENTITY();

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
			SELECT lc.ComponentId AS 'ci',
				 lc.ComponentName  AS 'cn',
				 lct.ComponentTypeName AS 'ctn',
				 CASE WHEN lc.StatusId = 1 THEN 'Active' ELSE 'Inactive' END AS 's'
			FROM LandingPage_Component lc WITH(NOLOCK)
			INNER JOIN LandingPage_ComponentType lct  WITH(NOLOCK) ON lc.ComponentType = lct.ComponentTypeId
			WHERE ComponentId = @NewComponentId
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
	);

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId    = @CreatorId
		,@AffId    = 0
		,@SPName   = @SPName
		,@NewData  = @NewData
		,@IP   	   = @IP
		,@Language = @Language
		,@Duration = @Duration;

END
GO
