  
  
  
Alter PROCEDURE [dbo].[Aff_AffiliateLogin]  
 @UserName varchar(50),  
 @UserPwd varchar(50),   
 @LoginIP varchar(20),  
 @ServerID int,   
 @CustID int OUTPUT,   
 @FirstName nvarchar(50) ='' OUTPUT,  
 @LastName nvarchar(50) ='' OUTPUT,  
 @Email nvarchar(50)='' OUTPUT,  
 @MailOption bit = 1 OUTPUT,  
 @PreferLang varchar(11) = 'en-US' OUTPUT,  
 @Language varchar(20) = 'en-US',  
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT,  
 --20090202 @Dung check whether user is required to input security question  
 @HasSecurityQuestion bit=1 OUTPUT,  
 --20101016@Peter check whether user is allowed to use Affiliate Personalized Page function  
 @IsAllowedPersonalizedPage bit=0 OUTPUT,  
 @AffLevel int=0 OUTPUT,  
 @HasDailyDetail bit = 0 OUTPUT,
 @CommGroupName  nvarchar(100) ='' OUTPUT,  
 --20120328@Johnny: Add output param for user has 12betcasino  
 @IsCasino bit = 0  OUTPUT  
AS  
/*  
 * Created: 20090720@Ken  
 * Task : Login to Affiliate  
 * DB: DB052.Affiliate_12Bet  
 *  
 * Revisions:    
  - 20120328@Johnny: Add output param for user has 12betcasino   
  - 20120424@Johnny: Recover code for check isclosed status  
*/  
SET NOCOUNT ON  
declare @LogData nvarchar(200)  
  
Declare @db_custid int, @db_userpwd nvarchar(50), @db_roleid tinyint, @failedcount int  
Declare @closed bit, @status varchar(30),@IsLocked bit,@LastLoginDate Datetime, @GroupId int 
  
declare @SPName varchar(50)  
select @SPName = OBJECT_NAME(@@ProcID), @HasDailyDetail = 0 
  
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
  
SELECT @db_custid = i.affID, @db_userpwd = isnull(Password,''), @failedcount = LoginCount,@LastLoginDate=isnull(LastLoginDate,current_timestamp),  
 @FirstName = firstname,@LastName = lastname,@Email = Email, @closed = IsClosed, @Status = Status,@IsLocked=isnull(IsLocked,0),  
 @HasSecurityQuestion = (case when Question is null or Answer is null then 0 else 1 end),  
 @MailOption = MailOption, @PreferLang = d.PreferredLanguage, @IsAllowedPersonalizedPage=i.IsPageEnabled,@AffLevel=i.Level,  
 @CommGroupName=g.GroupName, @GroupId = i.GroupID
   
FROM AffInfo i with (nolock)  
 INNER JOIN AffDetail d with(nolock) on i.AffID = d.affID  
 INNER JOIN CommGroup g with(nolock) on g.GroupID = i.GroupID  
WHERE i.username = @UserName or i.Email= @UserName   
 AND g.IsDeleted='False'   
   
-- user not found  
IF @@ROWCOUNT = 0  
BEGIN  
 SELECT @LogData = 'Failed login attempt (wrong username), ServerID:' + dbo.Aff_ToString(@ServerID) + ', [' + @UserName + ']'  
 EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData  
 select @ErrMsg = case @Language when 'en-US' then 'Wrong username or password.'  
         when 'zh-TW' then N'用戶名或密碼錯誤'  
         when 'zh-CN' then N'用户名或密码错误'  
         when 'J' then N'Wrong username or password.'  
         when 'th-TH' then N'ชื่อยูสเสอร์และพาสเวิดไม่ถูกต้อง.'  
         when 'es-ES' then N'El nombre de usuario o la contraseña son incorrectos.'  
         when 'vi-VN' then N'Tên truy cập hoặc mật khẩu sai.'  
         when 'id-ID' then N'Nama pengguna dan kata sandi salah.'  
		 when 'ko-KR' then N'잘못된 아이디 또는 비밀번호 입니다. 관리자에게 문의하십시오.'
         else N'Wrong username or password.'  
        end ,@ErrCode=1006        
 return  
END  
  
  
  
--check Account Is Locked   
IF IsNull(@closed, 1) = 1  
BEGIN  
 SELECT @LogData = 'Failed login attempt (account is closed), ServerID:' + dbo.Aff_ToString(@ServerID)  
 EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData  
 select @ErrMsg = case @Language when 'en-US' then 'Your account is closed. Please contact your administrator!'  
        when 'zh-TW' then N'帳號關閉. 請聯絡管理員.'  
        when 'zh-CN' then N'账号关闭，请联络管理员'  
        when 'J' then N'Your account is closed. Please contact your administrator!'  
        when 'th-TH' then N'บัญชีของคุณถูดปิด กรุณาติดต่อฝ่ายบริการลูกค้า!'  
        when 'es-ES' then N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'  
        when 'vi-VN' then N'Tài khoản của bạn bị đóng. Vui lòng liên hệ với quản trị viên của bạn!'  
        when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'  
		when 'ko-KR' then N'계정이 잠겨 있습니다. 관리자에게 문의하십시오.'
        else N'Your account is closed. Please contact your administrator!'  
      end ,@ErrCode=1008  
 return  
END  
  
--print datediff (n,@LastLoginDate,current_timestamp)  
IF (IsNull(@IsLocked,0) = 1 and datediff (mi,@LastLoginDate,current_timestamp)<10)  
BEGIN  
  --print datediff (n,@LastLoginDate,current_timestamp)  
 SELECT @LogData = 'Failed login attempt (account is Locked), ServerID:' + dbo.Aff_ToString(@ServerID)  
 EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData  
 select @ErrMsg = case @Language when 'en-US' then 'Your account is locked temporarily due to fail to log in greater than 5 times. Please try again after 10 minutes or contact your administrator!'  
        when 'zh-TW' then N'帳號關閉. 請聯絡管理員.'  
        when 'zh-CN' then N'账号关闭，请联络管理员'  
        when 'J' then N'Your account is closed. Please contact your administrator!'  
        when 'th-TH' then N'บัญชีของคุณถูดปิด กรุณาติดต่อฝ่ายบริการลูกค้า!'  
        when 'es-ES' then N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'  
        when 'vi-VN' then N'Tài khoản của bạn bị đóng. Vui lòng liên hệ với quản trị viên của bạn!'  
        when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'  
		when 'ko-KR' then N'로그인 실패 5회를 초과함에 따라 고객님의 계정이 일시적으로 비활성화되었습니다.10분 후에 다시 로그인 시도 해 주시거나  관리자에게 문의 해 주십시요.'
        else N'Your account is locked temporarily due to fail to log in greater than 5 times. Please try again after 10 minutes or contact your administrator!'  
      end ,@ErrCode=1008  
 return  
END  
  
UPDATE AffDetail with (rowlock, updlock)  
SET  LastLoginDate = CURRENT_TIMESTAMP  
WHERE AffID = @db_custid  
  
--check pending or expired  
IF @status <> 'Approved'   
BEGIN    
 SELECT @LogData = 'Failed login attempt (account is not approved), ServerID:' + dbo.Aff_ToString(@ServerID)  
 EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData  
   
 SELECT @LogData =  @UserName + ' IP:' + @LoginIP + ' Account not approved.' + dbo.Aff_ToString(@ServerID)  
 EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @Details = @LogData  
   
 select @ErrMsg = case @Language when 'en-US' then 'Wrong username or password.'  
         when 'zh-TW' then N'用戶名或密碼錯誤'  
         when 'zh-CN' then N'用户名或密码错误'  
         when 'J' then N'Wrong username or password.'  
         when 'th-TH' then N'ชื่อยูสเสอร์และพาสเวิดไม่ถูกต้อง.'  
         when 'es-ES' then N'El nombre de usuario o la contraseña son incorrectos.'  
         when 'vi-VN' then N'Tên truy cập hoặc mật khẩu sai.'  
         when 'id-ID' then N'Nama pengguna dan kata sandi salah.'  
		 when 'ko-KR' then N'잘못된 아이디 또는 비밀번호 입니다. 관리자에게 문의하십시오.'
         else N'Wrong username or password.'  
        end ,@ErrCode=1006     
  RETURN  
END   
  
IF @db_userpwd <> @UserPWD  
 BEGIN  
  SELECT @LogData = 'Failed login attempt (wrong password), ServerID:' + dbo.Aff_ToString(@ServerID)  
  EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData    
    
  SELECT @failedcount = @failedcount + 1    
  IF @failedcount > 5     
  BEGIN  
   UPDATE AffInfo with(rowlock, updlock) SET IsLocked = 1 WHERE AffID = @db_custid  
  
   SELECT @LogData = 'The A/C is Locked due to 5 wrong password attempts'  
   EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData        
   select @ErrMsg = case @Language when 'en-US' then 'Your account is locked temporarily due to fail to log in greater than 5 times. Please try again after 10 minutes or contact your administrator!'  
        when 'zh-TW' then N'帳號關閉. 請聯絡管理員.'  
        when 'zh-CN' then N'账号关闭，请联络管理员'  
        when 'J' then N'Your account is closed. Please contact your administrator!'  
        when 'th-TH' then N'บัญชีของคุณถูดปิด กรุณาติดต่อฝ่ายบริการลูกค้า!'  
        when 'es-ES' then N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'  
        when 'vi-VN' then N'Tài khoản của bạn bị đóng. Vui lòng liên hệ với quản trị viên của bạn!'  
        when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'  
		when 'ko-KR' then N'로그인 실패 5회를 초과함에 따라 고객님의 계정이 일시적으로 비활성화되었습니다.10분 후에 다시 로그인 시도 해 주시거나  관리자에게 문의 해 주십시요.'
        else N'Your account is locked temporarily due to fail to log in greater than 5 times. Please try again after 10 minutes or contact your administrator!'  
      end ,@ErrCode=1008  
     
  END  
  else  
  BEGIN  
    select @ErrMsg = case @Language when 'en-US' then 'Wrong username or password.'  
        when 'zh-TW' then N'用戶名或密碼錯誤'  
        when 'zh-CN' then N'用户名或密码错误'  
        when 'J' then N'Wrong username or password.'  
        when 'th-TH' then N'ชื่อยูสเสอร์และพาสเวิดไม่ถูกต้อง.'  
        when 'es-ES' then N'El nombre de usuario o la contraseña son incorrectos.'  
        when 'vi-VN' then N'Tên truy cập hoặc mật khẩu sai.'  
        when 'id-ID' then N'Nama pengguna dan kata sandi salah.'  
		when 'ko-KR' then N'잘못된 아이디 또는 비밀번호 입니다. 관리자에게 문의하십시오.'
        else N'Wrong username or password.'  
       end ,@ErrCode=1005  
   END  
  UPDATE AffDetail with(rowlock, updlock) SET logincount = @failedcount WHERE AffID = @db_custid    
  return  
 END  
  
-- Successful  
SELECT @CustID = @db_custid  
--Unlock user after 10 minute login sucessfully automatically  
  
if(IsNull(@IsLocked,0) = 1)  
begin   
  Update AffInfo with (rowlock,updlock)  
  set isLocked=~ isLocked  
  WHERE AffID = @db_custid  
end  
  
UPDATE AffDetail with (rowlock, updlock)  
SET logincount = 0, LastLoginIP = @LoginIP, LastLoginDate = CURRENT_TIMESTAMP  
WHERE AffID = @db_custid  
  
--Select 12betcasino info  
if exists(Select top 1 CValue   
		From CommonSettings (nolock)   
		Where [Type]='12betcasino' and CName = @UserName)  
	set @IsCasino = 1  

if Exists(Select top 1 CValue from CommonSettings (nolock) where [Type]='PlayerDetail' and CValue = @GroupId)
	Set @HasDailyDetail = 1
  
SELECT @LogData = 'Successful login, ServerID:' + dbo.Aff_ToString(@ServerID)  
EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData  
  
  

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateLogin] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateLogin] TO [VNTeam] 