SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_HotNewsUpd]
	@ID int,
	@important bit,
	@xml xml,	
	@IP varchar(20),
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090310@TrangLe
Task : Update affiliate hot news by message id
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
- 20140225@Joseph : Use xml data to update
- 20130815@Joseph : Insert data to RefResources if they are not exist when updating

Param's Explanation:
• @ID : message id input
• @xml: xml data
• @important: message important or not
• @UserID: user updating msg, will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
101: Invalid message ID.
1001: Update unsuccessful.

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
if not exists (select 1 from [dbo].[News]  with (nolock) where  msgid=@ID)
BEGIN
	Select @ErrMsg = 'Invalid message ID!', @ErrCode = 101		
	return
END
/*
UPDATE [News] with(rowlock,updlock)
   SET [message_en] = Coalesce(@MsgEN,[message_en])
      ,[message_cn] = Coalesce(@MsgCN,[message_cn])
      ,[message_tw] = Coalesce(@MsgTW,[message_tw])
      ,[message_es] = Coalesce(@MsgES,[message_es])
      ,[message_th] = Coalesce(@MsgTH,[message_th])
      ,[message_vi] = Coalesce(@MsgVI,[message_vi])
      ,[message_id] = Coalesce(@MsgID,[message_id])
      ,[important] = Coalesce(@important,[important])
      ,[updatedby]=Coalesce(@UserID,[updatedby])
      ,updateddate=current_timestamp
WHERE msgid=@ID
*/
UPDATE [News] with(rowlock,updlock)
   SET Message_En =  Coalesce(@xml.value('(/root/item[code="en-US"]/value)[1]','nvarchar(4000)'),Message_En)
		,[important] = Coalesce(@important,[important])
      ,[updatedby]=Coalesce(@UserID,[updatedby])
      ,updateddate=current_timestamp
WHERE msgid=@ID


update RefResources with(rowlock,updlock)
set ResourceValue = temp.Value
FROM RefResources r
INNER JOIN (
 select Tab.item.value('code[1]','varchar(100)') as Code		
		,Tab.item.value('value[1]','nvarchar(4000)') as Value
 from @xml.nodes('/root/item') Tab(item)
 ) temp ON r.LanguageCode = temp.Code
WHERE r.RefID = 'News' AND r.ResourceKey = cast(@ID as varchar(10))
 
 
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
 where NOT EXISTS(select 1 from RefResources where RefID = 'News' AND LanguageCode =  Tab.item.value('code[1]','varchar(100)')  AND ResourceKey = cast(@ID as varchar(10)))
 
IF @@ERROR <> 0
BEGIN
	
	Select @ErrMsg = N'Error! Message unsuccessfully updated!', @ErrCode = 1001
	return
END


 --Write the log 
DECLARE @LogData nvarchar(4000)
SELECT @LogData = 'Update Affiliate_News MsgID:' + dbo.Aff_ToString(@ID)                         

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator = @UserId,	
	@TypeName = 'Message',	
	@SPName = @SPName,
	@IP = @IP,
	@Details = @LogData
