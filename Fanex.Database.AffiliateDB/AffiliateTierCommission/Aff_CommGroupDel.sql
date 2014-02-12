ALTER Procedure [dbo].[Aff_CommGroupDel]  
 @UserId int,  
 @GroupId int,  
 @IP varchar(20),  
 @Language varchar(5)= 'en-US',
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT   
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
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
if(@ErrMsg<>'')  
  return  
if (not exists (select 1 from CommGroup(nolock) where GroupID=@GroupID and IsDeleted=0))  
  begin  
   select @ErrCode=101,
		@ErrMsg = case @Language 
							when 'en-US' then 'The group ID=' +  cast(@GroupId as varchar(10)) + ' is no longer existed. Please check.'
							when 'zh-CN' then N'這個群組ID ' +  cast(@GroupId as varchar(10)) + '已經不再存在.請確認.'
							when 'zh-TW' then N'这个群组ID ' +  cast(@GroupId as varchar(10)) + '已经不再存在。请确认。'
							else N'The group ID=' +  cast(@GroupId as varchar(10)) + ' is no longer existed. Please check.'
						end
    return  
  end  
--Check this group has 0 of affilliate assigment   
declare @noOfAff int  
select @noOfAff=sum(1)  
from AffInfo i with (nolock) where i.GroupID=@GroupID  
  
if(@noOfAff>0)    
  begin  
    select @ErrCode=101,
			@ErrMsg = case @Language 
							when 'en-US' then 'At least 1 affiliate was assigned to this group. You cannot delete it.'
							when 'zh-CN' then N'至少一個工作夥伴被安排到這個群組.您無法刪除.'
							when 'zh-TW' then N'至少一个工作伙伴被安排到这个群组。您无法删除。'
							else N'At least 1 affiliate was assigned to this group. You cannot delete it.'
						end
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
GRANT EXECUTE ON [dbo].[Aff_CommGroupDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupDel] TO [vnteam]
