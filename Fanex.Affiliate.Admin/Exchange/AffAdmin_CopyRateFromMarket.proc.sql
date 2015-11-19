ALTER PROCEDURE [dbo].[AffAdmin_CopyRateFromMarket] 
	@LicenseeID INT
	,@UserId INT
	,@ExchangeIdList VARCHAR(max) = ''
	,@IP VARCHAR(20)
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20110223@Viet
	Task : Copy rates from market
	DB: DB052.Affiliate_ZZun
	Revisions:
		- 20110223@Viet: initialize SP
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		
*/
BEGIN
	SET NOCOUNT ON

	--Check permission-----------------------------
	EXEC [dbo].[Aff_Con_CheckPermission] @LicenseeID = @LicenseeID
		,@custid = @UserId
		,@funcname = '[AffEx.Rate]'
		,@System = 'AFFILIATE'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0 RETURN

	DECLARE @Date SMALLDATETIME

	SELECT @Date = Max([Date])
	FROM ExchangeDaily WITH (NOLOCK)

	DECLARE @TmpExchange TABLE (exchangeid INT)

	INSERT INTO @TmpExchange
	SELECT val
	FROM dbo.strsplit(@ExchangeIdList, ',')

	UPDATE ExchangeDaily WITH (ROWLOCK, UPDLOCK)
	SET USD = USD_market
		,EUR = EUR_market
		,CNY = CNY_market
		,UUS = UUS_market
		,MYR = MYR_Market
		,SGD = SGD_Market
		,IDR = IDR_Market
		,AUD = AUD_Market
		,CHF = CHF_Market
		,GBP = GBP_Market
		,THB = THB_Market
		,VND = VND_Market
		,KRW = KRW_Market
		,JPY = JPY_Market
	WHERE exchangeID IN (
			SELECT exchangeid
			FROM @TmpExchange
			)
		AND [Date] = @Date

	UPDATE Exchange WITH (ROWLOCK, UPDLOCK)
	SET USD = USD_market
		,EUR = EUR_market
		,CNY = CNY_market
		,UUS = UUS_market
		,MYR = MYR_Market
		,SGD = SGD_Market
		,IDR = IDR_Market
		,AUD = AUD_Market
		,CHF = CHF_Market
		,GBP = GBP_Market
		,THB = THB_Market
		,VND = VND_Market
		,KRW = KRW_Market
		,JPY = JPY_Market
	WHERE exchangeID IN (
			SELECT exchangeid
			FROM @TmpExchange
			)

	DECLARE @LogData NVARCHAR(200)
		,@SPName VARCHAR(50)

	SELECT @LogData = 'Copy Rates from Market. ExchangeId:' + isnull(@ExchangeIdList, '')
		,@SPName = OBJECT_NAME(@@ProcID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserId
		,@TypeName = 'ExchangeRate'
		,@SPName = @SPName
		,@IP = @IP
		,@Details = @LogData
END
GO


