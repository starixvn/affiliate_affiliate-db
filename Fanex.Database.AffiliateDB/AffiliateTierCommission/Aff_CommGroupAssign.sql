
  
ALTER Procedure [dbo].[Aff_CommGroupAssign]  
 @UserId int,  
 @GroupId int,  
 @AffIDList nvarchar(4000),      
 @IP varchar(20),  
	@Language varchar(5)= 'en-US',
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT,  
 @RefNo bigint = null OUTPUT  
AS  
/*  
Created: 20090719@DungTong  
Task : Assign a commission group (GroupID<1000) for multiple Affilites   
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
Parameters:  
.@UserID : Administrator user id  
.@GroupID : <1000  
.@AfIDList: list of AffID separated by semi colon.Maximum of 200 AffIDs are assiged each time                  
.@IP : IP of admin user               
.@ErrCode:    
              0 : no error raised  
              >0 : there was an error  
.@ErrMsg :     
              empty: no error raised  
              others : the error message detail                            
                            
*/  
SET NOCOUNT ON  
--Check permission  
/*EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@UserID,@funcname='Affiliate',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
*/  
Declare @AffId int  
  
select @AffId = AffID  
from (select top 1 cast(val as int) as AffID from dbo.strsplit(@AffIDList, ';')) tmp  
  
EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@UserID,  
 @AffId=@AffId,  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
  
   
if(@ErrMsg<>'')  
  return  
  
if (@GroupID>1000 or  not exists (select 1 from CommGroup(nolock) where GroupID=@GroupID and IsDeleted=0))  
  begin  
   select @ErrCode=101,
			@ErrMsg = case @Language 
							when 'en-US' then 'Invalid Group. Please check.'
							when 'zh-CN' then N'無效的群組.請確認.'
							when 'zh-TW' then N'无效的群组请确认。'
							else N'Invalid Group. Please check.'
						end
    return  
  end  
  
  
--Check AffIDList  
/*    
    Input params is valid with the correct format. Use Try..Catch to eval the input value  
*/  
declare @NoAff int, @CountCurrency int  
BEGIN TRY  
    select @NoAff=sum(1)  
 from AffInfo with(nolock)  
 where AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ';'))  
   and status='approved' -- and IsClosed=0  
      
 if(@NoAff<> (select sum(1) from dbo.strsplit(@AffIDList, ';')))  
 begin  
  select @ErrCode=102,
		@ErrMsg = case @Language 
							when 'en-US' then 'Invalid Affiliate List. Please check.'
							when 'zh-CN' then N'無效的工作夥伴名單.請確認.'
							when 'zh-TW' then N'无效的工作伙伴名单，请确认。'
							else N'Invalid Affiliate List. Please check.'
						end
  return  
 end   
  
 --Check Currency of Group and Currency of Match   
 Set @CountCurrency=0  
 Select @CountCurrency=count(distinct currency)  
 from AffInfo (nolock)  
 where AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ';'))  
    
 if(isnull(@CountCurrency,0) > 1)  
 begin  
  Select @ErrCode=104,
		@ErrMsg = case @Language 
							when 'en-US' then 'Currency of the group does not match with affiliate''s currency. Please check.'
							when 'zh-CN' then N'貨幣的群組與工作夥伴的群組不相配.請確認.'
							when 'zh-TW' then N'货币的群组与工作伙伴的群组不相配。请确认。'
							else N'Currency of the group does not match with affiliate''s currency. Please check.'
						end
						
  return  
 end  
  
ENd TRY  
BEGIN CATCH  
 select @ErrCode=103,@ErrMsg = case @Language 
							when 'en-US' then 'Invalid Affiliate List. Please check.'
							when 'zh-CN' then N'無效的工作夥伴名單.請確認.'
							when 'zh-TW' then N'无效的工作伙伴名单，请确认。'
							else N'Invalid Affiliate List. Please check.'
						end    
    return  
END CATCH  
  
  
--BEGIN TRANSACTION AFTER CHECKING VALID INPUT DATA  
BEGIN TRANSACTION    
  --Delete GroupID>1000 where GroupID in AffiliateID list and already assigned before  
  Delete DeductionSetting  
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ';'))         
                      and AffID=GroupID  
    )   
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
							when 'en-US' then 'There was an error when updating data.Please try again!'
							when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
							when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
							else N'There was an error when updating data.Please try again!'
						end   
						, @ErrCode = 105  
     return   
   end  
     
  Delete GroupSetting  
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ';'))         
                      and AffID=GroupID  
    )   
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
							when 'en-US' then 'There was an error when updating data.Please try again!'
							when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
							when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
							else N'There was an error when updating data.Please try again!'
						end, @ErrCode = 106  
     return   
   end   
    
  Delete CommGroup     
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ';'))         
                       and AffID=GroupID  
    )   
        
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
							when 'en-US' then 'There was an error when updating data.Please try again!'
							when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
							when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
							else N'There was an error when updating data.Please try again!'
						end, @ErrCode = 107  
     return   
   end  
  
  Update AffInfo with (rowlock,updlock)  
  set GroupID=@GroupID        
  where AffID in (select cast(val as int)  as AffID from dbo.strsplit(@AffIDList, ';'))         
     
   if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
							when 'en-US' then 'There was an error when updating data.Please try again!'
							when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
							when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
							else N'There was an error when updating data.Please try again!'
						end, @ErrCode = 108  
     return   
   end  
          
commit transaction  
 --Write the log   
DECLARE @LogData nvarchar(4000), @SPName varchar(100)  
if ((select count(1) from dbo.strsplit(@AffIDList, ';'))=1)  
  select @AffID=cast(@AffIDList as int)  
else  
  select @AffID=0     
SELECT @LogData = N'Assign a common commission group.GroupID=' + dbo.Aff_ToString(@GroupID)  
                  + '\n AffIDList=' + dbo.Aff_ToString(@AffIDList)     
  
select @SPName=OBJECT_NAME(@@ProcID)  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'CommissionGroup',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @RefNo = @RefNo OUTPUT,   
 @Details=@LogData  
  

GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupAssign] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupAssign] TO [vnteam]

