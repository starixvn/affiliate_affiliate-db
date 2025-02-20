/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateMarketingNote_Ins]
	@Note		NVARCHAR(1000)
	,@AffID		INT
	,@UserID	INT
	,@IP		VARCHAR(50)
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20250218@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Customer - Note - Insert new marketing note

	Revisions:
		- 20250218@Sally: Initialize SP [RedmineID: #212201]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @NoteID INT, @Language NVARCHAR(5) = 'en-US'

	SELECT @ErrCode = 0, @ErrMsg = ''

-- Check permisison
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[MarketingTeamNote]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	BEGIN TRY
		INSERT INTO dbo.AdminNotes (AffID, Note, UpdatedBy, UpdatedDate, NoteType)
			VALUES (@AffID, @Note, @UserID, GETDATE(), 1) -- NoteType : 0 (note) and 1 (marketing team note)

		SELECT @NoteID = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @LogData NVARCHAR(MAX)
	SELECT  @LogData = 'NoteId=' + CONVERT(VARCHAR(20), @NoteId)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= '',
		@NewData	= @LogData,
		@IP			= @IP,
		@Language	= @Language
END
GO