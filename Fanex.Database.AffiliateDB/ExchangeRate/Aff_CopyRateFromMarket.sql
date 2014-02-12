ALTER PROCEDURE [dbo].[Aff_CopyRateFromMarket]
	@CustId int,
	@ExchangeIdList varchar(max)='',	
	@IP varchar(20),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: 20110223@Viet
	Task : Copy rates from market
	DB: DB052.Affiliate_ZZun
	Revisions:
		- 20110223@Viet: initialize SP
		
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@CustId,@funcname='[AffEx.Rate]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0	RETURN	

DECLARE @Date smalldatetime
SELECT @Date = Max([Date]) FROM ExchangeDaily with(nolock)
declare @TmpExchange table(exchangeid int)

insert into  @TmpExchange
select val from dbo.strsplit(@ExchangeIdList, ',')


UPDATE ExchangeDaily with(rowlock, updlock)
SET USD = USD_market,
	EUR = EUR_market,
	CNY = CNY_market,
	UUS = UUS_market,
	MYR = MYR_Market,
	SGD = SGD_Market,
	IDR = IDR_Market,
	AUD = AUD_Market,
	CHF = CHF_Market,
	GBP = GBP_Market,
	THB = THB_Market,
	VND = VND_Market
WHERE exchangeID in (select exchangeid from @TmpExchange)
	AND [Date] = @Date
		
UPDATE Exchange with(rowlock, updlock)
SET USD = USD_market,
	EUR = EUR_market,
	CNY = CNY_market,
	UUS = UUS_market,
	MYR = MYR_Market,
	SGD = SGD_Market,
	IDR = IDR_Market,
	AUD = AUD_Market,
	CHF = CHF_Market,
	GBP = GBP_Market,
	THB = THB_Market,
	VND = VND_Market
WHERE exchangeID in (select exchangeid from @TmpExchange)
		
DECLARE @LogData nvarchar(200), @SPName varchar(50)
SELECT @LogData = 'Copy Rates from Market. ExchangeId:' + isnull(@ExchangeIdList,'')
	   ,@SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator=@CustId,		
	@TypeName= 'ExchangeRate',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData

	
GO
GRANT EXEC ON [dbo].[Aff_CopyRateFromMarket] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CopyRateFromMarket] TO [VNTeam]