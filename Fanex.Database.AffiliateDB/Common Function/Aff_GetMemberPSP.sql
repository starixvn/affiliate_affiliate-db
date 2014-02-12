     
ALTER function [dbo].[Aff_GetMemberPSP] (    
@IBCCustID int,@WinlostDate smalldatetime,@ProductID int)    
RETURNS money    
AS    
/*    
 Task : Get PSP fee for member    
           @WinlostDate=null -->get all.Otherwise will get for specific date    
           @ProductID=0 --> Get all. Otherwisw will get for specific sport type     
 Author : Peter@20090909    
     
*/    
BEGIN     
   Declare @PSP money    
       
   select @PSP=Sum(PSP)    
  from MemberDaily with(nolock)      
 where IBCCustID =@IBCCustID              
  and WinlostDate = @WinlostDate  
  and ProductID  in (0, @ProductID)  
  --and (case when @Winlostdate is null or @WinlostDate=WinlostDate then 1 else 0 end)=1    
       --and (case when @ProductID=0 or @ProductID=ProductID then 1 else 0 end)=1   
     
 return isnull(@PSP,0)    
END