/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Assign_Deal]
	@UserId		INT,
	@AffId		INT,
	@GroupId	INT,
	@IP			VARCHAR(50) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20250526@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Customer - Left menu - Assign Deal
	
	Revisions:
		- 20250526@Lewis: Init [RedmineID: #228530]
		- 20250916@Lewis: Enhance Write log [RedmineID: #238483]
		- 20251014@Lewis: Add 2 column related SubAff [RedmineID: #235601]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	DECLARE @Duration INT
	DECLARE @StartTime DATETIME = GETDATE()

	DECLARE @CurrentDate DATETIME = DATEADD(HOUR, 12, GETDATE())
	DECLARE @ActionDate DATETIME =  CAST(@CurrentDate AS DATE)
			, @ToDate DATETIME = '9999-12-31'

	DECLARE @ParentAffId INT
			,@AllParentAffId VARCHAR(MAX)

	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[Deal]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF ISNULL(@GroupId, 0) = 0 OR NOT EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupId = @GroupId AND IsDeleted = 0)
	BEGIN
		-- Group is not existed
		SELECT @ErrCode = 100, @ErrMsg = dbo.Aff_f_GetMessageById(1006, @Language)
		RETURN
	END

	DECLARE @OldGroupId INT
	SELECT  @OldGroupId = GroupId 
			,@ParentAffId = ParentAffId
			,@AllParentAffId = AllParentAffId
	FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId
	
	DECLARE @MonthDate SMALLDATETIME
	SELECT  @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDate) + 1, 0))

	IF ISNULL(@OldGroupId, 0) = @GroupId
	BEGIN
		RETURN
	END

	DECLARE @OldActionDate DATETIME = ''
	SELECT @OldActionDate = FromDate 
	FROM dbo.AffGroupHistory WITH (NOLOCK)
	WHERE AffId = @AffId
		AND GroupId = @OldGroupId
		AND MonthDate = @MonthDate
		AND ToDate = @ToDate

	--TODO: Assign Deal
	UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
	SET GroupId = @GroupId
	WHERE AffId = @AffId

	IF EXISTS (SELECT 1 FROM dbo.AffGroupHistory WITH (NOLOCK) WHERE AffId = @AffId AND MonthDate = @MonthDate AND FromDate = @ActionDate AND ToDate = @ToDate)
	BEGIN
		--Delete for all actions in 1 day for this affid
		DELETE dbo.AffGroupHistory WITH (ROWLOCK)
		WHERE AffId = @AffId AND MonthDate = @MonthDate AND FromDate = @ActionDate AND ToDate = @ToDate
	END

	IF EXISTS (SELECT 1 FROM dbo.AffGroupHistory WITH (NOLOCK) WHERE AffId = @AffId AND MonthDate = @MonthDate AND ToDate = @ToDate)
	BEGIN
		--Update Old
		UPDATE dbo.AffGroupHistory WITH (ROWLOCK, UPDLOCK)
		SET MonthDate = DATEADD(dd,-1,@ActionDate)
			,ToDate = DATEADD(dd,-1,@ActionDate)
		WHERE AffId = @AffId AND MonthDate = @MonthDate AND ToDate = @ToDate
	END

	--Insert New
	INSERT INTO dbo.AffGroupHistory (AffId, GroupId, MonthDate, ParentAffId, AllParentAffId, FromDate, ToDate)
	VALUES (@AffId, @GroupId, @MonthDate, @ParentAffId, @AllParentAffId, @ActionDate, @ToDate)

	-- Write log
	DECLARE @EndTime DATETIME = GETDATE()
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime)
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)


	-- Get Old Group Info & Format JSON
	SELECT @OldData = (
		SELECT 
			ISNULL(cg.GroupName, '') as dn,
			ISNULL(gt.GroupTypeName, '') as dt,
			ISNULL(@OldActionDate, '') as ad
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	)
	FROM dbo.CommGroup cg WITH (NOLOCK)
		INNER JOIN dbo.GroupType gt WITH (NOLOCK) ON cg.GroupTypeId = gt.GroupTypeId
	WHERE cg.GroupId = @OldGroupId

	-- Get New Group Info & Format JSON  
	SELECT @NewData = (
		SELECT 
			ISNULL(cg.GroupName, '') as dn,
			ISNULL(gt.GroupTypeName, '') as dt,
			ISNULL(@ActionDate, '') as ad
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	)
	FROM dbo.CommGroup cg WITH (NOLOCK)
		INNER JOIN dbo.GroupType gt WITH (NOLOCK) ON cg.GroupTypeId = gt.GroupTypeId
	WHERE cg.GroupId = @GroupId

	-- Wrap in 'da' object
	SELECT  @OldData = '{"da":' + ISNULL(@OldData, '') + '}',
			@NewData = '{"da":' + ISNULL(@NewData, '') + '}'

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language,
		@Duration	= @Duration
END
GO