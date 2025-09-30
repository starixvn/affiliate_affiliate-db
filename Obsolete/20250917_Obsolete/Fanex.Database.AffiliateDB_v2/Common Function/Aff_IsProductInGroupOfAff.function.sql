
/****** Object:  UserDefinedFunction [dbo].[Aff_IsProductInGroupOfAff]    Script Date: 07/02/2013 02:54:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [dbo].[Aff_IsProductInGroupOfAff] (  
@AffID int,@ProductID int ,@MonthDate datetime=null)  
RETURNS int  
AS  
BEGIN   

declare @MinMonthDate datetime

select @MinMonthDate=MIN(MonthDate) from AffGroupHistory(nolock)
if datediff(m,CURRENT_TIMESTAMP,@MonthDate)>0 or datediff(m,@MinMonthDate,@MonthDate) < 0
  return 0
 Select @MonthDate=coalesce(@MonthDate,current_timestamp)  
 select @MonthDate=[dbo].[Aff_GetLastDayOfMonth](@MonthDate)  
 select @MonthDate=dbo.Aff_GetSmallDatetime(@MonthDate)  
 declare @Result int  
   
 if(datediff(m,current_timestamp,@MonthDate)>=0)  
 begin  
  select @Result=count(distinct c.ProductID)
  from AffInfo a with(nolock)  
  inner join GroupSetting c with(nolock) on a.GroupId = c.GroupId  
  where AffId = @AffId and  c.ProductID=@ProductID
 end  
 else  
 begin  
   select @Result=count(distinct c.ProductID) 
  from AffGroupHistory a with(nolock)  
  inner join GroupSettingHistory c with(nolock) on a.GroupId = c.GroupId  
  where a.AffId = @AffId and a.MonthDate=@MonthDate and c.MonthDate=@MonthDate and  c.ProductID=@ProductID  

 end  
   
     
 return isnull(@Result,0)  
END
