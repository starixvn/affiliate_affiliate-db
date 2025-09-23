/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Builder_ManageSel]
	@CampaignName VARCHAR(200) = '', -- Search in both CampaignName and CampaignCode
	@PageName VARCHAR(200) = '', -- Search in both PageName and PageCode
	@TargetCountryCodes VARCHAR(500) = '',
	@MarketIds VARCHAR(500) = '',
	@DealIds VARCHAR(2000) = '',
	@StatusIds VARCHAR(500) = '',
	@CampaignIds VARCHAR(500) = '',
	@IsExportExcel BIT = 0,
	@PageIndex INT = 1,
    @PageSize INT = 20,
    @NRows INT = 0 OUTPUT
AS
/*
	Created: 20250826@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Manage Landing Page builder
	Revisions:
		- 20250826@Sophia: Initial version [RedmineID: #236797]
		- 20250917@Sophia: Combine PageName and PageCode search into single @PageName parameter [RedmineID: #TBD]
*/
BEGIN
	SET NOCOUNT ON;

    DROP TABLE IF EXISTS #Data;
    
    CREATE TABLE #Data
    (
        CampaignCode VARCHAR(100),
        CampaignName VARCHAR(500),
        PageName VARCHAR(200),
        PageCode VARCHAR(100),
        TargetCountryCode VARCHAR(50),
        TargetCountryName VARCHAR(100),
        MarketId VARCHAR(50),
        Language VARCHAR(100),
        TargetLanguageCode VARCHAR(10),
        DealIds VARCHAR(2000),
        Deals NVARCHAR(MAX),
        NoOfDeals INT,
        CreatedDate DATETIME,
        CreatedBy VARCHAR(100),
        LastModifiedBy VARCHAR(100),
        LastModifiedDate DATETIME,
        StatusId TINYINT,
        Status VARCHAR(50),
        PageId INT,
        RowIdx INT
    );

    INSERT INTO #Data (
        CampaignCode, CampaignName, PageName, PageCode, 
        TargetCountryCode, TargetCountryName, MarketId, Language, TargetLanguageCode,
        DealIds, Deals, NoOfDeals, CreatedDate, CreatedBy, 
        LastModifiedBy, LastModifiedDate, StatusId, Status, PageId, RowIdx
    )
	SELECT
		c.CampaignCode,
		c.CampaignName,
		b.PageName,
		b.PageCode,
		b.TargetCountryCode,
		tc.CountryName AS TargetCountryName,
		b.MarketId,
		m.MarketName AS Language,
		ISNULL(lcm.TargetLanguageCode, m.ShortedCode) AS TargetLanguageCode,
		b.DealIds,
		ISNULL(STUFF((
			SELECT ', ' + cg.GroupName
			FROM STRING_SPLIT(NULLIF(b.DealIds, ''), ',') s
			INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON cg.GroupId = TRIM(s.value)			
			FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, ''), '') AS Deals,
		(SELECT COUNT(1) 
			FROM STRING_SPLIT(NULLIF(b.DealIds, ''), ',') 
			WHERE TRIM(value) <> '') AS NoOfDeals,
		b.CreatedDate,
		u1.UserName AS CreatedBy,
		u2.UserName AS LastModifiedBy,
		b.UpdatedDate AS LastModifiedDate,
		b.StatusId,
		s.Status,
		b.PageId,
        ROW_NUMBER() OVER (ORDER BY b.PageId DESC) AS RowIdx
	FROM dbo.LandingPage_Builder b WITH (NOLOCK)
	LEFT JOIN dbo.TargetCountry tc WITH (NOLOCK) ON tc.CountryCode = b.TargetCountryCode AND b.MarketId = tc.MarketId
	LEFT JOIN dbo.Market m WITH (NOLOCK) ON m.MarketId = b.MarketId
	LEFT JOIN dbo.Aff_f_GetTargetLanguageCode() lcm ON m.ShortedCode = lcm.ShortedCode
	LEFT JOIN dbo.Aff_f_LandingPage_Status() s ON b.StatusId = s.StatusId
	LEFT JOIN dbo.LandingPage_Campaign c WITH (NOLOCK) ON b.CampaignId = c.CampaignId
	LEFT JOIN dbo.Affiliate_User u1 WITH (NOLOCK) ON u1.CustId = b.Creator
	LEFT JOIN dbo.Affiliate_User u2 WITH (NOLOCK) ON u2.CustId = b.UpdatedBy
	WHERE
		(@CampaignName = '' 
			OR c.CampaignName LIKE '%' + @CampaignName + '%'
			OR c.CampaignCode LIKE '%' + @CampaignName + '%'
		)
		AND (
			@PageName = ''
			OR b.PageName LIKE '%' + @PageName + '%'
			OR b.PageCode LIKE '%' + @PageName + '%'
		)
		AND (
			@TargetCountryCodes = ''
			OR EXISTS (
				SELECT 1 FROM STRING_SPLIT(@TargetCountryCodes, ',') s WHERE b.TargetCountryCode = s.value
			)
		)
		AND (
			@MarketIds = ''
			OR EXISTS (
				SELECT 1 FROM STRING_SPLIT(@MarketIds, ',') s WHERE b.MarketId = s.value
			)
		)
		AND (
			@DealIds = ''
			OR EXISTS (
				SELECT 1 FROM STRING_SPLIT(@DealIds, ',') s 
				WHERE ',' + b.DealIds + ',' LIKE '%,' + s.value + ',%'
			)
		)
		AND (
			@StatusIds = ''
			OR EXISTS (
				SELECT 1 FROM STRING_SPLIT(@StatusIds, ',') s WHERE CONVERT(VARCHAR(10), b.StatusId) = s.value
			)
		)
		AND (
			@CampaignIds = ''
			OR EXISTS (
				SELECT 1 FROM STRING_SPLIT(@CampaignIds, ',') s WHERE CONVERT(VARCHAR(10), b.CampaignId) = s.value
			)
		);

    -- Get total row count
    SELECT @NRows = COUNT(*) FROM #Data;
    
    -- Paging logic
    DECLARE @RowStart INT, @RowEnd INT;
    
    IF @IsExportExcel = 0
    BEGIN
        SELECT @RowStart = (@PageIndex - 1) * @PageSize + 1,
               @RowEnd = @RowStart + @PageSize - 1;
    END
    ELSE
    BEGIN
        SELECT @RowStart = 1,
               @RowEnd = @NRows;
    END
    
    -- Return paged results
    SELECT 
        CampaignCode,
        CampaignName,
        PageName,
        PageCode,
        TargetCountryCode,
        TargetCountryName,
        MarketId,
        Language,
        TargetLanguageCode,
        DealIds,
        Deals,
        NoOfDeals,
        CreatedDate,
        CreatedBy,
        LastModifiedBy,
        LastModifiedDate,
        StatusId,
        Status,
        PageId,
        RowIdx
    FROM #Data
    WHERE RowIdx BETWEEN @RowStart AND @RowEnd
    ORDER BY PageId DESC;
    
    DROP TABLE #Data;
END;
GO
