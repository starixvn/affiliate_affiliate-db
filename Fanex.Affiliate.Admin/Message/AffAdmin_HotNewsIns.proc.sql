CREATE PROCEDURE [dbo].[AffAdmin_HotNewsIns]
		@important bit,
		@xml xml,
		@IP varchar(20),
		@UserID int,
		@ErrCode int = 0 OUTPUT
AS
begin
/*
Created: 20090310@TrangLe

Task : Insert message for Affiliate News
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
- 20130225@Joseph : Insert data into RefResources table
Param's Explanation:
• @important: message important or not
• @xml: data containing all messages that will be inserted
• @UserID: user inserting msg,creator, will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@UserID,@funcname='[HotNews]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------
BEGIN TRANSACTION
           
INSERT INTO [dbo].[News]
           (Message_En
           ,[creator]
           ,[posteddate]
           ,[important])
     VALUES
           (@xml.value('(/root/item[code="en-US"]/value)[1]','nvarchar(4000)')
           ,@UserID
           ,getdate()
           ,@important)
           
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrCode = 200
	return
END

DECLARE @ID int 
SELECT @ID = SCOPE_IDENTITY()
           
INSERT INTO [RefResources]
           ([ResourceID]
           ,[RefID]
           ,[LanguageCode]
           ,[ResourceKey]
           ,[ResourceValue])
  select newid()
		,'News'
		,Tab.item.value('code[1]','varchar(100)')		
		,@ID
		,Tab.item.value('value[1]','nvarchar(4000)')
 from @xml.nodes('/root/item') Tab(item)
      
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrCode = 201
	return
END

COMMIT TRANSACTION



 --Write the log 
DECLARE @LogData nvarchar(4000)
SELECT @LogData = 'Insert into Affiliate_News MsgID:' + dbo.Aff_ToString(@ID)       

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator = @UserId,	
	@TypeName = 'Message',	
	@SPName = @SPName,
	@IP = @IP,
	@Details = @LogData
end

GO
GRANT EXECUTE ON [dbo].[AffAdmin_HotNewsIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_HotNewsIns] TO [vnteam]