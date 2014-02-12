ALTER Procedure [dbo].[Aff_AffiliateUnlockMultiple]  
 @UserId int,   
 @AffIDList varchar(max),      
 @IP varchar(20),  
	@Language varchar(5)= 'en-US',
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT,  
 @RefNo bigint = null OUTPUT  
AS  
/*  
Created: 20090719@DungTong  
Task : Unlock/Lock for multiple Affilites   
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
Parameters:  
.@UserID : Administrator user id  
.@GroupID : <1000  
.@AfIDList: list of AffID   
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
EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@UserID,@funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
if(@ErrMsg<>'')  
  return  
  
  
--Check AffIDList  
/*    
    Input params is valid with the correct format. Use Try..Catch to eval the input value  
*/  
declare @NoAff int  
BEGIN TRY  
    select @NoAff=sum(1)  
 from AffInfo with(nolock)  
 where AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ','))  
   and status='approved' -- and IsClosed=0  
      
 if(@NoAff<> (select sum(1) from dbo.strsplit(@AffIDList, ',')))  
 begin  
  select @ErrCode=102,@ErrMsg = case @Language 
							when 'en-US' then 'Invalid Affiliate List. Please check.'
							when 'zh-CN' then N'無效的工作夥伴名單.請確認.'
							when 'zh-TW' then N'无效的工作伙伴名单，请确认。'
							else N'Invalid Affiliate List. Please check.'
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
  
update AffInfo with (rowlock,updlock)  
set IsLocked=~isnull(IsLocked,0)  
where AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ','))  
UPDATE AffDetail with (rowlock, updlock)  
SET logincount = 0  
WHERE AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ','))  
  
 --Write the log   
DECLARE @LogData nvarchar(4000), @SPName varchar(100)  
    
SELECT @LogData = N'Lock/Unlock Affiliate.AffIDList=' + isnull(@AffIDList,' ')     
  
select @SPName=OBJECT_NAME(@@ProcID)  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=0,  
 @Typename= 'Affiliate',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @RefNo = @RefNo OUTPUT,   
 @Details=@LogData  
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUnlockMultiple] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateUnlockMultiple] TO [vnteam]

