ALTER PROCEDURE [dbo].[Aff_ResourceKeyUpd]
	@Updatedby int ,
	@ID uniqueidentifier,
	@Value nvarchar(max),
	@Description nvarchar(100),	
	@IP nvarchar(15)='',	
	@Language varchar(5)= null, 
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
		@custid=@Updatedby,@funcname='[Resources]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output	
	
If @ErrCode <> 0
	RETURN
	
If(Not Exists (Select 1 from RefResources (nolock) where ResourceID=@ID))
BEGIN
Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! This key does not exists!' 
					when 'zh-CN' then N'錯誤!這個金鑰不存在!'
					when 'zh-TW' then N'错误！这个金者不存在！'
					else N'Error! This key does not exists!' 
				end, @ErrCode = 1001
	return
END
if @Language is not null 
BEGIN
	update RefResources with (rowlock,updlock)
	Set ResourceValue=@Value, [Description]=@Description
	where ResourceID=@ID
END
ELSE -- update All language
BEGIN
	declare @Key varchar(50),@Type varchar(50)
	select @Key = ResourceKey, @Type = RefID from 
		dbo.RefResources where ResourceID=@ID
		
	update RefResources with (rowlock,updlock)
	Set ResourceValue=@Value, [Description]=@Description
	where RefID=@Type and [ResourceKey]=@Key
END

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update a Resource. ID= ' + dbo.Aff_ToString(@ID) + '. Value=' + isnull(@Value,'') + '. Description=' + isnull(@Description,'') 

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'Resources', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end



GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeyUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourceKeyUpd] TO [vnteam]