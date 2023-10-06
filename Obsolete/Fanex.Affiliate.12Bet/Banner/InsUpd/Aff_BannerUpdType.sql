Alter PROCEDURE [dbo].[Aff_BannerUpdType]
	@TypeName varchar(50),
	@DisplayOrder tinyint,
	@Value varchar(50) ,
	@UserID int,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
SET NOCOUNT ON
--DB052.Affiliate_12BET
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission] 
	@custid=@UserID,@funcname='[Media]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------

IF Exists(Select 1 From BannerType with(nolock) Where Type=@TypeName and Value=@Value and displayorder<>@displayorder)
BEGIN
	select @ErrMsg = 	case @Language 
						when 'E' then N'Value  already exist'
						when 'CT' then N'數值已存在。'
						when 'CS' then N'数值已存在。'
						else N'Value  already exist'
					end,@ErrCode=1001
	return
END
ELSE
BEGIN
	Update BannerType with(rowlock,updlock) set value=@value
	Where type=@TypeName and DisplayOrder=@DisplayOrder
	IF @@Error <> 0 
	BEGIN
		Select @ErrMsg = 	case @Language 
						when 'E' then N'Error occurs.Update unsuccessfully.'
						when 'CT' then N'出現錯誤，更新失敗'
						when 'CS' then N'出现错误，更新失败'
						else N'Error occurs.Update unsuccessfully.'
					end,@ErrCode=1002
		return
	END 
	Select @ErrCode=0
END

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update ' + dbo.Aff_ToString(@TypeName)+' value: '+dbo.Aff_ToString(@Value)
EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'Banner', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail

GO
GRANT EXECUTE ON [dbo].[Aff_BannerUpdType] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerUpdType] TO [VNTeam]