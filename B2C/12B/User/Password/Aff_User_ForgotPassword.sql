/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_ForgotPassword]
    @Email		NVARCHAR(100) = NULL,
    @ValidCode	NVARCHAR(30),
    @IP			VARCHAR(50) = '',
	@Language	VARCHAR(10) = 'en-US',
    @ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Forgot password

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/

BEGIN
    SET NOCOUNT ON

    DECLARE @AffId INT, @Status VARCHAR(30), @IsClosed BIT
    SELECT  @AffId = AffId, @Status = Status, @IsClosed = IsClosed FROM dbo.AffInfo WITH (NOLOCK) WHERE Email = @Email

    IF @AffId IS NULL
    BEGIN
		-- You have not entered an email address that we recognise.
        SELECT @ErrCode = 1001, @ErrMsg = dbo.Aff_f_GetMessageById(201, @Language)

		RETURN
    END

	IF @IsClosed = 1
	BEGIN
		-- Your account is closed. Please contact your administrator!
        SELECT @ErrCode = 1008, @ErrMsg = dbo.Aff_f_GetMessageById(202, @Language)

		RETURN
    END
    
	IF @Status <> 'Approved'
	BEGIN
		-- Account is not approved. Please contact your administrator!
        SELECT @ErrCode = 1009, @ErrMsg = dbo.Aff_f_GetMessageById(203, @Language)

		RETURN
    END

    -- Update ValidCode, CodeExpiry
    UPDATE AffDetail WITH (ROWLOCK, UPDLOCK)
    SET ValidCode	= @ValidCode,
		CodeExpiry	= DATEADD(DAY, 1, CURRENT_TIMESTAMP) -- 24h
    WHERE AffId = @AffId

	-- Return information to send mail
    SELECT ai.AffId, ai.Username, ai.Firstname, ad.PreferredLanguage, ad.MailOption
    FROM AffInfo ai WITH (NOLOCK)
		INNER JOIN AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
    WHERE ai.AffId = @AffId

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SELECT  @NewData = 'ValidCode=' + ISNULL(@ValidCode, '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO