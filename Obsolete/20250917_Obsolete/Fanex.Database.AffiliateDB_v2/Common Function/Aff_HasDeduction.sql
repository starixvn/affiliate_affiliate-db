  
CREATE function [dbo].[Aff_HasDeduction] (  
@GroupID int,@ProductID tinyint, @DeductionName nvarchar(50),@MonthDate smalldatetime)  
RETURNS bit  
AS  
/*  
 Task : Check a sport has a deduction name  
 Author : Peter@20090909  
 @MonthDate=null : current month  
*/  
BEGIN    
      
    select @MonthDate=isnull(@MonthDate,current_timestamp)   
    if(datediff(m,current_timestamp,@MonthDate)<0)  
    BEGIN  
    if(exists (select top(1) 1   
      from DeductionSettingHistory with (nolock)   
      where GroupID=@GroupID   
      and datediff(m,MonthDate,@MonthDate)=0   
      and DeductionID= (select top(1) DTypeID  
             from DeductionType   
             where ProductID=@ProductID and DTypeName=@DeductionName)   
       )  
   )  
    return 1  
    else  
   return 0  
 END  
 ELSE  
 BEGIN  
    if(exists (select top(1) 1   
      from DeductionSetting with (nolock)   
      where GroupID=@GroupID         
      and DeductionID= (select top(1) DTypeID  
             from DeductionType   
             where ProductID=@ProductID and DTypeName=@DeductionName)   
       )  
   )  
    return 1  
    else  
   return 0  
 END  
     
   return 0   
END