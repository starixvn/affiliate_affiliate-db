Alter PROCEDURE [dbo].[Aff_AffiliateUpdPwd]
	@AffID int,
	@OldPwd nvarchar(50)=null,
	@AffPwd nvarchar(50),
	@UserID int = null,
	@IP varchar(20),
	@Language varchar(20) = 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: 200908230@DungTong
	Task : Admin Reset Password for Affiliate or Affiliate change password
	DB: DB052.Affiliate_ZZun

	Revisions:
	  - 20090930@VinhTrinh: Admin Change Affiliate Password
	Param's Explanation:
	• 
*/

SET NOCOUNT ON

--Check permission-----------------------------
if @OldPwd is null
BEGIN
	EXEC [dbo].[Aff_Con_CheckPermission] 
		@custid=@UserID,
		@funcname='[Affiliate]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output
		
	If @ErrCode <> 0
		RETURN
END
-----------------------------------------------
if not exists(select 1 from AffInfo with (NOLOCK) 
				where AffID = @AffID
				and (case when (@OldPwd is not null and Password = @OldPwd) or @OldPwd is null then 1 
						else 0 end ) = 1 )
BEGIN
	Select @ErrMsg =  case @Language 
			when 'en-US' then N'Old password is incorrect' 
			when 'zh-TW' then N'舊密碼不正確.' 
			when 'zh-CN' then N'旧密码不正确' 
			when 'th-TH' then N'Old password is incorrect' 
			when 'es-ES' then N'La contraseña antigua es incorrecta' 
			when 'vi-VN' then N'Mật khẩu cũ không đúng'	
			when 'id-ID' then N'Kata sandi lama salah'
			else N'Old password is incorrect'
		end,
	@ErrCode = 1001
	RETURN 
END


UPDATE AffInfo  with (ROWLOCK, UPDLOCK)
SET Password=@Affpwd
where AffID=@AffID

declare @SPName varchar(50), @LogData nvarchar(200)
Select @LogData = 'Reset password'
select @SPName = OBJECT_NAME(@@ProcID)
select @UserID = isnull(@UserID, @AffID)

EXEC [dbo].[Aff_WriteLog]
	@Creator = @UserID,
	@AffID = @AffID,
	@Typename = 'Password', -- refer to table LogType
	@SPName = @SPName,
	@Details = @LogData,
	@IP = @IP 
	

GO
GRANT  EXECUTE  ON [dbo].[Aff_AffiliateUpdPwd]  TO [bodbAdminNet]
GO
GRANT  EXECUTE  ON [dbo].[Aff_AffiliateUpdPwd]  TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateUpdPwd] TO [vnteam]