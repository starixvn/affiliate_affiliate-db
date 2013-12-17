Alter PROCEDURE [dbo].[Aff_HotNewsIns]
		@ID int OUTPUT,
		@MsgEN nvarchar(4000),
		@MsgCN nvarchar(4000),
		@MsgTW nvarchar(4000),
		@MsgES nvarchar(4000),
		@MsgTH nvarchar(4000),
		@MsgVI nvarchar(4000),
		@MsgID nvarchar(4000),
		@MsgKR nvarchar(4000),
		@important bit,
		@IP varchar(20),
		@UserID int,
		@ErrCode int = 0 OUTPUT,
		@ErrMsg nvarchar(4000) = '' OUTPUT
AS
begin
/*
Created: 20090310@TrangLe
Task : Insert message for Affiliate News
DB: DB052.Affiliate_12BET
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
- 20130218@LongLuu : Add Korean Language http://ccs.nexcel.vn/viewtopic.php?f=6&t=8460&start=0&st=0&sk=t&sd=a#p36106

Param's Explanation:
• @ID : message id generated, OUTPUT
• @MsgEN : message content in English
• @MsgCN: message content in Chinese Simplified
• @MsgTW: message content in Chinese Traditional
. @MsgES : message content in Spanish language
• @MsgTH: message content in Thai
. @MsgVI : message content in Vietnamese language
• @MsgID: message content in Indonesia
• @MsgKR: message content in Korean
• @important: message important or not
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
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------
BEGIN TRANSACTION
INSERT INTO [dbo].[News]
		   ([message_en]
		   ,[message_cn]
		   ,[message_tw]
		   ,[message_es]
		   ,[message_th]
		   ,[message_vi]
		   ,[message_id]
		   ,[message_kr]
		   ,[creator]
		   ,[posteddate]
		   ,[important])
	 VALUES
		   (@MsgEN
		   ,@MsgCN
		   ,@MsgTW
		   ,@MsgES
		   ,@MsgTH
		   ,@MsgVI
		   ,@MsgID
		   ,@MsgKR
		   ,@UserID
		   ,getdate()
		   ,@important)
		   
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrMsg = N'Error! Insert message unsuccessfully!', @ErrCode = 1001
	return
END

SELECT @ID = SCOPE_IDENTITY()
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
GRANT EXECUTE ON [dbo].[Aff_HotNewsIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HotNewsIns] TO [vnteam]
GO