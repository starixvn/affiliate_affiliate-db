/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20250910@Eddie
	DB: DBAFFN88-Affiliate_N88
	Task: Check data [RedmineID: #227560]
*/
USE Affiliate_N88
GO

-- Check with MarketId
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.DomainControl WITH (NOLOCK) WHERE MarketId = 'en-PH')
	BEGIN
		SELECT AffDomainId, CASE WHEN MarketID = 'en-PH' THEN 'en-US' ELSE MarketID END AS MarketId
		FROM dbo.DomainControl WITH (NOLOCK)
		WHERE IsDeleted = 0
		GROUP BY AffDomainId, CASE WHEN MarketID = 'en-PH' THEN 'en-US' ELSE MarketID END
		HAVING COUNT(1) > 1
	END
	ELSE
	BEGIN
		SELECT AffDomainId, MarketId
		FROM dbo.DomainControl WITH (NOLOCK)
		WHERE IsDeleted = 0
		GROUP BY AffDomainId, MarketId
		HAVING COUNT(1) > 1
	END
	/*
		No need to recheck if the query returns no results. Otherwise, check again.
	*/
END
GO



-- Check with TargetCountry
BEGIN
	DROP TABLE IF EXISTS #TargetCountry_Test

	CREATE TABLE #TargetCountry_Test(
		MarketID 	 VARCHAR(50) NOT NULL
		,MarketName  VARCHAR(100)
		,CountryCode VARCHAR(5) NOT NULL
		,CountryName VARCHAR(100)
		,ShortedCode VARCHAR(20)
		,OrderNo 	 INT
		,CONSTRAINT PK_Eddie_test_CountryCode_MarketID PRIMARY KEY (CountryCode, MarketID)
	)

	INSERT INTO #TargetCountry_Test(MarketID, MarketName, CountryCode, CountryName, OrderNo, ShortedCode)
	VALUES ('vi-VN', 'Vietnamese'		 , 'VN', 'Vietnam'	  , 5	, 'vn')
		  ,('en-US', 'English'			 , 'VN', 'Vietnam'	  , NULL, 'vnen')
		  ,('th-TH', 'Thai'				 , 'TH', 'Thailand'	  , 2	, 'th')
		  ,('en-US', 'English'			 , 'TH', 'Thailand'	  , NULL, 'then')
		  ,('en-US', 'English'			 , 'PH', 'Philippines', 7	, 'phen') -- No problem if the Philippines hasn't been released yet
		  ,('en-US', 'English'			 , 'MY', 'Malaysia'	  , 1 	, 'en')
		  ,('zh-CN', 'Chinese Simplified', 'MY', 'Malaysia'	  , NULL, 'cs')
		  ,('ms-MY', 'Malay'			 , 'MY', 'Malaysia'	  , NULL, 'ms')
		  ,('hi-IN', 'Hindi'			 , 'IN', 'India'	  , 4	, 'hi')
		  ,('en-US', 'English'			 , 'IN', 'India'	  , NULL, 'hien')
		  ,('id-ID', 'Indonesia'		 , 'ID', 'Indonesia'  , 3	, 'id')
		  ,('en-US', 'English'			 , 'ID', 'Indonesia'  , NULL, 'iden')
		  ,('bn-BD', 'Bangladeshi'		 , 'BD', 'Bangladesh' , 6	, 'bn')
		  ,('en-US', 'English'			 , 'BD', 'Bangladesh' , NULL, 'bnen')
	
	;WITH CTE_check AS (
		SELECT dc.AffDomainId, CASE WHEN dc.MarketID = 'en-US' THEN 'MY' ELSE t.CountryCode END AS TargetCountry
		FROM dbo.DomainControl dc WITH (NOLOCK)
			CROSS APPLY (
						SELECT TOP(1) tt.CountryCode
						FROM #TargetCountry_Test tt
						WHERE dc.MarketID = tt.MarketID
						ORDER BY tt.CountryCode
					) AS t
		WHERE IsDeleted = 0
		GROUP BY dc.AffDomainId, CASE WHEN dc.MarketID = 'en-US' THEN 'MY' ELSE t.CountryCode END
		HAVING COUNT(1) > 1
	)
	SELECT a.DomainName, l.DomainName, m.MarketName, CASE WHEN dc.MarketID = 'en-US' THEN 'Malaysia' ELSE t.CountryName END AS TargetCountry
	FROM dbo.DomainControl dc WITH (NOLOCK)
		INNER JOIN dbo.AffDomain a WITH (NOLOCK) ON a.DomainId = dc.AffDomainId
		INNER JOIN dbo.LicenseeDomain l WITH (NOLOCK) ON l.DomainId = dc.LicenseeDomainId
		INNER JOIN CTE_check c ON c.AffDomainId = dc.AffDomainId
		INNER JOIN dbo.Market m WITH (NOLOCK) ON m.MarketID = dc.MarketID
		CROSS APPLY (
					SELECT TOP(1) tt.CountryName
					FROM #TargetCountry_Test tt
					WHERE dc.MarketID = tt.MarketID
					AND tt.CountryCode = c.TargetCountry
					ORDER BY tt.CountryCode
				) AS t
	WHERE dc.IsDeleted = 0

	DROP TABLE #TargetCountry_Test

	/*
		No need to recheck if the query returns no results. Otherwise, check again.
	*/
END
GO