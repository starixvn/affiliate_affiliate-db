/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_CommGroup_Assign]
	@UserId		INT,
	@AffId		INT,
	@GroupId	INT,
	@IP			VARCHAR(50) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Customer - Left menu - Assign commission group
	
	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250526@Lewis: Apply FromDate - ToDate [RedmineID: #228530]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	DECLARE @Duration INT
	DECLARE @StartTime DATETIME = GETDATE()

	DECLARE @CurrentDate DATETIME = DATEADD(HOUR, 12, GETDATE())
	DECLARE @ActionDate DATETIME =  CAST(@CurrentDate AS DATE)
			, @ToDate DATETIME = '9999-12-31'

	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[RevenueGroup]',
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
	SELECT  @OldGroupId = GroupId FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId

	IF ISNULL(@OldGroupId, 0) = @GroupId
	BEGIN
		RETURN
	END

	DECLARE @MonthDate SMALLDATETIME
	SELECT  @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

	BEGIN TRY
		UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
		SET GroupId = @GroupId
		WHERE AffId = @AffId

		IF EXISTS (SELECT 1 FROM dbo.AffGroupHistory WITH (NOLOCK) WHERE AffId = @AffId AND MonthDate = @MonthDate)
		BEGIN
			UPDATE dbo.AffGroupHistory WITH (ROWLOCK, UPDLOCK)
			SET GroupId = @GroupId
			WHERE AffId = @AffId AND MonthDate = @MonthDate
		END
		ELSE
		BEGIN
			INSERT INTO dbo.AffGroupHistory (AffId, GroupId, MonthDate)
				VALUES (@AffId, @GroupId, @MonthDate)
		END
	END TRY
	BEGIN CATCH
		-- Rollback manually
		UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
		SET GroupId = @OldGroupId
		WHERE AffId = @AffId

		UPDATE dbo.AffGroupHistory WITH (ROWLOCK, UPDLOCK)
		SET GroupId = @OldGroupId
		WHERE AffId = @AffId AND MonthDate = @MonthDate

		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
		RETURN
	END CATCH

	-- Write log
	DECLARE @EndTime DATETIME = GETDATE()
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime)
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData = 'GroupId=' + ISNULL(CONVERT(VARCHAR(20), @OldGroupId), ''),
			@NewData = 'GroupId=' + ISNULL(CONVERT(VARCHAR(20), @GroupId), '')

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