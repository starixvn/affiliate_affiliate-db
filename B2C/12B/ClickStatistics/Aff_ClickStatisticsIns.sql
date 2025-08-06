/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_ClickStatisticsIns]
	@ClickId			BIGINT
	,@AffCode			VARCHAR(20)
	,@UpdatedTime		DATETIME = NULL
	,@IP				VARCHAR(25) = ''
	,@Browser			NVARCHAR(50) = ''
	,@URLReferrer		NVARCHAR(300) = NULL
	,@DomainReferrer	NVARCHAR(300) = NULL
	,@OS				NVARCHAR(50) = ''
	,@Device			NVARCHAR(50) = ''
	,@BrowserVersion	NVARCHAR(16) = ''
	,@BrowserResolution	NVARCHAR(16) = ''
	,@BrowserLanguage	NVARCHAR(8) = ''
	,@UserAgent			NVARCHAR(256) = ''
	,@Country			NVARCHAR(256) = ''
	,@LanguageCode		VARCHAR(10) = 'en'
	,@PageCode			VARCHAR(50) = ''
	,@RedirectURL		NVARCHAR(256) = NULL
	,@DeviceType		TINYINT = 0
	,@AffMediaLink		VARCHAR(500) = NULL
	,@ChannelCode		VARCHAR(50) = NULL
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT

AS
/*
	Created: 20250729@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Clicking AffMediaLink action

	Revisions:  
		- 20250729@Sally: Initialize SP [RedmineID: #233088]

*/
BEGIN
	SET NOCOUNT ON;
	-- Get AffId from AffiliateCode table using AffCode
	DECLARE @AffId INT;
	SELECT @AffId = AffId FROM dbo.AffiliateCode WITH(NOLOCK) WHERE AffCode = @AffCode;

	-- If AffCode not found, return error
	IF @AffId IS NULL
	BEGIN
		SET @ErrCode = 304;
		SET @ErrMsg = 'Invalid Affiliate!';
		RETURN;
	END

	DECLARE @ClickStatistics TABLE
	(
		AffId INT,
		UpdatedTime DATETIME,
		IP VARCHAR(25),
		Date SMALLDATETIME,
		Browser NVARCHAR(50),
		URLReferrer NVARCHAR(300),
		DomainReferrer NVARCHAR(300),
		OS NVARCHAR(50),
		Device NVARCHAR(50),
		BrowserVersion NVARCHAR(16),
		BrowserResolution NVARCHAR(16),
		BrowserLanguage NVARCHAR(8),
		UserAgent NVARCHAR(256),
		Country NVARCHAR(256),
		LanguageCode VARCHAR(10),
		SportCode VARCHAR(50),
		RedirectURL NVARCHAR(256),
		Status TINYINT,
		DeviceType TINYINT,
		AffMediaLink VARCHAR(500),
		ChannelCode VARCHAR(50),
		ClickID2 BIGINT
	);

	BEGIN TRY
	
		DECLARE @IPNum BIGINT, @CountryCode VARCHAR(256)
		SELECT  @IPNum = dbo.Aff_IPConvertToNumber(@IP)

		SELECT  TOP 1 @CountryCode =  Code3
		FROM dbo.IPv4Addresses WITH (NOLOCK)
		WHERE @IPNum BETWEEN [From] AND [To]

		SELECT @URLReferrer    = CASE WHEN @URLReferrer IS NULL OR TRIM(@URLReferrer) = '' THEN 'none' ELSE @URLReferrer END
		SELECT @DomainReferrer = CASE WHEN @DomainReferrer IS NULL OR TRIM(@DomainReferrer) = '' THEN 'none' ELSE @DomainReferrer END
		SELECT @AffMediaLink   = CASE WHEN @AffMediaLink IS NULL OR TRIM(@AffMediaLink) = '' THEN 'none' ELSE @AffMediaLink END
		
		-- Insert into ClickStatistics and output to @ClickStatistics
		INSERT INTO dbo.ClickStatistics
		(
			AffId, UpdatedTime, IP, Date, Browser, URLReferrer, DomainReferrer, OS, Device, BrowserVersion, BrowserResolution, BrowserLanguage, UserAgent, Country, LanguageCode, SportCode, RedirectURL, Status, DeviceType, AffMediaLink, ChannelCode, ClickId2
		)
		OUTPUT 
			INSERTED.AffId,
			INSERTED.UpdatedTime,
			INSERTED.IP,
			INSERTED.Date,
			INSERTED.Browser,
			INSERTED.URLReferrer,
			INSERTED.DomainReferrer,
			INSERTED.OS,
			INSERTED.Device,
			INSERTED.BrowserVersion,
			INSERTED.BrowserResolution,
			INSERTED.BrowserLanguage,
			INSERTED.UserAgent,
			INSERTED.Country,
			INSERTED.LanguageCode,
			INSERTED.SportCode,
			INSERTED.RedirectURL,
			INSERTED.Status,
			INSERTED.DeviceType,
			INSERTED.AffMediaLink,
			INSERTED.ChannelCode,
			INSERTED.ClickID2
		INTO @ClickStatistics
		VALUES
		(
			@AffId, @UpdatedTime, @IP, CAST(@UpdatedTime AS DATE), @Browser, @URLReferrer, @DomainReferrer, @OS, @Device, @BrowserVersion, @BrowserResolution, @BrowserLanguage, @UserAgent, COALESCE(@CountryCode, '(not set)', @Country), @LanguageCode, @PageCode, @RedirectURL, 0, @DeviceType, @AffMediaLink, @ChannelCode, @ClickId
		);

		-- Insert into ClickStatistics2 from @ClickStatistics
		INSERT INTO dbo.ClickStatistics2
		(
			ClickId, AffId, UpdatedTime, IP, Date, Browser, URLReferrer, DomainReferrer, OS, Device, BrowserVersion, BrowserResolution, BrowserLanguage, UserAgent, Country, LanguageCode, SportCode, RedirectURL, Status, DeviceType, AffMediaLink, ChannelCode
		)
		SELECT 
			ClickId2, AffId, UpdatedTime, IP, Date, Browser, URLReferrer, DomainReferrer, OS, Device, BrowserVersion, BrowserResolution, BrowserLanguage, UserAgent, Country, LanguageCode, SportCode, RedirectURL, Status, DeviceType, AffMediaLink, ChannelCode
		FROM @ClickStatistics;
	END TRY
	BEGIN CATCH
		-- Remove data from ClickStatistics if ClickStatistics2 insert failed
		DELETE FROM dbo.ClickStatistics WITH (ROWLOCK)
		WHERE ClickId2 = @ClickId;
		
		-- Set error information for insert failures
		SET @ErrCode = 303;
		SET @ErrMsg = 'Insert data ClickStatistics Fail!';
		RETURN;
	END CATCH
		
END
GO