USE [Affiliate_Athena000]
GO
/****** Object:  UserDefinedFunction [dbo].[IsZeroCommissionGroup]    Script Date: 04/28/2014 03:32:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  User Defined Function dbo.IsZeroCommissionGroup    Script Date: 7/29/2013 1:41:25 AM ******/
ALTER FUNCTION [dbo].[IsZeroCommissionGroup]  
(  
    @GroupID int,
    @MonthDate datetime  
)  
RETURNS bit
AS   
/*
   - 20120514@Peter : Check all the setting commission is Zero only             

*/
BEGIN  
 
Declare @Result bit

set @Result=0
if datediff(m,current_timestamp,@MonthDate)>=0 
begin
   if(not exists (select top(1) 1 from GroupSetting (nolock) where groupid=@GroupID and commission <> 0))
      set @Result=1
end
else 
begin
    if(not exists (select top(1) 1 from GroupSettingHistory (nolock) where groupid=@GroupID and datediff(m,monthdate,@MonthDate) =0 and commission <> 0))
      set @Result=1
end

return isnull(@Result,0) 


END

