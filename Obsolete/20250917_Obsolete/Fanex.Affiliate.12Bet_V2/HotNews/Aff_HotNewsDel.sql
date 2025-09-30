Alter PROCEDURE [dbo].[Aff_HotNewsDel]
	@listmsgid varchar(4000)=null,
	@UserID int,
	@IP varchar(20),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090624@VinhTrinh
Task : Delete affiliate hot news by message id
DB: DB052.Affiliate_12BET
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:
• @listmsgid : list of message ids need to delete separated by a comma
• @UserID: user deleting msg will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
101: Invalid message ID.
1001: Unsuccessful deleting msg.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@UserID,@funcname='[HotNews]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------
--Check list of messageid
if(@listmsgid is null)
begin
	Select @ErrMsg = 'Invalid message ID!', @ErrCode = 101	
	return
end	

declare @msgidTable table(msgid int)
 insert into  @msgidTable
		 select distinct val from dbo.strsplit(@listmsgid,',')
 declare @count int,@countDB int
  select @count=count(1) from @msgidTable
	select @countDB=count(1)
		  from News a  (nolock)
			   inner join @msgidTable t on a.msgid=t.msgid
	
	if (@count <> @countDB)
		BEGIN
			 Select @ErrMsg ='Sorry, your input message id is invalid. Please recheck it again.',								 
					@ErrCode = 102
			return      
		END    
--Check UserID is valid
if(not exists(select 1 from Affiliate_User (nolock) where custid=@UserID))
begin
	 Select @ErrMsg ='Sorry, Admin id is invalid. Please recheck it again.',								 
					@ErrCode = 103
			return
end

Delete News with(rowlock)
WHERE msgid in (select msgid from @msgidTable)

IF @@ERROR <> 0
BEGIN
	
	Select @ErrMsg = N'Error! Message unsuccessfully deleted!', @ErrCode = 1001
	return
END

 --Write the log 
DECLARE @LogData nvarchar(4000)
SELECT @LogData = 'Delete News MsgIDList:' + dbo.Aff_ToString(@listmsgid)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID)

EXEC [dbo].[Aff_WriteLog]
	@Creator=@UserId,	
	@TypeName= 'Message',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData
	


GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HotNewsDel] TO [vnteam]
GO

