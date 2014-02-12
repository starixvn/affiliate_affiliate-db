ALTER PROCEDURE [dbo].[Aff_AdminNoteUpd]
	@Noteid int ,
	@Note nvarchar(1000) ,
	@Updatedby int ,
	@UserID int,
	@IP nvarchar(15)='',
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@TrangLe
Task : [description of SP]
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20100904@Johnny: Check permission (media affiliate, normal affiliate on this function)
- 20130808@Joseph: fix write log params

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

EXEC dbo.Aff_CheckPermissionOnAff 
	@custid=@Updatedby,
	@AffId=@UserID,
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
	
	Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! Update note unsuccessfully!' 
					when 'zh-CN' then N'錯誤!更新註解不成功!'
					when 'zh-TW' then N'错误！更新注解不成功！'
					else N'Error! Update note unsuccessfully!' 
				end, @ErrCode = 1001
	return
END


DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Update Note ID:' + dbo.Aff_ToString(@Noteid)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog] 
@AffID = @UserID,  
@Creator = @Updatedby,
@Typename = 'UserNote', -- refer to table LogType
@SPName = @SPName,
@Details = @LogData,
@IP=@IP

end




GO
GRANT EXECUTE ON [dbo].[Aff_AdminNoteUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminNoteUpd] TO [vnteam]