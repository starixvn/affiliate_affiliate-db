/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Affiliate_Approved]
	@UserId		INT,
	@AffId		INT,
	@Password	NVARCHAR(40) = NULL,
	@Status		VARCHAR(30) = NULL,
	@IP			VARCHAR(50),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS  

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin site - Customer - Left menu - Change status from pending to approved
	
	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20240827@Eddie: Add new permission for Manage Pending Affiliate [RedmineId : #209510]
		- 20240916@Eddie: Permit update password with Manage Pending Affiliate [RedmineId : #210773]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US', @PermissionType SMALLINT = 0

	DECLARE @CurrentDate SMALLDATETIME
	SELECT  @CurrentDate = GETDATE()

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

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId)
	BEGIN
		-- Invalid Affiliate
		SELECT @ErrCode = 1003, @ErrMsg = dbo.Aff_f_GetMessageById(304, @Language)

		RETURN
	END

	DECLARE @UpdatedData TABLE
	(
		-- del
		Password_Del			VARCHAR(40),
		Status_Del				VARCHAR(30),
		ApprovedDate_Del		SMALLDATETIME,
		CasinoJoinedDate_Del	SMALLDATETIME,
		-- insert
		Password_Ins			VARCHAR(40),
		Status_Ins				VARCHAR(30),
		ApprovedDate_Ins		SMALLDATETIME,
		CasinoJoinedDate_Ins	SMALLDATETIME
	)

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	IF @Password IS NULL
	BEGIN
		-- Invalid input password!
		SELECT @ErrCode = 1004, @ErrMsg = dbo.Aff_f_GetMessageById(305, @Language)

		RETURN
	END
	
	IF @Status <> 'Approved' OR @Status IS NULL
	BEGIN
		-- Invalid input status!
		SELECT @ErrCode = 1005, @ErrMsg = dbo.Aff_f_GetMessageById(306, @Language)

		RETURN
	END
	
	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId AND Status <> 'Approved')
	BEGIN
		-- Can not change status!
		SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(307, @Language)

		RETURN
	END

	-- Update process
	BEGIN
		IF EXISTS (
			SELECT 1
			FROM dbo.AffInfo ai1 WITH (NOLOCK)
				INNER JOIN dbo.AffInfo ai2 WITH (NOLOCK) ON ai1.Email = ai2.Email AND ai1.AffId <> ai2.AffId
			WHERE ai1.AffId = @AffId
				AND ai2.Status = 'Approved'
		)
		BEGIN
			-- Email Address has been used. Please choose another one!
			SELECT @ErrCode = 1007, @ErrMsg = dbo.Aff_f_GetMessageById(1, @Language)

			RETURN
		END

		IF EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId AND ISNULL(GroupId, 0) = 0)
		BEGIN
			-- Please assign Commission Group first!
			SELECT @ErrCode = 1008, @ErrMsg = dbo.Aff_f_GetMessageById(307, @Language)

			RETURN
		END
		
		BEGIN TRY
			IF ISNULL(@PermissionType, 0) = 0
			BEGIN
				UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
				SET Status = ISNULL(@Status, Status),
					Password = ISNULL(@Password, Password),
					ApprovedDate = CASE WHEN @Status IN ('Approved', 'Disapproved') THEN @CurrentDate ELSE NULL END,
					CasinoJoinedDate = @CurrentDate
				OUTPUT	DELETED.Status, DELETED.Password, DELETED.ApprovedDate, DELETED.CasinoJoinedDate,
						INSERTED.Status, INSERTED.Password, INSERTED.ApprovedDate, INSERTED.CasinoJoinedDate
				INTO @UpdatedData (Status_Del, Password_Del, ApprovedDate_Del, CasinoJoinedDate_Del,
									Status_Ins, Password_Ins, ApprovedDate_Ins, CasinoJoinedDate_Ins)
				WHERE AffId = @AffId
			END
			ELSE
			BEGIN
				UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
				SET Status = @Status
				   ,ApprovedDate = @CurrentDate
				   ,Password = ISNULL(@Password, Password)
				   ,CasinoJoinedDate = @CurrentDate
				OUTPUT DELETED.Status, DELETED.ApprovedDate, DELETED.CasinoJoinedDate, INSERTED.Status, INSERTED.ApprovedDate, INSERTED.CasinoJoinedDate
				INTO @UpdatedData (Status_Del, ApprovedDate_Del, CasinoJoinedDate_Del, Status_Ins, ApprovedDate_Ins, CasinoJoinedDate_Ins)
				WHERE AffId = @AffId AND Status = 'Pending'
			END
		END TRY
		BEGIN CATCH
			-- Update process is unsuccessful. Please try again!
			SELECT @ErrCode = 1009, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)

			RETURN
		END CATCH
		
		SELECT	@OldData = '<root><row Status="'+ ISNULL(Status_Del, '') +'" ApprovedDate="'+ ISNULL(CONVERT(VARCHAR(20), ApprovedDate_Del), '') +'" CasinoJoinedDate="'+ ISNULL(CONVERT(VARCHAR(20), CasinoJoinedDate_Del), '') +'"></row></root>'
				,@NewData = '<root><row Status="'+ ISNULL(Status_Ins, '') +'" ApprovedDate="'+ ISNULL(CONVERT(VARCHAR(20), ApprovedDate_Ins), '') +'" CasinoJoinedDate="'+ ISNULL(CONVERT(VARCHAR(20), CasinoJoinedDate_Ins), '') +'"></row></root>'
		FROM @UpdatedData
	END
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO