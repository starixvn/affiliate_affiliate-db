 ALTER PROCEDURE [dbo].[Aff_AdminLogin] 
	@UserName varchar(50) OUTPUT,
	@UserPwd varchar(50),
	@LoginIP varchar(20),	
	@CustID int OUTPUT,
	@RoleID tinyint OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(5)= 'en-US',
	@From nvarchar(200) = '',
	@IsIT bit = 0 OUTPUT
AS
SET NOCOUNT ON
-- DB03.bodb02 --> DB052.Affiliate_ZZun
-- 20100713@Peter : Remove Write Log on IBC DB
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun

declare @LogData nvarchar(200),
	@db_userpwd nvarchar(50),
	@failedcount tinyint, @closed bit,	
	@SPName varchar(50),
	@GroupName nvarchar(50),
	@GroupID int

select @SPName = OBJECT_NAME(@@ProcID)
SELECT @LogData = '', @ErrMsg = '', @ErrCode = 0 -- initial value

SELECT @CustID = custid, @db_userpwd = UserPwd, @RoleID = roleid, @failedcount = IsNull(logincount, 0),
		@UserName = username, @closed = closed, @GroupName = GroupName, @GroupID = au.GroupId
FROM 	AdminUser au with (NOLOCK) 
		inner join AffGroupInfo g with (nolock) on au.GroupId = g.GroupId
WHERE username = @UserName


IF @@ROWCOUNT = 0 -- user not found
	SELECT  @ErrMsg = case @Language 
							when 'en-US' then 'Wrong username or password.'
							when 'zh-CN' then N'用户名或密码错误.'
							when 'zh-TW' then N'用戶名或密碼錯誤.'
							when 'J' then N'IDまたはパスワードが正しくありません。'
							when 'th-TH' then N'Wrong username or password.'
							when 'vi-VN' then N'Sai tên truy cập hoặc mật khẩu.'
							when 'es-ES' then N'Wrong username or password.'
							else N'Wrong username or password.'
						end,
		@ErrCode = 1001,
		@CustID = 0,
		@LogData = 'Admin:' + @UserName + ' IP:' + @LoginIP + ' Result:Failed(User_Not_Found) From:' + @From

ELSE IF @RoleID NOT IN (5,6,7,8,9,10)
	SELECT  @ErrMsg =case @Language 
							when 'en-US' then 'Wrong username or password.'
							when 'zh-CN' then N'用户名或密码错误.'
							when 'zh-TW' then N'用戶名或密碼錯誤.'
							when 'J' then N'IDまたはパスワードが正しくありません。'
							else N'Wrong username or password.'
						end,
		@ErrCode = 1002, 
		@LogData = 'Admin:' + @username + ' IP:' + @LoginIP + ' Result:Failed(Not_Admin) From:' + @From

ELSE IF @UserPWD <> @db_userpwd
BEGIN
	SELECT @ErrMsg = case @Language
							when 'en-US' then 'Wrong username or password.'
							when 'zh-CN' then N'用户名或密码错误.'
							when 'zh-TW' then N'用戶名或密碼錯誤.'
							when 'J' then N'IDまたはパスワードが正しくありません。'
							else N'Wrong username or password.'
					  end,
		@ErrCode = 1003,
		@LogData = 'Admin:' + @username + ' IP:' + @LoginIP + ' Result:Failed(Password) From:' + @From

	IF @failedcount = 5  -- already failed for 5 times, this is 6th time , LOCK THE A/C		
	BEGIN
		
		 UPDATE AdminUser with (rowlock, updlock) SET closed = 1 WHERE custid = @custid
		 
		
		select @LogData = 'The A/C is closed due to 5 wrong password attempts'	
			, @ErrMsg = case @Language
							when 'en-US' then 'Your account is closed due to 5 consecutive failed login attempts. Please contact your administrator.'
							when 'zh-CN' then N'Your account is closed due to 5 consecutive failed login attempts. Please contact your administrator.'
							when 'zh-TW' then N'Your account is closed due to 5 consecutive failed login attempts. Please contact your administrator.'
							when 'J' then N'Your account is closed due to 5 consecutive failed login attempts. Please contact your administrator.'
							else N'Your account is closed due to 5 consecutive failed login attempts. Please contact your administrator.'
					  end,
		@ErrCode = 1003
		
		
	END
	ELSE
		UPDATE AdminUser with (rowlock, updlock) SET logincount = @failedcount + 1 WHERE custid = @custid
END

IF (@ErrMsg = '') AND (@LogData = '')
BEGIN	
	
	IF @closed = 1
		SELECT  @ErrMsg = case @Language
							when 'en-US' then 'Account closed. Please contact your administrator!'
							when 'zh-CN' then N'账号已关闭，请联络管理员.'
							when 'zh-TW' then N'帳號已關閉. 請聯絡管理員.'
							when 'J' then N'Account closed. Please contact your administrator!'
							else N'Account closed. Please contact your administrator!'
						  end,
			@ErrCode = 1004,
			@LogData = 'Admin:' + @username + ' IP:' + @LoginIP + ' Result:Failed(A/C_Closed) From:' + @From	
	ELSE
	BEGIN
		UPDATE AdminUser with (rowlock, updlock)
		SET logincount = 0, iplogin = @LoginIP, lastlogged = CURRENT_TIMESTAMP, on_sessionid = 0
		WHERE custid = @custid

		SET @LogData = 'Admin:' + @username + ' IP:' + @LoginIP + ' Result:Success From:' + @From
	END
END

	IF @LogData <> ''
	BEGIN
			
		EXEC [dbo].[Aff_WriteLog] @Creator = @CustID, @AffID = 0, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData
	END

Declare @GroupIT varchar(50)

select @GroupIT = [dbo].[Aff_Con_GetGroupItID]()

if(@GroupID = @GroupIT)
	select @IsIT = 1

GO



GRANT EXECUTE ON [dbo].[Aff_AdminLogin] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminLogin] TO [VNTeam] 