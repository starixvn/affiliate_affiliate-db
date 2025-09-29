/*<info serverAlias="DBAFFN8B-Affiliate_N8B"></info>*/
/*
	Created: 20250804@Eddie
	DB: DBAFFN8B-Affiliate_N8B
	Task: Alter table structure and initialize data [RedmineID: #227560]
*/
USE Affiliate_N8B
GO

ALTER TABLE dbo.Market ADD IsDeleted BIT NOT NULL CONSTRAINT DF_Market_IsDeleted DEFAULT(0)
GO

-- Drop the existing table if it exists (optional, for re-creation)
DROP TABLE IF EXISTS TargetCountry;
-- Create the TargetCountry table with a composite primary key and no TargetCountry column
CREATE TABLE TargetCountry (
    MarketID  	 VARCHAR(50) NOT NULL
    ,MarketName  VARCHAR(100)
    ,CountryCode VARCHAR(5) NOT NULL
    ,CountryName VARCHAR(100)
	,ShortedCode VARCHAR(20)
    ,OrderNo 	 INT
    ,CONSTRAINT PK_CountryCode_MarketID PRIMARY KEY (CountryCode, MarketID)
)
GO

IF OBJECT_ID('dbo.Country', 'U') IS  NULL
BEGIN
	CREATE TABLE [dbo].[Country](
		[CountryCode] [varchar](5) NOT NULL,
		[CountryName] [varchar](200) NOT NULL,
	CONSTRAINT [PK_Country] PRIMARY KEY CLUSTERED
	(
		[CountryCode] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

INSERT INTO dbo.TargetCountry (MarketID, MarketName, CountryCode, CountryName, OrderNo, ShortedCode)
SELECT t.MarketID, t.MarketName, t.CountryCode, t.CountryName, t.OrderNo, t.ShortedCode
FROM (
		VALUES ('vi-VN', 'Vietnamese', 'VN', 'Vietnam', 1	, 'vn')
			  ,('en-US', 'English'	 , 'VN', 'Vietnam', NULL, 'en')
) AS t(MarketID, MarketName, CountryCode, CountryName, OrderNo, ShortedCode)
	LEFT JOIN dbo.TargetCountry tc WITH (NOLOCK) ON tc.CountryCode = t.CountryCode
												AND tc.MarketID = t.MarketID
WHERE tc.CountryCode IS NULL
   OR tc.MarketID IS NULL


INSERT INTO Country (CountryCode, CountryName)
SELECT DISTINCT t.CountryCode, t.CountryName
FROM TargetCountry t WITH(NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 
    FROM Country c WITH(NOLOCK)
    WHERE c.CountryCode = t.CountryCode
);

GO

-- BlockTargetCountry
ALTER TABLE dbo.AffDomain ADD BlockTargetCountry VARCHAR(200)
GO
ALTER TABLE dbo.LicenseeDomain ADD BlockTargetCountry VARCHAR(200)
GO
ALTER TABLE dbo.LandingPage Add BlockTargetCountry VARCHAR(200)
GO

-- DomainControl
ALTER TABLE dbo.DomainControl ADD TargetCountryCode VARCHAR(5)
GO

UPDATE adc WITH (ROWLOCK, UPDLOCK)
SET adc.TargetCountryCode = tc.CountryCode
FROM dbo.DomainControl adc
	INNER JOIN dbo.TargetCountry tc WITH (NOLOCK) ON adc.MarketID = tc.MarketID
WHERE adc.IsDeleted = 0
GO

	-- Update duplicate data with IsDeleted = 1 ( market different from default market in targetcountry )
	BEGIN
		;WITH CTE_dup_data AS(
			SELECT TargetCountryCode, AffDomainId 
			FROM dbo.DomainControl WITH (NOLOCK)
			WHERE IsDeleted = 0
			GROUP BY TargetCountryCode, AffDomainId
			HAVING COUNT(1) > 1
		),
		CTE_default_market AS(
				SELECT MarketID, CountryCode
				FROM dbo.TargetCountry WITH (NOLOCK)
				WHERE OrderNo IS NOT NULL
		)
		UPDATE dc WITH (ROWLOCK, UPDLOCK)
		SET dc.IsDeleted = IIF(dc.MarketId = m.MarketID, dc.IsDeleted, 1)
		FROM dbo.DomainControl dc
			INNER JOIN CTE_dup_data d ON d.AffDomainId = dc.AffDomainId
									 AND d.TargetCountryCode = dc.TargetCountryCode
			INNER JOIN CTE_default_market m ON m.CountryCode = dc.TargetCountryCode
		WHERE dc.IsDeleted = 0
	END

-- AffDetail
ALTER TABLE dbo.AffDetail ADD TargetCountryCode VARCHAR(5)
GO

UPDATE adc WITH (ROWLOCK, UPDLOCK) --1862 rows
SET adc.TargetCountryCode = tc.CountryCode
FROM dbo.AffDetail adc
	INNER JOIN dbo.TargetCountry tc WITH (NOLOCK) ON adc.PreferredLanguage = tc.MarketID
GO