ALTER PROCEDURE [dbo].[Aff_EmailHistoryDel]  
  @listmid varchar(4000)=null,  
  @UserID int,  
  @IP varchar(20),  
	@Language varchar(5)= 'en-US', 
  @ErrCode int = 0 OUTPUT,  
  @ErrMsg nvarchar(4000) = '' OUTPUT  
AS  
/*  
Created: 20090626@VinhTrinh  
Task : Delete affiliate email by list of mail id  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
  
Param's Explanation:  
• @listmid : list of mail id separated by a comma  
• @UserID: user deleting mid will be logged  
• @ErrCode:  
= 0: Transaction recorded successfully.  
101: Invalid message ID.  
1001: Unsuccessful deleting msg.  
  
• @ErrMsg: Error description.  
*/  
-----------------------------------------------  
SET NOCOUNT ON  
--Check permission(If AffId = userid => Affiliate update info else Admin Update Aff info)-----------------------------  
  
EXEC [dbo].[Aff_Con_CheckPermission]   
 @custid=@UserID,  
 @funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
  
If @ErrCode <> 0  
 RETURN  
  
--Check list of mail id  
if(@listmid is null)  
begin  
 Select @ErrMsg = case @Language 
							when 'en-US' then 'Invalid mail ID!' 
							when 'zh-CN' then N'無效的電子郵件ID!'
							when 'zh-TW' then N'无效的电子邮件ID！'
							else N'Invalid mail ID!' 
						end, @ErrCode = 101   
 return  
end   
  
declare @midTable table(mid int)  
 insert into  @midTable  
         select distinct val from dbo.strsplit(@listmid,',')  
 declare @count int,@countDB int  
  select @count=count(1) from @midTable  
    select @countDB=count(1)  
          from EmailHistory a  (nolock)  
               inner join @midTable t on a.mid=t.mid  
      
    if (@count <> @countDB)  
  BEGIN  
    Select @ErrMsg = case @Language 
							when 'en-US' then 'Sorry, the selected email(s) are invalid. Please recheck them again.' 
							when 'zh-CN' then N'抱歉,所選的電子郵件是無效的.請重新確認.'
							when 'zh-TW' then N'抱歉，所选的电子邮件是无效的，请重新确认。'
							else N'Sorry, the selected email(s) are invalid. Please recheck them again.' 
						end,           
		@ErrCode = 102  
         return        
        END      
--Check UserID is valid  
if(not exists(select 1 from AdminUser (nolock) where custid=@UserID))  
begin  
  Select @ErrMsg = case @Language 
							when 'en-US' then 'Sorry, Admin id is invalid. Please recheck it again.' 
							when 'zh-CN' then N'抱歉, 管理員ID是無效的.請重新確認.'
							when 'zh-TW' then N'抱歉，管理员ID是无效的，请重新确认。'
							else N'Sorry, Admin id is invalid. Please recheck it again.' 
						end,           
     @ErrCode = 103  
         return  
end  
  
  
Delete EmailHistory with(rowlock)  
WHERE mid in (select mid from @midTable)  
  
IF @@ERROR <> 0  
BEGIN  
   
 Select @ErrMsg = case @Language 
							when 'en-US' then 'Error! Email unsuccessfully deleted!' 
							when 'zh-CN' then N'錯誤!電子郵件刪除不成功!'
							when 'zh-TW' then N'错误！电子邮件删除不成功！'
							else N'Error! Email unsuccessfully deleted!' 
						end, @ErrCode = 1001  
 return  
END  
  
DECLARE @LogData nvarchar(200)  
SELECT @LogData = 'Delete EmailHistory Mail ID list:' + dbo.Aff_ToString(@listmid)  
  
declare @SPName varchar(50)  
select @SPName = OBJECT_NAME(@@ProcID)   
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @TypeName= 'Email',   
 @SPName=@SPName,  
 @IP =@IP,  
 @Details=@LogData  
   
	
GO
GRANT EXECUTE ON [dbo].[Aff_EmailHistoryDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_EmailHistoryDel] TO [vnteam]
GO

