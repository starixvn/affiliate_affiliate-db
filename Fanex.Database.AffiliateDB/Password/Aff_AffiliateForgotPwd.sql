Alter Procedure [Aff_AffiliateForgotPwd]
	@Email nvarchar(50)=Null,
	@ValidCode nvarchar(10),
	@Language varchar(20) = 'en-US',	
	@AffID int OUTPUT,
	@Username varchar(30) OUTPUT,
	@Firstname nvarchar(50) = NULL OUTPUT,
	@Lastname nvarchar(50) = NULL OUTPUT, 
	@PreferredLanguage varchar(11) = null Output,
	@MailOption bit = 1 Output,
	@IP varchar(20) = '', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg	 nvarchar(200) = '' OUTPUT
AS
/*
	Created: 20090930@VinhTrinh:
	Task : Affiliate require new password when they forget it.
	DB: DB052.Affiliate_ZZun

	Revisions:
	  - 
	Param's Explanation:
	• @Email email request password
	• @ValidCode 
	• @AffID return affid
	• @Username return username
	• @Firstname return firstname
	• @Lastname return lastname
*/
SET NOCOUNT ON
Declare @IsClosed bit

select @AffID = null

SELECT @AffID=AffID, @Username=c.username, @Firstname = c.firstname, @Lastname = c.lastname, @IsClosed = IsClosed
FROM AffInfo c with(nolock) 
WHERE Email=@Email 
	and Status = 'Approved'


IF @AffID is null
BEGIN
	IF EXISTS(
				SELECT 1 
				FROM AffInfo with(nolock) 
				where Email=@Email and Status <> 'Approved'
			   )
	BEGIN
		SELECT @ErrMsg =CASE @Language 
						WHEN 'en-US' THEN 'Account is not approved. Please contact your administrator!'
						WHEN 'zh-TW' THEN N'賬號未被核准，請聯絡管理員'
						WHEN 'zh-CN' THEN N'账号未被核准，请联络管理员'
						WHEN 'th-TH' THEN 'บัญชีของคุณไม่ได้รับการอนุมัติ กรุณาติดต่อฝ่ายบริการลูกค้า'
						WHEN 'es-ES' THEN 'No se ha aprobado la cuenta. Póngase en contacto con el administrador.'
						when 'vi-VN' then N'Tài khoản không được chấp nhận. Vui lòng liên hệ với quản trị viên của bạn!'
						when 'id-ID' then N'Rekening tidak disetujui. Harap menghubungi administrator Anda!'
						ELSE N'Account is not approved. Please contact your administrator!'
					END, @ErrCode = 1009	 
		RETURN 
	END

	SELECT @ErrMsg =CASE @Language 
					WHEN 'en-US' THEN N'You have not entered an email address that we recognise. Please try again or <a href=ContactUs.aspx>contact us</a>.'
					WHEN 'zh-TW' THEN N'您所輸入的電子郵箱地址無法識別，請重新輸入或者 <a href=ContactUs.aspx>contact us</a>.'
					WHEN 'zh-CN' THEN N'您所输入的电子邮箱地址无法识别，请重新输入或者 <a href=ContactUs.aspx>contact us</a>.'
					WHEN 'th-TH' THEN N'อีเมลล์ของคุณไม่ถูกต้อง กรุณาลองอีกครั้ง หรือ <a href=ContactUs.aspx> ติดต่อเรา </a>.'
					when 'vi-VN' then N'Bạn đã không nhập địa chỉ email mà chúng tôi ghi nhận. Hãy thử lại hoặc <a href=ContactUs.aspx>liên hệ với chúng tôi</a>.'
					when 'id-ID' then N'Anda belum memasukkan alamat email yang kami akui. Silakan coba lagi, atau <a href=ContactUs.aspx>hubungi kami</a>.'
					WHEN 'es-ES' THEN N'No se ha podido identificar la dirección de correo electrónico que ha proporcionado. Vuelva a intentarlo o <a href=ContactUs.aspx>póngase en contacto con nosotros</a>.'
					ELSE N'You have not entered an email address that we recognise. Please try again or <a href=ContactUs.aspx>contact us</a>.'
					
				END, @ErrCode = 1001	 
	RETURN 
	
END
ELSE IF @IsClosed = 1
BEGIN
	SELECT @ErrMsg =CASE @Language 
					WHEN 'en-US' THEN N'Your account is closed. Please contact your administrator!'
					WHEN 'zh-TW' THEN N'帳號關閉. 請聯絡管理員.'
					WHEN 'zh-CN' THEN N'账号关闭，请联络管理员'
					WHEN 'th-TH' THEN N'บัญชีของคุณถูดปิด กรุณาติดต่อฝ่ายบริการลูกค้า'
					WHEN 'es-ES' THEN N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'
					when 'vi-VN' then N'Tài khoản của bạn bị đóng. Vui lòng liên hệ với quản trị viên của bạn!'
					when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'
					ELSE N'Your account is closed. Please contact your administrator!'
				END, @ErrCode = 1008	 
	RETURN 
END

--Return preference language and mail option
select @PreferredLanguage = PreferredLanguage, @MailOption = MailOption
FROM AffDetail c with(nolock) 
WHERE AffID=@AffID

	
--Update customer store validcode in answer field,expiry in question field
UPDATE AffDetail with(rowlock,updlock) 
SET ValidCode=@ValidCode, CodeExpiry=dateadd(hh, 24, current_timestamp)
WHERE AffId=@AffId
Select @Errcode=0

--Write log
declare @SPName varchar(50), @LogData nvarchar(300)
Select @LogData = 'Forgot password for affiliateID:' + dbo.Aff_ToString(@AffID) + ' ValidCode:' + @ValidCode
select @SPName = OBJECT_NAME(@@ProcID)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @AffID,
	@AffID = @AffID,
	@Typename = 'Password', -- refer to table LogType
	@SPName = @SPName,
	@Details = @LogData,
	@IP = @IP 

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateForgotPwd] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateForgotPwd] TO [VnTeam]
