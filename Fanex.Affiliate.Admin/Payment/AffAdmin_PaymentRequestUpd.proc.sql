ALTER PROCEDURE [dbo].[AffAdmin_PaymentRequestUpd] 
	@LicenseeID INT
	,@TransID BIGINT
	,@Status NVARCHAR(50)
	,@AdminDesc NVARCHAR(300) = NULL
	,@AffDesc NVARCHAR(300) = NULL
	,@PreferredLanguage VARCHAR(20) = 'en-US' OUTPUT
	,@MailOption BIT = 0 OUTPUT
	,@UserID INT
	,@IP VARCHAR(15) = ''
	,@RefNo BIGINT = 0
	,@IbcRefNo BIGINT = 0
	,@IbcTransId BIGINT = 0
	,@IBCUsername VARCHAR(50) = ''
	,@ErrCode INT = 0 OUTPUT
AS
-- DB: DB052.Affiliate_MYM  
/*  
Creator : Peter@20090910  
Task : Update Payment status ('Approved','Rejected','Cancelled')  
  
Input   
    1) @AffId (For Double check)   
    2) @RefID (This ID is get from "B. deposit/withdrawal for approved" Output TransID )  
    3) @Status Status of transaction  
    3) @AdminDesc Description for this payment from Admin  
    4) @AffDesc Description visible for Affiliate  
    5) @userid ID of Admin update this payment  
    6) @IP IP update payment  
     
Revisions:  
	- Johnny@20131126: Update field BF in table AffInfo
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
• @ErrCode:  
 = 0: Transaction recorded successfully.  
 > 0: Specific Error.  
• @ErrMsg: Error description.  
*/
BEGIN
	--Check whether this is pending payment request   
	SET NOCOUNT ON

	DECLARE @AffID INT
		,@RefID BIGINT
		,@TransType INT

	SELECT @TransType = 202

	SELECT @AffID = AffID
		,@RefID = RefID
	FROM AffTrans(NOLOCK)
	WHERE TransID = @TransID AND TransType = @TransType AND STATUS = 'pending'

	IF (@AffID IS NULL OR @RefID IS NULL)
	BEGIN
		SELECT @ErrCode = 1

		RETURN
	END

	/*Check Condition to excute this sp  
  + From Affiliate Site : @UserID=@AffID and  @Status='Cancelled'  
  + From AffAdmin Site: @UserID<> @AffID and Status in ('Approved','Rejected')   
*/
	IF (@UserID <> @AffID)
	BEGIN
		--Check permission-----------------------------  
								EXEC [dbo].[Aff_Con_CheckPermission] 
			@LicenseeID = @LicenseeID
			,@custid = @UserID
			,@funcname = '[Payment]'
			,@System = 'AFFILIATE'
			,@ErrCode = @ErrCode OUTPUT

		IF @ErrCode <> 0 RETURN

		IF (@Status NOT IN ('Approved', 'Rejected'))
		BEGIN
			SELECT @ErrCode = 2

			RETURN
		END
	END

	IF (@UserID = @AffID AND @Status <> 'Cancelled')
	BEGIN
		SELECT @ErrCode = 2

		RETURN
	END

	BEGIN TRANSACTION

	BEGIN TRY
		DECLARE @CompletedDate DATETIME

		SELECT @PreferredLanguage = PreferredLanguage
			,@MailOption = MailOption
		FROM AffDetail(NOLOCK)
		WHERE AffID = @AffID

		SELECT @CompletedDate = current_timestamp

		UPDATE AffPayout WITH (ROWLOCK, UPDLOCK)
		SET [Status] = @Status
			,CompletedDate = @CompletedDate
			,AdminDesc = isnull(@AdminDesc, AdminDesc)
			,AffDesc = isnull(@AffDesc, AffDesc)
			,IbcRefNo = @IbcRefNo
			,IbcTransId = @IbcTransId
			,IBCUsername = (CASE 
				WHEN isnull(IBCUsername, '') = '' THEN @IBCUsername
				ELSE IBCUsername END
				)
		WHERE RefID = @RefID AND AffID = @AffID

		UPDATE AffTrans WITH (ROWLOCK, UPDLOCK)
		SET [Status] = @Status
			,CompletedDate = @CompletedDate
			,Creator = @UserID
		WHERE TransID = @TransID AND AffID = @AffID

		-- Recalculate BF in AffInfo table  
		UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
		SET BF = dbo.Aff_GetAffBalance(AffID)
		WHERE AffID = @AffID
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 3

		RETURN

		RETURN
	END CATCH

	COMMIT TRANSACTION

	DECLARE @SPName VARCHAR(50)
		,@LogData NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = 'Update status for payout Request. TransID = ' + dbo.Aff_ToString(@TransID) + '. Status = ' + dbo.Aff_ToString(@Status)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@AffID = @AffID
		,@Typename = 'Payout'
		,@SPName = @SPName
		,@RefNo = @RefNo
		,@IP = @IP
		,@Details = @LogData
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_PaymentRequestUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_PaymentRequestUpd] TO [vnteam] AS [dbo]