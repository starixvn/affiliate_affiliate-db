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

	DECLARE @SiteName VARCHAR(30)
	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName')

	IF @Amount < 0
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Sorry, amount is invalid.'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.Aff_f_GetBalBroughtForward(@AffId) WHERE BalBroughtForward < @Amount)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Sorry, you do not have enough money to withdraw.'
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId AND Status = 'Approved' AND IsClosed = 0)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Oops, Your account is not existed or closed. Please contact administrator.'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.AffPayout WITH (NOLOCK) WHERE AffID = @AffID AND Status = 'Pending')
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'You have a pending request. In order to create a new request, please cancel the pending one or wait until it has been processed.'
		RETURN
	END

	DECLARE
		@AffUserName			VARCHAR(30)
		,@PreferredPayment		VARCHAR(20)
		,@Player_IBCCustId		INT
		,@Player_IBCUserName	VARCHAR(30)
		,@Player_Username		VARCHAR(30)
		,@Player_Currency		INT
		,@AffCurrencyName		VARCHAR(50)
		,@AffCurrency			INT
		,@Player_ExRate			FLOAT
		,@Aff_ExRate			FLOAT
		,@MinAmount				MONEY

	SELECT
		@AffUserName		= ai.UserName
		,@PreferredPayment	= ad.PreferredPayment
		,@Player_Username	= ad.Player_Username
		,@AffCurrency		= ai.Currency
		,@AffCurrencyName	= e.Currency
		,@Aff_ExRate		= e.BuyingRate
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
		INNER JOIN dbo.Exchange_Current e WITH (NOLOCK) ON ai.Currency = e.ExchangeId
	WHERE ai.AffId = @AffId
	
	IF ISNULL(@PreferredPayment, '') <> 'Player'
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Sorry, only '+ '''12Bet Player Account'+''' method is supported. Please contact your Administrator.'
		RETURN
	END

	SELECT
		@Player_IBCCustId		= c.custid
		,@Player_IBCUserName	= c.username
		,@Player_Currency		= c.currency
		,@Player_ExRate			= e.ActualRate
	FROM bodb02.dbo.Customer c WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON c.Currency = e.ExchangeId
	WHERE c.username2 = @SiteName + '$' + @Player_Username

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'
		RETURN
	END

	SELECT @MinAmount = CONVERT(MONEY, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_Min'+ @PreferredPayment + @AffCurrencyName

	IF @MinAmount IS NOT NULL AND @Amount < @MinAmount
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Invalid balance account or either the currency or payment method is not supported.'
		RETURN
	END

	DECLARE @TransDate DATETIME, @RefId BIGINT
	SET @TransDate = GETDATE()

	BEGIN TRY
		INSERT INTO dbo.AffPayout (AffId, UserName, IBCCustId, IBCUserName, Amount, AffPayout, AffCurrency, MemberExRate, AffExRate, MemberCurrency, TransDate, Status, CompletedDate)
		VALUES (@AffId, @AffUserName, @Player_IBCCustID, @Player_IBCUserName, -@Amount, -@Amount, @AffCurrency, @Player_ExRate, @Aff_ExRate, @Player_Currency, @TransDate, 'pending', @TransDate)

		SELECT @RefId = SCOPE_IDENTITY()

		INSERT INTO dbo.AffTrans (AffId, TransDate, Amount, Status, Description, Creator, Currency, ActualRate, TransType, RefId, AffExRate, CompletedDate)
		VALUES (@AffId, @TransDate, -@Amount, 'pending', 'Request payout', @AffId, @AffCurrency, @Player_ExRate, 202, @RefId, @Aff_ExRate, @TransDate)

		SELECT @TransId = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		DELETE dbo.AffPayout WHERE RefId = @RefId
		DELETE dbo.AffTrans WHERE TransId = @TransId

		SELECT @ErrCode = 100, @ErrMsg = 'Insert transaction failed.'
		RETURN
	END CATCH
END
GO