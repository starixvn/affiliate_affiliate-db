/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_Affiliate_Ins]
	-- Type of affiliate: Asian, Euro, Media
	@AffType			INT = 0,
	-- Contact Information
	@FirstName			NVARCHAR(100),
	@LastName			NVARCHAR(100),
	@Gender				BIT,
	@Email				NVARCHAR(100),
	@Phone				NVARCHAR(100), -- Contact Number
	@ContactApps		NVARCHAR(2000), -- List of Skype, Zalo, QQ, Line,...
	-- Mailing Information
	@Address			NVARCHAR(500),
	@City				NVARCHAR(500),
	@State				NVARCHAR(100), -- support Chinese language
	@Postal				NVARCHAR(100), -- Postcode/Zip
	@Country			NVARCHAR(100),
	-- Website Information
	@SiteUrl			VARCHAR(1000), -- Website URL
	@MoreSiteUrls		VARCHAR(MAX) = NULL, -- Add new website URL
	@NoSiteDesc			NVARCHAR(MAX) = NULL,
	-- Preferrence
	@PreferredLanguage	VARCHAR(100),
	@Question			NVARCHAR(600),
	@Answer				NVARCHAR(600),
	-- Payment Information
	@PreferredPayment	VARCHAR(20) = 'Player',
	@Player_UserName	VARCHAR(100),
	-- Output
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(4000) = '' OUTPUT,
	@Username			NVARCHAR(50) = NULL OUTPUT,
	-- Others
	@IP					VARCHAR(50) = '',
	@Language			VARCHAR(10) = 'en-US'
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Signup affiliate

	Revisions:
		- 20180601@Percy: Initialize SP [Redmine: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffId INT, @Player_IBCCustId INT

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

	-- Get Player_IBCCustId from Player_Username
	SELECT @Player_IBCCustId = CustId FROM DBEXT.bodb02.dbo.Customer WITH (NOLOCK) WHERE Username2 = '12BET$' + @Player_UserName

	-- Generate username
	EXEC dbo.Aff_GenerateUsername @PrefixName = '12BETAFF', @Username = @Username OUTPUT

	-- Insert data
		-- AffInfo
	BEGIN TRY
		INSERT INTO dbo.AffInfo(UserName,FirstName,LastName,Status,IsClosed,Currency,RegisteredDate,Email,Password,AffType)
		VALUES(@UserName,@FirstName,@LastName,'Pending',0,3,GETDATE(),@Email,'',@AffType)

		SELECT @AffId = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
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
			PreferredLanguage,Question,Answer,
			-- Payment Information
			PreferredPayment,Player_IBCCustID,Player_UserName
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
			@PreferredLanguage,@Question,@Answer,
			-- Payment Information
			@PreferredPayment,@Player_IBCCustId,@Player_UserName
		)
	END TRY
	BEGIN CATCH
		-- Rollback manually
		DELETE dbo.AffInfo WITH (ROWLOCK, UPDLOCK) WHERE AffId = @AffId

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
			'Question='				+ ISNULL(@Question, '') + ',' +
			'Answer='				+ ISNULL(@Answer, '') + ',' +
			'PreferredPayment='		+ ISNULL(@PreferredPayment, '') + ',' +
			'Player_UserName='		+ ISNULL(@Player_UserName, '')

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO