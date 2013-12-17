-- =============================================
-- Script Template
-- =============================================
ALTER PROCEDURE [dbo].[AffAdmin_EmailHistoryDel]  
  @listmid varchar(4000)=null,  
  @UserID int,  
  @IP varchar(20),  
	@Language varchar(5)= 'en-US', 
  @ErrCode int = 0 OUTPUT
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
 @ErrCode=@ErrCode output

If @ErrCode <> 0  
 RETURN  
  
--Check list of mail id  
if(@listmid is null)  
begin  
 Select @ErrCode = 6   --Invalid mail ID!
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
    Select @ErrCode = 7 -- the selected email(s) are invalid.
         return        
        END      
--Check UserID is valid  
if(not exists(select 1 from AdminUser (nolock) where custid=@UserID))  
begin  
  Select @ErrCode = 8   --Admin id is invalid
         return  
end  
  
  
Delete EmailHistory with(rowlock)  
WHERE mid in (select mid from @midTable)  
  
IF @@ERROR <> 0  
BEGIN  
   
 Select @ErrCode = 9  --Email unsuccessfully deleted!
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
GRANT EXECUTE ON [dbo].[AffAdmin_EmailHistoryDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_EmailHistoryDel] TO [vnteam]