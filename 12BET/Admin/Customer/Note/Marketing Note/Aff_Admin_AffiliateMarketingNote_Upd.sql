/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateMarketingNote_Upd]
	@NoteID		INT
	,@Note		NVARCHAR(1000)
	,@AffID		INT
	,@UserID	INT
	,@IP		VARCHAR(50)
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20231115@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Customer - Note - Update marketing note's content

	Revisions:
		- 20231115@Eddie: Initialize SP [RedmineID: #195391]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	SELECT @ErrCode = 0, @ErrMsg = ''

	-- Check permisison
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[MarketingTeamNote]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- For Log
	DECLARE @OldData NVARCHAR(4000), @NewData NVARCHAR(4000), @SPName VARCHAR(50)

	SELECT @SPName	= OBJECT_NAME(@@PROCID)

	SELECT  @OldData = CONVERT(NVARCHAR(MAX),
					   (
							SELECT NoteID AS '@NoteId'
							     , Note   AS '@Note'
							FROM dbo.AdminNotes WITH (NOLOCK)
							WHERE NoteID = @NoteID
							FOR XML PATH('row'), root('root')
					    ))

	SELECT  @NewData = CONVERT(NVARCHAR(MAX),
					   (
							SELECT @NoteID AS '@NoteId'
							     , @Note   AS '@Note'
							FOR XML PATH('row'), root('root')
					    ))

	IF @OldData = @NewData
		RETURN

	BEGIN TRY
		UPDATE dbo.AdminNotes WITH (ROWLOCK)
		SET Note = @Note
			,UpdatedBy = @UserID
			,UpdatedDate = GETDATE()
		WHERE NoteID = @NoteID
		
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Invalid Note!'
			RETURN
		END
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
		RETURN
	END CATCH

	-- Write Log
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserID		= @UserID
		,@AffID		= @AffID
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
		,@Language	= @Language
END
GO