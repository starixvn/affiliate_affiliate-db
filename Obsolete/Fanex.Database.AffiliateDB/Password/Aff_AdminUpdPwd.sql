ALTER PROCEDURE [dbo].[Aff_AdminUpdPwd]  
	@CustID int,
	@UserID int,  
	@OldPwd nvarchar(50)=null,
	@UserPwd nvarchar(50),    
	@Language varchar(5)= 'en-US', 
	@IP varchar(20), 
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(2000)='' OUTPUT  
AS  
  
SET NOCOUNT ON  
--DB02.bodb02 --> DB052.Affiliate_ZZun
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
--Check permission-----------------------------
if @OldPwd is null
BEGIN
	EXEC [dbo].[Aff_Con_CheckPermission] 
		@custid=@UserID,
		@funcname='[UserControl]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output
		
	If @ErrCode <> 0
		RETURN
END
	
	
if not exists(select 1 from AdminUser with (NOLOCK) 
				where CustID = @CustID 
				and (case when (@OldPwd is not null and UserPwd = @OldPwd) or @OldPwd is null then 1 
						else 0 end ) = 1 )
BEGIN
	Select @ErrMsg =  case @Language 
	when 'en-US' then N'Old password is incorrect' 
	when 'zh-TW' then N'舊密碼不正確.' 
	when 'zh-CN' then N'旧密码不正确' 
	when 'th-TH' then N'ใส่พาสเวิดเดิมไม่ถูกต้อง' 
	when 'es-ES' then N'La contraseña antigua es incorrecta' 
	when 'vi-VN' then N'Mật khẩu cũ không đúng'	
	when 'id-ID' then N'Kata sandi lama salah'
	else N'Old password is incorrect'
	end,
	@ErrCode = 1001
	RETURN 
END


	  
declare @PwdExpiry datetime
  
select @PwdExpiry = dateadd(dd, 30, getdate())  
UPDATE AdminUser  with (ROWLOCK, UPDLOCK)  
SET userpwd=@UserPwd, pwdexpiry=@PwdExpiry   
where custid=@CustID  
 
 
 --Write log
declare @SPName varchar(50),@LogData nvarchar(200)  
Select @LogData = 'Changed password CustID:' + dbo.Aff_ToString(@CustID)
select @SPName = OBJECT_NAME(@@ProcID)
  
EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'Password', -- refer to table LogType
	@SPName = @SPName,
	@Details = @LogData,
	@IP = @IP  
  
GO
GRANT EXECUTE ON [dbo].[Aff_AdminUpdPwd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminUpdPwd] TO [vnteam]

