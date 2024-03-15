/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_TransferLimit_Upd]
	@UserId				INT
	,@AffId				INT
	,@TransferLimit		MONEY
	,@DisabledTransfer	BIT
	,@IP				VARCHAR(20) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			VARCHAR(1000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin site - Customer - Left menu - Transfer Limit
	
	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
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

	-- Write log
END
GO