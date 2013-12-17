set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

  
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