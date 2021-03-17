/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_EmailHistoryIns]
	@MID		INT OUTPUT,
	@creator	INT=-1,
	@content	NVARCHAR(4000),
	@sender		NVARCHAR(100),
	@affiliate	VARCHAR(30)=NULL,
	@email		NVARCHAR(50),
	@subject	NVARCHAR(2000),
	@ip			NVARCHAR(15),
	@browser	NVARCHAR(100),
	@sessionid	NVARCHAR(100),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
BEGIN
	/*
	Created: 20090626@VinhTrinh
	Task : Insert new email for EmailHistory
	DB: DB052.Affiliate_12Bet
	Original:

	Revisions:
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]


	Param's Explanation:
	.@MID: OUTPUT of mail id,
	.@creator : id of customer sent this email
	.@content: content of this email,
	.@sender: sender name,
	.@affiliate: name of affiliate in the system,
	.@email: email of sender,
	.@subject: email subject,
	.@ip: ip of computer sent,
	.@browser: name of browser,
	.@sessionid: ASP.NET session id,
	• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Insert unsuccessful.

	• @ErrMsg: Error description.
	*/
	SET NOCOUNT ON

	--check all of parameter is valid.
	DECLARE @affiliateid INT,@maximumPer10minutes INT --maximum of 20 emails per 10 minutes for each session

	SELECT @affiliateid=-1,@maximumPer10minutes=20
	--Check creator name
	IF(@creator<>-1 AND NOT EXISTS(SELECT 1 FROM AffInfo WITH (NOLOCK) WHERE AffId=@creator))
	BEGIN
		BEGIN 
				SELECT @ErrMsg='Invalid creator!',@ErrCode=101
				RETURN
		  END 
	END
	--check affiliate username
	IF(@affiliate IS NOT NULL)
	BEGIN
		SELECT @affiliateid=AffID
		FROM AffInfo  WITH (NOLOCK)  
		WHERE username=@affiliate

		IF (@@rowcount<>1)
		BEGIN 
			SELECT @affiliateid=-1            
		END           
	END

	--check content
	IF (ISNULL(@content,'')='')
	BEGIN
		SELECT @ErrMsg='Invalid mail content!',@ErrCode=102
		RETURN
	END
	--check sender name
	IF (ISNULL(@sender,'')='')
	BEGIN
		SELECT @ErrMsg='Invalid sender name!',@ErrCode=103
		RETURN
	END
 
	--check email
	IF (ISNULL(@email,'')='')
	BEGIN
		SELECT @ErrMsg='Invalid  email address!',@ErrCode=104
		RETURN
	END

	--check mail subject
	IF (ISNULL(@subject,'')='')
	BEGIN
		SELECT @ErrMsg='Invalid  mail subject!',@ErrCode=105
		RETURN
	END

	--check ip
	IF (isnull(@ip,'')='')
	BEGIN
		SELECT @ErrMsg='Invalid sender ip!',@ErrCode=106
		RETURN
	END

	--check browser
	IF (ISNULL(@browser,'')='')
	BEGIN
		SELECT @ErrMsg='Invalid browser name!',@ErrCode=107
		RETURN
	END

	--check session id
	IF (ISNULL(@sessionid,'')='')
	BEGIN
		SELECT @ErrMsg='Invalid ASP.NET session id!',@ErrCode=108
		RETURN
	END
	--Check is allow to send email (just allow to send maximum of @maximumPer10minutes per 10 minutes)
	--if (@affiliateid<>-1)
	--begin
	DECLARE @count INT
	SELECT @count=count(1) FROM [EmailHistory] WITH (NOLOCK)
	WHERE sessionid=@sessionid and datediff(mi,createddate,current_timestamp)<=10

	IF(@count>@maximumPer10minutes)
	BEGIN
		SELECT @ErrMsg='You are just allowed to send maximum of ' + CAST(@maximumPer10minutes AS VARCHAR(5)) + ' emails per 10 minutes!',@ErrCode=102
		RETURN
	END
	--end
	BEGIN TRANSACTION
	INSERT INTO [dbo].[EmailHistory]
			   ([content]
			   ,[sender]
			   ,[creator]
			   ,[AffID]
			   ,[affname]
			   ,[email]
			   ,[subject]
			   ,[createddate]
			   ,[ip]
			   ,[browser]
			   ,[sessionid]
			   )
		 VALUES
			   (@content
			   ,@sender
			   ,@creator
			   ,@affiliateid
			   ,@affiliate
			   ,@email
			   ,@subject
			   ,GETDATE()
			   ,@ip
			   ,@browser
			   ,@sessionid)
		   
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		SELECT @ErrMsg = N'Error! Insert email unsuccessfully!', @ErrCode = 1001
		RETURN
	END

	SELECT @MID = SCOPE_IDENTITY()
	COMMIT TRANSACTION

	DECLARE @LogData NVARCHAR(MAX), @SPName VARCHAR(50)
	SELECT @LogData	= CONVERT(NVARCHAR(MAX),
					  (
							SELECT 
								@sender AS '@Name', 
								@affiliateid AS '@AffiliateId', 
								@email AS '@Email', 
								@subject AS '@Subject', 
								@content AS '@Comment' 
							FOR XML PATH ('row'), ROOT('root')
				      ))

	SELECT @SPName = OBJECT_NAME(@@ProcID) 

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog    
			 @SPName = @SPName
			 ,@UserId = @creator
			 ,@AffId = @affiliateid
			 ,@OldData = NULL
			 ,@NewData = @LogData
			 ,@IP = @IP	
	
END        
GO
