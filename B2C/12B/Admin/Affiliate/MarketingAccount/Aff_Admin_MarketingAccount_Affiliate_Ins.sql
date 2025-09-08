/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_MarketingAccount_Affiliate_Ins]
	@UserId				INT,
	@AffType			INT = 0,
	@Password			NVARCHAR(40) = NULL,
	@GroupId			INT = 0,
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
	@Player_CustId		INT			= NULL,
	@Player_UserName	VARCHAR(30)	= NULL,
	@Player_Currency	INT			= NULL,
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
	Created: 20250617@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Affiliate - Marketing Account - Add New Account [RedmineID: #212201]

	Revisions:
		- 20250617@Sally: Initialize SP [RedmineID: #212201]
		- 20250526@Lewis: Deals - AffGroupHistory [RedmineID: #228530]

*/

BEGIN
	SET NOCOUNT ON

    -- Check permission
	EXEC [dbo].[Aff_Con_CheckPermission]
		@CustId		= @UserId
		,@funcname	= '[AddMarketingAccount]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE @AffId 			INT
		,@MonthDate 		SMALLDATETIME
		,@AffCategoryId 	TINYINT
		,@CurrentDate 		SMALLDATETIME
	  	,@AffCode 			VARCHAR(20) = NULL
	
	
	SELECT @CurrentDate 	= DATEADD(HOUR, 12, GETDATE())
	DECLARE @FromDate DATETIME =  CAST(@CurrentDate AS DATE)
	DECLARE @ToDate DATETIME = '9999-12-31'

	SELECT @AffCategoryId 	= 2 -- Marketing Account
	SELECT @MonthDate 		= EOMONTH(@CurrentDate)


	-- Check exists email
	IF EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE Email = @Email AND AffCategoryId = 1)
		AND NOT EXISTS (SELECT 1 FROM dbo.Aff_f_GetSpecialEmail() f WHERE f.Email = @Email)
	BEGIN
		-- Email Address has been used. Please choose another one!
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(1, @Language)
		RETURN
	END

	-- Check exists player_username
	IF EXISTS (
		SELECT 1 FROM dbo.AffDetail a WITH (NOLOCK) 
			INNER JOIN dbo.AffInfo i WITH (NOLOCK) ON a.AffId = i.AffId
		WHERE a.Player_UserName = @Player_UserName 
			AND ISNULL(@Player_UserName, '') <> ''
	)
	BEGIN
		-- Player Username has been used. Please choose another one!
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(3, @Language)
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupID = @GroupID AND IsDeleted = 0) 
		OR @GroupId = 0
	BEGIN
		-- Group is not existed
		SELECT @ErrCode = 1008, @ErrMsg = dbo.Aff_f_GetMessageById(1006, @Language)
		RETURN
	END

	-- Player currency Info
	DECLARE @SiteName VARCHAR(30), @AffCurrency INT, @AffCurrencyName NVARCHAR(50), @AffCurrencyCode VARCHAR(3)
			,@Player_CurrencyName NVARCHAR(50), @Player_CurrencyCode VARCHAR(3)

	SELECT  @SiteName 	  = dbo.Aff_f_GetSetting('SiteName')
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
		INSERT INTO dbo.AffInfo(UserName, FirstName, LastName, GroupId, Status, ApprovedDate, IsClosed, Currency, DefaultCurrency, CurrencyName, CurrencyCode, RegisteredDate, Email, Password, AffType, ApprovedBy, AffCategoryId)
		VALUES(@UserName, @FirstName, @LastName, @GroupId, 'Approved', @CurrentDate, 0, @AffCurrency, @AffCurrency, @AffCurrencyName, @AffCurrencyCode, GETDATE(), @Email, @Password, @AffType, @UserId, @AffCategoryId)

		SELECT @AffId = SCOPE_IDENTITY()

		-- Get AffCode
		;WITH CTE_AffCode AS
		(
			SELECT TOP 1 * FROM dbo.AffiliateCode WITH (ROWLOCK)
			WHERE AffId IS NULL
			ORDER BY NEWID() -- random
		)
		UPDATE CTE_AffCode
		SET AffId = @AffId
	    
		SELECT @AffCode = AffCode FROM dbo.AffiliateCode WITH (NOLOCK) WHERE AffId = @AffId

		UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
		SET AffCode = @AffCode
		WHERE AffId = @AffId

		INSERT INTO dbo.AffGroupHistory (AffId,MonthDate,GroupId, FromDate, ToDate)
		VALUES (@AffId, @MonthDate, @GroupId, @FromDate, @ToDate)
		-- AffDetail
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
		DELETE dbo.AffDetail WITH (ROWLOCK, UPDLOCK) WHERE AffId = @AffId
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

	INSERT INTO dbo.AffMediaChannel (AffId, ChannelCode, ChannelName)
	SELECT @AffId, LOWER(t.ChannelName), t.ChannelName
	FROM (
			SELECT 'Youtube' as ChannelName
			UNION ALL SELECT 'Facebook'
			UNION ALL SELECT 'Twitter'
			UNION ALL SELECT 'Tiktok'
			UNION ALL SELECT 'Whatsapp'
			UNION ALL SELECT 'Telegram'
	) t
		LEFT JOIN dbo.AffMediaChannel a WITH (NOLOCK) ON a.AffId = @AffId AND a.ChannelCode = LOWER(t.ChannelName)
	WHERE a.AffId IS NULL

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SELECT  @NewData = 
			'AffType='				+ ISNULL(CONVERT(VARCHAR(10), @AffType), '') + ',' +
			'AffId='				+ ISNULL(CONVERT(VARCHAR(20), @AffId), '') + ',' +
			'UserName='				+ ISNULL(@UserName, '') + ',' +
			'FirstName='			+ ISNULL(@FirstName, '') + ',' +
			'LastName='				+ ISNULL(@LastName, '') + ',' +
			'GroupId='				+ ISNULL(CONVERT(VARCHAR(10), @GroupId), '') + ',' +
			'Status='				+ ISNULL('Approved', '') + ',' +
			'ApprovedDate='			+ ISNULL(CONVERT(VARCHAR(20), @CurrentDate, 120), '') + ',' +
			'Gender='				+ ISNULL(CONVERT(VARCHAR(10), @Gender), '') + ',' +
			'Email='				+ ISNULL(@Email, '') + ',' +
			'Password='				+ ISNULL(@Password, '') + ',' +
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
			'Player_CustId='		+ ISNULL(CONVERT(VARCHAR(20), @Player_CustId), '') + ',' +
			'ApprovedBy='			+ ISNULL(CONVERT(VARCHAR(10), @UserId), '') + ',' +
			'AffCode='				+ ISNULL(@AffCode, '') + ',' +		   	
			'AffCategoryId='		+ ISNULL(CONVERT(VARCHAR(10), @AffCategoryId), '')

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO