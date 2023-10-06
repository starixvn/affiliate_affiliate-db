ALTER PROCEDURE [dbo].[Aff_CustomerUdpSecurityQuestion]  
 @AffID int,  
 @UserName varchar(50),  
 @Question nvarchar(300),  
 @Answer nvarchar(300),  
 @LoginIP varchar(20),  
 @ServerID int,  
 @Language varchar(20) = 'en-US',   
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT,  
 @IP varchar(20)  
AS  
/*  
Created: 20091028@HungPham  
Task : update security question for those affiliates who hadn't had security question before this feature came  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
 - 20091028@[Reviewer]: [Description of revision]   
  
Param's Explanation:  
• @ErrCode:  
 = 0: Transaction recorded successfully.  
 > 0: Specific Error.  
   
• @ErrMsg: Error description.  
• @AffID: AffID of this affiliate  
• @Language: current session language of this affiliate.  
*/  
SET NOCOUNT ON  
  
declare @LogData nvarchar(200), @SPName varchar(100)  
select @SPName = OBJECT_NAME(@@ProcID)  
--CONTENT OF SP HERE  
IF NOT EXISTS (SELECT 1 FROM AffInfo with(nolock) where affid=@AffID and status = 'Approved')  
 BEGIN    
 SELECT @LogData =  @UserName + ' IP:' + @LoginIP + ' Update Security Question failed.(Account not approved)' + CAST(@ServerID as nvarchar(20))  
  EXEC [dbo].[Aff_WriteLog]  @Creator=@AffID, @AffID=@AffID,@Details = @LogData,@Typename= 'UserInfo',@SPName=@SPName,@IP =@IP  
  select @ErrMsg = case @Language when 'en-US' then 'Account is not approved. Please contact your administrator!'  
        when 'zh-TW' then N'帳號未核準，請聯絡管理員。'  
        when 'zh-CN' then N'账号未核准，请联络管理员'  
        when 'J' then N'Account is not approved. Please contact your administrator!'  
        when 'th-TH' then N'บัญชีของคุณไม่ได้รับการอนุมัติ กรุณาติดต่อฝ่ายบริการลูกค้า'  
        when 'es-ES' then N'No se ha aprobado la cuenta. Póngase en contacto con el administrador.'  
        when 'vi-VN' then N'Tài khoản không được chấp nhận. Vui lòng liên hệ với quản trị viên của bạn!'  
        when 'id-ID' then N'Rekening tidak disetujui. Harap menghubungi administrator Anda!'  
        else N'Account is not approved. Please contact your administrator!'  
       end ,@ErrCode=1009  
  RETURN  
  END   
  
IF EXISTS (SELECT 1 FROM AffDetail with(nolock) where affid=@AffID and not(Question is null or Question='null' or ltrim(rtrim(Question))='' or Answer is null or Answer='null' or ltrim(rtrim(Answer))=''))  
  BEGIN  
  SELECT @LogData =  @UserName + ' IP:' + @LoginIP + ' Update Security Question failed.(Account had already had secutity question)' + CAST(@ServerID as nvarchar(20))  
  EXEC [dbo].[Aff_WriteLog]  @Creator=@AffID, @AffID=@AffID,@Details = @LogData,@Typename= 'UserInfo',@SPName=@SPName,@IP =@IP  
  select @ErrMsg = case @Language when 'en-US' then 'Account had already had secutity question. Please contact your administrator!'  
        when 'zh-TW' then N'Account had already had secutity question. Please contact your administrator!'  
        when 'zh-CN' then N'Account had already had secutity question. Please contact your administrator!'  
        when 'J' then N'Account had already had secutity question. Please contact your administrator!'  
        when 'th-TH' then N'บัญชีนี้มีคำถามตรวจสอบความปลอดภัย กรุณาติดต่อฝ่ายบริการ!'  
        when 'es-ES' then N'Ya se ha realizado la pregunta de seguridad de la cuenta. Póngase en contacto con el administrador.'  
        when 'vi-VN' then N'Tài khoản đã có câu hỏi bảo mật. Vui lòng liên hệ với quản trị viên của bạn!'  
        when 'id-ID' then N'Rekening sudah memiliki pertanyaan keamanan. Harap menghubungi administrator Anda!'  
        else N'Account had already had secutity question. Please contact your administrator!'  
       end ,@ErrCode=1009  
  RETURN  
  END  
  
UPDATE AffDetail with (rowlock, updlock)  
SET Question = @Question, Answer=@Answer  
WHERE affid =@AffID  
  
SELECT @LogData =  @UserName + ' IP:' + @LoginIP + ' Update Security Question Successfully. ServerID:' + dbo.Aff_ToString(@ServerID)  
  
EXEC [dbo].[Aff_WriteLog]   
 @AffID=@AffID,  
 @Details=@LogData,  
 @Creator=@AffID,   
 @Typename= 'UserInfo',    @SPName=@SPName,  
 @IP =@IP  
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerUdpSecurityQuestion] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerUdpSecurityQuestion] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerUdpSecurityQuestion] TO [vnteam]