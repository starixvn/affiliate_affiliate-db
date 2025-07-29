/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateStatus_Upd]
	@AffID		INT
	,@UserID	INT
	,@Status	VARCHAR(30)
	,@GroupID	INT = NULL
	,@IP		VARCHAR(20) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000)	= '' OUTPUT
AS

/*
	Created: 20160614@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin - Customer - Left menu - Update Affiliate's Status

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
		- 20201026@Percy: Add AffCode - auto generate code when affiliate was approved [RedmineID: #143852]
		- 20200107@Percy: Add suspended status [RedmineID: #148373]
		- 20201215@Percy: Add AffMediaLink [RedmineID: #146201]
		- 20210223@Percy: Do not update ApprovedDate if change from Suspended [RedmineID: #150493]
		- 20240828@Sally: Add new permission for approve new affiliate [RedmineID: #209858]
		- 20250623@Sally: valid Affiliate account by Affcategory [RedmineID: #212201]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'
	DECLARE @AffCode VARCHAR(20)
        ,@AffCategoryId INT

	SELECT @ErrCode = 0, @ErrMsg = '', @Status = ISNULL(@Status, '')

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserID,
		@FuncName	= '[EditAffiliateStatus]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg	    = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffID = @AffID)
	BEGIN
		-- Invalid Affiliate!
		SELECT @ErrCode = 1005, @ErrMsg = dbo.Aff_f_GetMessageById(304, @Language)
		RETURN
	END

	IF @Status NOT IN ('Pending', 'Approved', 'Disapproved', 'Suspended')
	BEGIN
		-- Invalid input Status!
		SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(306, @Language)
		RETURN
	END
	
	DECLARE @OldStatus VARCHAR(30)
	SELECT  @OldStatus = CASE
							WHEN Status = 'Approved' AND IsClosed = 1 THEN 'Closed'
							WHEN Status = 'Approved' AND IsRejected = 1 THEN 'Suspended'
							ELSE Status END
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE AffId = @AffId

	IF @OldStatus = @Status
		RETURN

	-- For Log
	DECLARE @OldData NVARCHAR(4000), @NewData NVARCHAR(4000), @SPName VARCHAR(50), @Email NVARCHAR(50)
	SELECT  @OldData	= 'Status=' + @OldStatus
			,@NewData	= 'Status=' + @Status
			,@SPName	= OBJECT_NAME(@@PROCID)
			,@Email		= Email
            ,@AffCategoryId = AffCategoryId
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE AffID = @AffID

	IF @Status = 'Approved' -- From Pending/Disapproved
	BEGIN
		IF EXISTS (
			SELECT 1 
			FROM dbo.AffInfo WITH (NOLOCK) 
			WHERE AffId <> @AffID 
				AND Email = @Email 
				AND Status = 'Approved' 
				AND (
					(AffCategoryId = 1 AND @AffCategoryId = 2)
					OR
					(@AffCategoryId = 1)
				)
        )
		BEGIN
			-- Email Address has been used. Please choose another one!
			SELECT @ErrCode = 1007, @ErrMsg = dbo.Aff_f_GetMessageById(1, @Language)
			RETURN
		END

		IF @OldStatus = 'Pending'
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupID = @GroupID AND IsDeleted = 0)
			BEGIN
				-- Group is not existed
				SELECT @ErrCode = 1008, @ErrMsg = dbo.Aff_f_GetMessageById(1006, @Language)
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
		END
	END
	ELSE IF @Status = 'Suspended'
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE Status = 'Approved' AND AffID = @AffID AND IsClosed = 0)
		BEGIN
			-- Invalid input Status!
			SELECT @ErrCode = 1007, @ErrMsg = dbo.Aff_f_GetMessageById(1, @Language)
			RETURN
		END
	END

	BEGIN TRY
		UPDATE dbo.AffInfo WITH (ROWLOCK)
		SET	Status = CASE WHEN @Status = 'Suspended' THEN Status ELSE @Status END
			,GroupID = ISNULL(@GroupID, GroupID)
			,ApprovedDate = CASE WHEN ApprovedDate IS NULL AND @Status IN ('Approved', 'Disapproved') THEN GETDATE() ELSE ApprovedDate END
			,AffCode = ISNULL(@AffCode, AffCode)
			,IsRejected = CASE WHEN @Status = 'Suspended' THEN 1 WHEN @Status = 'Approved' THEN 0 ELSE IsRejected END
		WHERE AffID = @AffID
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