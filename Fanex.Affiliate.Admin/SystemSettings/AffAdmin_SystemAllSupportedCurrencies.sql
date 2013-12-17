-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_SystemAllSupportedCurrencies]       
AS  
/*    
Task : Get Affiliate System Supported Currencies Information (not affected by permission) 
DB:    
Original:[AffAdmin_SystemAllSupportedCurrencies]      
Revisions:          
  - 20131031@Joseph: create
 */ 
BEGIN  
   
 SET NOCOUNT ON;    
    declare @Currencies varchar(max)  
    select @Currencies=(select SValue from SystemSettings where SName = 'AFF_SupportedCurrencies' and Type ='Meta')  
 -- Insert statements for procedure here  
 select c.CurrencyID,c.CurrencyCode ,c.MultipliedBy from Currency (nolock)  c 
 where c.CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )  
  
END  
  

GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemAllSupportedCurrencies] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_SystemAllSupportedCurrencies] TO [vnteam]