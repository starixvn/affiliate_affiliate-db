/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[Aff_User_PaymentRequestIns]  
	@AffID				INT,  
	@Player_UserName	VARCHAR(30), 	
	@Player_IBCUserName VARCHAR(30), 	
	@Player_Currency	VARCHAR(5),	
	@Amount				MONEY,   
	@IP					VARCHAR(20),   
	@language			VARCHAR(20) = 'en-US',  
	@PreferredLanguage	VARCHAR(5) = 'en-US' OUTPUT,  
	@MailOption			BIT = 1 OUTPUT,
	@TransDate			DATETIME = NULL OUTPUT,  
	@TransID			BIGINT = 0 OUTPUT,  
	@ErrCode			INT = 0 OUTPUT
AS
 
/*
	Created: 20130314@Johnny
	Task: Insert an payment request from Affiliate
	DB: DBAFF
	Original:

	Revisions:
		- 20130314@Johnny: Create new SP

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (
		SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffID = @AffID AND Status = 'Approved' AND IsClosed = 0
	)
	BEGIN
		SELECT @ErrCode = 107 -- 'Oops, Your account is not existed or closed. Please contact administrator.' 
		RETURN
	END

	-- Checking amount
	IF @Amount <= 0
	BEGIN
		SELECT @ErrCode = 135 -- 'Sorry, amount is invalid.'
		RETURN
	END

	-- Checking whether this account has a pending request.
	IF EXISTS (
		SELECT 1 FROM dbo.AffPayout WITH (NOLOCK) WHERE AffID = @AffID AND Status = 'Pending'
	)
	BEGIN
		SELECT @ErrCode = 130 -- 'You have a pending request. In order to create a new request, please cancel the pending one or wait until it has been processed.'
		RETURN
	END

	-- Checking Balance Brought Forward  
	DECLARE @AffBalance MONEY
	SELECT  @AffBalance = dbo.Aff_GetAffBalance(@AffID)

	IF (@AffBalance<=0) OR (@Amount > @AffBalance)
	BEGIN
		SELECT @ErrCode = 131 --'Sorry, this Affiliate does not have enough money to withdraw.'
		RETURN
	END
	
	DECLARE @TransType INT = 202  
  
	-- Get all related info and Check Preferred Payment  
	DECLARE @PreferredPayment VARCHAR(20), @AffCurrencyID SMALLINT, @AffCurrency VARCHAR(5), @Member_ExRate FLOAT

	SELECT  @PreferredPayment = PreferredPayment, @PreferredLanguage = PreferredLanguage, @MailOption = MailOption
	FROM dbo.AffDetail WITH (NOLOCK)
	WHERE AffID = @AffID

	IF @PreferredPayment <> 'Player'
	BEGIN
		SELECT @ErrCode = 137 -- 'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''Player Account'+''' method is supported. Please click here to make a change.'
		RETURN
	END
  
	 -- Check supported player's currency
	DECLARE @SupportedCurrencies VARCHAR(100)

	SELECT  @SupportedCurrencies = SValue
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE Type = 'Meta' AND SName = 'AFF_PlayerCurrencies'
	
	IF @SupportedCurrencies NOT LIKE '%' + @Player_Currency + '%'
	BEGIN
		SELECT @ErrCode = 138 -- 'We do not support this currency. Please contact administrator.'
		RETURN
	END

	DECLARE @Player_ExRate FLOAT, @Player_CurrencyId INT

	SELECT @AffCurrencyId = Currency
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE AffID = @AffID

	SELECT @Player_CurrencyId = ExchangeId
	FROM dbo.CurrencyConverter WITH (NOLOCK)
	WHERE PartnerCurrency = @Player_Currency

	-- Get player's Exchange rate (row is aff currency, column is player currency)
	SELECT @Player_ExRate = dbo.Aff_GetExchangeRate(@AffCurrencyId, @Player_CurrencyId, DEFAULT)
	
	-- check min amount for withdrawing  
	DECLARE @SName VARCHAR(50), @MinAmount MONEY
	
	SELECT @MinAmount = CAST(SValue AS MONEY)   
    FROM dbo.SystemSettings WITH (NOLOCK)
    WHERE SName = 'AFF_Min' + @PreferredPayment + @AffCurrency  
  
	IF @MinAmount IS NOT NULL AND @Amount < @MinAmount   
	BEGIN  
		SELECT @ErrCode = 133 -- 'Invalid balance account or either the currency or payment method is not supported.'
		RETURN  
	END

	DECLARE @SysCurrency VARCHAR(5), @SysCurrencyId SMALLINT, @SysExRate FLOAT

	SELECT  @SysCurrency = SValue
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE Type = 'Meta' AND SName = 'SystemCurrency'

	SELECT  @SysCurrencyId = ExchangeId
	FROM dbo.Exchange WITH (NOLOCK)
	WHERE Code = @SysCurrency

	SELECT @SysExRate = dbo.Aff_GetExchangeRate(@AffCurrencyId, @SysCurrencyId, DEFAULT)

	IF EXISTS (
		SELECT 1 FROM dbo.AffDetail WITH (NOLOCK) WHERE AffID = @AffID AND Player_Currency IS NULL
	)
	BEGIN
		UPDATE dbo.AffDetail WITH (ROWLOCK, UPDLOCK)
		SET Player_Currency = @Player_Currency
		WHERE AffID = @AffID
	END

	BEGIN TRANSACTION

	BEGIN TRY
		DECLARE @RefNo BIGINT

		SELECT  @TransDate = CURRENT_TIMESTAMP

		INSERT INTO dbo.AffPayout (AffID, UserName, IBCUserName, AffCurrency, Amount, MemberCurrency, MemberExRate, AffPayout, SysCurrency, SysExRate, TransDate, Status)
			VALUES (@AffID, @Player_UserName, @Player_IBCUserName, @AffCurrencyId, -@Amount, @Player_CurrencyId, @Player_ExRate, -@Amount * @Player_ExRate, @SysCurrencyId, @SysExRate, @TransDate, 'pending')

		SELECT @RefNo = SCOPE_IDENTITY()

		INSERT INTO dbo.AffTrans (AffID, TransDate, Amount, Status, Description, Creator, AffCurrency, SysCurrency, SysExRate, TransType, RefID, IsProcessing)
			VALUES (@AffID, @TransDate, -@Amount, 'pending', 'Request payout', @AffID, @AffCurrencyId, @SysCurrencyId, @SysExRate, @TransType, @RefNo, 0)

		SELECT @TransID = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION

		SELECT @@ERROR

		SELECT @ErrCode = 134 -- 'Insert transaction failed.'
		RETURN
	END CATCH

	COMMIT TRANSACTION

	-- Write log
	DECLARE @LogData NVARCHAR(4000), @SPName VARCHAR(100)
	SELECT  @LogData = 'Affiliate request payout. Amount=' +  dbo.Aff_ToString(@Amount)
  
	SELECT  @SPName = OBJECT_NAME(@@PROCID)
   
	EXEC [dbo].[Aff_WriteLog]
		@Creator = @AffID,
		@AffID = @AffID,
		@Typename = 'Payout',
		@SPName = @SPName,
		@IP = @IP,
		@Details = @LogData
END
GO