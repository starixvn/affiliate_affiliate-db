ALTER PROCEDURE [dbo].[Aff_BannerInsType]
	@TypeName varchar(50),
	@Value varchar(50) ,
	@UserID int,
	@Language varchar(5) = 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--DB: DB052.Affiliate_ZZun
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission] 
	@custid=@UserID,@funcname='[Media]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------

IF Exists(Select 1 From BannerTypes with(nolock) Where Type=@TypeName and Value=@Value)
BEGIN
	select @ErrMsg = case @Language 
						when 'en-US' then N'Value  already exist'
						when 'zh-TW' then N'數值已存在。'
						when 'zh-CN' then N'数值已存在。'
						else N'Value  already exist'
					end,@ErrCode=1001
	return
END
ELSE
BEGIN
	Declare @MaxOrder int
	Select @MaxOrder=max(displayorder) From BannerTypes with(nolock) where Type=@TypeName
	INSERT INTO BannerTypes(type,value,displayorder)values(@typename,@value,@maxorder+1)
	IF @@Error <> 0 
	BEGIN
		Select @Errcode=1002, @ErrMsg = case @Language 
						when 'en-US' then 'Error occurs.Insert unsuccessfully.'
						when 'zh-CN' then N'錯誤發生.插入不成功'
						when 'zh-TW' then N'错误发生。插入不成功'
						else N'Error occurs.Insert unsuccessfully.!'
					end
		return
	END 
	Select @Errcode=0
END

--
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Create ' + dbo.Aff_ToString(@TypeName) +' value: '+ dbo.Aff_ToString(@Value)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'Banner', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail
GO
GRANT EXECUTE ON [dbo].[Aff_BannerInsType] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerInsType] TO [vnteam]
GO
