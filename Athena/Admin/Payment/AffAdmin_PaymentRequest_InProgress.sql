/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_PaymentRequest_InProgress]
	@TransID		BIGINT,
	@UserID			INT,
	@AdminUserName	VARCHAR(50) = '',
	@IP				VARCHAR(20) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created by Percy
	Date: 2017-11-30
	DB: DBAFF
	Task: Processing payment request: Approve or Reject

	Revisions:
		- 20171130@Percy: Create new SP [RedmineID: #87322]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Status NVARCHAR(100), @IsProcessing BIT, @AffID INT
	SELECT  @Status = Status, @IsProcessing = IsProcessing, @AffID = AffID
	FROM dbo.AffTrans WITH (NOLOCK) WHERE TransID = @TransID AND TransType = 202

	IF @Status IS NULL
	BEGIN
		SELECT  @ErrCode = 100,
				@ErrMsg = 'This request is not found.'

		RETURN
	END

	IF @Status <> 'Pending' OR @IsProcessing = 1
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'Your request is ' + CASE WHEN @IsProcessing = 1 THEN 'In Progress' ELSE @Status END + '.'

		RETURN
	END

	BEGIN TRANSACTION

	UPDATE dbo.AffTrans WITH (ROWLOCK, UPDLOCK)
	SET IsProcessing = 1
	WHERE TransID = @TransID

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT  @ErrCode = 102,
				@ErrMsg = ERROR_MESSAGE()

		RETURN
	END

	COMMIT TRANSACTION

	-- Write log
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Update status for payout Request. TransID = ' + dbo.Aff_ToString(@TransID)
					+ '. Status = ' + dbo.Aff_ToString(@Status)
					+ '. Username = ' + ISNULL(@AdminUserName, '')

	EXEC [dbo].[Aff_WriteLog]
		@Creator = @UserID
		,@AffID = @AffID
		,@Typename = 'Payout'
		,@SPName = @SPName
		,@IP = @IP
		,@Details = @Detail
END
GO