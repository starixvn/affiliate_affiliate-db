/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_PaymentRequest_Upd]
	@AffId		INT,
	@TransId	BIGINT,
	@IP			VARCHAR(20),
	@Language	VARCHAR(10),
	@Status		VARCHAR(20),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Creator: 20180601@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: User site - Payment Request - Update Status (Cancelled only)

	Revisions:
		- 20180601@Percy: Initiliaze SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @RefID BIGINT, @AffId_DB INT
	
	SELECT @AffId_DB = AffId, @RefID = RefID
	FROM dbo.AffTrans WITH (NOLOCK)
	WHERE TransID = @TransID
		AND TransType = 202 -- payment request
		AND Status = 'pending'

	IF @AffId_DB IS NULL
	BEGIN
		-- This transaction is not a withdrawal.
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(501, @Language)

		RETURN
	END

	IF @AffId <> @AffId_DB OR @Status <> 'Cancelled'
	BEGIN
		-- Oops, You do not have permission to update this transaction.
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(502, @Language)

		RETURN
	END

	-- Update payment request
	BEGIN TRY
		DECLARE @CompletedDate DATETIME
		SELECT  @CompletedDate = GETDATE()

		UPDATE dbo.AffTrans WITH (ROWLOCK, UPDLOCK)
		SET	Status = @Status,  
			CompletedDate = @CompletedDate,  
			Creator = @AffId
		WHERE TransID = @TransID AND AffID = @AffID

		UPDATE dbo.AffPayout WITH (ROWLOCK, UPDLOCK)
		SET Status = @Status,
			CompletedDate = @CompletedDate
		WHERE RefID = @RefID AND AffID = @AffID
	END TRY
	BEGIN CATCH
		-- Update failed. Please try again!
		SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(503, @Language)

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData = 'Status=pending', @NewData = 'Status=Cancelled'
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO