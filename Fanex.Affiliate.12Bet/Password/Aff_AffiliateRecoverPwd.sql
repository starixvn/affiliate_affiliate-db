/****** Object:  Stored Procedure dbo.Aff_AffiliateRecoverPwd    Script Date: 8/7/2010 4:23:02 AM ******/  
Alter PROCEDURE [dbo].[Aff_AffiliateRecoverPwd]  
 @AffId int,  
 @ValidCode varchar(10),  
 @NewPwd varchar(40),  
 @Email nvarchar(50) = NULL OUTPUT,  
 @Username varchar(30)= NULL OUTPUT,  
 @Firstname nvarchar(50) = NULL OUTPUT,  
 @Lastname nvarchar(50) = NULL OUTPUT,  
 @PreferredLanguage varchar(11) = 'en-US' OUTPUT,  
 @MailOption bit = 0 OUTPUT,  
 @Language varchar(20) = 'en-US',  
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
/*  
 Created: 20090930@VinhTrinh:  
 Task : Affiliate require new password when they forget it.  
 DB: DB052.Affiliate_12BET  
  
 Revisions:  
   -   
 Param's Explanation:  
 • @Email email request password  
 • @ValidCode code generate to affiliate when using forget password  
 • @NewPwd Generate random password and send to Affiliate  
 • @AffID return affid  
 • @Username return username  
 • @Firstname return firstname  
 • @Lastname return lastname  
*/  
SET NOCOUNT ON  
IF Exists(Select 1 FROM AffDetail with(nolock) WHERE AffId=@AffId and ValidCode=@ValidCode and datediff(hh, convert(datetime,CodeExpiry), current_timestamp)< 24)  
BEGIN  
 UPDATE AffInfo with(rowlock,updlock)  
 SET Password=@NewPwd--, pwdexpiry=dateadd(dd, 30, CURRENT_TIMESTAMP),answer='',question=''  
 WHERE AffId=@AffId  
   
 UPDATE AffDetail with(rowlock,updlock)  
 SET ValidCode='', CodeExpiry = null--, pwdexpiry=dateadd(dd, 30, CURRENT_TIMESTAMP),answer='',question=''  
 WHERE AffId=@AffId  
   
 Select @Email=email,@UserName=UserName,@ErrCode=0,@Firstname = firstname, @Lastname = lastname  
 From AffInfo with(nolock)   
 Where AffId=@AffId  
   
 Select @PreferredLanguage = PreferredLanguage, @MailOption = MailOption  
 From AffDetail with(nolock)   
 Where AffId=@AffId  
END  
ELSE  
BEGIN  
 SELECT @ErrMsg =CASE @Language   
     WHEN 'en-US' THEN 'The address that you have used to request a new password is not valid.'  
     WHEN 'zh-TW' THEN N'您用於申請新密碼的地址無效'   
     WHEN 'zh-CN' THEN N'您用于申请新密码的地址无效。'       
     WHEN 'th-TH' THEN 'ระบุที่อยู่ เพื่อแจ้งเปลี่ยนพาสเวิดไม่ถูกต้อง.'  
     WHEN 'es-ES' THEN 'La dirección que ha utilizado para solicitar una nueva contraseña no es válida.'  
     WHEN 'vi-VN' THEN 'Địa chỉ bạn đã sử dụng để yêu cầu mật khẩu mới không hợp lệ.'  
     WHEN 'id-ID' THEN 'Alamat yang Anda gunakan untuk meminta kata sandi baru, tidak valid.'  
	 when 'ko-KR' then N'새비밀번호를 발급받기위한 이메일주소가 유효하지 않습니다.'
     ELSE N'The address that you have used to request a new password is not valid.'  
    END, @ErrCode = 1001    
 RETURN   
END  
  
declare @SPName varchar(50), @LogData nvarchar(300)  
Select @LogData = 'Recover password for customer AffiliateID:' + dbo.Aff_ToString(@AffId)   
select @SPName = OBJECT_NAME(@@ProcID)  
  
EXEC [dbo].[Aff_WriteLog]   
 @Creator = @AffID,  
 @AffID = @AffID,  
 @Typename = 'Password', -- refer to table LogType  
 @SPName = @SPName,  
 @Details = @LogData

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateRecoverPwd] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateRecoverPwd] TO [bodbAdminNet]