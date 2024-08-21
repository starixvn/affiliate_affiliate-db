/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateStatus_Upd]
	@AffID		INT
	,@UserID	INT
	,@Status	VARCHAR(30)
	,@GroupID	INT = NULL
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000)	= '' OUTPUT
AS

/*
	Created: 20160614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Customer - Left menu - Update Affiliate's Status

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]
		- 20240828@Eddie: Add new permission for Manage Pending Affiliate [RedmineId : #209510]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US', @PermissionType SMALLINT = 0

	SELECT @ErrCode = 0, @ErrMsg = '', @Status = ISNULL(@Status, '')

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Affiliate]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
	BEGIN
		-- Check permission for Manage Pending Affiliate
		EXEC dbo.Aff_CheckPermission
			@CustId		= @UserId
			,@FuncName	= '[ManagePendingAffiliate]'
			,@ErrCode	= @ErrCode OUTPUT
			,@ErrMsg	= @ErrMsg OUTPUT

		IF @ErrCode <> 0
			RETURN

		SELECT @PermissionType = 1
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffID = @AffID)
	BEGIN
		-- Invalid Affiliate!
		SELECT @ErrCode = 1005, @ErrMsg = dbo.Aff_f_GetMessageById(304, @Language)
		RETURN
	END

	IF @Status NOT IN ('Pending', 'Approved', 'Disapproved')
	BEGIN
		-- Invalid input Status!
		SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(306, @Language)
		RETURN
	END

	-- For Log
	DECLARE @OldData NVARCHAR(4000), @NewData NVARCHAR(4000), @SPName VARCHAR(50), @Email NVARCHAR(50)

	SELECT  @OldData	= '<root><row Status="'+ ISNULL(CONVERT(VARCHAR(10), Status), '') +'"></row></root>'
			,@NewData	= '<root><row Status="'+ ISNULL(CONVERT(VARCHAR(10), @Status), '') +'"></row></root>'
			,@SPName	= OBJECT_NAME(@@PROCID)
			,@Email		= Email
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE AffID = @AffID

	IF @OldData = @NewData
		RETURN

	IF @Status = 'Approved' -- From Pending/Disapproved
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE Email = @Email AND Status = 'Approved' AND AffID <> @AffID)
		BEGIN
			-- Email Address has been used. Please choose another one!
			SELECT @ErrCode = 1007, @ErrMsg = dbo.Aff_f_GetMessageById(302, @Language)
			RETURN
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupID = @GroupID AND IsDeleted = 0)
		BEGIN
			-- Group is not existed
			SELECT @ErrCode = 1008, @ErrMsg = dbo.Aff_f_GetMessageById(1006, @Language)
			RETURN
		END
	END

	BEGIN TRY
		IF ISNULL(@PermissionType, 0) = 0
		BEGIN
			UPDATE dbo.AffInfo WITH (ROWLOCK)
			SET	Status = @Status
				,GroupID = ISNULL(@GroupID, GroupID)
				,ApprovedDate = CASE WHEN @Status IN ('Approved', 'Disapproved') THEN GETDATE() ELSE NULL END
				,CasinoJoinedDate = CASE WHEN @Status = 'Approved' AND CasinoJoinedDate IS NULL THEN CONVERT(DATE, GETDATE()) ELSE CasinoJoinedDate END
			WHERE AffID = @AffID
		END
		ELSE
		BEGIN
			UPDATE dbo.AffInfo WITH (ROWLOCK)
			SET	Status = @Status
				,GroupID = ISNULL(@GroupID, GroupID)
				,ApprovedDate = CASE WHEN @Status IN ('Approved', 'Disapproved') THEN GETDATE() ELSE NULL END
				,CasinoJoinedDate = CASE WHEN @Status = 'Approved' AND CasinoJoinedDate IS NULL THEN CONVERT(DATE, GETDATE()) ELSE CasinoJoinedDate END
			WHERE AffID = @AffID AND Status = 'Pending'
		END
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 1008, @ErrMsg = dbo.Aff_f_GetMessageById(1006, @Language)
		RETURN
	END CATCH

	-- Write Log
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffID,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO