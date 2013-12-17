-- =============================================
-- Script Template
-- =============================================

ALTER Procedure [dbo].[AffAdmin_SystemSupportedCurrencies]   
    @UserId int
AS  
/*    
Task : Get Affiliate System Supported Currencies Information  
DB:    
Original:[Aff_SystemSupportedCurrencies]      
Revisions:          
 - 20130219@Peter: created 
 - 20130830@Joseph: restrict user permission by currency   
 */ 
BEGIN  
   
 SET NOCOUNT ON;  
  SELECT AttributeID as CurrencyID INTO #tmpCurrency
FROM dbo.Aff_f_GetCurrencybyUser (@UserId,1)
    declare @Currencies varchar(max)  
    select @Currencies=(select SValue from SystemSettings where SName = 'AFF_SupportedCurrencies' and Type ='Meta')  
 -- Insert statements for procedure here  
 select c.CurrencyCode, c.CurrencyID ,c.MultipliedBy from Currency (nolock)  c
 inner join #tmpCurrency tmp ON c.CurrencyID=tmp.CurrencyID
 where c.CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )  
  
END  
  
  GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSupportedCurrencies] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_SystemSupportedCurrencies] TO [vnteam]
  
  