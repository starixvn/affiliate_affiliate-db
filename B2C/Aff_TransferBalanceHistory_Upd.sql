/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_TransferBalanceHistory_Upd]
	@TransId	BIGINT
	,@Status	VARCHAR(20)
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(1000) = '' OUTPUT
AS

/*
	Created: 20211005@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Transfer Balance For Player

	Revisions:
		- 20211005@Percy: Initialize SP [RedmineID: #153227]
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