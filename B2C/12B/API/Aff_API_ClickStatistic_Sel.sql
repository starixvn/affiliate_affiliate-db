/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_API_ClickStatistic_Sel]
    @FromDate   SMALLDATETIME
	,@ToDate    SMALLDATETIME
	,@PageIndex	INT = 1
	,@PageSize	INT = 1000

AS

/*
	Created: 20250625@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Get Clickstatistic Info

	Revisions:
		- 20250625@Sally: Initialize SP [RedmineID: #230555]
		- 20250707@Sally: Fix get DateTime GMT-4 [RedmineID: #232334]
		- 20250709@Sally: Enhance filter data by MemberInfo data where the ClickId exists in [RedmineID: #232701]
		- 20251022@Sophia: Add IsExcluded = 0 condition to filter excluded clicks [RedmineID: #241768]
    
    Param's Explanation:
		- @FromDate, @ToDate: GMT+8
        - @PageIndex: The page index for pagination, starting from 1
        - @PageSize: The number of records to return per page, limit 1k rows

*/
BEGIN
	SET NOCOUNT ON;

	-- Declare variables for date handling
    DECLARE @ArchiveDate SMALLDATETIME;
    DECLARE @FromDate_Local DATETIME;
    DECLARE @ToDate_Local DATETIME;
    DECLARE @tempFromDate DATE;
    DECLARE @tempToDate DATE;

    -- Create temporary table with same structure as ClickStatistics
    CREATE TABLE #TempClickstatisticData (
        ClickId BIGINT NOT NULL,
        AffId INT NOT NULL,
        UpdatedTime DATETIME NOT NULL,
        IP VARCHAR(25) NOT NULL,
        [Date] SMALLDATETIME NOT NULL,
        Browser NVARCHAR(50) NOT NULL,
        URLReferrer NVARCHAR(300) NOT NULL,
        DomainReferrer NVARCHAR(300) NOT NULL,
        OS NVARCHAR(50) NULL,
        Device NVARCHAR(50) NULL,
        BrowserVersion NVARCHAR(16) NULL,
        BrowserResolution NVARCHAR(16) NULL,
        BrowserLanguage NVARCHAR(8) NULL,
        UserAgent NVARCHAR(256) NULL,
        Country NVARCHAR(256) NULL,
        LanguageCode VARCHAR(10) NULL,
        SportCode VARCHAR(50) NULL,
        RedirectURL NVARCHAR(256) NULL,
        Status TINYINT NULL DEFAULT (0),
        DeviceType TINYINT NULL DEFAULT (0),
        AffMediaLink VARCHAR(500) NULL,
        ChannelCode VARCHAR(50) NULL
    );

    -- Create clustered index on ClickId, AffId
    CREATE CLUSTERED INDEX CIX_TempClickstatistic_ClickId_AffId 
    ON #TempClickstatisticData (ClickId, AffId);

	-- Limit Pagesize to 1000 rows
	SELECT @Pagesize = CASE 
		WHEN @PageSize <= 0 OR @PageSize > 1000 THEN 1000 
		ELSE @PageSize 
	END;

	SELECT @ArchiveDate = dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics'); -- GMT-4

	SELECT @FromDate_Local = DATEADD(HOUR, -12, CAST(@FromDate AS DATETIME)) -- GMT+8 to GMT-4
		,@ToDate_Local = DATEADD(HOUR, -12,  CAST(@ToDate AS DATETIME)); -- GMT+8 to GMT-4

	IF @ToDate_Local > @ArchiveDate
	BEGIN
		SELECT @tempFromDate = CASE 
									WHEN @FromDate_Local > @ArchiveDate THEN CONVERT(DATE, @FromDate_Local) 
									ELSE DATEADD(DAY, 1, @ArchiveDate) 
							   END
			,@tempToDate = DATEADD(DAY, 1, CONVERT(DATE, @ToDate_Local))

		INSERT INTO #TempClickstatisticData (
			ClickId, AffId, UpdatedTime, IP, [Date], Browser, URLReferrer, DomainReferrer,
			OS, Device, BrowserVersion, BrowserResolution, BrowserLanguage, UserAgent,
			Country, LanguageCode, SportCode, RedirectURL, Status, DeviceType,
			AffMediaLink, ChannelCode
			)
		SELECT c.ClickId, c.AffId, c.UpdatedTime, c.IP, c.[Date], c.Browser, c.URLReferrer, c.DomainReferrer,
			c.OS, c.Device, c.BrowserVersion, c.BrowserResolution, c.BrowserLanguage, c.UserAgent,
			c.Country, c.LanguageCode, c.SportCode, c.RedirectURL, c.Status, c.DeviceType,
			c.AffMediaLink, c.ChannelCode
		FROM dbo.ClickStatistics c WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON c.ClickId = m.ClickId
		WHERE c.[Date] >= @tempFromDate
			AND c.[Date] < @tempToDate
			AND c.UpdatedTime BETWEEN @FromDate_Local AND @ToDate_Local -- GMT-4
			AND c.IsExcluded = 0
			
		
	END

	IF CONVERT(DATE, @FromDate_Local) <= @ArchiveDate
	BEGIN
		 SELECT @tempFromDate = CONVERT(DATE, @FromDate_Local)
			,@tempToDate = CASE 
								WHEN @ToDate_Local <= @ArchiveDate THEN DATEADD(DAY, 1, CONVERT(DATE, @ToDate_Local)) 
								ELSE DATEADD(DAY, 1, @ArchiveDate) 
						   END		
		INSERT INTO #TempClickstatisticData (
			ClickId, AffId, UpdatedTime, IP, [Date], Browser, URLReferrer, DomainReferrer,
			OS, Device, BrowserVersion, BrowserResolution, BrowserLanguage, UserAgent,
			Country, LanguageCode, SportCode, RedirectURL, Status, DeviceType,
			AffMediaLink, ChannelCode
		)
		SELECT c.ClickId, c.AffId, c.UpdatedTime, c.IP, c.[Date], c.Browser, c.URLReferrer, c.DomainReferrer,
			c.OS, c.Device, c.BrowserVersion, c.BrowserResolution, c.BrowserLanguage, c.UserAgent,
			c.Country, c.LanguageCode, c.SportCode, c.RedirectURL, c.Status, c.DeviceType,
			c.AffMediaLink, c.ChannelCode
		FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON c.ClickId = m.ClickId
		WHERE c.[Date] >= @tempFromDate
			AND c.[Date] < @tempToDate
			AND c.UpdatedTime BETWEEN @FromDate_Local AND @ToDate_Local -- GMT-4
			AND c.IsExcluded = 0
	END

	-- Return paginated results with AffInfo data
	SELECT 
		t.ClickId,
		t.AffId,
		a.AffCode,
		a.UserName AS AffUserName,
		t.UpdatedTime,
		t.IP,
		t.[Date],
		t.Browser,
		t.URLReferrer,
		t.DomainReferrer,
		t.OS,
		t.Device,
		t.BrowserVersion,
		t.BrowserResolution,
		t.BrowserLanguage,
		t.UserAgent,
		t.Country,
		t.LanguageCode,
		t.SportCode,
		t.RedirectURL,
		t.Status,
		t.DeviceType,
		t.AffMediaLink,
		t.ChannelCode
	FROM #TempClickstatisticData t
	    INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON t.AffId = a.AffId
	ORDER BY t.UpdatedTime ASC, t.ClickId ASC
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;

	-- Clean up temporary tables
	DROP TABLE #TempClickstatisticData;
END
GO