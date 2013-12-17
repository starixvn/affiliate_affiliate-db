 declare @ErrCode int,@ErrMsg nvarchar(200)
Exec [dbo].[DBA_Aff_ExchangeUpdate]
	@CustId =1155577,
	@CurrencyName ='RM',
	@Rate=	0.28269,
	@Date = '1 May 2010',
	@IP = '202.78.228.8',
	@language  = 'E',
	@ErrCode  = @ErrCode OUTPUT,
	@ErrMsg  = 	@ErrMsg OUTPUT

select @ErrCode ,@ErrMsg

Exec [dbo].[DBA_Aff_ExchangeUpdate]
	@CustId =1155577,
	@CurrencyName ='AUD',
	@Rate=	0.83169,
	@Date = '1 May 2010',
	@IP = '202.78.228.8',
	@language  = 'E',
	@ErrCode  = @ErrCode OUTPUT,
	@ErrMsg  = 	@ErrMsg OUTPUT

select @ErrCode ,@ErrMsg


Exec [dbo].[DBA_Aff_ExchangeUpdate]
	@CustId =1155577,
	@CurrencyName ='CHF',
	@Rate=	0.83529,
	@Date = '1 May 2010',
	@IP = '202.78.228.8',
	@language  = 'E',
	@ErrCode  = @ErrCode OUTPUT,
	@ErrMsg  = 	@ErrMsg OUTPUT

select @ErrCode ,@ErrMsg


Exec [dbo].[DBA_Aff_ExchangeUpdate]
	@CustId =1155577,
	@CurrencyName ='EURO',
	@Rate=		1.19646,
	@Date = '1 May 2010',
	@IP = '202.78.228.8',
	@language  = 'E',
	@ErrCode  = @ErrCode OUTPUT,
	@ErrMsg  = 	@ErrMsg OUTPUT

select @ErrCode ,@ErrMsg

Exec [dbo].[DBA_Aff_ExchangeUpdate]
	@CustId =1155577,
	@CurrencyName ='GBP',
	@Rate=	1.37457,
	@Date = '1 May 2010',
	@IP = '202.78.228.8',
	@language  = 'E',
	@ErrCode  = @ErrCode OUTPUT,
	@ErrMsg  = 	@ErrMsg OUTPUT

select @ErrCode ,@ErrMsg

Exec [dbo].[DBA_Aff_ExchangeUpdate]
	@CustId =1155577,
	@CurrencyName ='IN',
	@Rate=	0.0999,
	@Date = '1 May 2010',
	@IP = '202.78.228.8',
	@language  = 'E',
	@ErrCode  = @ErrCode OUTPUT,
	@ErrMsg  = 	@ErrMsg OUTPUT

select @ErrCode ,@ErrMsg

Exec [dbo].[DBA_Aff_ExchangeUpdate]
	@CustId =1155577,
	@CurrencyName ='RMB',
	@Rate=	0.13185,
	@Date = '1 May 2010',
	@IP = '202.78.228.8',
	@language  = 'E',
	@ErrCode  = @ErrCode OUTPUT,
	@ErrMsg  = 	@ErrMsg OUTPUT

select @ErrCode ,@ErrMsg

Exec [dbo].[DBA_Aff_ExchangeUpdate]
	@CustId =1155577,
	@CurrencyName ='SD$',
	@Rate=	0.65691,
	@Date = '1 May 2010',
	@IP = '202.78.228.8',
	@language  = 'E',
	@ErrCode  = @ErrCode OUTPUT,
	@ErrMsg  = 	@ErrMsg OUTPUT

select @ErrCode ,@ErrMsg

Exec [dbo].[DBA_Aff_ExchangeUpdate]
	@CustId =1155577,
	@CurrencyName ='TB',
	@Rate=		0.0279,
	@Date = '1 May 2010',
	@IP = '202.78.228.8',
	@language  = 'E',
	@ErrCode  = @ErrCode OUTPUT,
	@ErrMsg  = 	@ErrMsg OUTPUT

select @ErrCode ,@ErrMsg

Exec [dbo].[DBA_Aff_ExchangeUpdate]
	@CustId =1155577,
	@CurrencyName ='UUS',
	@Rate=	0.000000,
	@Date = '1 May 2010',
	@IP = '202.78.228.8',
	@language  = 'E',
	@ErrCode  = @ErrCode OUTPUT,
	@ErrMsg  = 	@ErrMsg OUTPUT

select @ErrCode ,@ErrMsg


