ALTER function [dbo].[Aff_GetMemberWinlost] (  
@AffID int,@ProductID tinyint, @MonthDate smalldatetime)  
RETURNS money  
AS  
/*  
 Task : Get MemberWinlost for Affiliate  
 Author : Peter@20100508  
 @MonthDate=null : current month  
*/  
BEGIN    
    declare @MemberWinlost money  
    select @MemberWinlost=0  
      
    If Datediff(m, @monthdate, current_timestamp) = 0  
    BEGIN  
            Declare @Today smalldatetime,@FirstDay smalldatetime,@LastDay smalldatetime  
  
   Select @FirstDay = cast(cast(year(getdate()) as varchar(5)) + '-' + cast(Month(getdate()) as varchar(5)) + '-' +'1' as smalldatetime)  
   --Get last day of inputted month  
   Select @Today = convert (varchar(12),current_timestamp)  
   select @LastDay=@Today   
     
   select @MemberWinlost=sum(isnull(MemWinlost,0) * isnull(AffExRate,0))  
   from AffDaily (nolock)   
   where AffId=@AffID and ProductID=@ProductID and winlostdate between @FirstDay and @LastDay  
     
    END  
    ELSE  
    BEGIN  
        Declare @MaxTransDate smalldatetime   
     select @MaxTransDate = Max(winlostdate) From AffCommission(nolock)  
     If @MaxTransDate < @monthdate  
   BEGIN  
          select @MemberWinlost=sum(isnull(MemWinlost,0) * isnull(AffExRate,0))  
    from AffDaily (nolock)   
    where AffId=@AffID and ProductID=@ProductID and datediff(m,WinlostDate,@MonthDate) = 0  
   END  
     ELSE  
   BEGIN  
          Select @MemberWinlost = isnull(MemberWinlost, 0) From AffCommission(nolock) where AffId = @AffId and WinlostDate = @monthdate and ProductID=@ProductID  
   END  
    END      
     
    return  isnull(@MemberWinlost,0)  
END  
  
  