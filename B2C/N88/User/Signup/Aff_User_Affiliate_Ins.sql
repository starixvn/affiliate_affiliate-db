/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Affiliate_Ins]
	-- Type of affiliate: Asian, Euro, Media
	@AffParentCode		VARCHAR(20) = '',
	@AffType			INT = 0,
	-- Contact Information
	@FirstName			NVARCHAR(50),
	@LastName			NVARCHAR(50),
	@Gender				BIT,
	@Email				NVARCHAR(50),
	@Phone				VARCHAR(50), -- Contact Number
	@ContactApps		NVARCHAR(2000), -- List of Skype, Zalo, QQ, Line,...
	-- Mailing Information
	@Address			NVARCHAR(250),
	@City				NVARCHAR(250),
	@State				NVARCHAR(50), -- support Chinese language
	@Postal				NVARCHAR(50), -- Postcode/Zip
	@Country			NVARCHAR(100),
	-- Website Information
	@SiteUrl			VARCHAR(100), -- Website URL
	@MoreSiteUrls		VARCHAR(1000) = NULL, -- Add new website URL
	@NoSiteDesc			NVARCHAR(1000) = NULL,
	-- Preferrence
	@PreferredLanguage	VARCHAR(11),
	@QuestionID			TINYINT,
	@Answer				NVARCHAR(300),
	-- Payment Information
	@PreferredPayment	VARCHAR(20) = 'Player',
	@Player_CustId		INT,
	@Player_UserName	VARCHAR(30),
	@Player_Currency	INT,
	-- Output
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(4000) = '' OUTPUT,
	@Username			NVARCHAR(50) = NULL OUTPUT,
	-- Others
	@IP					VARCHAR(50) = '',
	@Language			VARCHAR(10) = 'en-US',
	-- TargetCountryCode
	@TargetCountryCode	VARCHAR(5)
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Signup affiliate

	Revisions:
		- 20200220@Percy: Initialize SP [Redmine: #128775]
		- 20201026@Percy: Replace ParentAffId to AffCode [RedmineID: #143852]
		- 20230912@Sally: Fix recursion 100 has been exhausted [RedmineID: #193867]
		- 20231109@Sally: Retrieved Correctly Player_currencyCode Player_CurrencyName Values
		- 20250729@Danny: Add TargetCountry [RedmineID: #227560]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffId INT, @MonthDate SMALLDATETIME

	-- Check exists email
	IF EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE Email = @Email)
	BEGIN
		-- Email Address has been used. Please choose another one!
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(1, @Language)

		RETURN
	END

	-- Check exists player_username
	IF EXISTS (SELECT 1 FROM dbo.AffDetail WITH (NOLOCK) WHERE Player_Username = @Player_UserName)
	BEGIN
		-- Player Username has been used. Please choose another one!
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(3, @Language)

		RETURN
	END

	DECLARE @MaxSubLevel SMALLINT
	DECLARE @ParentAffId INT, @AllParentAffId VARCHAR(MAX)

	IF ISNULL(@AffParentCode, '') <> ''
	BEGIN
		SELECT @ParentAffId = AffId FROM dbo.AffiliateCode WITH (NOLOCK) WHERE AffCode = @AffParentCode

		IF @@ROWCOUNT = 0
		BEGIN
			-- The information you have entered is invalid. Please check again.
			SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(105, @Language)

			RETURN
		END

		SELECT @AllParentAffId = AllParentAffId FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @ParentAffId

		IF @@ROWCOUNT = 0
		BEGIN
			-- The information you have entered is invalid. Please check again.
			SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(105, @Language)

			RETURN
		END

		SELECT @MaxSubLevel = CONVERT(SMALLINT, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'MaxSubLevel'

		IF (SELECT COUNT(1) + 1 AS SubLevel FROM STRING_SPLIT(@AllParentAffId, ',')) > @MaxSubLevel
		BEGIN
			-- The information you have entered is invalid. Please check again.
			SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(105, @Language)

			RETURN
		END

		SELECT @AllParentAffId = CONVERT(VARCHAR(50), @ParentAffId) + ISNULL(',' + @AllParentAffId, '')
	END
	ELSE
	BEGIN
		SELECT @ParentAffId = NULL, @AllParentAffId = NULL
	END

	DECLARE @SiteName VARCHAR(30), @AffCurrency INT, @AffCurrencyName NVARCHAR(50), @AffCurrencyCode VARCHAR(3)
			,@Player_CurrencyName NVARCHAR(50), @Player_CurrencyCode VARCHAR(3)

	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName')
			,@AffCurrency = dbo.Aff_f_GetSetting('AffCurrency')
	
	-- Get Currency mapping
	DECLARE @AffExchangeId INT = @AffCurrency
		,@Player_ExchangeId INT = @Player_Currency

	SELECT @AffExchangeId = te.ExchangeId
	FROM dbo.TpExchange te WITH (NOLOCK)
	WHERE te.TpExchangeId = @AffCurrency

	SELECT @Player_ExchangeId = te.ExchangeId
	FROM dbo.TpExchange te WITH (NOLOCK)
	WHERE te.TpExchangeId = @Player_Currency

	-- Get Player_IBCCustId from Player_Username
	SELECT @AffCurrencyName = Currency, @AffCurrencyCode = Code FROM bodb02.dbo.Exchange WITH (NOLOCK) WHERE ExchangeId = @AffExchangeId
	SELECT @Player_CurrencyName = Currency, @Player_CurrencyCode = Code FROM bodb02.dbo.Exchange WITH (NOLOCK) WHERE ExchangeId = @Player_ExchangeId

	DECLARE @PrefixName VARCHAR(30)
	SELECT  @PrefixName = @SiteName + 'AFF'

	-- Generate username
	EXEC dbo.Aff_GenerateUsername @PrefixName = @PrefixName, @Username = @Username OUTPUT

	-- Insert data
	
		-- AffInfo
	BEGIN TRY
		INSERT INTO dbo.AffInfo(UserName,FirstName,LastName,Status,IsClosed,Currency,DefaultCurrency,CurrencyName,CurrencyCode,RegisteredDate,Email,Password,AffType,ParentAffId,AllParentAffId)
		VALUES(@UserName,@FirstName,@LastName,'Pending',0,@AffCurrency,@AffCurrency,@AffCurrencyName,@AffCurrencyCode,GETDATE(),@Email,'',@AffType,@ParentAffId,@AllParentAffId)

		SELECT @AffId = SCOPE_IDENTITY()

		SELECT @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

		INSERT INTO dbo.AffGroupHistory (AffId,MonthDate,GroupId,ParentAffId,AllParentAffId)
		VALUES (@AffId,@MonthDate,0,@ParentAffId,@AllParentAffId)
	END TRY
	BEGIN CATCH
		-- Rollback manually
		DELETE dbo.AffInfo WITH (ROWLOCK, UPDLOCK) WHERE AffId = @AffId

		DELETE dbo.AffGroupHistory WITH (ROWLOCK, UPDLOCK) WHERE AffId = @AffId AND MonthDate = @MonthDate

		-- Rolback username 
		DELETE 	Username_AutoIncrement WITH (ROWLOCK) 
		WHERE 	PrefixName = @PrefixName
				AND SubfixName = (CONVERT(INT, RIGHT(@Username, LEN(@Username) - LEN(@PrefixName))))
				
		-- Create customer failed. Please try again.
		SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(2, @Language)

		RETURN
	END CATCH

		-- AffDetail
	BEGIN TRY
		INSERT INTO dbo.AffDetail
		(
			AffId, UserName,
			-- Contact Information
			Gender,MailOption,Phone,ContactApps,Fax,
			-- Mailing Information
			Address,City,State,Postal,Country,
			-- Website Information
			SiteUrl,MoreSiteUrls,NoSiteDesc,
			-- Preferrence
			PreferredLanguage,QuestionID,Answer,TargetCountryCode,
			-- Payment Information
			PreferredPayment,Player_CustID,Player_UserName,Player_Currency,Player_CurrencyName,Player_CurrencyCode
		)
		VALUES
		(
			@AffId, @UserName,
			-- Contact Information
			@Gender,0,@Phone,@ContactApps,'',
			-- Mailing Information
			@Address,@City,@State,@Postal,@Country,
			-- Website Information
			@SiteUrl,@MoreSiteUrls,@NoSiteDesc,
			-- Preferrence
			@PreferredLanguage,@QuestionID,@Answer,@TargetCountryCode,
			-- Payment Information
			@PreferredPayment,@Player_CustId,@Player_UserName,@Player_Currency,@Player_CurrencyName,@Player_CurrencyCode
		)
	END TRY
	BEGIN CATCH
		-- Rollback manually
		DELETE dbo.AffInfo WITH (ROWLOCK, UPDLOCK) WHERE AffId = @AffId

		DELETE dbo.AffGroupHistory WITH (ROWLOCK, UPDLOCK) WHERE AffId = @AffId AND MonthDate = @MonthDate
		
		-- Rolback username 
		DELETE 	Username_AutoIncrement WITH (ROWLOCK) 
		WHERE 	PrefixName = @PrefixName
				AND SubfixName = (CONVERT(INT, RIGHT(@Username, LEN(@Username) - LEN(@PrefixName))))

		-- Create customer failed. Please try again.
		SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(2, @Language)

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SELECT  @NewData = 
			'AffType='				+ ISNULL(CONVERT(VARCHAR(10), @AffType), '') + ',' +
			'AffId='				+ ISNULL(CONVERT(VARCHAR(20), @AffId), '') + ',' +
			'ParentAffId='			+ ISNULL(CONVERT(VARCHAR(20), @ParentAffId), '') + ',' +
			'AllParentAffId='		+ ISNULL(@AllParentAffId, '') + ',' +
			'UserName='				+ ISNULL(@UserName, '') + ',' +
			'FirstName='			+ ISNULL(@FirstName, '') + ',' +
			'LastName='				+ ISNULL(@LastName, '') + ',' +
			'Gender='				+ ISNULL(CONVERT(VARCHAR(10), @Gender), '') + ',' +
			'Email='				+ ISNULL(@Email, '') + ',' +
			'Phone='				+ ISNULL(@Phone, '') + ',' +
			'ContactApps='			+ ISNULL(@ContactApps, '') + ',' +
			'Address='				+ ISNULL(@Address, '') + ',' +
			'City='					+ ISNULL(@City, '') + ',' +
			'State='				+ ISNULL(@State, '') + ',' +
			'Postal='				+ ISNULL(@Postal, '') + ',' +
			'Country='				+ ISNULL(@Country, '') + ',' +
			'SiteUrl='				+ ISNULL(@SiteUrl, '') + ',' +
			'MoreSiteUrls='			+ ISNULL(@MoreSiteUrls, '') + ',' +
			'NoSiteDesc='			+ ISNULL(@NoSiteDesc, '') + ',' +
			'PreferredLanguage='	+ ISNULL(@PreferredLanguage, '') + ',' +
			'TargetCountryCode='	+ ISNULL(@TargetCountryCode, '') + ',' +
			'QuestionID='			+ ISNULL(CONVERT(VARCHAR(5), @QuestionID), '') + ',' +
			'Answer='				+ ISNULL(@Answer, '') + ',' +
			'PreferredPayment='		+ ISNULL(@PreferredPayment, '') + ',' +
			'Player_UserName='		+ ISNULL(@Player_UserName, '') + ',' +
			'Player_CustId='		+ ISNULL(CONVERT(VARCHAR(20), @Player_CustId), '')

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO