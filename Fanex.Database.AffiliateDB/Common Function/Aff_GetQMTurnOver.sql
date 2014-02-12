ALTER function [dbo].[Aff_GetQMTurnOver] (  
@AffID int,@MonthDate datetime=null)  
RETURNS money  
AS  
/*  
 Task : Get Balance Brought Forward for Affiliate  
 Author : Peter@20090909  
   
*/  
BEGIN   
 Select @MonthDate=coalesce(@MonthDate,current_timestamp)  
 select @MonthDate=[dbo].[Aff_GetLastDayOfMonth](@MonthDate)  
 select @MonthDate=dbo.Aff_GetSmallDatetime(@MonthDate)  
 declare @QMTurnover money  
   
 if(datediff(m,@MonthDate,current_timestamp)>=0)  
 begin  
  select @QMTurnover = QualifiedAmount  
  from AffInfo a with(nolock)  
  inner join CommGroup c with(nolock) on a.GroupId = c.GroupId  
  where AffId = @AffId  
 end  
 else  
 begin  
  select @QMTurnover = QualifiedAmount  
  from AffGroupHistory a with(nolock)  
  inner join CommGroupHistory c with(nolock) on a.GroupId = c.GroupId  
  where a.AffId = @AffId and a.MonthDate=@MonthDate and c.MonthDate=@MonthDate  
 end  
   
     
 return isnull(@QMTurnover,0)  
END  