/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap,wsv_alp,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_TransferBalanceHistory_Upd]
	@TransId	BIGINT
	,@Status	VARCHAR(20)
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(1000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Transfer Balance For Player

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		UPDATE dbo.TransferBalanceHistory WITH (ROWLOCK)
		SET Status = @Status
		WHERE TransId = @TransId

		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'This transaction does not exist!'
			RETURN
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Update transaction failed!'
		RETURN
	END CATCH
END
GO