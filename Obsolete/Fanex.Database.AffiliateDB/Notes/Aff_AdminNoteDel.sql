Alter PROCEDURE [dbo].[Aff_AdminNoteDel]
	@AffId int,
	@listnode varchar(500),
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
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:
.@Noteid: Note needs to be deleted.
.@UserID: User to be logged

• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Delete note unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON
/*EXEC [dbo].[Aff_Con_CheckPermission] 
	@custid=@UserID,
	@funcname='[Affiliate]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output*/
	
EXEC dbo.Aff_CheckPermissionOnAff 
	@custid=@UserID,
	@AffId=@AffId,
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
Delete AdminNotes with(rowlock)
WHERE Noteid in (select Val from strSplit(@listnode, ';'))

IF @@ERROR <> 0
BEGIN
	
	Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! Delete note unsuccessfully!' 
					when 'zh-CN' then N'錯誤!刪除註解不成功!'
					when 'zh-TW' then N'错误！删除注解不成功！'
					else N'Error! Delete note unsuccessfully!' 
				end, @ErrCode = 1001
	return
END

DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Delete Notes:' + dbo.Aff_ToString(@listnode)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog] 
@Creator = @UserID,
@AffID = @AffID,
@Typename = 'UserNote', -- refer to table LogType
@SPName = @SPName,
@IP=@IP,
@Details = @LogData
end 

GO
GRANT EXECUTE ON [dbo].[Aff_AdminNoteDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminNoteDel] TO [vnteam]