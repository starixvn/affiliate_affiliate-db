Alter PROCEDURE [dbo].[Aff_AdminNoteUpd]
	@Noteid int ,
	@Note nvarchar(1000) ,
	@Updatedby int ,
	@UserID int,
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@TrangLe
Task : [description of SP]
DB: DB052.Affiliate_12Bet
Original:

Revisions:
- 20100904@Johnny: Check permission (media affiliate, normal affiliate on this function)
- 20110711@Johnny: Admin can grant the access to add note only

Param's Explanation:
. @Noteid : autonumber output
. @Note: content of the note
. @UserID Affiliate ID
. @Updatedby: User cust id

• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Update note unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission] 
	@custid=@Updatedby,
	@funcname='[Note]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
UPDATE AdminNotes with(rowlock,updlock)
SET 	
	Updateddate = getdate(),
	Note=@Note,
	Updatedby=@Updatedby
WHERE Noteid=@Noteid

IF @@ERROR <> 0
BEGIN
	
	Select @ErrMsg = N'Error! Update note unsuccessfully!', @ErrCode = 1001
	return
END


DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Update Note ID:' + dbo.Aff_ToString(@Noteid)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog] 
@Creator = @UserID,
@Typename = 'UserNote', -- refer to table LogType
@SPName = @SPName,
@Details = @LogData,
@IP=@IP

end



GO
GRANT EXECUTE ON [dbo].[Aff_AdminNoteUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminNoteUpd] TO [vnteam]