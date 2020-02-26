/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_AffiliateInsClickStatistics_New] 
	@AffiliateID		INT
	,@AffDomain			NVARCHAR(256) = ''
	,@PageCode			VARCHAR(50) = ''
	,@LanguageCode		VARCHAR(6) = 'en'
	,@IP				VARCHAR(20) = ''
	,@Browser			NVARCHAR(50) = ''
	,@URLReferrer		NVARCHAR(300) = NULL
	,@DomainReferrer	NVARCHAR(300) = NULL
	,@OS				NVARCHAR(50) = ''
	,@Device			NVARCHAR(50) = ''
	,@BrowserVersion	NVARCHAR(16) = ''
	,@BrowserResolution NVARCHAR(16) = ''
	,@BrowserLanguage	NVARCHAR(8) = ''
	,@UserAgent			NVARCHAR(256) = ''
	,@Country			NVARCHAR(256) = ''
	,@DeviceType		TINYINT = 0
	,@RedirectPage		NVARCHAR(256) = NULL OUTPUT
	,@ClickID			BIGINT = 0 OUTPUT
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200220@Percy
	Task: Clicking Banner action
	DB: DBAFFN8G-Affiliate_N8G

	Revisions:  
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	IF COALESCE(@IP, '') = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'The IP is required. Please check!'
		RETURN
	END

	DECLARE
		@IsClosed			BIT
		,@PreferredLanguage VARCHAR(11)
		,@LicenseeDomain	NVARCHAR(50)
		,@IsSSL				BIT
		,@AffDomainId 		INT

	SELECT @PreferredLanguage = ad.PreferredLanguage, @IsClosed = ai.IsClosed
	FROM dbo.AffDetail ad WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId = @AffiliateID AND ai.Status = 'Approved'

	IF @IsClosed IS NULL OR @IsClosed = 1
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This affiliate does not exists. Please contact administrator!'
		RETURN
	END

	--Get redirect link
	BEGIN
		SELECT @AffDomainId	= DomainID
		FROM dbo.AffDomain WITH (NOLOCK)
		WHERE DomainName = @AffDomain
			AND IsDeleted = 0

		SELECT TOP 1
			@LicenseeDomain = b.DomainName
			,@IsSSL			= b.IsSSL
		FROM dbo.DomainControl a WITH (NOLOCK)
			INNER JOIN dbo.LicenseeDomain b WITH (NOLOCK) ON a.LicenseeDomainId = b.DomainId
		WHERE a.MarketId = @PreferredLanguage
			AND a.AffDomainId = @AffDomainId
			AND a.[status] = 1
			AND a.IsDeleted = 0
			AND b.IsDeleted = 0

		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @ErrCode = 103, @ErrMsg = 'This link does not exists. Please contact administrator!'
			RETURN
		END

		-- Replace Affilliate domain by Licensee domain to redirect to licensee site
		SELECT @RedirectPage = CASE WHEN @IsSSL = 1 THEN 'https' ELSE 'http' END + '://' + @LicenseeDomain + '/' + @LanguageCode + '/' + @PageCode + 'Register?affid=' + CONVERT(VARCHAR(20), @AffiliateID)
	END

	DECLARE @IPNum BIGINT,@CountryCode VARCHAR(256)
	SELECT  @IPNum = dbo.Aff_IPConvertToNumber(@IP)

	SELECT  TOP 1 @CountryCode =  Code3
	FROM dbo.IPv4Addresses WITH (NOLOCK)
	WHERE @IPNum BETWEEN [From] AND [To]

	INSERT INTO dbo.ClickStatistics
	(
		AffID
		,UpdatedTime
		,IP
		,Date
		,Browser
		,URLReferrer
		,DomainReferrer
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
		@AffiliateID
		,CURRENT_TIMESTAMP
		,@IP
		,CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
		,@Browser
		,ISNULL(@URLReferrer, 'none')
		,ISNULL(@DomainReferrer, 'none')
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
GO