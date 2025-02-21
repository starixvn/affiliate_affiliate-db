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

	SELECT @AffId = ac.AffId
	FROM dbo.AffiliateCode ac WITH(NOLOCK)
	WHERE ac.AffCode = @AffCode

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
		SELECT @AffDomainId	= DomainID
		FROM dbo.AffDomain WITH (NOLOCK)
		WHERE DomainName = @AffDomain AND @AffDomain NOT IN ( 'join.best5689.com', 'go.12real.com', 'go.5689fun.com', 'go.6789sutzo.com', 'go.12fifa18.com', '12aff.best5689.com', 'go.9012ijk.com', 'go.sbc31.com', 'go.tha88.com', 'go.apa56.com', 'go.12qiuball.com', 'go.all2356.com', 'go.amo38.com', 'go.12winball.com', 'goto.12bsprt1.com', 'goto.12bsprt2.com', 'goto.12bsprt3.com')
			AND IsDeleted = 0

		SELECT TOP (1) @LicenseeDomain = b.DomainName
					,  @IsSSL		   = b.IsSSL
		FROM dbo.DomainControl a WITH (NOLOCK)
			INNER JOIN dbo.LicenseeDomain b WITH (NOLOCK) ON a.LicenseeDomainId = b.DomainId
		WHERE a.MarketId = @PreferredLanguage
			AND a.AffDomainId = @AffDomainId
			AND a.[Status] = 1
			AND a.IsDeleted = 0
			AND b.IsDeleted = 0

		IF @AffDomain = 'join.best5689.com' AND (@AffUsername IN ('12BETAFF16000', '12BETAFF16186', '12BETAFF16096', '12BETAFF16097'))
		BEGIN
			SET @RedirectPage = 'https://www.620elv.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.12real.com' AND (@AffUsername IN ('12BETAFF16105', '12BETAFF16204', '12BETAFF16205'))
		BEGIN
			SET @RedirectPage = 'https://www.nen77.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.5689fun.com' AND (@AffUsername = '12BETAFF15932')
		BEGIN
			SET @RedirectPage = 'https://www.12kaixin.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.6789sutzo.com' AND (@AffUsername = '12BETAFF16326')
		BEGIN
			SET @RedirectPage = 'https://www.12amethyst.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.12fifa18.com' AND (@AffUsername = '12BETAFF16105')
		BEGIN
			SET @RedirectPage = 'https://www.12crystal.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.5689fun.com' AND (@AffUsername = '12BETAFF16325')
		BEGIN
			SET @RedirectPage = 'https://www.12amber.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = '12aff.best5689.com' AND (@AffUsername IN ('12BETAFF15932', '12BETAFF130', '12BETAFF16311', '12BETAFF16314', '12BETAFF16225', '12BETAFF14617', '12BETAFF13902', '12BETAFF16313', '12BETAFF15775', '12BETAFF16214', '12BETAFF13506', '12BETAFF13065', '12BETAFF7782', '12BETAFF16050'))
		BEGIN
			SET @RedirectPage = 'https://www.12bfacai.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.9012ijk.com' AND (@AffUsername = '12BETAFF16343')
		BEGIN
			SET @RedirectPage = 'https://www.12amethyst.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.sbc31.com' AND (@AffUsername = '12BETAFF16344')
		BEGIN
			SET @RedirectPage = 'https://www.12amberclub.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.tha88.com' AND (@AffUsername = '12BETAFF16342')
		BEGIN
			SET @RedirectPage = 'https://www.12bola.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.apa56.com' AND (@AffUsername = '12BETAFF16342')
		BEGIN
			SET @RedirectPage = 'https://www.bola112.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.12qiuball.com' AND (@AffUsername = '12BETAFF16341')
		BEGIN
			SET @RedirectPage = 'https://www.12vndb.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.all2356.com' AND (@AffUsername = '12BETAFF16386')
		BEGIN
			SET @RedirectPage = 'https://www.12bwinb.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.amo38.com' AND (@AffUsername = '12BETAFF16386')
		BEGIN
			SET @RedirectPage = 'https://www.12bplay.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'go.12winball.com' AND (@AffUsername = '12BETAFF16007')
		BEGIN
			SET @RedirectPage = 'https://www.12bbe.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'goto.12bsprt1.com' AND (@AffUsername = '12BETAFF16338')
		BEGIN
			SET @RedirectPage = 'https://www.12bsaff1.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'goto.12bsprt2.com' AND (@AffUsername = '12BETAFF16336')
		BEGIN
			SET @RedirectPage = 'https://www.12bsaff2.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE IF @AffDomain = 'goto.12bsprt3.com' AND (@AffUsername = '12BETAFF16337')
		BEGIN
			SET @RedirectPage = 'https://www.12bsaff3.com/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
		END
		ELSE
		BEGIN
		-- Replace Affilliate domain by Licensee domain to redirect to licensee site
			SELECT @RedirectPage = CASE WHEN @IsSSL = 1 THEN 'https' ELSE 'http' END + '://' + @LicenseeDomain + '/' + @LanguageCode + '/' + @PageCode + '?affCode=' + @AffCode
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