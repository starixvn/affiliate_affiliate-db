/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_EmailHistoryIns]
	@MId		INT = 0 OUTPUT,
	@Creator	INT = -1,
	@Content	NVARCHAR(4000),
	@Sender		NVARCHAR(100),
	@Affiliate	VARCHAR(30) = NULL,
	@Email		NVARCHAR(50),
	@Subject	NVARCHAR(2000),
	@IP			NVARCHAR(25),
	@Browser	NVARCHAR(100),
	@SessionId	NVARCHAR(100),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User Site - Contact Us - Add email

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''

	-- Check valid input
	IF ISNULL(@Content, '') = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid mail content!'
		RETURN
	END

	IF ISNULL(@Sender, '') = ''
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Invalid sender name!'
		RETURN
	END

	IF ISNULL(@Email, '') = ''
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Invalid email address!'
		RETURN
	END

	IF ISNULL(@Subject, '') = ''
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'Invalid email subject!'
		RETURN
	END

	IF ISNULL(@IP, '') = ''
	BEGIN
		SELECT @ErrCode = 105, @ErrMsg = 'Invalid sender ip!'
		RETURN
	END

	IF ISNULL(@Browser, '') = ''
	BEGIN
		SELECT @ErrCode = 106, @ErrMsg = 'Invalid browser name!'
		RETURN
	END

	IF ISNULL(@SessionId, '') = ''
	BEGIN
		SELECT @ErrCode = 107, @ErrMsg = 'Invalid ASP.NET session id!'
		RETURN
	END

	DECLARE @AffId INT, @MaxNoOfMail INT
	SELECT  @AffId = -1, @MaxNoOfMail = 20 -- maximum of 20 mails per 10 minutes for each session

	IF @Creator <> -1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @Creator)
		BEGIN
			SELECT @ErrCode = 108, @ErrMsg = 'Invalid creator!'
			RETURN
		END
	END

	IF ISNULL(@Affiliate, '') <> ''
	BEGIN
		SELECT @AffId = AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE username = @Affiliate

		IF @@ROWCOUNT <> 1 -- not found or many results found
			SELECT @AffId = -1
	END

	-- Just allow to send maximum of @MaxNoOfMail per 10 minutes
	DECLARE @Count INT
	SELECT  @Count = COUNT(1)
	FROM dbo.EmailHistory WITH (NOLOCK)
	WHERE SessionId = @SessionId
		AND DATEDIFF(MINUTE, CreatedDate, CURRENT_TIMESTAMP) <= 10

	IF @Count > @MaxNoOfMail
	BEGIN
		SELECT @ErrCode = 109, @ErrMsg = 'You are just allowed to send maximum of ' + CONVERT(VARCHAR(5), @MaxNoOfMail) + ' emails per 10 minutes!'
		RETURN
	END

	BEGIN TRY
		INSERT INTO dbo.EmailHistory (Content,Sender,Creator,AffId,AffName,Email,Subject,CreatedDate,IP,Browser,SessionId)
		VALUES (@Content,@Sender,@Creator,@AffId,@Affiliate,@Email,@Subject,GETDATE(),@IP,@Browser,@SessionId)

		SELECT @MId = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 110, @ErrMsg = 'Error! Insert email unsuccessfully!'
		RETURN
	END CATCH

	-- Write Log
	DECLARE @LogData NVARCHAR(200), @SPName VARCHAR(50)
	SELECT	@LogData = 'Insert into EmailHistory Mail ID: ' + CONVERT(VARCHAR(20), @MId)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= '',
		@NewData	= @LogData,
		@IP			= @IP
END
GO