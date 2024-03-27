/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliatePaymentRequest_Upd]
	@TransId	BIGINT
	,@Status	VARCHAR(30) = NULL
	,@AdminDesc	NVARCHAR(300) = NULL
	,@AffDesc	NVARCHAR(300) = NULL
	,@UserID	INT
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Affiliate - Payment Request - Update payment request by TransId

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	IF @Status = 'Processing'
		SELECT @Status = 'Pending'

	DECLARE @Language NVARCHAR(5) = 'en-US'

	SELECT @ErrCode = 0, @ErrMsg = ''

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustID		= @UserID
		,@FuncName	= '[Payment]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Update description only
	IF @Status IS NULL OR @Status = 'Pending'
	BEGIN
		IF ISNULL(@AdminDesc, '') = '' AND ISNULL(@AffDesc, '') = ''
			RETURN
	END
	ELSE IF @Status NOT IN ('Approved', 'Rejected')
	BEGIN
		-- Oops, You do not have permission to update this transaction.
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(502, @Language)
		RETURN
	END

	DECLARE @AffId INT, @RefId BIGINT

	-- For Log
	DECLARE @OldData NVARCHAR(4000), @NewData NVARCHAR(4000), @SPName VARCHAR(50)
	
	SELECT  @AffId		= ap.AffId
			,@RefId		= ap.RefId
			,@OldData	= 'TransId=' + CONVERT(VARCHAR(10), @TransId)
							+ 'Status=' + ISNULL(ap.Status, 'NULL')
							+ 'AdminDesc=' + ISNULL(ap.AdminDesc, 'NULL')
							+ 'AffDesc=' + ISNULL(ap.AffDesc, 'NULL')
			,@NewData	= 'TransId=' + CONVERT(VARCHAR(10), @TransId)
							+ 'Status=' + ISNULL(@Status, 'NULL')
							+ 'AdminDesc=' + ISNULL(@AdminDesc, 'NULL')
							+ 'AffDesc=' + ISNULL(@AffDesc, 'NULL')
			,@SPName	= OBJECT_NAME(@@PROCID)
	FROM dbo.AffPayout ap WITH (NOLOCK)
		INNER JOIN dbo.AffTrans a WITH (NOLOCK) ON a.RefID = ap.RefID
	WHERE a.TransId = @TransID AND a.TransType = 202 AND a.Status = 'Pending'
		AND ap.Status = 'Pending'

	IF @AffId IS NULL
	BEGIN
		-- This transaction is not a withdrawal.
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(501, @Language)
		RETURN
	END
	
	IF ISNULL(@OldData, '') = ISNULL(@NewData, '')
		RETURN

	DECLARE @CompletedDate DATETIME
	SELECT  @CompletedDate = GETDATE()

	BEGIN TRY
		UPDATE dbo.AffPayout WITH (ROWLOCK)
		SET Status			= ISNULL(@Status, Status)
			,CompletedDate	= CASE WHEN @Status IS NOT NULL THEN @CompletedDate ELSE CompletedDate END
			,AdminDesc		= ISNULL(@AdminDesc, AdminDesc)
			,AffDesc		= ISNULL(@AffDesc, AffDesc)
		WHERE AffID = @AffID AND RefID = @RefID

		IF @Status IS NOT NULL
		BEGIN
			UPDATE dbo.AffTrans WITH (ROWLOCK)
			SET Status			= @Status
				,CompletedDate	= @CompletedDate
				,Creator		= @UserID
			WHERE TransID = @TransID
		END
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
		RETURN
	END CATCH

	-- Write Log
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO