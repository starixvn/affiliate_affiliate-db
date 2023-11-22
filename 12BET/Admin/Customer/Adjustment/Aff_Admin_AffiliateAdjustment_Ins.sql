/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateAdjustment_Ins]
	@AffID		INT
	,@UserID	INT
	,@Amount	MONEY
	,@AdminDesc	NVARCHAR(300) = ''
	,@AffDesc	NVARCHAR(300) = ''
	,@TransID	BIGINT = 0 OUTPUT
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20160614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Customer - Adjustment - Insert adjustment amount

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20240605@Eddie: Enhance Adjustment Function with description for user's view [RedmineId : #205432]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	SELECT @ErrCode = 0, @ErrMsg = '', @Amount = ISNULL(@Amount, 0)

	-- Check permisison
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[AffAdjustment]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF @Amount = 0
	BEGIN
		-- Sorry, amount is invalid.
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(1301, @Language)
		RETURN
	END

	DECLARE @Currency	INT
			,@AffExRate	FLOAT
			,@Status	VARCHAR(30)

	SELECT	@Currency	= ai.Currency
			,@AffExRate	= e.ActualRate
			,@Status	= ai.STATUS
	FROM AffInfo ai WITH (NOLOCK)
		INNER JOIN Exchange_Current e WITH (NOLOCK) ON ai.Currency = e.ExchangeID
	WHERE ai.AffID = @AffID

	IF @@ROWCOUNT = 0
	BEGIN
		-- Invalid Affiliate!
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(304, @Language)
		RETURN
	END

	IF @Status <> 'Approved'
	BEGIN
		-- Sorry, You cannot do adjustment because this Affiliate is not approved yet.
		SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(1302, @Language)
		RETURN
	END

	BEGIN TRY
		INSERT INTO dbo.AffTrans (AffID, TransDate, CompletedDate, Amount, Status, Description, AffDescription, Creator, Currency, TransType, AffExRate)
			VALUES (@AffID, GETDATE(), GETDATE(), @Amount, 'Completed', @AdminDesc, @AffDesc, @UserID, @Currency, 203, @AffExRate)
	END TRY
	BEGIN CATCH
		-- This transaction is unsuccessful.
		SELECT @ErrCode = 104, @ErrMsg = dbo.Aff_f_GetMessageById(1303, @Language)
		RETURN
	END CATCH

	-- Write Log
	DECLARE @LogData NVARCHAR(4000), @SPName VARCHAR(50)

	SELECT  @LogData = '<root><row Amount="'+ CONVERT(VARCHAR(50), @Amount) +'"></row></root>'
			,@SPName = OBJECT_NAME(@@PROCID)
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffID,
		@SPName		= @SPName,
		@OldData	= '',
		@NewData	= @LogData,
		@IP			= @IP,
		@Language	= @Language
END
GO