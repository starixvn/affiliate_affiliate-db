  ALTER PROCEDURE [dbo].[Aff_ResourceTypeIns]
	@Updatedby int ,
	@Key int,
	@Value nvarchar(max),
	@Type varchar(50)='',
	@IP nvarchar(15)='',
	@ID int=0 OUTPUT,
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
	
If(Exists (Select 1 from SystemSettings (nolock) where SName=@key and Type=@Type))
BEGIN
Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! This setting key is existed!' 
					when 'zh-CN' then N'錯誤!這個設定金鑰已經存在!'
					when 'zh-TW' then N'错误！这个设置金者已经存在！'
					else N'Error! This setting key is existed!' 
				end, @ErrCode = 1001
	return
END
INSERT INTO [dbo].[SystemSettings]
           ([SName]
           ,[SValue]
           ,[Type])
     VALUES(@Key,@Value,@Type)

SELECT @ID = SCOPE_IDENTITY()
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add new Sytem Setting. ID=' + dbo.Aff_ToString(@ID) + '.Key=' + dbo.Aff_ToString(@Key) + '.Value=' + isnull(@Value,'') + '.Type=' + dbo.Aff_ToString(@Type)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'SystemSettings', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end

GO
GRANT EXECUTE ON [dbo].[Aff_ResourceTypeIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourceTypeIns] TO [vnteam]