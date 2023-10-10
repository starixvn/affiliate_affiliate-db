ALTER PROCEDURE [dbo].[Aff_AffiliateInternalLogin]
	@AdminID int,
	@UserName varchar(50),	
	@LoginIP varchar(20),
	@ServerID int,	
	@AdminUserName varchar(50) OUTPUT,
	@CustID int OUTPUT,	
	@FirstName nvarchar(50) ='' OUTPUT,
	@LastName nvarchar(50) ='' OUTPUT,
	@Email nvarchar(50)='' OUTPUT,
	@PreferLang varchar(11) = 'en-US' OUTPUT,
	@Language varchar(20) = 'en-US',
	@Prefix varchar(3) = '$' OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT,
	--20101016@Peter check whether user is allowed to use Affiliate Personalized Page function
	@IsAllowedPersonalizedPage bit=0 OUTPUT,
	@AffLevel int=0 OUTPUT,
	@InputAffType int = 1,--Check Kiosk system login
	@AffType int = 1 OUTPUT,
	@Currency varchar(6) OUTPUT
AS
/*
 *	Created: 20090316@Ken
 *	Task : Login Affiliate from Admin site (internal login)
 *	DB: DB052.Affiliate_ZZun
 *
 *	Revisions:			
*/
SET NOCOUNT ON
declare @LogData nvarchar(200)

Declare @db_custid int, @failedcount int
Declare @closed bit, @status varchar(30)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

SELECT @AdminUserName = ''
SELECT @AdminUserName = UserName
FROM AdminUser WITH(NOLOCK)
WHERE CustID = @AdminID

IF @AdminUserName = '' RETURN

SELECT @db_custid = i.affID, @failedcount = LoginCount,
	@FirstName = firstname,@LastName = lastname,@Email = Email, @closed = IsClosed, @Status = Status, @PreferLang = d.PreferredLanguage, @IsAllowedPersonalizedPage=i.IsPageEnabled,@AffLevel=i.Level
	, @Prefix = isnull(Prefix, '$'), @AffType = AffType,@Currency = c.CurrencyCode
FROM AffInfo i with (nolock)
	INNER JOIN AffDetail d with(nolock) on i.AffID = d.affID
	left join Exchange e with(nolock) on e.ExchangeID = i.Currency
	inner join Currency c with(nolock) on i.Currency = c.CurrencyID
WHERE i.username = @UserName	

-- user not found
IF (@@ROWCOUNT = 0 Or (@InputAffType = 3 and @AffType <> 3) or (@InputAffType <> 3 and @AffType = 3))--Check for kiosk system
BEGIN
	SELECT @LogData = '[FROM ADMIN] Failed login attempt (wrong username), ServerID:' + dbo.Aff_ToString(@ServerID) + ', [' + @UserName + ']'
	EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData

	select @ErrMsg = case @Language	when 'en-US' then 'Wrong username or password.'
									when 'zh-TW' then N'用戶名或密碼錯誤'
									when 'zh-CN' then N'用户名或密码错误'
									when 'J' then N'Wrong username or password.'
									when 'th-TH' then N'Wrong username or password.'
									when 'es-ES' then N'El nombre de usuario o la contraseña son incorrectos.'
									when 'vi-VN' then N'Tên truy cập hoặc mật khẩu sai.'
									when 'id-ID' then N'Nama pengguna dan kata sandi salah.'
									else N'Wrong username or password.'
								end	,@ErrCode=1006						
	return
END

IF IsNull(@closed, 1) = 1
	BEGIN
		SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is closed), ServerID:' + dbo.Aff_ToString(@ServerID)
		EXEC [dbo].[Aff_WriteLog] 
			@Creator = @AdminID, 
			@AffID = @db_custid, 
			@Typename = 'LoginAdmin', 
			@SPName = @SPName, 
			@IP = @LoginIP, 
			@Details = @LogData

		select @ErrMsg =	case @Language	when 'en-US' then 'Your account is closed. Please contact your administrator!'
								when 'zh-TW' then N'帳號關閉. 請聯絡管理員.'
								when 'zh-CN' then N'账号关闭，请联络管理员'
								when 'J' then N'Your account is closed. Please contact your administrator!'
								when 'th-TH' then N'Your account is closed. Please contact your administrator!'
								when 'es-ES' then N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'
								when 'vi-VN' then N'Tài khoản của bạn bị đóng. Vui lòng liên hệ với quản trị viên của bạn!'
								when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'
								else N'Your account is closed. Please contact your administrator!'
							end	,@ErrCode=1008
		return
	END

--check pending or expired
IF @status <> 'Approved'	
BEGIN  
	SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is not approved), ServerID:' + dbo.Aff_ToString(@ServerID)
	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @AdminID, 
		@AffID = @db_custid, 
		@Typename = 'LoginAdmin', 
		@SPName = @SPName, 
		@IP = @LoginIP, 
		@Details = @LogData
	
	select @ErrMsg =	case @Language	when 'en-US' then 'Account is not approved. Please contact your administrator!'
								when 'zh-TW' then N'帳號未核準，請聯絡管理員。'
								when 'zh-CN' then N'账号未核准，请联络管理员'
								when 'J' then N'Account is not approved. Please contact your administrator!'
								when 'th-TH' then N'Account is not approved. Please contact your administrator!'
								when 'es-ES' then N'No se ha aprobado la cuenta. Póngase en contacto con el administrador.'
								when 'vi-VN' then N'Tài khoản không được chấp nhận. Vui lòng liên hệ với quản trị viên của bạn!'
								when 'id-ID' then N'Rekening tidak disetujui. Harap menghubungi administrator Anda!'
								else N'Account is not approved. Please contact your administrator!'
						end	,@ErrCode=1009
	RETURN
END 


-- Successful
SELECT @CustID = @db_custid

SELECT @LogData = '[FROM ADMIN] Successful login, ServerID:' + dbo.Aff_ToString(@ServerID)
EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID, @AffID = @db_custid, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData



GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateInternalLogin] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateInternalLogin] TO [VNTeam] 
