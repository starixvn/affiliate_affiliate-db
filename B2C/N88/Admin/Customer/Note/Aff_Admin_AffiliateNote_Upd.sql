/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateNote_Upd]
	@NoteID		INT
	,@Note		NVARCHAR(1000)
	,@AffID		INT
	,@UserID	INT
	,@IP		VARCHAR(20)
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20190614@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin - Customer - Note - Update note's content

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
		- 20240906@Sally: Add new permission for approve new affiliate [RedmineID: #209858]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	SELECT @ErrCode = 0, @ErrMsg = ''

	-- Check permisison
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[Note]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- For Log
	DECLARE @OldData NVARCHAR(4000), @NewData NVARCHAR(4000), @SPName VARCHAR(50)
	SELECT  @OldData	= 'Note=' + ISNULL(Note, '')
			,@NewData	= 'Note=' + ISNULL(@Note, '')
			,@SPName	= OBJECT_NAME(@@PROCID)
	FROM dbo.AdminNotes WITH (NOLOCK)
	WHERE NoteID = @NoteID

	IF @@ROWCOUNT = 0
	BEGIN
		-- Invalid Note!
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(1201, @Language)
		RETURN
	END

	IF @OldData = @NewData
		RETURN

	BEGIN TRY
		UPDATE dbo.AdminNotes WITH (ROWLOCK)
		SET Note = @Note
			,UpdatedBy = @UserID
			,UpdatedDate = GETDATE()
		WHERE NoteID = @NoteID
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
		RETURN
	END CATCH

	-- Write Log
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserID		= @UserID,
		@AffID		= @AffID,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO