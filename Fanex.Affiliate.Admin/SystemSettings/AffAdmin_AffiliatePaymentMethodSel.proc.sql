ALTER Procedure [dbo].[AffAdmin_AffiliatePaymentMethodSel]  
    
AS  
BEGIN  
   
SET NOCOUNT ON;  

	SELECT SID,Type,SName,SValue,Description,Environment 
	FROM SystemSettings(nolock)
	WHERE Type='PaymentMethod'

END  
  


