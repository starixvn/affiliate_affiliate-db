/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Deal_Ins]
(
	@DealId INT,
	@UserId INT,
	@IP VARCHAR(50) = '',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(MAX) = '' OUTPUT
)
AS
/*
	Created: 20250825@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Insert Landing Page Deal

	Revisions:  
		- 20250825@Sophia: Initialize SP [RedmineID: #236797]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @Language NVARCHAR(5) = 'en-US'
	DECLARE @Duration INT
	DECLARE @StartTime DATETIME = GETDATE()
	DECLARE @NewData NVARCHAR(MAX)

	-- =========================
	-- Check permission
	-- =========================
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[ComponentManagement]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Get Deal Name from CommGroup
	DECLARE @DealName NVARCHAR(100)
	SELECT @DealName = GroupName
	FROM CommGroup WITH (NOLOCK)
	WHERE GroupId = @DealId AND IsDeleted = 0

	IF @DealName IS NULL OR @DealName = ''
	BEGIN
		SET @ErrCode = 101
		SET @ErrMsg = N'Deal ID does not exist or has been deleted.'
		RETURN
	END

	-- Check if DealId already exists in LandingPage_Deal 
	IF EXISTS (SELECT 1 FROM LandingPage_Deal WITH (NOLOCK) WHERE DealId = @DealId )
	BEGIN
		SET @ErrCode = 102
		SET @ErrMsg = N'Deal already exists.'
		RETURN
	END

	-- Insert new deal into LandingPage_Deal table
	INSERT INTO LandingPage_Deal 
	(
		DealId,
		Creator,
		CreatedDate,
		StatusId
	)
	VALUES
	(
		@DealId,
		@UserId,
		DATEADD(HOUR, 8, GETUTCDATE()), -- GMT+8
		1
	)

	-- =========================
	-- Write log
	-- =========================
	DECLARE @EndTime DATETIME = GETDATE()
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime)

	-- Compose @NewData JSON
	SELECT @NewData = (
		SELECT @DealId AS 'd'
			  ,@DealName AS 'dn'
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
	);

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT @SPName = OBJECT_NAME(@@PROCID)
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language,
		@Duration	= @Duration
END
