ALTER Procedure [dbo].[AffAdmin_AffiliateUpdClosedStatus]  
 @affid int,  
 @userid int,  
 @closed bit,  
 @ip varchar(20),  
	@Language varchar(5)= 'en-US', 
 @ErrCode int = 0 OUTPUT 
AS    
/*Created: 20090321@Peter  
Task : [description of SP]  
DB: DB052.Affiliate_ZZun  
Original : [Aff_AffiliateUpdClosedStatus]  
Revisions:  
Param's Explanation:  
• @affid : Affiliate id  
• @userid : User update  
• @closed : Status of affiliate.  
. @ip : Ip of Admin user  
*/  
SET NOCOUNT ON  
/*EXEC [dbo].[Aff_Con_CheckPermission]   
 @custid=@UserID,@funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output*/  
   
EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@UserID,  
 @AffId=@AffId,  
 @ErrCode=@ErrCode output 
   
If @ErrCode <> 0  
 RETURN  
--this is use for change to noncommission group when close affiliate.  
--20100904@Johnny: no need to use this anymore, SP: "Aff_CommGroupAssign" is assign funcname: "affiliate"  
/*if @Closed = 1  
Begin  
 --Check permission whether this user has [CommissionGroup] right  
 EXEC [dbo].[Aff_Con_CheckPermission]  
  @custid=@UserID,@funcname='[CommissionGroup]',  
  @System = 'AFFILIATE',  
  @ErrCode=@ErrCode output,  
  @ErrMsg=@ErrMsg output  
 If @ErrCode <> 0  
    RETURN  
end*/  
  
Declare @LoginCount int, @Old_Closed bit, @RefNo bigint  
select @LoginCount = LoginCount    
from AffDetail with (nolock)    
where AffID = @affid    
    
select @Old_Closed=IsClosed  
from AffInfo with (nolock)    
where AffID = @AffID   
  
--This account is closed because last try to login failed more than 5 times    
--So no need top update this just temporarily lock  
IF @Old_Closed = @Closed and @LoginCount > 5    
  return    
  
Update AffInfo with(rowlock,updlock) set [IsClosed]=@closed where affid=@affid  
IF @@error<>0   
Begin  
 SELECT @ErrCode = 1005  
 RETURN  
END  
  
if @Closed = 1  
Begin  
 Declare @NoCommGroupId int, @AffList nvarchar(200)  
 select @NoCommGroupId = GroupId from CommGroup with (nolock) where GroupName = 'NoCommission'  
   
 select @AffList = cast(@affid as nvarchar(20))  
  
 Exec Aff_CommGroupAssign  
  @UserId = @userid,  
  @GroupId = @NoCommGroupId,  
  @AffIDList = @AffList,      
  @IP = @ip,  
  @ErrCode = @ErrCode OUTPUT,  
  @RefNo = @RefNo OUTPUT  
    
 IF @@error<>0   
  RETURN  
End  
  
--admin allow to loginable again  
IF @Old_Closed = 1 and @Closed = 0 and @LoginCount > 5    
begin  
  update AffDetail with (ROWLOCK, UPDLOCK) set LoginCount = 0    
  where affid = @affid  
  IF @@error<>0   
      BEGIN  
     SELECT @ErrCode = 1005
   RETURN  
  END  
 end  
   
--Write the log   
DECLARE @LogData nvarchar(4000),@SPName varchar(100)  
SELECT @LogData = 'Update Affiliate''s Closed Status. '  
                  + 'IsClosed=' + dbo.Aff_ToString(@Closed)  
  
select @SPName=OBJECT_NAME(@@ProcID)  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @RefNo = @RefNo,  
 @Details=@LogData  	


