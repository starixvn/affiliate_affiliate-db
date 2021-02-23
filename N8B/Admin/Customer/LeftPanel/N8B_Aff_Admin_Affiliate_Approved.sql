/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Affiliate_Approved]
	@UserId		INT,
	@AffId		INT,
	@Password	NVARCHAR(40) = NULL,
	@Status		VARCHAR(30) = NULL,
	@IP			VARCHAR(50),
	@AffCode	VARCHAR(20)	= '' OUTPUT,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS  

/*
	Creator: 20180601@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Admin site - Customer - Left menu - Change status from pending to approved
	
	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20201026@Percy: Add AffCode - auto generate code when affiliate was approved [RedmineID: #143852]
		- 20201215@Percy: Add AffMediaLink [RedmineID: #146201]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	DECLARE @CurrentDate SMALLDATETIME
	SELECT  @CurrentDate = GETDATE()

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserID,
		@FuncName	= '[Affiliate]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

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
		ApprovedBy_Del			INT,
		-- insert
		Password_Ins			VARCHAR(40),
		Status_Ins				VARCHAR(30),
		ApprovedDate_Ins		SMALLDATETIME,
		ApprovedBy_Ins			INT
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

		;WITH CTE_AffCode AS
		(
			SELECT TOP 1 * FROM dbo.AffiliateCode WITH (ROWLOCK)
			WHERE AffId IS NULL
			ORDER BY NEWID() -- random
		)
		UPDATE CTE_AffCode
		SET AffId = @AffId

		SELECT @AffCode = AffCode FROM dbo.AffiliateCode WITH (NOLOCK) WHERE AffId = @AffId
		
		BEGIN TRY
			UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
			SET Status = ISNULL(@Status, Status),
				Password = ISNULL(@Password, Password),
				ApprovedDate = CASE WHEN @Status IN ('Approved', 'Disapproved') THEN @CurrentDate ELSE NULL END,
				ApprovedBy = @UserId,
				AffCode = ISNULL(@AffCode, AffCode)
			OUTPUT	DELETED.Status, DELETED.Password, DELETED.ApprovedDate, DELETED.ApprovedBy,
					INSERTED.Status, INSERTED.Password, INSERTED.ApprovedDate, INSERTED.ApprovedBy
			INTO @UpdatedData (Status_Del, Password_Del, ApprovedDate_Del, ApprovedBy_Del,
								Status_Ins, Password_Ins, ApprovedDate_Ins, ApprovedBy_Ins)
			WHERE AffId = @AffId
		END TRY
		BEGIN CATCH
			-- Update process is unsuccessful. Please try again!
			SELECT @ErrCode = 1009, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)

			RETURN
		END CATCH

		INSERT INTO dbo.AffMediaChannel (AffId, ChannelCode, ChannelName)
		SELECT @AffId, LOWER(t.ChannelName), t.ChannelName
		FROM (
			select 'Youtube' as ChannelName
			union all select 'Facebook'
			union all select 'Twitter'
			union all select 'Tiktok'
			union all select 'Whatsapp'
			union all select 'Telegram'
		) t
			LEFT JOIN dbo.AffMediaChannel a WITH (NOLOCK) ON a.AffId = @AffId AND a.ChannelCode = LOWER(t.ChannelName)
		WHERE a.AffId IS NULL

		SELECT	@OldData =
					'Password='			+ ISNULL(Password_Del, '') + ',' +
					'Status='			+ ISNULL(Status_Del, '') + ',' + 
					'ApprovedDate='		+ ISNULL(CONVERT(VARCHAR(20), ApprovedDate_Del, 120), '') + ',' +
					'ApprovedBy='		+ ISNULL(u1.UserName, ''),
				@NewData =
					'Password='			+ ISNULL(Password_Ins, '') + ',' +
					'Status='			+ ISNULL(Status_Ins, '') + ',' + 
					'ApprovedDate='		+ ISNULL(CONVERT(VARCHAR(20), ApprovedDate_Ins, 120), '') + ',' +
					'ApprovedBy='		+ ISNULL(u2.UserName, '')
		FROM @UpdatedData ud
			LEFT JOIN dbo.Affiliate_User u1 WITH (NOLOCK) ON ud.ApprovedBy_Del = u1.CustId
			LEFT JOIN dbo.Affiliate_User u2 WITH (NOLOCK) ON ud.ApprovedBy_Ins = u2.CustId
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