/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_AffiliateUpdPwd]
	@AffID INT,
	@OldPwd NVARCHAR(50) = NULL,
	@AffPwd NVARCHAR(50),
	@UserID INT = NULL,
	@IP VARCHAR(50),
	@Language VARCHAR(20) = 'en-US',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*  
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task : Admin Reset Password for Affiliate or Affiliate change password  
	  
	Revisions:  
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
	   
	Param's Explanation:  
	 
*/
BEGIN
	SET NOCOUNT ON

	--Check permission-----------------------------  
	IF @OldPwd IS NULL
	BEGIN
		EXEC [dbo].[Aff_Con_CheckPermission] @CustID = @UserID
											,@FuncName = '[Affiliate]'
											,@ErrCode = @ErrCode OUTPUT
											,@ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
			RETURN
	END
	-----------------------------------------------  
	IF NOT EXISTS(
		SELECT 1
		FROM AffInfo WITH (NOLOCK)
		WHERE AffId = @AffID
			AND (CASE WHEN 
					(@OldPwd IS NOT NULL AND Password = @OldPwd) 
					OR
					@OldPwd IS NULL THEN 1 ELSE 0 END) 
				= 1)
	BEGIN
		SELECT
			@ErrMsg =
			CASE @Language
				WHEN 'en-US' THEN N'Old password is incorrect'
				WHEN 'zh-TW' THEN N'舊密碼不正確.'
				WHEN 'zh-CN' THEN N'旧密码不正确'
				WHEN 'th-TH' THEN N'Old password is incorrect'
				WHEN 'es-ES' THEN N'La contraseña antigua es incorrecta'
				WHEN 'vi-VN' THEN N'Mật khẩu cũ không đúng'
				WHEN 'id-ID' THEN N'Kata sandi lama salah'
				WHEN 'ko-KR' THEN N'예전 비밀번호가 일치하지 않습니다.'
				WHEN 'ja-JP' THEN N'旧パスワードが間違っています'
				ELSE N'Old password is incorrect'
			END
		   ,@ErrCode = 1001
		RETURN
	END

	UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
	SET Password = @AffPwd
	WHERE AffId = @AffID

	DECLARE @SPName VARCHAR(50)
		   ,@LogData NVARCHAR(200)

	SELECT @LogData = 'Reset password'
	SELECT @SPName = OBJECT_NAME(@@procid)
	SELECT @UserID = ISNULL(@UserID, @AffID)

END 
GO