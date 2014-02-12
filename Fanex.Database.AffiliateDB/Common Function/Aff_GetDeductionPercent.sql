ALTER function [dbo].[Aff_GetDeductionPercent] (  
@AffID int,@ProductID tinyint, @DeductionName nvarchar(50),@MonthDate smalldatetime)  
RETURNS float  
AS  
/*  
 Task : Check a sport has a deduction name  
 Author : Peter@20090909  
 @MonthDate=null : current month  
*/  
BEGIN    
    declare @percent float,@GroupID int  
    select @percent=null  
      
   select @MonthDate=isnull(@MonthDate,current_timestamp)   
   if(datediff(m,current_timestamp,@MonthDate)<0)  
    BEGIN  
       select @GroupID=GroupID  
       from AffGroupHistory with (nolock)  
       where AffID=@AffID and datediff(m,MonthDate,@MonthDate)=0  
         
       select @percent= DeductedPercentage  
       from DeductionSettingHistory with (nolock)   
      where GroupID=@GroupID   
      and datediff(m,MonthDate,@MonthDate)=0  
      and DeductionID= (select top(1) DTypeID  
             from DeductionType   
             where ProductID=@ProductID and DTypeName=@DeductionName)  
 END  
 ELSE  
 BEGIN  
    select @GroupID=GroupID  
       from AffInfo with (nolock)  
       where AffID=@AffID  
         
    select @percent= DeductedPercentage  
       from DeductionSetting with (nolock)   
      where GroupID=@GroupID         
      and DeductionID= (select top(1) DTypeID  
             from DeductionType   
             where ProductID=@ProductID and DTypeName=@DeductionName)         
 END  
 if(@percent is NULL)  
  set @percent=0  
   return @percent  
END