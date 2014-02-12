 ALTER PROCEDURE [dbo].[Aff_SystemSettingsUpd]
	@Updatedby int ,
	@ID int,
	@Value nvarchar(max),
	@Type varchar(50)=NULL,
	@Description nvarchar(100),	
	@IP nvarchar(15)='',	
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@Peter
Task : [description of SP]
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
		@custid=@Updatedby,@funcname='[SystemSettings]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output	
	
If @ErrCode <> 0
	RETURN
	
If(Not Exists (Select 1 from SystemSettings (nolock) where SID=@ID))
BEGIN
Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! This setting key does not exist!' 
					when 'zh-CN' then N'錯誤!這個設定金鑰不存在!'
					when 'zh-TW' then N'错误！这个设置金者不存在！'
					else N'Error! This setting key does not exist!' 
				end, @ErrCode = 1001
	return
END
update SystemSettings with (rowlock,updlock)
Set SValue=@Value, Type=coalesce(@Type,Type), [Description]=@Description
where SID=@ID 


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update Sytem Setting. ID= ' + dbo.Aff_ToString(@ID) + '. Value=' + isnull(@Value,'') + '.Type=' + dbo.Aff_ToString(@Type)  + '. Description=' + isnull(@Description,'') 

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'SystemSettings', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end



GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsUpd] TO [vnteam]