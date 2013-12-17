ALTER PROCEDURE [dbo].[AffAdmin_NoteUpd]
	@Noteid int ,
	@Content nvarchar(1000) ,
	@Updatedby int ,
	@AffId int,
	@IP nvarchar(15)='',
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT
as
begin 
/*
Created: 20090122@TrangLe
Task : [description of SP]
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20100904@Johnny: Check permission (media affiliate, normal affiliate on this function)

Param's Explanation:
. @Noteid : autonumber output
. @Content: content of the note
. @AffId Affiliate ID
. @Updatedby: User cust id

• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Update note unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC dbo.Aff_CheckPermissionOnAff 
	@custid=@Updatedby,
	@AffId=@AffId,
	@ErrCode=@ErrCode output
	
If @ErrCode <> 0
	RETURN
UPDATE AdminNotes with(rowlock,updlock)
SET 	
	Updateddate = getdate(),
	Note=@Content,
	Updatedby=@Updatedby
WHERE Noteid=@Noteid

IF @@ERROR <> 0
BEGIN
	
	Select @ErrCode = 51
	return
END


DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Update Note ID:' + dbo.Aff_ToString(@Noteid)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog] 
@Creator = @AffId,
@Typename = 'UserNote', -- refer to table LogType
@SPName = @SPName,
@Details = @LogData,
@IP=@IP

end







