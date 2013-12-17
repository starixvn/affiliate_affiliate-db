CREATE function [dbo].[Aff_GetAffDeductionBaseAll] (  
	@AffID int,  
	@MonthDate smalldatetime
)  
RETURNS money  
AS  
/*  
 Task : Get sum Deduction value for affiliate of a month  
 Author : 20131212@Johnny
   
*/  
BEGIN   
   Declare @AffDeductionAllAmount money, @GroupID int  
   select @MonthDate=isnull(@MonthDate,current_timestamp)   
   if(datediff(m,current_timestamp,@MonthDate)<0)  
    BEGIN  
       select @GroupID=GroupID  
       from AffGroupHistory with (nolock)  
       where AffID=@AffID and datediff(m,MonthDate,@MonthDate)=0  
         
       select @AffDeductionAllAmount= sum(isnull(a.Amount,0) * isnull(d.DeductedPercentage,0) * ISNULL(a.SysExRate, 0))  
       from AffDeductionTransaction a with (nolock)    
             inner join  DeductionSettingHistory d with (nolock)  on d.DeductionID=a.DTypeID and datediff(m,a.MonthDate,d.MonthDate)=0               
  where d.GroupID=@GroupID   
              and a.AffID=@AffID  
      and datediff(m,d.MonthDate,@MonthDate)=0  
              and a.ProductID=0                 
 END  
 ELSE  
 BEGIN  
    select @GroupID=GroupID  
       from AffInfo with (nolock)  
       where AffID=@AffID  
         
   select @AffDeductionAllAmount=sum(isnull(a.Amount,0) * isnull(d.DeductedPercentage,0) * ISNULL(a.SysExRate, 0))  
       from AffDeductionTransaction a with (nolock)    
             inner join  DeductionSetting d with (nolock)  on d.DeductionID=a.DTypeID   
  where d.GroupID=@GroupID   
              and a.AffID=@AffID  
      and datediff(m,a.MonthDate,@MonthDate)=0  
              and a.ProductID=0                    
 END  
   
 return isnull(@AffDeductionAllAmount,0)  
END  
  
  