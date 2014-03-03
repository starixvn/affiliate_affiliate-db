ALTER PROC [dbo].[Aff_AffiliateInternalLogin] 
	@AdminID INT
	,@UserName VARCHAR(50)
	,@LoginIP VARCHAR(20)
	,@ServerID INT
	,@AdminUserName VARCHAR(50) OUTPUT
	,@CustID INT OUTPUT
	,@FirstName NVARCHAR(50) = '' OUTPUT
	,@LastName NVARCHAR(50) = '' OUTPUT
	,@Email NVARCHAR(50) = '' OUTPUT
	,@PreferLang VARCHAR(11) = 'en-US' OUTPUT
	,@Language VARCHAR(20) = 'en-US'
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
	,
	--20101016@Peter check whether user is allowed to use Affiliate Personalized Page function  
	@IsAllowedPersonalizedPage BIT = 0 OUTPUT
	,@HasDailyDetail BIT = 0 OUTPUT
	,@AffLevel INT = 0 OUTPUT
	,@AffType INT = 0 OUTPUT
	,@CommGroupName NVARCHAR(100) = '' OUTPUT
	,
	--20120328@Johnny: Add output param for user has 12betcasino  
	@IsCasino BIT = 0 OUTPUT
AS
/*  
 * Created: 20090316@Ken  
 * Task : Login Affiliate from Admin site (internal login)  
 * DB: DB052.Affiliate_12Bet  
 *  
 * Revisions:     
	- 20120328@Johnny: Add output param for user has 12betcasino  
	- 20130218@LongLuu : Add Korean Language http://ccs.nexcel.vn/viewtopic.php?f=6&t=8460&start=0&st=0&sk=t&sd=a#p36106
	- 20130426@LongLuu: Add Japanese Language
	- 20140228@Brian: Add AffType OUTPUT
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @LogData NVARCHAR(200)
	DECLARE @db_custid INT
		,@failedcount INT
		,@GroupId INT
	DECLARE @closed BIT
		,@status VARCHAR(30)
	DECLARE @SPName VARCHAR(50)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @AdminUserName = ''
		,@HasDailyDetail = 0

	SELECT @AdminUserName = UserName
	FROM Affiliate_User WITH (NOLOCK)
	WHERE CustID = @AdminID

	SELECT @AdminUserName AS UserName

	IF @AdminUserName = '' RETURN

	SELECT @db_custid = i.affID
		,@failedcount = LoginCount
		,@FirstName = firstname
		,@LastName = lastname
		,@Email = Email
		,@closed = IsClosed
		,@Status = STATUS
		,@PreferLang = d.PreferredLanguage
		,@IsAllowedPersonalizedPage = i.IsPageEnabled
		,@AffLevel = i.LEVEL
		,@AffType = i.AffType
		,@CommGroupName = g.GroupName
		,@GroupId = i.GroupID
	FROM AffInfo i WITH (NOLOCK)
		INNER JOIN AffDetail d WITH (NOLOCK)
		ON i.AffID = d.affID
		INNER JOIN CommGroup g WITH (NOLOCK)
		ON g.GroupID = i.GroupID
	WHERE i.username = @UserName
		AND g.IsDeleted = 'False'

	-- user not found  
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @LogData = '[FROM ADMIN] Failed login attempt (wrong username), ServerID:' + dbo.Aff_ToString(@ServerID) + ', [' + @UserName + ']'

		EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID
			,@Typename = 'LoginAdmin'
			,@SPName = @SPName
			,@IP = @LoginIP
			,@Details = @LogData

		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Wrong username or password.'
				WHEN 'zh-TW' THEN N'用戶名或密碼錯誤'
				WHEN 'zh-CN' THEN N'用户名或密码错误'
				WHEN 'J' THEN N'Wrong username or password.'
				WHEN 'th-TH' THEN N'Wrong username or password.'
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

	IF IsNull(@closed, 1) = 1
	BEGIN
		SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is closed), ServerID:' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID
			,@AffID = @db_custid
			,@Typename = 'LoginAdmin'
			,@SPName = @SPName
			,@IP = @LoginIP
			,@Details = @LogData

		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Your account is closed. Please contact your administrator!'
				WHEN 'zh-TW' THEN N'帳號關閉. 請聯絡管理員.'
				WHEN 'zh-CN' THEN N'账号关闭，请联络管理员'
				WHEN 'J' THEN N'Your account is closed. Please contact your administrator!'
				WHEN 'th-TH' THEN N'Your account is closed. Please contact your administrator!'
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

	--check pending or expired  
	IF @status <> 'Approved'
	BEGIN
		SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is not approved), ServerID:' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID
			,@AffID = @db_custid
			,@Typename = 'LoginAdmin'
			,@SPName = @SPName
			,@IP = @LoginIP
			,@Details = @LogData

		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Account is not approved. Please contact your administrator!'
				WHEN 'zh-TW' THEN N'帳號未核準，請聯絡管理員。'
				WHEN 'zh-CN' THEN N'账号未核准，请联络管理员'
				WHEN 'J' THEN N'Account is not approved. Please contact your administrator!'
				WHEN 'th-TH' THEN N'Account is not approved. Please contact your administrator!'
				WHEN 'es-ES' THEN N'No se ha aprobado la cuenta. Póngase en contacto con el administrador.'
				WHEN 'vi-VN' THEN N'Tài khoản không được chấp nhận. Vui lòng liên hệ với quản trị viên của bạn!'
				WHEN 'id-ID' THEN N'Rekening tidak disetujui. Harap menghubungi administrator Anda!'
				WHEN 'ko-KR' THEN N'승인되지 않은 계정입니다. 관리자에게 문의하십시오.'
				WHEN 'ja-JP' THEN N'アカウントが承認されませんでした。管理者にお問い合わせください'
				ELSE N'Account is not approved. Please contact your administrator!'
				END
			,@ErrCode = 1009

		RETURN
	END

	-- Successful  
	SELECT @CustID = @db_custid

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

	SELECT @LogData = '[FROM ADMIN] Successful login, ServerID:' + dbo.Aff_ToString(@ServerID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID
		,@AffID = @db_custid
		,@Typename = 'LoginAdmin'
		,@SPName = @SPName
		,@IP = @LoginIP
		,@Details = @LogData
END
GO

GRANT EXECUTE ON [dbo].[Aff_AffiliateInternalLogin] TO [bodbDownlineNetView]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateInternalLogin] TO [VNTeam]
