/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_TransferBalanceHistory_Upd]
	@TransId	BIGINT
	,@Status	VARCHAR(20)
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(1000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Transfer Balance For Player

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
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