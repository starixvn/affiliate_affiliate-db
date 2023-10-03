-- =============================================
-- Script Template
-- =============================================

set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[Aff_BannerInsType_1]
	@TypeName varchar(50),
	@Value varchar(50) ,
	@UserID int,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--DB: DB052.Affiliate_12BET
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

IF Exists(Select 1 From BannerTypes_1 with(nolock) Where Type=@TypeName and Value=@Value)
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
	Declare @MaxOrder int
	Select @MaxOrder=max(displayorder) From BannerTypes_1 with(nolock) where Type=@TypeName
	INSERT INTO BannerTypes_1(type,value,displayorder)values(@typename,@value,@maxorder+1)
	IF @@Error <> 0 
	BEGIN
		Select @ErrMsg = 	case @Language 
						when 'E' then N'Error occurs.Insert unsuccessfully.'
						when 'CT' then N'出現錯誤，插入失敗。'
						when 'CS' then N'出现错误，插入失败。'
						else N'Error occurs.Insert unsuccessfully.'
					end,@Errcode=1002
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
GRANT EXECUTE ON [dbo].[Aff_BannerInsType_1] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerInsType_1] TO [vnteam]
GO