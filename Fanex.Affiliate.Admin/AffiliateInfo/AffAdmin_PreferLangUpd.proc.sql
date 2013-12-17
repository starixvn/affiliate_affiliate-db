CREATE Procedure [dbo].[AffAdmin_PreferLangUpd]  
 @affid int,  
 @userid int,  
 @PreferredLanguage varchar(5),    
 @IP varchar(20),  
 @Language varchar(5) = 'en-US',    
 @ErrCode int = 0 OUTPUT
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
 @ErrCode=@ErrCode output
   
If @ErrCode <> 0  
 RETURN  
   
if(not exists(select 1 from AffInfo(nolock) where affid=@affid))  
begin  
         SELECT @ErrCode = 1006  
   return  
end  
   
Update AffDetail with(rowlock,updlock)  
set PreferredLanguage = @PreferredLanguage  
where affid = @affid  
  
IF @@error<>0   
Begin  
 SELECT @ErrCode = 1005  
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
	


