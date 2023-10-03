ALTER PROCEDURE [dbo].[Aff_BannerDelType]
	@TypeName varchar(50),
	@Value varchar(50) ,
	@UserID int,
	@IP nvarchar(15)='',
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 
DB: DB052.Affiliate_12BET
Original:

Revisions:
*/
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


Delete From BannerTypes Where Type=@TypeName and Value=@Value
IF @@Error <> 0 
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'Error occurs.Delete unsuccessfully.'
					when 'CT' then N'出現錯誤，刪除失敗.'
					when 'CS' then N'出现错误，删除失败.'
					else N'Error occurs.Delete unsuccessfully.'
				end,@Errcode=1001
	return
END 
	Select @Errcode=0

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete ' + dbo.Aff_ToString(@TypeName) +' value: '+ dbo.Aff_ToString(@Value)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'Banner', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP

GO
GRANT EXECUTE ON [dbo].[Aff_BannerDelType] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerDelType] TO [vnteam]
GO
