/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_TransferBalanceInfo_Sel]
	@AffId			INT
	,@PlayerName	VARCHAR(50)
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User site - Transfer Balance For Player

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @TimeZone INT = dbo.Aff_f_GetSetting('TimeZone')
	DECLARE @CurrentDate DATETIME = CONVERT(DATE, DATEADD(HOUR, 4 + @TimeZone, GETDATE()))

	DECLARE @PaymentAccountId INT, @PaymentAccountName VARCHAR(50), @PaymentAccountCurrencyId INT, @PaymentAccountCurrency VARCHAR(10)
	DECLARE @PlayerId INT, @PlayerCurrencyId INT, @PlayerCurrency VARCHAR(10)
	DECLARE @TransferLimit MONEY, @DisabledTransfer BIT, @TransferedAmount MONEY
	DECLARE @PlayerExRate DECIMAL(20, 5), @PaymentAccountExRate DECIMAL(20, 5)

	-- Payment Account Info
	SELECT @PaymentAccountId = Player_CustId, @PaymentAccountName = Player_Username
		,@PaymentAccountCurrencyId = Player_Currency, @PaymentAccountCurrency = Player_CurrencyCode
		,@TransferLimit = ISNULL(TransferLimit, 0), @DisabledTransfer = ISNULL(DisabledTransfer, 0)
	FROM dbo.AffDetail WITH (NOLOCK) WHERE AffId = @AffId

	-- Payment Account Info Mapping
	DECLARE @PaymentAccountExchangeId INT = @PaymentAccountCurrencyId
	SELECT @PaymentAccountExchangeId = tp.ExchangeId
	FROM dbo.TpExchange tp WITH (NOLOCK)
	WHERE tp.TpExchangeId = @PaymentAccountCurrencyId

	-- Player Info
	SELECT @PlayerId = CustId, @PlayerCurrencyId = Currency
	FROM dbo.MemberInfo WITH (NOLOCK) WHERE AffId = @AffId AND UserName = @PlayerName AND IsRemoved = 0

	-- Player Info mapping
	DECLARE @PlayerExchangeId INT = @PlayerCurrencyId 
	SELECT  @PlayerExchangeId = tp.ExchangeId
	FROM dbo.TpExchange tp WITH (NOLOCK)
	WHERE tp.TpExchangeId = @PlayerCurrencyId

	-- Exchange Rate
	SELECT @PlayerExRate = Rate, @PlayerCurrency = Code
	FROM dbo.Aff_f_ExchangeRate_Sel(@CurrentDate, @PlayerExchangeId, @PaymentAccountExchangeId)

	SELECT @PaymentAccountExRate = Rate
	FROM dbo.Aff_f_ExchangeRate_Sel(@CurrentDate, @PaymentAccountExchangeId, @PlayerExchangeId)

	-- Transfered Amount
	IF @TransferLimit < 100000000000 -- 100,000,000,000 = Unlimited
		SELECT @TransferedAmount = SUM(Amount * ExRate)
		FROM dbo.TransferBalanceHistory WITH (NOLOCK)
		WHERE TransDate = @CurrentDate
			AND AffId = @AffId
			AND CustId = @PlayerId
			AND Status IN ('Completed', 'Pending')

	SELECT @TransferedAmount = ISNULL(@TransferedAmount, 0)

	-- Return data
	SELECT @PaymentAccountId		AS PaymentAccountId
		,@PaymentAccountName		AS PaymentAccountName
		,@PaymentAccountCurrencyId	AS PaymentAccountCurrencyId
		,@PaymentAccountCurrency	AS PaymentAccountCurrency
		,@PaymentAccountExRate		AS PaymentAccountExRate
		,@PlayerId			AS PlayerId
		,@PlayerCurrencyId	AS PlayerCurrencyId
		,@PlayerCurrency	AS PlayerCurrency
		,@PlayerExRate		AS PlayerExRate
		,@TransferLimit		AS TransferLimit
		,@TransferedAmount	AS TransferedAmount
END
GO