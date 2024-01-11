/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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
	Creator: 20211005@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin site - Customer - Left menu - Transfer Limit
	
	Revisions:
		- 20211005@Percy: Initialize SP [RedmineID: #153227]
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