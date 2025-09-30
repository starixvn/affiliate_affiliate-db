ALTER PROCEDURE [dbo].[Aff_User_SecureLoginUpdate]
(
	@AffID				INT 
	,@IsSuccess 		BIT
	,@ServerID 			INT
	,@LoginIP 			VARCHAR(20)
	,@NetSessionID 		VARCHAR(30)
	,@OnUserID 			INT = 0 OUTPUT
	,@ErrCode 			INT = 0 OUTPUT
	,@ErrMsg 			NVARCHAR(500) = '' OUTPUT
)
AS
/*
	Author:	20140917@Bobby
	Task: Apply Secure Form Permission - After login
	Orgrinal:DBAFFATHENA000\Affiliate_Athena000
	
	Revisions:
		
	Params Explanations:
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @UserName	VARCHAR(30)
		,@IsLocked		BIT
		,@FailedCount	INT
		,@LogData 		NVARCHAR(200)
		,@SPName 		VARCHAR(50)
		
	SELECT @SPName = OBJECT_NAME(@@ProcID)
	
	SELECT TOP 1 
		ai.AffID
		,ai.UserName
		,ai.[STATUS]
		,ai.IsClosed
		,ai.IsLocked
		,ad.LoginCount		AS FailedCount
	INTO #AffLoginInfo
	FROM [dbo].[AffInfo] ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) 
		ON ai.AffID = ad.affID
	WHERE ai.AffID 	= @AffID
	
	SELECT @UserName	= ai.UserName
		,@IsLocked		= ai.IsLocked
		,@FailedCount	= ai.FailedCount
	FROM #AffLoginInfo ai
	
	-- Aff User not found
	IF(@UserName IS NULL)
	BEGIN
		RETURN
	END
	
	IF ( @IsSuccess = 0 ) -- Login failed
	BEGIN
		SELECT @LogData = 'Failed login attempt (wrong password), ServerID:' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] 
			@Creator 	= @AffID
			,@AffID 	= @AffID
			,@Typename 	= 'LoginAffiliate'
			,@SPName 	= @SPName
			,@IP 		= @LoginIP
			,@Details 	= @LogData

		SELECT @FailedCount += 1

		IF (@FailedCount > 5)
		BEGIN
			UPDATE d
			SET IsLocked = ~ ISNULL(IsLocked, 0)
			FROM dbo.AffInfo d WITH (ROWLOCK, UPDLOCK)
			WHERE AffID = @AffID

			SELECT @LogData = 'The A/C is Locked due to 5 wrong password attempts'

			EXEC [dbo].[Aff_WriteLog] 
				@Creator 	= @AffID
				,@AffID 	= @AffID
				,@Typename 	= 'LoginAffiliate'
				,@SPName 	= @SPName
				,@IP 		= @LoginIP
				,@Details 	= @LogData

			SELECT @ErrCode = 103
				, @ErrMsg	= 'Failed login attempt (wrong password). The A/C is Locked due to 5 wrong password attempts'
		END
		ELSE
		BEGIN
			SELECT @ErrCode = 101
				,@ErrMsg	= 'Failed login attempt (wrong password).'
		END
		
		--Update FailedCount
		UPDATE d 
		SET LoginCount = @FailedCount
		FROM dbo.AffDetail d WITH (ROWLOCK, UPDLOCK)
		WHERE AffID = @AffID

		RETURN
	END
	
	IF ( @IsSuccess = 1 ) -- Login Successful
	BEGIN
		--Unlock user after 10 minute login sucessfully automatically    
		IF (ISNULL(@IsLocked, 0) = 1)
		BEGIN
			UPDATE d
			SET isLocked = ~ isLocked
			FROM dbo.AffInfo d WITH (ROWLOCK, UPDLOCK)
			WHERE AffID = @AffID
		END

		--Reset LoginCount value
		UPDATE d
		SET LoginCount 		= 0
			,LastLoginIP 	= @LoginIP
			,LastLoginDate 	= CURRENT_TIMESTAMP
		FROM dbo.AffDetail d WITH (ROWLOCK, UPDLOCK)
		WHERE AffID = @AffID

		UPDATE d
		SET IsKickedout = 1
			,ServerID 	= 0
		FROM dbo.on_user d WITH (ROWLOCK)
		WHERE CustID = @AffId

		--insert into on_user
		INSERT INTO on_user (
			custid
			,NetSessionID
			,on_sessionid
			,ServerId
			,IsKickedout
			,IP
			,SubAccID
			,reload_time
			)
		VALUES (
			@AffId
			,@NetSessionid
			,0
			,@ServerID
			,0
			,@LoginIP
			,0
			,CURRENT_TIMESTAMP
			)

		SELECT @OnUserID = SCOPE_IDENTITY()

		SELECT @LogData = 'Successful login, ServerID:' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] 
			@Creator 	= @AffID
			,@AffID 	= @AffID
			,@Typename 	= 'LoginAffiliate'
			,@SPName 	= @SPName
			,@IP 		= @LoginIP
			,@Details 	= @LogData
	END
	
	RETURN;
END
GO

GRANT EXECUTE ON [dbo].[Aff_User_SecureLoginUpdate] TO [bodbDownlineNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Aff_User_SecureLoginUpdate] TO [bodbDownlineNetView] AS [dbo]
GO
