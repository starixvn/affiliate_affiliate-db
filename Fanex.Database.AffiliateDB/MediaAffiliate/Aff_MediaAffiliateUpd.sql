ALTER PROCEDURE [dbo].[Aff_MediaAffiliateUpd]
	@AffId int ,
	@userid int,
	@firstname nvarchar(50) = NULL,
	@lastname nvarchar(50) = NULL,
	@Gender bit = null,
	@country nvarchar(50) = NULL,
	@email nvarchar(50),	
	@phone nvarchar(50),
	@mobilephone nvarchar(50),
	@address nvarchar(80),
	@city nvarchar(50),	
	@state nvarchar(50),
	@postal nvarchar(50),	
	---------------------------------------------------------------------------------
	-- Parameter for Affiliate info(use for update/insert data to DB03)
	@SiteURL varchar(100)=NULL,
	@MoreSiteURLs varchar(1000) = NULL,	
	---------------------------------------------------------------------------------
	@language varchar(20) = 'es-ES',
    @IP varchar(20),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*Updated: 20090324@VinhTrinh
Task : Update affiliate infor.
DB: DB052.Affiliate_ZZun
Original : [Aff_MediaAffiliateUpd]
Revisions:
	Peter@20100209 : Check If Admin update Player_UserName, we must make sure there is no pending payment request.
	
Param's Explanation:
• @AffId : Affiliate custid
• @userid : user update.
• @firstname : update firstname.
....
*/

SET NOCOUNT ON

--Check permission(If AffId = userid => Affiliate update info else Admin Update Aff info)-----------------------------
if @AffId <> @userid
Begin
	EXEC [dbo].[Aff_Con_CheckPermission] 
		@custid=@UserID,@funcname='[MediaAffiliate]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output
	
	If @ErrCode <> 0
		RETURN
End

--Check duplicate Email 

IF Exists(Select 1 From AffInfo a with(nolock) where a.email=@email and a.AffId <> @AffId and a.Status <> 'Disapproved')
BEGIN
	SELECT @ErrMsg = case @Language 
						when 'en-US' then 'Email Address has been used. Please choose another one!'
						when 'zh-TW' then N'此郵箱地址已被使用，請選用其他郵箱地址。'
						when 'zh-CN' then N'此邮箱地址已被使用，请选用其他邮箱地址。'
						when 'th-TH' then N'อีเมลล์นี้ได้ถูกใช้แล้ว กรุณาระบุข้อมูลใหม่คะ!'
						when 'es-ES' then N'Esta dirección de correo electrónico ya se ha utilizado. Escoja otra diferente.'
						when 'vi-VN' then N'Địa chỉ Email đã được sử dụng. Vui lòng chọn địa chỉ khác!'
						when 'id-ID' then N'Alamat Email sudah digunakan. Silakan pilih yang berbeda!'
						else N'Email Address has been used. Please choose another one!'
						end, @ErrCode = 1002
	return
END	

Begin Transaction

UPDATE AffInfo with(rowlock,updlock) 
SET firstname = isnull(@firstname,firstname),
	lastname = isnull(@lastname,lastname),
	email = isnull(@email,email)	
WHERE AffId = @AffId

IF @@error<>0 
BEGIN
	SELECT @ErrMsg = CASE @Language 
						WHEN 'es-ES' THEN 'Invalid user infomation. Update process is unsuccessful!'
						WHEN 'zh-TW' THEN N'用戶信息無效，更新失敗。'
						WHEN 'zh-CN' THEN N'用户信息无效，更新失败。'
						WHEN 'J' THEN N'Invalid user infomation. Update process is unsuccessful!'
						WHEN 'th-TH' THEN N'ข้อมูลผู้ใช้ไม่ถุกต้อง อัพเดทข้อมูลไม่สำเร็จคะ!'
						WHEN 'es-ES' THEN N'La información de usuario no es válida. No se ha podido completar el proceso de actualización.'						
						WHEN 'vi-VN' THEN N'Thông tin người dùng không hợp lệ. Quá trình cập nhật không thành công!'
						WHEN 'id-ID' THEN N'Informasi pengguna tidak valid. Proses pembaruan tidak berhasil!'						
						ELSE N'Invalid user infomation. Update process is unsuccessful!'
					END, @ErrCode = 1004					 
	RollBack Transaction
	RETURN
END

UPDATE AffDetail  with(rowlock,updlock) 
SET  
	Gender = isnull(@Gender,Gender),
	country = isnull(@country,country),
	phone = isnull(@phone,phone),
	mobilephone = isnull(@mobilephone,mobilephone),
	address = isnull(@address,address),
	city = isnull(@city,city),
	postal = isnull(@postal,postal),
	SiteURL=isnull(@SiteURL,SiteURL),  
	MoreSiteURLs=@MoreSiteURLs
where AffId = @AffId

IF @@Error <> 0
BEGIN 
	SELECT @ErrMsg = CASE @Language 
						WHEN 'es-ES' THEN 'Error occurs. Update process is unsuccessful!'
							WHEN 'zh-TW' THEN N'出現錯誤，更新程序失敗。'
							WHEN 'zh-CN' THEN N'出现错误，更新程序失败。'
							WHEN 'J' THEN N'Error occurs. Update process is unsuccessful!'
							WHEN 'th-TH' THEN N'มีความผิดพลาดเกิดขึ้น อัพเดทข้อมูลไม่สำเร็จคะ!'
							WHEN 'es-ES' THEN N'Se ha producido un error. No se ha podido completar el proceso de actualización.'
							WHEN 'vi-VN' THEN N'Xảy ra lỗi. Quá trình cập nhật không thành công!'
							WHEN 'id-ID' THEN N'Terjadi kesalahan. Proses pembaruan tidak berhasil!'
							ELSE N'Error occurs. Update process is unsuccessful!'
					END, @ErrCode = 1006
	Rollback Transaction
	RETURN
END
Commit Transaction

--Update succeeded

declare @SPName varchar(50), @Detail nvarchar(4000)
select @SPName = OBJECT_NAME(@@ProcID) 

Select @Detail = 'Update Affifilate''s Info 
firstname='+ dbo.Aff_ToString(@firstname) + ',
lastname'+ dbo.Aff_ToString(@lastname) + ',
Gender='+ dbo.Aff_ToString(@Gender) + ',
country='+ dbo.Aff_ToString(@country) + ',
email='+ dbo.Aff_ToString(@email) + ',
phone='+ dbo.Aff_ToString(@phone) + ',
mobilephone='+ dbo.Aff_ToString(@mobilephone) + ',
address='+ dbo.Aff_ToString(@address) + ',
city='+ dbo.Aff_ToString(@city) + ',
state='+ dbo.Aff_ToString(@state) + ',
postal='+ dbo.Aff_ToString(@postal) + ',
SiteURL='+ dbo.Aff_ToString(@SiteURL) + ',
MoreSiteURLs='+ dbo.Aff_ToString(@MoreSiteURLs) + ',
language='+ dbo.Aff_ToString(@language) 

EXEC [dbo].[Aff_WriteLog]
	@Creator=@UserId,	
	@AffID=@AffID,
	@Typename= 'UserInfo',	
	@SPName=@SPName ,
	@IP =@IP,
	@Details=@Detail	

GO
GRANT EXECUTE ON [dbo].[Aff_MediaAffiliateUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MediaAffiliateUpd] TO [VNTeam] 
