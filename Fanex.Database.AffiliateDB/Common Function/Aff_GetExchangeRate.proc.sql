/****** Object:  UserDefinedFunction [dbo].[Aff_GetExchangeRate]    Script Date: 06/03/2013 04:33:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[Aff_GetExchangeRate](    
    @FromCurrency smallint,    
 @ToCurrency smallint,  
 @Date smalldatetime = null  
 )    
 RETURNS float    
AS    
/*    
   Get ExchangeRate @FromCurrency to @ToCurrency    
*/    
BEGIN    
  
if @FromCurrency=@ToCurrency  
  return 1  
  
   -- check @ToCurrency is a base-currency    
select @Date = ISNULL(@Date, current_timestamp)  
  
select @Date = dbo.Date_Only(@Date)  
  
Declare @TmpExchange table([ExchangeID] [smallint],  
        [USD] [float], [USD_Market] [float],  
        [EUR] [float], [EUR_Market] [float],  
        [CNY] [float], [CNY_Market] [float],  
        [UUS] [float], [UUS_Market] [float],  
        [MYR] [float], [MYR_Market] [float],  
        [SGD] [float], [SGD_Market] [float],  
        [IDR] [float], [IDR_Market] [float],  
        [AUD] [float], [AUD_Market] [float],  
        [CHF] [float], [CHF_Market] [float],  
        [GBP] [float], [GBP_Market] [float],  
        [THB] [float], [THB_Market] [float],  
        [VND] [float], [VND_Market] [float],  
        [Code] [varchar](5), [DepositPercent] [float],  
        [WithdrawalPercent] [float], [IsAutoRefresh] [bit])  
  
If(DATEDIFF(D, @Date, CURRENT_TIMESTAMP) = 0)  
begin  
 insert into @TmpExchange  
 Select [ExchangeID],  
   [USD], [USD_Market],  
   [EUR], [EUR_Market],  
   [CNY], [CNY_Market],  
   [UUS], [UUS_Market],  
   [MYR], [MYR_Market],  
   [SGD], [SGD_Market],  
   [IDR], [IDR_Market],  
   [AUD], [AUD_Market],  
   [CHF], [CHF_Market],  
   [GBP], [GBP_Market],  
   [THB], [THB_Market],  
   [VND], [VND_Market],  
   [Code], [DepositPercent],  
   [WithdrawalPercent], [IsAutoRefresh]  
 from Exchange nolock  
end  
Else  
Begin  
 insert into @TmpExchange  
 Select [ExchangeID],  
   [USD], [USD_Market],  
   [EUR], [EUR_Market],  
   [CNY], [CNY_Market],  
   [UUS], [UUS_Market],  
   [MYR], [MYR_Market],  
   [SGD], [SGD_Market],  
   [IDR], [IDR_Market],  
   [AUD], [AUD_Market],  
   [CHF], [CHF_Market],  
   [GBP], [GBP_Market],  
   [THB], [THB_Market],  
   [VND], [VND_Market],  
   [Code], [DepositPercent],  
   [WithdrawalPercent], [IsAutoRefresh]  
 from ExchangeDaily nolock  
 where Date = @Date  
End  
  
  
declare @Rate float, @FromRate float, @ToRate float, @ToCode varchar(5),@FromCode varchar(5),@SysCurrencyCode varchar(5)    
      
select @ToCode=dbo.Aff_GetCurrencyCode(@ToCurrency),@FromCode=dbo.Aff_GetCurrencyCode(@FromCurrency)    
    
if CHARINDEX(@ToCode,dbo.[Aff_GetSettingValue]('Meta','AFF_SupportedCurrencies',NULL))>0  -- if ToCurrency is in base currencies list for the system  
begin    
         
 select @Rate = case @ToCode    
  When 'USD' then USD    
  when 'EUR' then EUR    
  When 'CNY' then CNY    
  when 'UUS' then UUS    
  when 'MYR' then MYR    
  When 'SGD' then SGD  
  when 'IDR' then IDR  
  When 'AUD' then AUD  
  when 'CHF' then CHF  
  when 'GBP' then GBP  
  when 'THB' then THB  
  when 'VND' then VND  
  ELSE 0 end    
 FROM @TmpExchange   
 WHERE ExchangeID = @FromCurrency        
    
end    
else if CHARINDEX(@FromCode,dbo.[Aff_GetSettingValue]('Meta','AFF_SupportedCurrencies',NULL))>0 --from currencies is in list base currencies list  
begin  
     select @Rate = case @FromCode    
  When 'USD' then USD    
  when 'EUR' then EUR    
  When 'CNY' then CNY    
  when 'UUS' then UUS    
  when 'MYR' then MYR    
  When 'SGD' then SGD  
  when 'IDR' then IDR  
  When 'AUD' then AUD  
  when 'CHF' then CHF  
  when 'GBP' then GBP  
  when 'THB' then THB  
  when 'VND' then VND  
  ELSE 0 end    
 FROM @TmpExchange   
 WHERE ExchangeID = @ToCurrency        
   
 if @Rate >= 0.0000000000001   
   select @Rate=1/@Rate    
   
end  
  
else  
begin    
    -- Get SystemCurrency    
    /*     
        1 THB = 0.10670 MYR    
        1 AUD= 3.24 MYR    
    => 1 AUD= ? THB    
    */    
    select @SysCurrencyCode=dbo.[Aff_GetSettingValue]('Meta','SystemCurrency',NULL)    
    select @FromRate = case @SysCurrencyCode    
  When 'USD' then USD    
  when 'EUR' then EUR    
  When 'CNY' then CNY    
  when 'UUS' then UUS    
  when 'MYR' then MYR    
  When 'SGD' then SGD    when 'IDR' then IDR  
  When 'AUD' then AUD  
  when 'CHF' then CHF  
  when 'GBP' then GBP  
  when 'THB' then THB  
  when 'VND' then VND   
  ELSE 0 end    
 FROM @TmpExchange     
 WHERE ExchangeID = @FromCurrency    
       
 select @ToRate = case @SysCurrencyCode    
   When 'USD' then USD    
   when 'EUR' then EUR    
   When 'CNY' then CNY    
   when 'UUS' then UUS    
   when 'MYR' then MYR    
   When 'SGD' then SGD  
   when 'IDR' then IDR  
   When 'AUD' then AUD  
   when 'CHF' then CHF  
   when 'GBP' then GBP  
   when 'THB' then THB  
   when 'VND' then VND    
   ELSE 0 end    
 FROM @TmpExchange     
 WHERE ExchangeID = @ToCurrency    
  
 if @FromRate < 0.0000000000001   
   select @Rate=0  
    else  
     select @Rate=@ToRate/@FromRate      
  
  
        
end    
return @Rate    
     
END  