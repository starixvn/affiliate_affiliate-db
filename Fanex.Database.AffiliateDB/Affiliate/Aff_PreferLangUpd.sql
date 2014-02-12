 ALTER Procedure [dbo].[Aff_PreferLangUpd]  
 @affid int,  
 @userid int,  
 @PreferredLanguage varchar(5),    
 @IP varchar(20),  
 @Language varchar(5) = 'en-US',    
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
  
/*Created: 20090822@Peter  
Task : [description of SP]  
DB: DB052.Affiliate_ZZun  
Original : [Aff_PreferLangUpd]  
Revision:s  
  
Param's Explanation:  
• @custid : Affiliate custid  
• @userid : User update  
• @PreferredLanguage : Preferred language update.  
*/  
SET NOCOUNT ON  
/*EXEC [dbo].[Aff_Con_CheckPermission]   
 @custid=@UserID,  
 @funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output*/  
   
EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@UserID,  
 @AffId=@AffId,  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
If @ErrCode <> 0  
 RETURN  
   
if(not exists(select 1 from AffInfo(nolock) where affid=@affid))  
begin  
         SELECT @ErrMsg = case @Language 
							when 'en-US' then 'Invalid Affiliate!'
							when 'zh-CN' then N'無效的工作夥伴!'
							when 'zh-TW' then N'无效的工作伙伴！'
							else N'Invalid Affiliate!'
						end, @ErrCode = 1005  
   return  
end  
   
Update AffDetail with(rowlock,updlock)  
set PreferredLanguage = @PreferredLanguage  
where affid = @affid  
  
IF @@error<>0   
Begin  
 SELECT @ErrMsg = case @Language 
							when 'en-US' then 'Error occurs. Update process is unsuccessful!'
							when 'zh-CN' then N'出現錯誤.更新過程不成功!'
							when 'zh-TW' then N'出现错误。更新过程不成功！'
							else N'Error occurs. Update process is unsuccessful!'
						end, @ErrCode = 1005  
 RETURN  
END  
  
--Write the log   
DECLARE @LogData nvarchar(4000),@SPName varchar(100)  
SELECT @LogData = 'Update Affiliate''s Prefered Languague. '  
                  + 'PreferredLanguage=' +  dbo.Aff_ToString(@PreferredLanguage)  
  
select @SPName=OBJECT_NAME(@@ProcID)  
   
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @Details=@LogData  
	
GO
GRANT EXECUTE ON [dbo].[Aff_PreferLangUpd] TO bodbAdminNet
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PreferLangUpd] TO [VNTeam] 
