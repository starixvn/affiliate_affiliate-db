/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_PaymentRequestUpd] 
	@TransID			BIGINT,
	@Status				NVARCHAR(50),
	@AdminDesc			NVARCHAR(300) = NULL,
	@AffDesc			NVARCHAR(300) = NULL,
	@PreferredLanguage	VARCHAR(20) = 'en-US' OUTPUT,
	@MailOption			BIT = 0 OUTPUT,
	@UserID				INT,
	@AdminUserName		VARCHAR(50),
	@IP					VARCHAR(15) = '',
	@RefNo				BIGINT = 0,
	@IbcRefNo			BIGINT = 0,
	@IbcTransId			BIGINT = 0,
	@IBCUsername		VARCHAR(50) = '',
	@ErrCode			INT = 0 OUTPUT
AS

/*
	Creator: Peter@20090910  
	Task: Update Payment status ('Approved','Rejected','Cancelled')
	DB: DBAFF
    
	Revisions:  
		- Johnny@20131126: Update field BF in table AffInfo
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20171130@Percy: Add IsProcessing, log [RedmineID: #87322]
		- 20180208@Alex: Support Liecnsee admin portal #90545
	
	
	Param's Explanation:
		1) @AffId (For Double check)
		2) @RefID (This ID is get from "B. deposit/withdrawal for approved" Output TransID)
		3) @Status Status of transaction
		3) @AdminDesc Description for this payment from Admin
		4) @AffDesc Description visible for Affiliate
		5) @userid ID of Admin update this payment
		6) @IP IP update payment
		7) @ErrType:
			0: successfull
			1: failed API inserted bettrans
			2: failed API checked exists player username
			3: not exists player username
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffID INT, @RefID BIGINT

	SELECT @AffID = AffID, @RefID = RefID
	FROM dbo.AffTrans WITH (NOLOCK)
	WHERE TransID = @TransID AND TransType = 202 AND Status = 'Pending'

	IF (@AffID IS NULL OR @RefID IS NULL)
	BEGIN
		SELECT @ErrCode = 1

		RETURN
	END

	DECLARE @CompletedDate DATETIME
	SELECT  @CompletedDate = CURRENT_TIMESTAMP

	BEGIN TRANSACTION

	SELECT  @PreferredLanguage = PreferredLanguage, @MailOption = MailOption
	FROM AffDetail WITH(NOLOCK)
	WHERE AffID = @AffID

	UPDATE AffPayout WITH (ROWLOCK, UPDLOCK)
	SET
		[Status] = @Status
		,CompletedDate = @CompletedDate
		,AdminDesc = ISNULL(@AdminDesc, AdminDesc)
		,AffDesc = ISNULL(@AffDesc, AffDesc)
		,IbcRefNo = @IbcRefNo
		,IbcTransId = @IbcTransId
		,IBCUsername = (CASE WHEN ISNULL(IBCUsername, '') = '' THEN @IBCUsername ELSE IBCUsername END)
	WHERE RefID = @RefID AND AffID = @AffID

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 3
		RETURN
	END

	UPDATE AffTrans WITH (ROWLOCK, UPDLOCK)
	SET
		[Status] = @Status
		,CompletedDate = @CompletedDate
		,Creator = @UserID
		,AdminUserName=@AdminUserName
		,IsProcessing = 0
	WHERE TransID = @TransID AND AffID = @AffID

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 3
		RETURN
	END

	UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
	SET BF = dbo.Aff_GetAffBalance(AffID)
	WHERE AffID = @AffID

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 3
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Update status for payout Request. TransID = ' + dbo.Aff_ToString(@TransID) + '. Status = ' + dbo.Aff_ToString(@Status)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@AffID = @AffID
		,@Typename = 'Payout'
		,@SPName = @SPName
		,@RefNo = @RefNo
		,@IP = @IP
		,@Details = @Detail
END
GO