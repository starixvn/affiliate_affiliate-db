/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_TransferBalanceHistory_Ins]
	@AffId						INT
	,@PaymentAccountId			INT
	,@PaymentAccountCurrencyId	INT
	,@PaymentAccountExRate		DECIMAL(20, 5)
	,@PlayerId					INT
	,@PlayerCurrencyId			INT
	,@PlayerExRate				DECIMAL(20, 5)
	,@Amount					MONEY
	,@TransId					BIGINT = 0 OUTPUT
	,@ErrCode					INT = 0 OUTPUT
	,@ErrMsg					NVARCHAR(1000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Transfer Balance For Player

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	-- For convert timezone: from GMT-4 (server) to @TimeZone
	DECLARE @TimeZone INT
	SELECT  @TimeZone = dbo.Aff_f_GetSetting('TimeZone')

	DECLARE @currentTime DATETIME = DATEADD(HOUR, 4 + @TimeZone, GETDATE())
	DECLARE @currentDate DATETIME = CONVERT(DATE, @currentTime)

	--Get payment account currency mapping
	DECLARE @PaymentAccountExchangeId INT = @PaymentAccountCurrencyId
	SELECT @PaymentAccountExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @PaymentAccountCurrencyId

	--Get player currency mapping
	DECLARE @PlayerExchangeId INT = @PlayerCurrencyId
	SELECT @PlayerExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @PlayerCurrencyId

	-- Check Exchange Rate
	IF NOT EXISTS (
		SELECT 1
		FROM dbo.Aff_f_ExchangeRate_Sel(@currentDate, @PlayerExchangeId, @PaymentAccountExchangeId)
		WHERE CONVERT(DECIMAL(20, 5), Rate) = ISNULL(@PlayerExRate, 0)
	)
		OR NOT EXISTS (
		SELECT 1
		FROM dbo.Aff_f_ExchangeRate_Sel(@currentDate, @PaymentAccountExchangeId, @PlayerExchangeId)
		WHERE CONVERT(DECIMAL(20, 5), Rate) = ISNULL(@PaymentAccountExRate, 0)
	)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Exchange rate has just been updated, please submit again.'
		RETURN
	END

	-- Check exists transfer request is being processed
	IF EXISTS (
		SELECT 1 FROM dbo.TransferBalanceHistory WITH (NOLOCK) WHERE AffId = @AffId AND Status = 'Pending'
	)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'You have a pending transaction. Please wait until the pending transaction completes and try again.'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.MemberInfo WITH(NOLOCK) WHERE IsRemoved = 1 AND CustId = @PlayerId)
	BEGIN
		SELECT @ErrCode = 107, @ErrMsg = 'Player is removed. Please check again.'
		RETURN
	END

	-- Check Amount
	IF @Amount <= 0
	BEGIN
		SELECT @ErrCode = 105, @ErrMsg = 'Amount must be a whole positive number.'
		RETURN
	END

	-- Check Transfer Limit Amount
	DECLARE @TransferLimit MONEY = 0
	SELECT  @TransferLimit = ISNULL(TransferLimit * @PaymentAccountExRate, 0) FROM dbo.AffDetail WITH (NOLOCK) WHERE AffId = @AffId

	IF @TransferLimit < 100000000000 -- 100,000,000,000 = Unlimited
	BEGIN
		SELECT @TransferLimit = @TransferLimit - ISNULL(SUM(Amount), 0)
		FROM dbo.TransferBalanceHistory WITH (NOLOCK)
		WHERE TransDate = @currentDate
			AND AffId = @AffId
			AND CustId = @PlayerId
			AND Status IN ('Completed', 'Pending')

		IF @Amount > @TransferLimit
		BEGIN
			SELECT @ErrCode = 106, @ErrMsg = 'Amount must not exceed Transfer Limit.'
			RETURN
		END
	END

	BEGIN TRY
		INSERT INTO dbo.TransferBalanceHistory
		(
			TransTime,TransDate,Status,AffId,AffUserName,Player_CustId,Player_UserName,Player_Currency,Player_CurrencyCode
			,CustId,UserName,Currency,CurrencyCode,Amount,ExRate
		)
		SELECT @currentTime,@currentDate,'Pending',a.AffId,a.UserName,a.Player_CustId,a.Player_UserName,a.Player_Currency,a.Player_CurrencyCode
			,m.CustId,m.UserName,m.Currency,e.Code,@Amount,@PlayerExRate
		FROM dbo.AffDetail a WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON a.AffId = m.AffId
			LEFT JOIN dbo.TpExchange tp WITH (NOLOCK) ON m.Currency = tp.TpExchangeId
			INNER JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(tp.ExchangeId, m.Currency) = e.ExchangeId
		WHERE a.AffId = @AffId AND m.CustId = @PlayerId
			AND a.Player_CustId = @PaymentAccountId
			AND a.Player_Currency = @PaymentAccountCurrencyId

		SET @TransId = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = 'Insert transaction failed!'
		RETURN
	END CATCH

	IF ISNULL(@TransId, 0) = 0
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'Invalid input data!'
		RETURN
	END
END
GO