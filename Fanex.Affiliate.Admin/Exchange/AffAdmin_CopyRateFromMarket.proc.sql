/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

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
	Task: Copy rates from market
	DB: DBAFF
	
	Revisions:
		- 20110223@Viet: initialize SP
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @Date SMALLDATETIME
	SELECT  @Date = MAX([Date]) FROM dbo.ExchangeDaily WITH(NOLOCK)

	DECLARE @TmpExchange TABLE (exchangeid INT)

	INSERT INTO @TmpExchange (exchangeid)
	SELECT CONVERT(INT, val) FROM dbo.strsplit(@ExchangeIdList, ',')

	BEGIN TRANSACTION

	UPDATE ExchangeDaily WITH(ROWLOCK, UPDLOCK)
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
	WHERE exchangeID IN (SELECT exchangeid FROM @TmpExchange)
		AND [Date] = @Date

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END

	UPDATE Exchange WITH(ROWLOCK, UPDLOCK)
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
	WHERE exchangeID IN (SELECT exchangeid FROM @TmpExchange)

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Copy Rates from Market. ExchangeId:' + ISNULL(@ExchangeIdList, '')

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserId
		,@TypeName = 'ExchangeRate'
		,@SPName = @SPName
		,@IP = @IP
		,@Details = @Detail
END
GO