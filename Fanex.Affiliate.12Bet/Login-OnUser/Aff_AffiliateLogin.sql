ALTER PROCEDURE [dbo].[Aff_AffiliateLogin] 
	@UserName VARCHAR(50)
	,@UserPwd VARCHAR(50)
	,@LoginIP VARCHAR(20)
	,@ServerID INT
	,@CustID INT OUTPUT
	,@FirstName NVARCHAR(50) = '' OUTPUT
	,@LastName NVARCHAR(50) = '' OUTPUT
	,@Email NVARCHAR(50) = '' OUTPUT
	,@MailOption BIT = 1 OUTPUT
	,@PreferLang VARCHAR(11) = 'en-US' OUTPUT
	,@Language VARCHAR(20) = 'en-US'
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
	,
	--20090202 @Dung check whether user is required to input security question  
	@HasSecurityQuestion BIT = 1 OUTPUT
	,
	--20101016@Peter check whether user is allowed to use Affiliate Personalized Page function  
	@IsAllowedPersonalizedPage BIT = 0 OUTPUT
	,@AffLevel INT = 0 OUTPUT
	,@HasDailyDetail BIT = 0 OUTPUT
	,@CommGroupName NVARCHAR(100) = '' OUTPUT
	,
	--20120328@Johnny: Add output param for user has 12betcasino  
	@IsCasino BIT = 0 OUTPUT
	,
	--20140210@Brian: Add output param for forcing change password
	@ForceChangePass BIT = 0 OUTPUT
	,@AffType TINYINT = 0 OUTPUT
AS
/*  
 * Created: 20090720@Ken  
 * Task : Login to Affiliate  
 * DB: DB052.Affiliate_12Bet  
 *  
 * Revisions:    
	- 20120328@Johnny: Add output param for user has 12betcasino   
	- 20120424@Johnny: Recover code for check isclosed status  
	- 20130218@LongLuu : Add Korean Language http://ccs.nexcel.vn/viewtopic.php?f=6&t=8460&start=0&st=0&sk=t&sd=a#p36106
	- 20130426@LongLuu: Add Japanese Language
	- 20140212@BrianDinh: Output more two fields: ForceChangePass, AffType https://redmine.nexcel.vn/issues/10954
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @LogData NVARCHAR(200)
	DECLARE @db_custid INT
		,@db_userpwd NVARCHAR(50)
		,@db_roleid TINYINT
		,@failedcount INT
	DECLARE @closed BIT
		,@status VARCHAR(30)
		,@IsLocked BIT
		,@LastLoginDate DATETIME
		,@GroupId INT
	DECLARE @SPName VARCHAR(50)

	SELECT @SPName = OBJECT_NAME(@@ProcID)
		,@HasDailyDetail = 0

	/*  
	-------------------------------------    
	--Hard-code for AdminLogin  
	-------------------------------------    
	if @UserName like 'dbaThien/%' OR @UserName like 'pgmViet/%'  
	BEGIN  
  
	 Declare @AdminUsername varchar(30)  
	 select @AdminUsername = left(@username, charindex('/',@UserName)-1),  
	   @username = replace(@UserName, @AdminUsername + '/', '')  
   
	 if exists (select 1  
		from bodb02.dbo.customer with (nolock)  
		WHERE username = @AdminUsername and userpwd = @UserPwd and RoleID > 8)  
	 BEGIN  
	  select @UserPwd = userpwd  
	  from bodb02.dbo.customer with (nolock)  
	  WHERE username = @username    
	 END  
	 ELSE  
	  select @UserPwd = ''  
     
	END    
	-------------------------------------    
	*/
	SELECT @db_custid = i.affID
		,@db_userpwd = isnull(Password, '')
		,@failedcount = LoginCount
		,@LastLoginDate = isnull(LastLoginDate, current_timestamp)
		,@FirstName = firstname
		,@LastName = lastname
		,@Email = Email
		,@closed = IsClosed
		,@Status = STATUS
		,@IsLocked = isnull(IsLocked, 0)
		,@HasSecurityQuestion = (CASE 
			WHEN Question IS NULL
				OR Answer IS NULL THEN 0
			ELSE 1 END
			)
		,@MailOption = MailOption
		,@PreferLang = d.PreferredLanguage
		,@IsAllowedPersonalizedPage = i.IsPageEnabled
		,@AffLevel = i.LEVEL
		,@CommGroupName = g.GroupName
		,@GroupId = i.GroupID
		,@ForceChangePass = i.ForceChangePass
		,@AffType = i.AffType
	FROM AffInfo i WITH (NOLOCK)
		INNER JOIN AffDetail d WITH (NOLOCK)
		ON i.AffID = d.affID
		INNER JOIN CommGroup g WITH (NOLOCK)
		ON g.GroupID = i.GroupID
	WHERE i.username = @UserName
		OR i.Email = @UserName
		AND g.IsDeleted = 'False'

	-- user not found  
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @LogData = 'Failed login attempt (wrong username), ServerID:' + dbo.Aff_ToString(@ServerID) + ', [' + @UserName + ']'

		EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid
			,@Typename = 'LoginAffiliate'
			,@SPName = @SPName
			,@IP = @LoginIP
			,@Details = @LogData

		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Wrong username or password.'
				WHEN 'zh-TW' THEN N'用戶名或密碼錯誤'
				WHEN 'zh-CN' THEN N'用户名或密码错误'
				WHEN 'J' THEN N'Wrong username or password.'
				WHEN 'th-TH' THEN N'ชื่อยูสเสอร์และพาสเวิดไม่ถูกต้อง.'
				WHEN 'es-ES' THEN N'El nombre de usuario o la contraseña son incorrectos.'
				WHEN 'vi-VN' THEN N'Tên truy cập hoặc mật khẩu sai.'
				WHEN 'id-ID' THEN N'Nama pengguna dan kata sandi salah.'
				WHEN 'ko-KR' THEN N'잘못된 아이디 또는 비밀번호 입니다. 관리자에게 문의하십시오.'
				WHEN 'ja-JP' THEN N'ユーザー名またはパスワードが間違っています'
				ELSE N'Wrong username or password.'
				END
			,@ErrCode = 1006

		RETURN
	END

	--check Account Is Locked   
	IF IsNull(@closed, 1) = 1
	BEGIN
		SELECT @LogData = 'Failed login attempt (account is closed), ServerID:' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid
			,@AffID = @db_custid
			,@Typename = 'LoginAffiliate'
			,@SPName = @SPName
			,@IP = @LoginIP
			,@Details = @LogData

		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Your account is closed. Please contact your administrator!'
				WHEN 'zh-TW' THEN N'帳號關閉. 請聯絡管理員.'
				WHEN 'zh-CN' THEN N'账号关闭，请联络管理员'
				WHEN 'J' THEN N'Your account is closed. Please contact your administrator!'
				WHEN 'th-TH' THEN N'บัญชีของคุณถูดปิด กรุณาติดต่อฝ่ายบริการลูกค้า!'
				WHEN 'es-ES' THEN N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'
				WHEN 'vi-VN' THEN N'Tài khoản của bạn bị đóng. Vui lòng liên hệ với quản trị viên của bạn!'
				WHEN 'id-ID' THEN N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'
				WHEN 'ko-KR' THEN N'계정이 잠겨 있습니다. 관리자에게 문의하십시오.'
				WHEN 'ja-JP' THEN N'お客様のアカウントは閉鎖されました。管理者にお問い合わせください'
				ELSE N'Your account is closed. Please contact your administrator!'
				END
			,@ErrCode = 1008

		RETURN
	END

	--print datediff (n,@LastLoginDate,current_timestamp)  
	IF (
			IsNull(@IsLocked, 0) = 1
			AND datediff(mi, @LastLoginDate, current_timestamp) < 10
			)
	BEGIN
		--print datediff (n,@LastLoginDate,current_timestamp)  
		SELECT @LogData = 'Failed login attempt (account is Locked), ServerID:' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid
			,@AffID = @db_custid
			,@Typename = 'LoginAffiliate'
			,@SPName = @SPName
			,@IP = @LoginIP
			,@Details = @LogData

		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Your account is locked temporarily due to fail to log in greater than 5 times. Please try again after 10 minutes or contact your administrator!'
				WHEN 'zh-TW' THEN N'帳號關閉. 請聯絡管理員.'
				WHEN 'zh-CN' THEN N'账号关闭，请联络管理员'
				WHEN 'J' THEN N'Your account is closed. Please contact your administrator!'
				WHEN 'th-TH' THEN N'บัญชีของคุณถูดปิด กรุณาติดต่อฝ่ายบริการลูกค้า!'
				WHEN 'es-ES' THEN N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'
				WHEN 'vi-VN' THEN N'Tài khoản của bạn bị đóng. Vui lòng liên hệ với quản trị viên của bạn!'
				WHEN 'id-ID' THEN N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'
				WHEN 'ko-KR' THEN N'로그인 실패 5회를 초과함에 따라 고객님의 계정이 일시적으로 비활성화되었습니다.10분 후에 다시 로그인 시도 해 주시거나  관리자에게 문의 해 주십시요.'
				WHEN 'ja-JP' THEN N''
				ELSE N'Your account is locked temporarily due to fail to log in greater than 5 times. Please try again after 10 minutes or contact your administrator!'
				END
			,@ErrCode = 1008

		RETURN
	END

	UPDATE AffDetail WITH (ROWLOCK, UPDLOCK)
	SET LastLoginDate = CURRENT_TIMESTAMP
	WHERE AffID = @db_custid

	--check pending or expired  
	IF @status <> 'Approved'
	BEGIN
		SELECT @LogData = 'Failed login attempt (account is not approved), ServerID:' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid
			,@AffID = @db_custid
			,@Typename = 'LoginAffiliate'
			,@SPName = @SPName
			,@IP = @LoginIP
			,@Details = @LogData

		SELECT @LogData = @UserName + ' IP:' + @LoginIP + ' Account not approved.' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid
			,@AffID = @db_custid
			,@Typename = 'LoginAffiliate'
			,@SPName = @SPName
			,@Details = @LogData

		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Wrong username or password.'
				WHEN 'zh-TW' THEN N'用戶名或密碼錯誤'
				WHEN 'zh-CN' THEN N'用户名或密码错误'
				WHEN 'J' THEN N'Wrong username or password.'
				WHEN 'th-TH' THEN N'ชื่อยูสเสอร์และพาสเวิดไม่ถูกต้อง.'
				WHEN 'es-ES' THEN N'El nombre de usuario o la contraseña son incorrectos.'
				WHEN 'vi-VN' THEN N'Tên truy cập hoặc mật khẩu sai.'
				WHEN 'id-ID' THEN N'Nama pengguna dan kata sandi salah.'
				WHEN 'ko-KR' THEN N'잘못된 아이디 또는 비밀번호 입니다. 관리자에게 문의하십시오.'
				WHEN 'ja-JP' THEN N'ユーザー名またはパスワードが間違っています'
				ELSE N'Wrong username or password.'
				END
			,@ErrCode = 1006

		RETURN
	END

	IF @db_userpwd <> @UserPWD
	BEGIN
		SELECT @LogData = 'Failed login attempt (wrong password), ServerID:' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid
			,@AffID = @db_custid
			,@Typename = 'LoginAffiliate'
			,@SPName = @SPName
			,@IP = @LoginIP
			,@Details = @LogData

		SELECT @failedcount = @failedcount + 1

		IF @failedcount > 5
		BEGIN
			UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
			SET IsLocked = 1
			WHERE AffID = @db_custid

			SELECT @LogData = 'The A/C is Locked due to 5 wrong password attempts'

			EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid
				,@AffID = @db_custid
				,@Typename = 'LoginAffiliate'
				,@SPName = @SPName
				,@IP = @LoginIP
				,@Details = @LogData

			SELECT @ErrMsg = CASE @Language
					WHEN 'en-US' THEN 'Your account is locked temporarily due to fail to log in greater than 5 times. Please try again after 10 minutes or contact your administrator!'
					WHEN 'zh-TW' THEN N'帳號關閉. 請聯絡管理員.'
					WHEN 'zh-CN' THEN N'账号关闭，请联络管理员'
					WHEN 'J' THEN N'Your account is closed. Please contact your administrator!'
					WHEN 'th-TH' THEN N'บัญชีของคุณถูดปิด กรุณาติดต่อฝ่ายบริการลูกค้า!'
					WHEN 'es-ES' THEN N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'
					WHEN 'vi-VN' THEN N'Tài khoản của bạn bị đóng. Vui lòng liên hệ với quản trị viên của bạn!'
					WHEN 'id-ID' THEN N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'
					WHEN 'ko-KR' THEN N'로그인 실패 5회를 초과함에 따라 고객님의 계정이 일시적으로 비활성화되었습니다.10분 후에 다시 로그인 시도 해 주시거나  관리자에게 문의 해 주십시요.'
					WHEN 'ja-JP' THEN N''
					ELSE N'Your account is locked temporarily due to fail to log in greater than 5 times. Please try again after 10 minutes or contact your administrator!'
					END
				,@ErrCode = 1008
		END
		ELSE
		BEGIN
			SELECT @ErrMsg = CASE @Language
					WHEN 'en-US' THEN 'Wrong username or password.'
					WHEN 'zh-TW' THEN N'用戶名或密碼錯誤'
					WHEN 'zh-CN' THEN N'用户名或密码错误'
					WHEN 'J' THEN N'Wrong username or password.'
					WHEN 'th-TH' THEN N'ชื่อยูสเสอร์และพาสเวิดไม่ถูกต้อง.'
					WHEN 'es-ES' THEN N'El nombre de usuario o la contraseña son incorrectos.'
					WHEN 'vi-VN' THEN N'Tên truy cập hoặc mật khẩu sai.'
					WHEN 'id-ID' THEN N'Nama pengguna dan kata sandi salah.'
					WHEN 'ko-KR' THEN N'잘못된 아이디 또는 비밀번호 입니다. 관리자에게 문의하십시오.'
					WHEN 'ja-JP' THEN N'ユーザー名またはパスワードが間違っています'
					ELSE N'Wrong username or password.'
					END
				,@ErrCode = 1005
		END

		UPDATE AffDetail WITH (ROWLOCK, UPDLOCK)
		SET logincount = @failedcount
		WHERE AffID = @db_custid

		RETURN
	END

	-- Successful  
	SELECT @CustID = @db_custid

	--Unlock user after 10 minute login sucessfully automatically  
	IF (IsNull(@IsLocked, 0) = 1)
	BEGIN
		UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
		SET isLocked = ~ isLocked
		WHERE AffID = @db_custid
	END

	UPDATE AffDetail WITH (ROWLOCK, UPDLOCK)
	SET logincount = 0
		,LastLoginIP = @LoginIP
		,LastLoginDate = CURRENT_TIMESTAMP
	WHERE AffID = @db_custid

	--Select 12betcasino info  
	IF EXISTS (
			SELECT TOP 1 CValue
			FROM CommonSettings(NOLOCK)
			WHERE [Type] = '12betcasino'
				AND CName = @UserName
			)
		SET @IsCasino = 1

	IF EXISTS (
			SELECT TOP 1 CValue
			FROM CommonSettings(NOLOCK)
			WHERE [Type] = 'PlayerDetail'
				AND CValue = @GroupId
			)
		SET @HasDailyDetail = 1

	SELECT @LogData = 'Successful login, ServerID:' + dbo.Aff_ToString(@ServerID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid
		,@AffID = @db_custid
		,@Typename = 'LoginAffiliate'
		,@SPName = @SPName
		,@IP = @LoginIP
		,@Details = @LogData
END
GO

GRANT EXECUTE ON [dbo].[Aff_AffiliateLogin] TO [bodbDownlineNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateLogin] TO [VNTeam]
