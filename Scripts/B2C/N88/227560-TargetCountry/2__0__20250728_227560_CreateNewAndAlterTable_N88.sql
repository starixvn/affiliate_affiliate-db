/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20250804@Eddie
	DB: DBAFFN88-Affiliate_N88
	Task: Alter table structure and initialize data [RedmineID: #227560]
*/
USE Affiliate_N88
GO

-- Drop the existing table if it exists (optional, for re-creation)
DROP TABLE IF EXISTS TargetCountry;
-- Create the TargetCountry table with a composite primary key and no TargetCountry column
CREATE TABLE dbo.TargetCountry (
    MarketID 	 VARCHAR(50) NOT NULL
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

INSERT INTO dbo.TargetCountry (MarketID, MarketName, CountryCode, CountryName, OrderNo, ShortedCode)
SELECT t.MarketID, t.MarketName, t.CountryCode, t.CountryName, t.OrderNo, t.ShortedCode
FROM (
		VALUES ('en-US', 'English'			 , 'MY', 'Malaysia'	  , 1 	, 'en')
			  ,('zh-CN', 'Chinese Simplified', 'MY', 'Malaysia'	  , NULL, 'cs')
			  ,('ms-MY', 'Malay'			 , 'MY', 'Malaysia'	  , NULL, 'ms')
			  ,('th-TH', 'Thai'				 , 'TH', 'Thailand'	  , 2	, 'th')
			  ,('en-US', 'English'			 , 'TH', 'Thailand'	  , NULL, 'then')
			  ,('id-ID', 'Indonesia'		 , 'ID', 'Indonesia'  , 3	, 'id')
			  ,('en-US', 'English'			 , 'ID', 'Indonesia'  , NULL, 'iden')
			  ,('hi-IN', 'Hindi'			 , 'IN', 'India'	  , 4	, 'hi')
			  ,('en-US', 'English'			 , 'IN', 'India'	  , NULL, 'hien')
			  ,('vi-VN', 'Vietnamese'		 , 'VN', 'Vietnam'	  , 5	, 'vn')
			  ,('en-US', 'English'			 , 'VN', 'Vietnam'	  , NULL, 'vnen')
			  ,('bn-BD', 'Bangladeshi'		 , 'BD', 'Bangladesh' , 6	, 'bn')
			  ,('en-US', 'English'			 , 'BD', 'Bangladesh' , NULL, 'bnen')
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
SET adc.TargetCountryCode = CASE WHEN adc.MarketId = 'en-US' THEN 'MY' ELSE t.CountryCode END
FROM dbo.DomainControl adc
	CROSS APPLY (
		SELECT TOP(1) tc.CountryCode
		FROM dbo.TargetCountry tc WITH (NOLOCK)
		WHERE tc.MarketID = adc.MarketID
		ORDER BY tc.CountryCode ASC
	) AS t
WHERE adc.IsDeleted = 0
GO
	-- Make sure to run the check query before updating the IsDeleted value
	/*
		SELECT TargetCountryCode, AffDomainId
		FROM dbo.DomainControl WITH (NOLOCK)
		WHERE IsDeleted = 0
		GROUP BY TargetCountryCode, AffDomainId
		HAVING COUNT(1) > 1

		>>>> No need to recheck if the query returns no results. Otherwise, check again.
	*/

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
GO
-- AffDetail
ALTER TABLE dbo.AffDetail ADD TargetCountryCode VARCHAR(5)
GO

BEGIN
	DROP TABLE IF EXISTS #TmpAffDetailUpd
	
	DROP TABLE IF EXISTS #TmpAffDetailUpdTOP2000
	
	CREATE TABLE #TmpAffDetailUpd (AffID INT PRIMARY KEY)
	
	CREATE TABLE #TmpAffDetailUpdTOP2000 (AffID INT PRIMARY KEY)
	
	INSERT INTO #TmpAffDetailUpd(AffID)
	SELECT AffID
	FROM dbo.AffDetail WITH (NOLOCK)
	
	
	WHILE 1 = 1
	BEGIN
		DELETE TOP(2000) FROM #TmpAffDetailUpd
		OUTPUT DELETED.AffID
		INTO #TmpAffDetailUpdTOP2000(AffID)
		
		UPDATE ad WITH (ROWLOCK, UPDLOCK)
		SET ad.TargetCountryCode = CASE WHEN ad.PreferredLanguage = 'en-US' THEN 'MY' ELSE t.CountryCode END
		FROM dbo.AffDetail ad
			INNER JOIN #TmpAffDetailUpdTOP2000 u ON ad.AffID = u.AffID
			CROSS APPLY (
				SELECT TOP(1) tc.CountryCode
				FROM dbo.TargetCountry tc WITH (NOLOCK)
				WHERE tc.MarketID = ad.PreferredLanguage
				ORDER BY tc.CountryCode
			) AS t

		IF @@ROWCOUNT < 2000
			BREAK
			
		DELETE FROM #TmpAffDetailUpdTOP2000
		
		WAITFOR DELAY '00:00:00.280'
	END
	
	DROP TABLE #TmpAffDetailUpdTOP2000
	DROP TABLE #TmpAffDetailUpd
END
GO