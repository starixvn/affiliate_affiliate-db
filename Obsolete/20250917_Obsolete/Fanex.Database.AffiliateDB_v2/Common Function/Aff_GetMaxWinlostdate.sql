  
ALTER function [dbo].[Aff_GetMaxWinlostdate] (  
@AffID int,@ProductID tinyint,@MonthDate smalldatetime)  
RETURNS smalldatetime  
AS  
/*  
 Task : Get the current max winlostdate for a specific month of affiliate  
 Author : Peter@20101126  
 @MonthDate=null : current month  
*/  
BEGIN    
      
   select @MonthDate=isnull(@MonthDate,current_timestamp)   
     
   declare @MaxWinlostDate smalldatetime  
   select @MaxWinlostDate=max(winlostdate)  
   from AffDailySummary (nolock)   
  where datediff(m,winlostdate,@MonthDate)=0  
    and AffID= @AffID and ProductID=@ProductID  
      
   return @MaxWinlostDate  
END