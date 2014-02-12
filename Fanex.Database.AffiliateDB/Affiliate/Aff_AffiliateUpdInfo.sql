set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

  
ALTER PROCEDURE [dbo].[Aff_AffiliateUpdInfo]  
 @AffId int ,  
 @userid int,  
 @firstname nvarchar(50) = NULL,  
 @lastname nvarchar(50) = NULL,  
 @Gender bit = null,  
 @country nvarchar(50) = NULL,  
 @email nvarchar(50) = NULL,  
 @password varchar(40)=NULL,  
 @phone nvarchar(50) = NULL,  
 @mobilephone nvarchar(50) = NULL,  
 @address nvarchar(80),  
 @city nvarchar(50) = NULL,   
 @state nvarchar(50) = NULL,  
 @postal nvarchar(50) = NULL,  
 @emailformat bit = null,  
 @currency smallint = null,  
 @playerCurrency nvarchar(50) = null,  
     --Add for Personalized Site  
    @IsPageEnabled bit=0,  
    @Level int=0,    
 ---------------------------------------------------------------------------------  
 -- Parameter for Affiliate info(use for update/insert data to DB03)  
 @SiteURL varchar(100)=NULL,  
 @MoreSiteURLs varchar(1000) = NULL,  
 @PreferredLanguage varchar(11)=NULL,  
 @PreferredPayment varchar(20), --Player, Neteller, Moneybookers, Wire, Cheque  
 @Player_Username varchar(30) = NULL,  
 @Neteller_AccountID varchar(50) = NULL,  
 @Moneybookers_Email varchar(50) = NULL,  
 @Wire_BankName  nvarchar(100) = NULL,  
 @Wire_BankAddress nvarchar(200) = NULL,  
 @Wire_SwiftCode  nvarchar(20) = NULL,  
 @Wire_AccountName nvarchar(100) = NULL,   
 @Wire_AccountNo  varchar(50) = NULL,  
 @Cheque_FullName nvarchar(200) = NULL,  
 @Cheque_Address  nvarchar(200) = NULL,  
 @Cheque_City  nvarchar(50) = NULL,  
 @Cheque_State  nvarchar(50) = NULL,  
 @Cheque_Postal  nvarchar(50) = NULL,  
 @Cheque_Country  varchar(50) = NULL,  
 ---------------------------------------------------------------------------------  
 @language varchar(20) = 'es-ES',  
    @IP varchar(20),  
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
/*Updated: 20090324@VinhTrinh  
Task : Update affiliate infor.  
DB: DB052.Affiliate_ZZun  
Original : [Aff_AffiliateUpdInfo]  
Revisions:  
 Peter@20100209 : Check If Admin update Player_UserName, we must make sure there is no pending payment request.  
 Johnny@20110228 : Do not allow affiliate update player_user if they have already  
 Johnny@20130319 : Do not allow update currency  
 Long@20130911: do not check email existance in case of Kiosk
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
  @custid=@UserID,@funcname='[Affiliate]',  
  @System = 'AFFILIATE',  
  @ErrCode=@ErrCode output,  
  @ErrMsg=@ErrMsg output  
   
 If @ErrCode <> 0  
  RETURN  
End  
  
--Check If we change player_username  
  
if (@Player_Username Is not null AND @Player_Username <> (Select Player_UserName from AffDetail with (nolock) where AffId=@AffID)  
     and exists (Select 1 from AffPayout with (nolock) where AffID=@AffID and Status='pending')   
    )  
      
 BEGIN  
    SELECT @ErrMsg = case @Language   
      when 'en-US' then 'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'zh-TW' then N'这个帐号有一笔付款要求还在等待，请先更新这笔交易！'  
      when 'zh-CN' then N'這個帳號有一筆付款要求還在等待,請先更新這筆交易!'  
      when 'th-TH' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'es-ES' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'vi-VN' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'id-ID' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      else N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      end, @ErrCode = 1001  
    return  
      
 END     
-----------------------------------------------  
  
  
--Check duplicate Email 
IF (select at.Name
	from afftype at with(nolock)
		inner join affinfo ai with(nolock) on ai.AffType = at.TypeID
		where ai.AffID = @AffId) not like '%kiosk%'
BEGIN 
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
END
/*  
-- Check Currency is Editable  
declare @CurrencyCurrent smallint  
Select @CurrencyCurrent =currency  
from AffINfo (nolock)  
where AffID=@AffID  
  
  
if(@Currency<>@CurrencyCurrent and exists (select top(1)  1 from Memberdaily (nolock) where AffID = @AffID))  
begin  
 SELECT @ErrMsg = case @Language   
      when 'en-US' then 'Cannot change the currency of this Affiliate!'  
      when 'zh-TW' then N'Cannot change the currency of this Affiliate!'  
      when 'zh-CN' then N'Cannot change the currency of this Affiliate!'  
      when 'th-TH' then N'Cannot change the currency of this Affiliate!'  
      when 'es-ES' then N'Cannot change the currency of this Affiliate!'  
      when 'vi-VN' then N'Cannot change the currency of this Affiliate!'  
      when 'id-ID' then N'Cannot change the currency of this Affiliate!'  
      else N'Cannot change the currency of this Affiliate!'  
      end, @ErrCode = 1003  
 return  
end  
*/  
Begin Transaction  
  
UPDATE AffInfo with(rowlock,updlock)   
SET firstname = isnull(@firstname,firstname),  
 lastname = isnull(@lastname,lastname),  
 email = isnull(@email,email),  
 Password = isnull(@password,Password),  
 IsPageEnabled = isnull(@IsPageEnabled,IsPageEnabled),  
 [Level] = isnull(@Level,[Level])  
 ,Currency=(case when status in ('Pending','Disapproved') then  isnull(@currency,currency) else currency end)  
   
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
 CountryID = isnull(@country, countryID),  
 phone = isnull(@phone,phone),  
 mobilephone = isnull(@mobilephone,mobilephone),  
 address = isnull(@address,address),  
 city = isnull(@city,city),  
 state = isnull(@state,state),  
 postal = isnull(@postal,postal),  
 SiteURL=isnull(@SiteURL,SiteURL),    
 MoreSiteURLs=@MoreSiteURLs,    
 PreferredLanguage = isnull(@PreferredLanguage, PreferredLanguage),  
 PreferredPayment=@PreferredPayment,   
 --Player_IBCCustID=@Player_IBCCustId,   
 Player_Username=case when @AffId <> @UserId then @Player_Username else isnull(Player_Username, @Player_Username) end,    
 Player_Currency = @playerCurrency,  
 Neteller_AccountID=@Neteller_AccountID,    
 Moneybookers_Email=@Moneybookers_Email,    
 Wire_BankName=@Wire_BankName,    
 Wire_BankAddress=@Wire_BankAddress,    
 Wire_SwiftCode=@Wire_SwiftCode,    
 Wire_AccountName=@Wire_AccountName,    
 Wire_AccountNo=@Wire_AccountNo,    
 Cheque_FullName=@Cheque_FullName,    
 Cheque_Address=@Cheque_Address,    
 Cheque_City=@Cheque_City,    
 Cheque_State=@Cheque_State,    
 Cheque_Postal=@Cheque_Postal,    
 Cheque_Country=@Cheque_Country ,  
 MailOption = @EmailFormat   
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
lastname='+ dbo.Aff_ToString(@lastname) + ',  
Gender='+ dbo.Aff_ToString(@Gender) + ',  
country='+ dbo.Aff_ToString(@country) + ',  
email='+ dbo.Aff_ToString(@email) + ',  
password='+ dbo.Aff_ToString(@password) + ',  
phone='+ dbo.Aff_ToString(@phone) + ',  
mobilephone='+ dbo.Aff_ToString(@mobilephone) + ',  
address='+ dbo.Aff_ToString(@address) + ',  
city='+ dbo.Aff_ToString(@city) + ',  
state='+ dbo.Aff_ToString(@state) + ',  
postal='+ dbo.Aff_ToString(@postal) + ',  
SiteURL='+ dbo.Aff_ToString(@SiteURL) + ',  
MoreSiteURLs='+ dbo.Aff_ToString(@MoreSiteURLs) + ',  
PreferredPayment='+ dbo.Aff_ToString(@PreferredPayment) + ',  
PreferredLanguage='+ dbo.Aff_ToString(@PreferredLanguage) + ',  
Player_Username='+ dbo.Aff_ToString(@Player_Username) + ',  
Player_Currency='+ @playerCurrency + ',  
Neteller_AccountID='+ dbo.Aff_ToString(@Neteller_AccountID) + ',  
Moneybookers_Email='+ dbo.Aff_ToString(@Moneybookers_Email) + ',  
Wire_BankName='+ dbo.Aff_ToString(@Wire_BankName) + ',  
Wire_BankAddress='+ dbo.Aff_ToString(@Wire_BankAddress) + ',  
Wire_SwiftCode='+ dbo.Aff_ToString(@Wire_SwiftCode) + ',  
Wire_AccountName='+ dbo.Aff_ToString(@Wire_AccountName) + ',  
Wire_AccountNo='+ dbo.Aff_ToString(@Wire_AccountNo) + ',  
Cheque_FullName='+ dbo.Aff_ToString(@Cheque_FullName) + ',  
Cheque_Address='+ dbo.Aff_ToString(@Cheque_Address) + ',  
Cheque_City='+ dbo.Aff_ToString(@Cheque_City) + ',  
Cheque_State='+ dbo.Aff_ToString(@Cheque_State) + ',  
Cheque_Postal='+ dbo.Aff_ToString(@Cheque_Postal) + ',  
Cheque_Country='+ dbo.Aff_ToString(@Cheque_Country) + ',  
IsPageEnabled='+ dbo.Aff_ToString(@IsPageEnabled) + ',  
Level='+ dbo.Aff_ToString(@Level) + ',  
Currency'+ dbo.Aff_ToString(@Currency) + ',  
language='+ dbo.Aff_ToString(@language)   
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @Details=@Detail   
  
  
  
  

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdInfo] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdInfo] TO bodbAdminNet
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateUpdInfo] TO [VNTeam] 
