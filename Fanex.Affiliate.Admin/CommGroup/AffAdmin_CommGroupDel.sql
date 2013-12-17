-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_CommGroupDel]  
 @UserId int,  
 @GroupId int,  
 @IP varchar(20),  
 @ErrCode int = 0 OUTPUT 
AS  
/*  
Created: 20090719@DungTong  
Task : Delete a Commission Group   
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
*/  
SET NOCOUNT ON  
--Check permission  
EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@UserID,@funcname='[CommissionGroup]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output
 
if(@ErrCode<>0)  
  return  

--Check Currency Permission
DECLARE @Currency int
Select @Currency = Currency from CommGroup nolock where GroupID=@GroupID
EXEC [dbo].[AffAdmin_CheckPermissionCurrency]
	@UserId = @UserID,
	@CurrencyId = @Currency,
	@ErrCode = @ErrCode output
if(@ErrCode <> 0)  
	return  

if (not exists (select 1 from CommGroup(nolock) where GroupID=@GroupID and IsDeleted=0))  
  begin  
   select @ErrCode=31  --The group ID=' +  cast(@GroupId as varchar(10)) + ' is no longer existed. Please check.'					
    return  
  end  
--Check this group has 0 of affilliate assigment   
declare @noOfAff int  
select @noOfAff=sum(1)  
from AffInfo i with (nolock) where i.GroupID=@GroupID  
  
if(@noOfAff>0)    
  begin  
    select @ErrCode=32 --At least 1 affiliate was assigned to this group. You cannot delete it.
			
    return  
  end  
    
  
update CommGroup with (rowlock, updlock)  
set isDeleted = 1  
where GroupId = @GroupId  
--Write the log   
DECLARE @LogData nvarchar(200), @AffID int,@SPName varchar(100)  
if (@GroupID>1000)  
  select @AffID=@GroupID  
else  
  select @AffID=0    
SELECT @LogData = 'Delete commission group.GroupID=' + dbo.Aff_ToString(@GroupID)  
  
select @SPName=OBJECT_NAME(@@ProcID)  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'CommissionGroup',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @Details=@LogData  
 
 
 GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupDel] TO [vnteam]

