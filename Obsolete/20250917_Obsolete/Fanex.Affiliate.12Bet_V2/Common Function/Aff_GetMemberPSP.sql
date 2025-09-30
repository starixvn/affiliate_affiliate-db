 USE [Affiliate_12BET]
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetMemberPSP]    Script Date: 09/09/2009 16:01:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

  
Alter function [dbo].[Aff_GetMemberPSP] (  
@IBCCustID int,@WinlostDate smalldatetime,@SportID int)  
RETURNS money  
AS  
/*  
 Task : Get PSP fee for member  
		   @WinlostDate=null -->get all.Otherwise will get for specific date  
		   @SportId=0 --> Get all. Otherwisw will get for specific sport type   
 Author : Peter@20090909  
   
*/  
BEGIN   
   Declare @PSP money  
	 
   select @PSP=Sum(PSP)  
  from MemberDaily with(nolock)    
 where IBCCustID =@IBCCustID            
		and WinlostDate = @WinlostDate
		and sporttype  in (0, @SportID)
		--and (case when @Winlostdate is null or @WinlostDate=WinlostDate then 1 else 0 end)=1  
	   --and (case when @SportID=0 or @SportID=sporttype then 1 else 0 end)=1 
   
 return isnull(@PSP,0)  
END