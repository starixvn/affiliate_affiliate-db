/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_EmailHistory_Del]
	@MIDs VARCHAR(4000) = NULL
	,@UserID	INT
	,@IP		VARCHAR(20) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Affiliate - Email History - Delete Email by list of ID

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

	Param's Explanation:
		- @MIDs: List of Mail ID
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'

	SELECT @MIDs = ISNULL(@MIDs, ''), @ErrCode = 0, @ErrMsg = ''

	IF @MIDs = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid mail ID!'
		RETURN
	END

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustID		= @UserID
		,@FuncName	= '[Affiliate]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.Affiliate_User WITH (NOLOCK) WHERE CustID = @UserID)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Sorry, Admin ID is invalid. Please recheck it again.'
		RETURN
	END
	-- End check permission

	DECLARE @tblMailID TABLE (MID INT NOT NULL PRIMARY KEY)
	INSERT INTO @tblMailID (MID)
	SELECT DISTINCT val FROM dbo.Aff_f_StringSplit (@MIDs, ',')
	OPTION(MAXRECURSION 0)

	IF EXISTS (
		SELECT 1
		FROM @tblMailID tmp
			OUTER APPLY (
				SELECT MID
				FROM dbo.EmailHistory e WITH (NOLOCK)
				WHERE tmp.MID = e.MID
					AND ISNULL(IsDeleted, 0) = 0
			) AS e
		WHERE e.MID IS NULL
	)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Sorry, your input mail id is invalid. Please recheck it again.'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.EmailHistory WITH (ROWLOCK, UPDLOCK)
		SET IsDeleted = 1
		WHERE MID IN (SELECT MID FROM @tblMailID)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 1001, @ErrMsg = 'Error! Email unsuccessfully deleted!'
		RETURN
	END CATCH

	-- Write Log
	DECLARE @LogData NVARCHAR(200), @SPName VARCHAR(50)
	SELECT	@LogData = 'Delete EmailHistory Mail ID list:' + @MIDs
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= @LogData,
		@NewData	= '',
		@IP			= @IP,
		@Language	= @Language
END
GO