ALTER PROCEDURE [dbo].[Aff_User_SecureLoginInfo]
(
	@UserName			VARCHAR(30)
	,@InputAffType 		INT = 1
	,@ServerID 			INT
	,@LoginIP 			VARCHAR(20)
	,@ErrCode 			INT = 0 OUTPUT
	,@ErrMsg 			NVARCHAR(500) = '' OUTPUT
)
AS
/*
	Author:	20140917@Bobby
	Task: Apply Secure Form Permission
	Orgrinal:DBAFFATHENA000\Affiliate_Athena000
	
	Revisions:
		
	Params Explanations:
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @AffID		INT
		,@AffType 		INT
		,@AffStatus		VARCHAR(100)
		,@IsClosed		BIT
		,@IsLocked		BIT
		,@FailedCount	INT
		,@LastLoginDate DATETIME
		;
	DECLARE @LogData 	NVARCHAR(200)
		,@SPName 		VARCHAR(50)
		
	SELECT @SPName = OBJECT_NAME(@@ProcID)
	
	SELECT TOP 1 
		ai.AffID
		,ai.UserName
		,ai.FirstName
		,ai.LastName
		,ai.[STATUS]
		,ai.IsClosed
		,ai.Email
		,ai.[Password]
		,ai.[LEVEL]				AS AffLevel
		,ai.IsPageEnabled		AS IsAllowedPersonalizedPage
		,ai.IsLocked
		,ai.AffType
		,at.Name				AS AffTypeName
		,ad.PreferredLanguage	AS PreferLang
		,ad.MailOption
		,CASE 
			WHEN ad.Question IS NULL
				OR ad.Answer IS NULL THEN 0
			ELSE 1
			END					AS HasSecurityQuestion
		,ad.LoginCount			AS FailedCount
		,ISNULL(ad.LastLoginDate, CURRENT_TIMESTAMP) AS LastLoginDate
		,ex.ExchangeID			AS CurrencyID
		,ex.Code				AS Currency
	INTO #AffLoginInfo
	FROM [dbo].[AffInfo] ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) 
		ON ai.AffID = ad.affID
		INNER JOIN dbo.AffType at WITH(NOLOCK) 
		ON ai.AffType = at.TypeID
		LEFT JOIN dbo.Exchange ex WITH (NOLOCK) 
		ON ai.Currency = ex.ExchangeID
	WHERE ai.UserName 	= @UserName
		OR ai.Email 	= @UserName
	
	
	SELECT @AffID		= ai.AffID
		,@AffType 		= ai.AffType
		,@AffStatus		= ai.[Status]
		,@IsClosed		= ai.IsClosed
		,@IsLocked		= ai.IsLocked
		,@FailedCount	= ai.FailedCount
		,@LastLoginDate	= ai.LastLoginDate
	FROM #AffLoginInfo ai
	
	-- Aff User not found
	IF(@AffID IS NULL
		OR (
				@InputAffType = 3
				AND @AffType <> 3
				)
			OR (
				@InputAffType <> 3
				AND @AffType = 3
				)
	) --Check for kiosk system  
	BEGIN
		SELECT @LogData = 'Failed login attempt (wrong username), ServerID:' + dbo.Aff_ToString(@ServerID) + ', [' + @UserName + ']'

		EXEC [dbo].[Aff_WriteLog] 
			@Creator 	= @AffID
			,@Typename 	= 'LoginAffiliate'
			,@SPName 	= @SPName
			,@IP 		= @LoginIP
			,@Details 	= @LogData

		SELECT @ErrCode = 101
			,@ErrMsg 	= 'Failed login attempt (wrong username).'

		RETURN
	END
	
	--check Account IsClosed    
	IF (ISNULL(@IsClosed, 0) = 1)
	BEGIN
		SELECT @LogData = 'Failed login attempt (account is Closed), ServerID:' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] 
			@Creator 	= @AffID
			,@AffID 	= @AffID
			,@Typename 	= 'LoginAffiliate'
			,@SPName 	= @SPName
			,@IP 		= @LoginIP
			,@Details 	= @LogData

		SELECT @ErrCode = 102
			,@ErrMsg 	= 'Failed login attempt (account is Closed).'
		RETURN
	END

	--check Account Is Locked     
	IF (
			ISNULL(@IsLocked, 0) = 1
			AND DATEDIFF(mi, @LastLoginDate, CURRENT_TIMESTAMP) < 10
			)
	BEGIN
		SELECT @LogData = 'Failed login attempt (account is Locked), ServerID:' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] @Creator = @AffID
			,@AffID 	= @AffID
			,@Typename 	= 'LoginAffiliate'
			,@SPName 	= @SPName
			,@IP 		= @LoginIP
			,@Details 	= @LogData

		SELECT @ErrCode = 103
			,@ErrMsg 	= 'Failed login attempt (account is Locked).'

		RETURN
	END

	--Update last login info
	UPDATE d
	SET LastLoginDate = CURRENT_TIMESTAMP
	FROM dbo.AffDetail d WITH (ROWLOCK, UPDLOCK)
	WHERE AffID = @AffID

	--check pending or expired    
	IF @AffStatus <> 'Approved'
	BEGIN
		SELECT @LogData = 'Failed login attempt (account is not approved), ServerID:' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] 
			@Creator 	= @AffID
			,@AffID 	= @AffID
			,@Typename 	= 'LoginAffiliate'
			,@SPName 	= @SPName
			,@IP 		= @LoginIP
			,@Details 	= @LogData

		SELECT @LogData = @UserName + ' IP:' + @LoginIP + ' Account not approved.' + dbo.Aff_ToString(@ServerID)

		EXEC [dbo].[Aff_WriteLog] 
			@Creator 	= @AffID
			,@AffID 	= @AffID
			,@Typename 	= 'LoginAffiliate'
			,@SPName 	= @SPName
			,@Details 	= @LogData

		SELECT @ErrCode = 104
			,@ErrMsg 	= 'Failed login attempt (account is not approved).'

		RETURN
	END
	
	--select to output
	SELECT ai.AffId
		,ai.[Password]
		,ai.FirstName
		,ai.LastName
		,ai.Email
		,ai.MailOption
		,ai.PreferLang
		,ai.HasSecurityQuestion
		,ai.IsAllowedPersonalizedPage
		,ai.AffLevel
		,ai.AffType
		,ai.Currency
		,ai.CurrencyID
		,ai.FailedCount
	FROM #AffLoginInfo ai
	
	DROP TABLE #AffLoginInfo;
	
	RETURN;
	
END
GO

GRANT EXECUTE ON [dbo].[Aff_User_SecureLoginInfo] TO [bodbDownlineNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Aff_User_SecureLoginInfo] TO [bodbDownlineNetView] AS [dbo]
GO
