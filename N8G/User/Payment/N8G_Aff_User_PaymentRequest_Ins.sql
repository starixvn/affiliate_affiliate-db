/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_PaymentRequest_Ins]
	@AffId		INT
	,@Amount	MONEY
	,@TransId	BIGINT = 0 OUTPUT
	,@IP		VARCHAR(20) = ''
	,@Language	VARCHAR(10) = 'en-US'
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Creator: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: User site - Payment Request - Insert new request

	Revisions:
		- 20200220@Percy: Initiliaze SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @currentDate SMALLDATETIME
	SELECT  @currentDate = CONVERT(DATE, GETDATE())

	IF ISNULL(@Amount, 0) < 0
	BEGIN
		-- Sorry, amount is invalid.
		SELECT @ErrCode = 100, @ErrMsg = dbo.Aff_f_GetMessageById(506, @Language)
		RETURN
	END

	DECLARE @BalBroughtForward MONEY
	SELECT  @BalBroughtForward = BalBroughtForward FROM dbo.Aff_f_GetBalBroughtForward(@AffId)
	SELECT  @BalBroughtForward = ISNULL(@BalBroughtForward, 0)

	IF @BalBroughtForward < @Amount
	BEGIN
		-- Sorry, you do not have enough money to withdraw.
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(505, @Language)
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId AND Status = 'Approved' AND IsClosed = 0)
	BEGIN
		-- Your account is closed. Please contact your administrator!
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(202, @Language)
		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.AffPayout WITH (NOLOCK) WHERE AffID = @AffID AND Status = 'Pending')
	BEGIN
		-- Oops, this account is having 1 pending pay out request, please update this transaction first!
		SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(301, @Language)
		RETURN
	END

	DECLARE
		@AffUserName			VARCHAR(30)
		,@PreferredPayment		VARCHAR(20)
		,@Player_CustId			INT
		,@Player_Username		VARCHAR(30)
		,@Player_Currency		INT
		,@Player_CurrencyName	NVARCHAR(50)
		,@Player_CurrencyCode	VARCHAR(3)
		,@AffCurrency			INT
		,@AffCurrencyName		VARCHAR(50)
		,@AffRate				FLOAT
		,@MinAmount				MONEY
		,@AffPayout				MONEY

	SELECT
		@AffUserName			= ai.UserName
		,@PreferredPayment		= ad.PreferredPayment
		,@Player_CustId			= ad.Player_CustID
		,@Player_Username		= ad.Player_Username
		,@Player_Currency		= ad.Player_Currency
		,@Player_CurrencyName	= ad.Player_CurrencyName
		,@Player_CurrencyCode	= ad.Player_CurrencyCode
		,@AffCurrency			= ai.Currency
		,@AffCurrencyName		= ai.CurrencyName
		,@AffRate				= e.Rate
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@currentDate, ai.Currency, 0) e
	WHERE ai.AffId = @AffId
	
	IF ISNULL(@PreferredPayment, '') <> 'Player'
	BEGIN
		-- Sorry, only Player Account method is supported. Please contact your Administrator.
		SELECT @ErrCode = 104, @ErrMsg = dbo.Aff_f_GetMessageById(507, @Language)
		RETURN
	END

	SELECT @MinAmount = CONVERT(MONEY, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'Payment_MinAmount'

	IF @MinAmount IS NOT NULL AND @Amount < @MinAmount
	BEGIN
		-- Invalid request amount! Amount must be between {MinAmount} and {MaxAmount}
		SELECT @ErrCode = 106, @ErrMsg = dbo.Aff_f_GetMessageById(510, @Language)
		SELECT @ErrMsg = REPLACE(REPLACE(@ErrMsg, '{MinAmount}', CONVERT(VARCHAR(30), @MinAmount)), '{MaxAmount}', CONVERT(VARCHAR(30), @BalBroughtForward))

		RETURN
	END

	DECLARE @TransDate DATETIME, @RefId BIGINT
	SET @TransDate = GETDATE()

	IF @Player_Currency = 20 -- UUS
		SELECT @AffPayout = @Amount
	ELSE
		SELECT @AffPayout = CASE WHEN Rate = 0 THEN 0 ELSE @Amount / Rate END
		FROM dbo.Aff_f_ExchangeRate_Sel(@currentDate, @Player_Currency, @AffCurrency)

	BEGIN TRY
		INSERT INTO dbo.AffPayout(AffId,TransDate,Status,Amount,AffPayout,AffCurrency,AffRate,PreferredPayment,Player_CustId,Player_Username,Player_Currency,Player_CurrencyName,Player_CurrencyCode)
		VALUES (@AffId,@TransDate,'Pending',-@Amount,-@AffPayout,@AffCurrency,@AffRate,@PreferredPayment,@Player_CustId,@Player_Username,@Player_Currency,@Player_CurrencyName,@Player_CurrencyCode)

		SELECT @RefId = SCOPE_IDENTITY()

		INSERT INTO dbo.AffTrans (AffId,TransType,TransDate,Amount,Status,Description,Creator,AffCurrency,AffRate,RefId)
		VALUES (@AffId,202,@TransDate,-@Amount,'Pending','Request payout',@AffId,@AffCurrency,@AffRate,@RefId)

		SELECT @TransId = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		DELETE dbo.AffPayout WHERE RefId = @RefId
		DELETE dbo.AffTrans WHERE TransId = @TransId

		-- Insert transaction failed. Please try again!
		SELECT @ErrCode = 107, @ErrMsg = dbo.Aff_f_GetMessageById(511, @Language)
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SELECT  @NewData = 'RefId=' + CONVERT(VARCHAR(30), @RefId)
						+ ',' + 'Amount=' + CONVERT(VARCHAR(30), @Amount)
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO