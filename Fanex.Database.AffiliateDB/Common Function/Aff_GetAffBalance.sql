ALTER function [dbo].[Aff_GetAffBalance] (  
@AffID int)  
RETURNS money  
AS  
/*  
 Task : Get Balance Brought Forward for Affiliate  
 Author : Peter@20090909  
   
*/  
BEGIN   
   Declare @BalBroughtForward money  
 select @BalBroughtForward=sum(Amount)  
 from AffTrans (nolock)  
 where AffID=@AffId and status in ('approved','pending','completed')    
 return isnull(@BalBroughtForward,0)  
END  