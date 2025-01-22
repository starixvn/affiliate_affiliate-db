/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_TransferLimit_Upd]
	@UserId				INT
	,@AffId				INT
	,@TransferLimit		MONEY
	,@DisabledTransfer	BIT
	,@IP				VARCHAR(50) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			VARCHAR(1000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Customer - Left menu - Transfer Limit
	
	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/

BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		UPDATE dbo.AffDetail WITH (ROWLOCK)
		SET TransferLimit = @TransferLimit, DisabledTransfer = @DisabledTransfer
		WHERE AffId = @AffId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 100, @ErrMsg = ''
	END CATCH

END
GO