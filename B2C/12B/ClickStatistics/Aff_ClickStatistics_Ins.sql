/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_ClickStatistics_Ins]
	@AffCode			VARCHAR(20)
	,@AffDomain			NVARCHAR(50) = ''
	,@PageCode			VARCHAR(50) = ''
	,@LanguageCode		VARCHAR(6) = 'en'
	,@IP				VARCHAR(50) = ''
	,@Browser			NVARCHAR(50) = ''
	,@URLReferrer		NVARCHAR(300) = NULL
	,@DomainReferrer	NVARCHAR(300) = NULL
	,@AffMediaLink		VARCHAR(500) = NULL
	,@OS				NVARCHAR(50) = ''
	,@Device			NVARCHAR(50) = ''
	,@BrowserVersion	NVARCHAR(16) = ''
	,@BrowserResolution NVARCHAR(16) = ''
	,@BrowserLanguage	NVARCHAR(8) = ''
	,@UserAgent			NVARCHAR(256) = ''
	,@Country			NVARCHAR(256) = ''
	,@DeviceType		TINYINT = 0
    ,@ChannelCode       VARCHAR(50) = NULL
	,@RedirectPage		NVARCHAR(256) = NULL OUTPUT
	,@ClickID			BIGINT = 0 OUTPUT
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Clicking Banner action

	Revisions:  
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250221@Eddie: Support to config redirect link for specific affiliates [RedmineID: #218213]
        - 20250221@Sally: Enhance AFFMediaLink  [RedmineID: #212201]
		- 20250305@Sally: Specific AFF Link SP [RedmineID: #219049]
*/

BEGIN
	SET NOCOUNT ON
	DECLARE @AffId 				INT = NULL
	      , @AffUsername 		NVARCHAR(30)
		  , @IsClosed			BIT
		  , @PreferredLanguage 	VARCHAR(11)
		  , @LicenseeDomain		NVARCHAR(50)
		  , @IsSSL				BIT
		  , @AffDomainId 		INT
		  , @RedirectDomain		NVARCHAR(256) = NULL
		  ,	@affMediaLinkId		VARCHAR(50)	  = ''
		  , @LanguageMediaLink	VARCHAR(11)	  = ''

    SET @ChannelCode = ISNULL(@ChannelCode, '')

	SELECT @AffId = ac.AffId
	FROM dbo.AffiliateCode ac WITH(NOLOCK)
	WHERE ac.AffCode = @AffCode

	SELECT @LanguageMediaLink = m.MarketId
	FROM dbo.Market m WITH(NOLOCK)
	WHERE m.ShortedCode = @LanguageCode

	IF COALESCE(@IP, '') = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'The IP is required. Please check!'
		RETURN
	END

	SELECT @AffUsername = ai.Username
		 , @PreferredLanguage = ad.PreferredLanguage
		 , @IsClosed = ai.IsClosed
	FROM dbo.AffDetail ad WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId = @AffId AND ai.Status = 'Approved'

	--check Affiliate ID 
	IF @AffUsername IS NULL OR @IsClosed IS NULL OR @IsClosed = 1
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This affiliate does not exists. Please contact administrator!'
		RETURN
	END

	--Get redirect link
	BEGIN

		IF NOT EXISTS(
			SELECT TOP 1 1
			FROM dbo.Aff_f_SpecificRedirectDomain()
			WHERE AffDomain = @AffDomain
		)
		BEGIN
			SELECT @AffDomainId	= DomainID
			FROM dbo.AffDomain WITH (NOLOCK)
			WHERE DomainName = @AffDomain 
				AND IsDeleted = 0
			
			SELECT TOP (1) @LicenseeDomain 	= b.DomainName
					,  @IsSSL		   		= b.IsSSL
			FROM dbo.DomainControl a WITH (NOLOCK)
				INNER JOIN dbo.LicenseeDomain b WITH (NOLOCK) ON a.LicenseeDomainId = b.DomainId
			WHERE a.MarketId = @PreferredLanguage
				AND a.AffDomainId = @AffDomainId
				AND a.[Status] = 1
				AND a.IsDeleted = 0
				AND b.IsDeleted = 0
		END

		-- Get AffMediaLinkId: only tracking link is ON
		SELECT @affMediaLinkId = AffMediaLinkId
		FROM dbo.AffMediaLink WITH (NOLOCK)
		WHERE AffId 		 = @AffId
			AND ChannelCode  = @ChannelCode
			AND LanguageCode = @LanguageMediaLink
			AND AffMediaLink = @AffMediaLink
			AND IsShow 		 = 1

		-- Get redirect domain of specific AFF
		SELECT @RedirectDomain = RedirectDomain
		FROM dbo.Aff_f_SpecificRedirectDomain()
		WHERE AffDomain = @AffDomain AND AffUsername = @AffUsername

		IF @RedirectDomain IS NOT NULL
		BEGIN	
			--Specific redirect domain	
			SET @RedirectPage = @RedirectDomain + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode + '&affMediaLinkId=' + @affMediaLinkId
		END
		ELSE
		BEGIN
		-- Replace Affilliate domain by Licensee domain to redirect to licensee site
			SELECT @RedirectPage = CASE WHEN @IsSSL = 1 THEN 'https' ELSE 'http' END + '://' + @LicenseeDomain + '/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode + '&affMediaLinkId=' + @affMediaLinkId
		END
	END

	IF (@RedirectPage IS NULL)
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'This link does not exists. Please contact administrator!'
		RETURN;
	END

	-- Insert into ClickStatistics
	BEGIN
		DECLARE @IPNum BIGINT, @CountryCode VARCHAR(256)
		SELECT  @IPNum = dbo.Aff_IPConvertToNumber(@IP)

		SELECT  TOP 1 @CountryCode =  Code3
		FROM dbo.IPv4Addresses WITH (NOLOCK)
		WHERE @IPNum BETWEEN [From] AND [To]

		INSERT INTO dbo.ClickStatistics
		(
			AffId
			,UpdatedTime
			,IP
			,Date
			,Browser
			,URLReferrer
			,DomainReferrer
			,AffMediaLink
			,OS
			,Device
			,BrowserVersion
			,BrowserResolution
			,BrowserLanguage
			,UserAgent
			,Country
			,LanguageCode
			,SportCode
			,RedirectURL
			,Status
			,DeviceType
		)
		VALUES
		(
			@AffId
			,CURRENT_TIMESTAMP
			,@IP
			,CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
			,@Browser
			,ISNULL(@URLReferrer, 'none')
			,ISNULL(@DomainReferrer, 'none')
			,ISNULL(@AffMediaLink, 'none')
			,@OS
			,@Device
			,@BrowserVersion
			,@BrowserResolution
			,@BrowserLanguage
			,@UserAgent
			,COALESCE(@CountryCode, '(not set)', @Country)
			,CASE WHEN @LanguageCode = 'vi' THEN 'vn' ELSE @LanguageCode END
			,@PageCode
			,@RedirectPage
			,0
			,@DeviceType
		)

		SELECT @ClickID = SCOPE_IDENTITY()
	END
END
GO