/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_AffiliateInsClickStatistics_New] 
	@AffiliateID INT
	,@AffDomain NVARCHAR(256) = ''
	,--Url is showed in affiliate site
	@PageCode VARCHAR(50) = 'sportsbook'
	,@LanguageCode VARCHAR(6) = 'en'
	,@IP VARCHAR(45) = ''
	,@Browser NVARCHAR(50) = ''
	,@URLReferrer NVARCHAR(300) = NULL
	,@DomainReferrer NVARCHAR(300) = NULL
	,@OS NVARCHAR(50) = ''
	,@Device NVARCHAR(50) = ''
	,@BrowserVersion NVARCHAR(16) = ''
	,@BrowserResolution NVARCHAR(16) = ''
	,@BrowserLanguage NVARCHAR(8) = ''
	,@UserAgent NVARCHAR(256) = ''
	,@Country NVARCHAR(256) = ''
	,@DeviceType TINYINT = 0
	,@RedirectPage NVARCHAR(256) = NULL OUTPUT
	,@ClickID BIGINT = 0 OUTPUT
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*  Created: 20111005@Johnny  
Task : record clicking Banner action with a specific tracking code  
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
	- 20111228: Get RedirectURL follow affiliate
	- 20121120: Redirect to the main domain (except list affiliates with pagecode 12betcasino still redirect to 12betcasino.com)
	- 20140220@Peter : Support EU aff link
	- 20140326@Bobby : check IsCLosed affiliate user
	- 20140708@Bobby : Apply DeviceType info
	- 20141013@Bobby : Hot fix Euro (PC-Mobile) site
	- 20150728@Bobby : Update new formation of mobile link
	- 20160624@Bobby : #59652 - Update new formation of mobile link
	- 20161215@Bobby : #68815 - Update new link formation for promotion page
	- 20180420@Percy : Change indiancricket to cricket when insert data [RedmineID: #92544]
	- 20180504@Walter: Exclude query by DeviceType [#94324]
	- 20220919@Eddie : Get country code by IP [RedmineID: #176390]
	 
Param's Explanation:   
	- @DeviceType: 0-PC & 1-Mobile
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @AffUsername NVARCHAR(30)
		,@PreferredLanguage VARCHAR(11)
		,@Default12Betdomain NVARCHAR(100)
		,@IsCasino BIT
		,@AffType INT
		,@IsClosed BIT
		,@DomainDeviceType TINYINT = 0
		,@DomainName NVARCHAR(100)
		,@W3Http VARCHAR(5) = ''

	--Off default domain
	--SELECT @Default12Betdomain = NULL --If redirect page is null => redirect to this default domain

	SELECT @AffUsername = ai.Username
		,@PreferredLanguage = PreferredLanguage
		,@AffType = ai.AffType
		,@IsClosed = ai.IsClosed
	FROM AffDetail ad WITH (NOLOCK)
		INNER JOIN AffInfo ai WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId = @AffiliateID
		AND STATUS = 'Approved'

	--check Affiliate ID  
	IF (
			@AffUsername IS NULL
			OR (
				@IsClosed = 1
				AND @AffUsername = '12BETAFF9151'
				)
			)
	BEGIN
		SELECT @ErrCode = 101
			,@ErrMsg = 'This affiliate does not exists. Please contact administrator!'

		RETURN
	END

	--Checking Input member IP
	IF COALESCE(@IP, '') = ''
	BEGIN
		SELECT @ErrCode = 102
			,@ErrMsg = 'The IP is required. Please check!'

		RETURN
	END

	--Get redirect link
	SELECT @RedirectPage = (
			SELECT TOP 1 CValue --Get link for some special affiliate
			FROM CommonSettings(NOLOCK)
			WHERE [Type] = @PageCode
				AND CName = @AffUsername
			)

	IF (@RedirectPage IS NULL)
	BEGIN
		DECLARE @AffDomainId 	INT
			,@AffDomainName 	NVARCHAR(255)
			
		
		SELECT @AffDomainId = DomainID
			,@AffDomainName = DomainName
		FROM AffDomain WITH(NOLOCK)
		WHERE DomainName = @AffDomain
			AND IsDeleted = 0

		SELECT TOP 1 @DomainName = b.DomainName
			,@W3Http = CASE WHEN ISNULL(b.IsSSL, 0) = 1 THEN 'https' ELSE 'http' END
		FROM AffDomainControl a WITH (NOLOCK)
			INNER JOIN [12BetDomain] b WITH (NOLOCK) 
			ON a.[12BetDomainID] = b.DomainID
		WHERE a.MarketId = @PreferredLanguage
			AND a.AffDomainId = @AffDomainId
			AND a.[status] = 1
			AND a.IsDeleted = 0
			AND b.IsDeleted = 0

		--Replace Aff Domain by 12bet domain to redirect to 12bet site
		SET @RedirectPage = CASE 
				WHEN @DomainName IS NOT NULL THEN @W3Http + '://' + @DomainName + '/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
				ELSE @Default12Betdomain
				END
	END
	ELSE
	BEGIN --This aff is special aff and pagecode = '12betcasino'
		SELECT @LanguageCode = (CASE 
				WHEN @LanguageCode = 'ch' THEN 'cs'
				WHEN @LanguageCode = 'eneuro'
					OR @LanguageCode = 'es' THEN 'en'
				WHEN @LanguageCode = 'vn' THEN 'vi'
				ELSE @LanguageCode END
			)

		SELECT @RedirectPage = replace(@RedirectPage, '{custid}', @AffiliateID)

		SELECT @RedirectPage = replace(@RedirectPage, '{target}', @pagecode)

		SELECT @RedirectPage = replace(@RedirectPage, '{lang}', @LanguageCode)

		SELECT @RedirectPage = replace(@RedirectPage, '{/TrackingCode}', '')
	END

	IF (@RedirectPage IS NULL)
	BEGIN
		SELECT @ErrCode = 103
			,@ErrMsg = 'This link does not exists. Please contact administrator!'
		RETURN;
	END
	ELSE
	BEGIN
		DECLARE @EUDomain 		VARCHAR(100)		
		SELECT @EUDomain 		= 'eu.12bet.com'
		
		--final check for EU member site
		IF(@LanguageCode IN ('eneuro', 'es'))
		BEGIN
			-- Reset language code
			SELECT @RedirectPage = REPLACE(@RedirectPage, 'eneuro', 'en')
			SELECT @RedirectPage = REPLACE(@RedirectPage, 'es', 'en')
			-- Reset mobile link
			IF(@DomainName <> @EUDomain)
			BEGIN
				SET @RedirectPage = REPLACE(@RedirectPage, @DomainName, @EUDomain)
			END
		END
		IF(@PageCode IN ('promotion') AND @LanguageCode IN ('hien'))
		BEGIN
			SELECT @RedirectPage = REPLACE(@RedirectPage, 'hien', 'hi')
		END
	END
	
	-- process aff link
	DECLARE @CountryCode VARCHAR(2)

	SELECT @CountryCode = [dbo].[Aff_f_IP_GetCountryCode](@IP)

	--Temporarily hard code afftype, will be removed soon
	IF @AffType <= 2
	BEGIN
		SELECT @AffType = 2
	END

	-- check whether this aff belongs to Korean's comm group
	IF EXISTS (
			SELECT 1
			FROM [dbo].[AffInfo] a WITH (NOLOCK)
				JOIN [dbo].[CommGroup] c WITH (NOLOCK) ON a.[GroupID] = c.[GroupID]
			WHERE a.[AffID] = @AffiliateID
				AND c.[GroupName] = 'Korean Agent Comm'
			)
	BEGIN
		SELECT @AffType = 5

		IF CHARINDEX('?', @RedirectPage) > 0
		BEGIN
			SELECT @RedirectPage = @RedirectPage + '&IsKA=1'
		END
		ELSE
		BEGIN
			SELECT @RedirectPage = @RedirectPage + '?IsKA=1'
		END
	END

	INSERT INTO [ClickStatistics1] (
		[AffID]
		,[UpdatedTime]
		,[IP]
		,[Date]
		,[Browser]
		,[URLReferrer]
		,[DomainReferrer]
		,[OS]
		,[Device]
		,[BrowserVersion]
		,[BrowserResolution]
		,[BrowserLanguage]
		,[UserAgent]
		,[Country]
		,[LanguageCode]
		,[SportCode]
		,[RedirectURL]
		,[Status]
		,[DeviceType]
		)
	VALUES (
		@AffiliateID
		,getdate()
		,@IP
		,CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
		,@Browser
		,coalesce(@URLReferrer, 'none')
		,coalesce(@DomainReferrer, 'none')
		,@OS
		,@Device
		,@BrowserVersion
		,@BrowserResolution
		,@BrowserLanguage
		,@UserAgent
		,ISNULL(@CountryCode, '-')
		,(CASE 
			WHEN @LanguageCode = 'vi' THEN 'vn'
			ELSE @LanguageCode END
			) --Only store vn for vietnamese
		,CASE WHEN @PageCode = 'indiancricket' THEN 'cricket' ELSE @PageCode END
		,@RedirectPage --if not Casino aff => redirect to main domain
		,0
		,@DeviceType
		)

	SELECT @ClickID = SCOPE_IDENTITY()

	SELECT @RedirectPage = replace(@RedirectPage, '{clickid}', @ClickID)

	SELECT @RedirectPage = replace(@RedirectPage, '{typeid}', @AffType)

	UPDATE [ClickStatistics1] WITH (ROWLOCK, UPDLOCK)
	SET [RedirectURL] = @RedirectPage
	WHERE clickId = @ClickID

	RETURN;
END

GO