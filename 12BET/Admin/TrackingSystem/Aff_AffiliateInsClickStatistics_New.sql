/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_AffiliateInsClickStatistics_New] 
	@AffiliateID 		INT
	,@TargetCountryCode	VARCHAR(2) = NULL
	,@AffDomain 		NVARCHAR(256) = ''
	--Url is showed in affiliate site
	,@PageCode 			VARCHAR(50) = 'sportsbook'
	,@LanguageCode 		VARCHAR(6) = 'en'
	,@IP 				VARCHAR(45) = ''
	,@Browser 			NVARCHAR(50) = ''
	,@URLReferrer 		NVARCHAR(300) = NULL
	,@DomainReferrer 	NVARCHAR(300) = NULL
	,@OS 				NVARCHAR(50) = ''
	,@Device 			NVARCHAR(50) = ''
	,@BrowserVersion 	NVARCHAR(16) = ''
	,@BrowserResolution NVARCHAR(16) = ''
	,@BrowserLanguage 	NVARCHAR(8) = ''
	,@UserAgent 		NVARCHAR(256) = ''
	,@Country 			NVARCHAR(256) = ''
	,@DeviceType 		TINYINT = 0
	,@RedirectPage 		NVARCHAR(256) = NULL OUTPUT
	,@ClickID 			BIGINT = 0 OUTPUT
	,@ErrCode 			INT = 0 OUTPUT
	,@ErrMsg 			NVARCHAR(4000) = '' OUTPUT
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
	- 20231124@Eddie: use TargetCountryCode to check AffDomain and PageCode [RedmineID: #181590]
	- 20240129@Eddie: remove hardcoding for 'promotion' pagecode [RedmineID: #200168]
	- 20240604@Eddie: Support to config redirect link for specific affiliate [RedmineID: #206066]
	- 20240819@Eddie: Hide Hindi Market [RedmineID: #209409]
	- 20241113@Eddie: Support to config redirect link for specific affiliates [RedmineID: #210540]
	- 20241121@Eddie: Support to config redirect link for specific affiliates [RedmineID: #214070]
	- 20241127@Eddie: Remove config redirect link for specific affiliate [RedmineID: #214274]
	- 20241203@Eddie: Support to config redirect link for specific affiliates [RedmineID: #214694]
	- 20241209@Eddie: Support to config redirect link for specific affiliates [RedmineID: #214956]
	- 20241211@Eddie: Support to config redirect link for specific affiliates [RedmineID: #215140]
	- 20241217@Eddie: Support to config redirect link for specific affiliates [RedmineID: #215396]
	- 20241231@Eddie: Support to config redirect link for specific affiliates [RedmineID: #216117]
	- 20250114@Eddie: Support to config redirect link for specific affiliates [RedmineID: #216799]
	 
Param's Explanation:   
	- @DeviceType: 0-PC & 1-Mobile
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @AffUsername NVARCHAR(30)
		,@Default12Betdomain NVARCHAR(100)
		,@AffType INT
		,@IsClosed BIT
		,@DomainDeviceType TINYINT = 0
		,@DomainName NVARCHAR(100) -- DomainName of table [12BetDomain]
		,@W3Http VARCHAR(5) = ''
		,@CheckAffDomain BIT
		,@CheckPageCode BIT

	--Off default domain
	--SELECT @Default12Betdomain = NULL --If redirect page is null => redirect to this default domain
	
	SELECT @TargetCountryCode = ISNULL(@TargetCountryCode, '')
	
	IF @TargetCountryCode = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'TargetCountryCode is invalid. Please check!'
		RETURN
	END

	SELECT @AffUsername = ai.Username
		  ,@AffType 	= ai.AffType
		  ,@IsClosed 	= ai.IsClosed
	FROM AffDetail ad WITH (NOLOCK)
		INNER JOIN AffInfo ai WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId = @AffiliateID
		AND STATUS = 'Approved'

	--check Affiliate ID  
	IF ( @AffUsername IS NULL OR ( @IsClosed = 1 AND @AffUsername = '12BETAFF9151'))
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This affiliate does not exists. Please contact administrator!'

		RETURN
	END

	--Checking Input member IP
	IF COALESCE(@IP, '') = ''
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'The IP is required. Please check!'

		RETURN
	END

	--Get redirect link
	SELECT @RedirectPage = ( SELECT TOP 1 CValue --Get link for some special affiliate
							 FROM CommonSettings(NOLOCK)
							 WHERE [Type] = @PageCode 
							   AND CName = @AffUsername )

	IF (@RedirectPage IS NULL)
	BEGIN

		--Get AffDomain by @TargetCountryCode and @AffDomain
		;WITH CTE_AffDomain AS(
			SELECT a.DomainID, a.DomainName
			FROM dbo.AffDomain a WITH (NOLOCK)
				INNER JOIN dbo.AffDomainControl b WITH (NOLOCK) ON a.DomainID = b.AffDomainID
				INNER JOIN dbo.[12BetDomain] ld WITH (NOLOCK) ON b.[12BetDomainID] = ld.DomainID
			WHERE b.STATUS = 1
			  AND a.IsDeleted = 0
			  AND b.IsDeleted = 0
			  AND ld.IsDeleted = 0
			  AND b.TargetCountryCode = @TargetCountryCode
			  AND b.MarketID NOT IN ('es-ES', 'hi') -- not use Spanish, Hindi
			  AND a.DomainName = @AffDomain
			GROUP BY a.DomainID, a.DomainName
		), --Get PageCode by @TargetCountryCode and @PageCode
		CTE_LandingPage AS (  
			SELECT lp.PageId, lp.PageName, lp.PageCode
			FROM dbo.LandingPage lp WITH (NOLOCK)
				OUTER APPLY(
					SELECT t.CountryCode
					FROM(
						SELECT DISTINCT CountryCode
						FROM dbo.TargetCountry WITH (NOLOCK)
						WHERE CountryCode NOT IN (SELECT value FROM STRING_SPLIT(lp.BlockTargetCountry, ','))
					) AS t
				) As oam
			WHERE lp.IsDeleted = 0 
			  AND oam.CountryCode = @TargetCountryCode
			  AND lp.PageCode = @PageCode
		)
		SELECT @CheckAffDomain = CASE WHEN ISNULL(ad.DomainName, '') = '' AND @AffDomain NOT IN ( 'join.best5689.com', 'go.12real.com', 'go.5689fun.com', 'go.6789sutzo.com', 'go.12fifa18.com', '12aff.best5689.com', 'go.9012ijk.com', 'go.sbc31.com', 'go.tha88.com', 'go.apa56.com', 'go.12qiuball.com', 'go.all2356.com', 'go.amo38.com') THEN 0 ELSE 1 END
			 , @CheckPageCode  = CASE WHEN ISNULL(clp.PageCode, '') = '' THEN 0 ELSE 1 END
		FROM CTE_AffDomain AS ad
			FULL OUTER JOIN CTE_LandingPage AS clp ON clp.PageCode = @PageCode

		IF @CheckPageCode = 0
		BEGIN
			SELECT @ErrCode = 104, @ErrMsg = 'PageCode is invalid. Please check!'
			RETURN
		END
		ELSE IF @CheckAffDomain = 0
		BEGIN
			SELECT @ErrCode = 105, @ErrMsg = 'AffDomain is invalid. Please check!'
			RETURN
		END

		SELECT TOP(1) @DomainName = b.DomainName
				,@W3Http = CASE WHEN ISNULL(b.IsSSL, 0) = 1 THEN 'https' ELSE 'http' END
		FROM dbo.AffDomainControl a WITH (NOLOCK)
			INNER JOIN dbo.[12BetDomain] b WITH (NOLOCK) ON a.[12BetDomainID] = b.DomainID
			INNER JOIN dbo.AffDomain c WITH (NOLOCK) ON a.AffDomainID = c.DomainID
		WHERE c.DomainName = @AffDomain
			AND a.[status] = 1
			AND a.IsDeleted = 0
			AND b.IsDeleted = 0
			AND c.IsDeleted = 0
			AND a.MarketID NOT IN ('es-ES', 'hi')-- not use Spanish, Hindi
			AND a.TargetCountryCode = @TargetCountryCode

		IF @AffDomain = 'join.best5689.com' AND (@AffUsername IN ('12BETAFF16000', '12BETAFF16186', '12BETAFF16096', '12BETAFF16097'))
		BEGIN
			SET @RedirectPage = 'https://www.620elv.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.12real.com' AND (@AffUsername IN ('12BETAFF16105', '12BETAFF16204', '12BETAFF16205'))
		BEGIN
			SET @RedirectPage = 'https://www.nen77.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.5689fun.com' AND (@AffUsername = '12BETAFF15932')
		BEGIN
			SET @RedirectPage = 'https://www.12kaixin.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.6789sutzo.com' AND (@AffUsername = '12BETAFF16326')
		BEGIN
			SET @RedirectPage = 'https://www.12amethyst.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.12fifa18.com' AND (@AffUsername = '12BETAFF16105')
		BEGIN
			SET @RedirectPage = 'https://www.12crystal.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.5689fun.com' AND (@AffUsername = '12BETAFF16325')
		BEGIN
			SET @RedirectPage = 'https://www.12amber.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = '12aff.best5689.com' AND (@AffUsername IN ('12BETAFF15932', '12BETAFF130', '12BETAFF16311', '12BETAFF16314', '12BETAFF16225', '12BETAFF14617', '12BETAFF13902', '12BETAFF16313', '12BETAFF15775', '12BETAFF16214', '12BETAFF13506', '12BETAFF13065', '12BETAFF7782', '12BETAFF16050'))
		BEGIN
			SET @RedirectPage = 'https://www.12haoqiu.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.9012ijk.com' AND (@AffUsername = '12BETAFF16343')
		BEGIN
			SET @RedirectPage = 'https://www.12amethyst.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.sbc31.com' AND (@AffUsername = '12BETAFF16344')
		BEGIN
			SET @RedirectPage = 'https://www.12amberclub.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.tha88.com' AND (@AffUsername = '12BETAFF16342')
		BEGIN
			SET @RedirectPage = 'https://www.12bola.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.apa56.com' AND (@AffUsername = '12BETAFF16342')
		BEGIN
			SET @RedirectPage = 'https://www.bola112.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.12qiuball.com' AND (@AffUsername = '12BETAFF16341')
		BEGIN
			SET @RedirectPage = 'https://www.12vndb.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.all2356.com' AND (@AffUsername = '12BETAFF16386')
		BEGIN
			SET @RedirectPage = 'https://www.12bwinb.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE IF @AffDomain = 'go.amo38.com' AND (@AffUsername = '12BETAFF16386')
		BEGIN
			SET @RedirectPage = 'https://www.12bplay.com/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
		END
		ELSE
		BEGIN
			--Replace Aff Domain by 12bet domain to redirect to 12bet site
			SET @RedirectPage = CASE WHEN @DomainName IS NOT NULL THEN @W3Http + '://' + @DomainName + '/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}' ELSE @Default12Betdomain END
		END
	END
	ELSE
	BEGIN --This aff is special aff and pagecode = '12betcasino'
		SELECT @LanguageCode = (CASE WHEN @LanguageCode = 'ch' THEN 'cs'
									 WHEN @LanguageCode = 'eneuro'
									   OR @LanguageCode = 'es' THEN 'en'
									 WHEN @LanguageCode = 'vn' THEN 'vi'
								ELSE @LanguageCode END)

		SELECT @RedirectPage = REPLACE(@RedirectPage, '{custid}', @AffiliateID)

		SELECT @RedirectPage = REPLACE(@RedirectPage, '{target}', @pagecode)

		SELECT @RedirectPage = REPLACE(@RedirectPage, '{lang}', @LanguageCode)

		SELECT @RedirectPage = REPLACE(@RedirectPage, '{/TrackingCode}', '')
	END

	IF (@RedirectPage IS NULL)
	BEGIN
		SELECT @ErrCode = 106, @ErrMsg = 'This link does not exists. Please contact administrator!'
		RETURN;
	END
	ELSE
	BEGIN
		DECLARE @EUDomain VARCHAR(100)		
		SELECT @EUDomain = 'eu.12bet.com'
		
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

	SELECT @RedirectPage = REPLACE(@RedirectPage, '{clickid}', @ClickID)

	SELECT @RedirectPage = REPLACE(@RedirectPage, '{typeid}', @AffType)

	UPDATE [ClickStatistics1] WITH (ROWLOCK, UPDLOCK)
	SET [RedirectURL] = @RedirectPage
	WHERE clickId = @ClickID

	RETURN;
END

GO