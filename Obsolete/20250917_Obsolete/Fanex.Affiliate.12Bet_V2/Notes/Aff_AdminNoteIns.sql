Alter PROCEDURE [dbo].[Aff_AdminNoteIns]
	@Noteid int OUTPUT,
	@Note nvarchar(1000) ,
	@CustID int ,
	@Updatedby int ,
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
- 20090122@[Reviewer]: [Description of revision] 
- 20110711@Johnny: Admin can grant the access to add note only

Param's Explanation:
. @Noteid : autonumber output
. @Note: content of the note
. @CustID: Affiliate ID
. @Updatedby: User cust id

• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert note unsuccessfully!

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
BEGIN TRANSACTION
INSERT INTO AdminNotes
(		
	[Note] ,
	[Updateddate] ,
	[AffID] ,
	[Updatedby] 
)
VALUES
(	
	@Note ,
	GETDATE(),
	@CustID ,
	@Updatedby 
)
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrMsg = N'Error! Insert note unsuccessfully!', @ErrCode = 1001
	return
END

SELECT @Noteid = SCOPE_IDENTITY()
COMMIT TRANSACTION

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Create Note ID:' + dbo.Aff_ToString(@Noteid)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @CustID,
	@Typename = 'UserNote', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end

GO
GRANT EXECUTE ON [dbo].[Aff_AdminNoteIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminNoteIns] TO [vnteam]