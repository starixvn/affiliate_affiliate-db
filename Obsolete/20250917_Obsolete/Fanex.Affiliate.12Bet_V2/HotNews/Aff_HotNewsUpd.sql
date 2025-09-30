Alter PROCEDURE [dbo].[Aff_HotNewsUpd]
	@ID int,
	@MsgEN nvarchar(4000)=NULL,
	@MsgCN nvarchar(4000)=NULL,
	@MsgTW nvarchar(4000)=NULL,
	@MsgES nvarchar(4000)=NULL,
	@MsgTH nvarchar(4000)=NULL,
	@MsgVI nvarchar(4000)=NULL,
	@MsgID nvarchar(4000)=NULL,
	@MsgKR nvarchar(4000)=NULL,
	@important bit=NULL,
	@IP varchar(20),
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090310@TrangLe
Task : Update affiliate hot news by message id
DB: DB052.Affiliate_12BET
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
- 20130218@LongLuu : Add Korean Language http://ccs.nexcel.vn/viewtopic.php?f=6&t=8460&start=0&st=0&sk=t&sd=a#p36106

Param's Explanation:
• @ID : message id input
• @MsgEN : new message content in English 
• @MsgCN: new message content in Chinese Simplified
• @MsgTW: new message content in Chinese Traditional
. @MsgES: new message content in Spanish language
• @MsgTH: new message content in Thai
. @MsgVI : message content in Vietnamese language
• @MsgID: message content in Indonesia
• @MsgKR: message content in Korean
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

UPDATE [News] with(rowlock,updlock)
   SET [message_en] = Coalesce(@MsgEN,[message_en])
	  ,[message_cn] = Coalesce(@MsgCN,[message_cn])
	  ,[message_tw] = Coalesce(@MsgTW,[message_tw])
	  ,[message_es] = Coalesce(@MsgES,[message_es])
	  ,[message_th] = Coalesce(@MsgTH,[message_th])
	  ,[message_vi] = Coalesce(@MsgVI,[message_vi])
	  ,[message_id] = Coalesce(@MsgID,[message_id])
	  ,[message_kr] = Coalesce(@MsgKR,[message_kr])
	  ,[important] = Coalesce(@important,[important])
	  ,[updatedby]=Coalesce(@UserID,[updatedby])
	  ,updateddate=current_timestamp
WHERE msgid=@ID

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


GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HotNewsUpd] TO [vnteam]
GO

