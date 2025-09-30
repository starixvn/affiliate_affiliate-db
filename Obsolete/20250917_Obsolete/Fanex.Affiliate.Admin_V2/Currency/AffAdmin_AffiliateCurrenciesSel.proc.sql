ALTER Procedure [dbo].[AffAdmin_AffiliateCurrenciesSel]  
    
AS  
BEGIN  
   
 SET NOCOUNT ON;  
  
    declare @Currencies varchar(max)  
    select @Currencies=(select SValue from SystemSettings where SName = 'AffiliateCurrencies' and Type ='Meta')  
 -- Insert statements for procedure here  
 select CurrencyCode as Code,'' as Prefix, CurrencyID as ExchangeID,MultipliedBy from Currency (nolock)  
 where CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )  
  
  
  
END  
  
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateCurrenciesSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffiliateCurrenciesSel] TO [vnteam]