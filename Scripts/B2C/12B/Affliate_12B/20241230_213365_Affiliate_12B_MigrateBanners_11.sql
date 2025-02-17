/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250213@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Migrate Banner, AffDomain and 12BetDomain [RedmineID: #212201]
	
	Affiliate_12Bet.dbo.Banners 		 >>> Affiliate_12Bet.dbo.Banners_Pro
	Affiliate_12Bet.dbo.AffDomainControl >>> Affiliate_12Bet.dbo.AffDomainControl_Pro
	Affiliate_12Bet.dbo.AffDomain 		 >>> Affiliate_12Bet.dbo.AffDomain_Pro
	Affiliate_12Bet.dbo.[12BetDomain] 	 >>> Affiliate_12Bet.dbo.[12BetDomain_Pro]
*/
/* Table: banners
	1) No migrate with ImageType = 'Text' ---> Text related SPs will be dropped
	2) No migrate with Category = 'Racebook' ---> Remove Racebook from related SPs
	3) No migrate with Languages not be supported
	4) Fill SubCategories with ''
	5) Use Target Product to replace for Category
	6) Use acc 'sa' with Creator and UpdatedBy
	7) Use all supported currencies apply for Currencies column

*/
/* Table: AffDomainControl
	1) No migrate when it is deleted 
	2) No migrate with Languages not be supported
	3) No migrate with Status = 0
*/
/* Table: AffDomain
	1) No migrate when it is out of specific go domain list
	2) No migrate when it is out of AffDomainControl
*/
/* Table: [12BetDomain]
	1) No migrate when it is out of AffDomainControl
*/

USE Affiliate_12B
GO

TRUNCATE TABLE MediaGallery
TRUNCATE TABLE LicenseeDomain
TRUNCATE TABLE DomainControl
TRUNCATE TABLE AffDomain
TRUNCATE TABLE SubAffDomain

SET IDENTITY_INSERT dbo.MediaGallery OFF;
SET IDENTITY_INSERT dbo.LicenseeDomain OFF;
SET IDENTITY_INSERT dbo.DomainControl OFF;
SET IDENTITY_INSERT dbo.AffDomain OFF;

-- Info Currencies
DECLARE @Currencies VARCHAR(500) = ''

SELECT @Currencies = STRING_AGG(RIGHT(t.value, 3), ',')
FROM dbo.SystemSettings s WITH (NOLOCK)
	CROSS APPLY (SELECT value FROM STRING_SPLIT(SValue, ',')) AS t
WHERE s.SName = 'AFF_SupportedCurrencies'

-- Info exclude banners
DROP TABLE IF EXISTS #BannerExcluded;
CREATE TABLE #BannerExcluded (BannerId INT NOT NULL)

;WITH CTE_Text AS(
	SELECT BannerId
	FROM Affiliate_12Bet.dbo.Banners WITH (NOLOCK)
	WHERE ImageType = 'Text'
),
CTE_Language_NoSupport AS(
	SELECT b.BannerId
	FROM Affiliate_12Bet.dbo.Banners b WITH (NOLOCK)
		LEFT JOIN dbo.Market m WITH (NOLOCK) ON b.language = m.MarketName OR b.language = m.DisplayName
	WHERE m.MarketName IS NULL OR m.DisplayName IS NULL
),
CTE_Category_NoSupport AS(
	SELECT b.BannerId
	FROM Affiliate_12Bet.dbo.Banners b WITH (NOLOCK)
		LEFT JOIN CTE_Text c ON c.BannerId = b.BannerId
	WHERE c.BannerId IS NULL
	  AND (b.Categories = 'Racebook' OR ISNULL(b.TargetProductIds, '') = '')
),
CTE_AffTypes_NoSupport AS(
	SELECT b.BannerId
	FROM Affiliate_12Bet.dbo.Banners b WITH (NOLOCK)
		LEFT JOIN CTE_Category_NoSupport c ON c.BannerId = b.BannerId
	WHERE c.BannerId IS NULL
	  AND b.AffTypes NOT LIKE '%2%'
)
INSERT INTO #BannerExcluded(BannerId)
SELECT BannerId FROM CTE_Text
UNION ALL
SELECT BannerId FROM CTE_Language_NoSupport
UNION ALL
SELECT BannerId FROM CTE_Category_NoSupport
UNION ALL
SELECT BannerId FROM CTE_AffTypes_NoSupport

-- Table:  Banners
SET IDENTITY_INSERT dbo.MediaGallery ON;

	INSERT INTO dbo.MediaGallery([MediaId], [FileName], [TargetId], [ImageType], [Message], [Size], [Categories], [SubCategories], [Language], [Currencies], [AffTypes], [DeviceTypes], [Creator], [CreatedDate], [UpdatedBy], [UpdatedDate])
	SELECT b.BannerId, b.FileName, 1 AS TargetId, b.ImageType, b.Message, b.Size
	, STRING_AGG(tp.ProductName, ',') AS Categories
	, '' AS SubCategories, b.Language, @Currencies AS Currencies, '2' AS AffTypes, CASE WHEN ISNULL(b.DeviceTypes, 'Null') =  'Null' THEN '0,1' ELSE b.DeviceTypes END AS DeviceTypes, 1000000000 AS Creator, b.CreatedDate, 1000000000 AS UpdatedBy, b.UpdatedDate
	FROM Affiliate_12Bet.dbo.Banners b WITH (NOLOCK)
		LEFT JOIN dbo.MediaGallery m WITH (NOLOCK) ON m.MediaId = b.BannerId
		CROSS APPLY (SELECT value FROM STRING_SPLIT(b.TargetProductIds, ',')) AS t
		INNER JOIN Affiliate_12Bet.dbo.TargetProduct tp WITH (NOLOCK) ON CONVERT(INT, t.value) = tp.ProductID
	WHERE m.MediaId IS NULL
	  AND NOT EXISTS (SELECT 1 FROM #BannerExcluded be WHERE be.BannerId = b.BannerId)
	GROUP BY b.BannerId, b.FileName, b.ImageType, b.Message, b.Size, b.Language, b.AffTypes, CASE WHEN ISNULL(b.DeviceTypes, 'Null') =  'Null' THEN '0,1' ELSE b.DeviceTypes END, b.CreatedDate, b.UpdatedDate

SET IDENTITY_INSERT dbo.MediaGallery OFF;


-- Info exclude aff domain control
DROP TABLE IF EXISTS #DomainControlExcluded;
CREATE TABLE #DomainControlExcluded (Id INT NOT NULL)

; WITH CTE_Language_NoSupport AS(
	SELECT b.Id
	FROM Affiliate_12Bet.dbo.AffDomainControl b WITH (NOLOCK)
		LEFT JOIN dbo.Market m WITH (NOLOCK) ON b.MarketID = m.MarketID
	WHERE m.MarketID IS NULL AND b.MarketID <> 'hi'
),
CTE_Be_Deleted AS(
	SELECT b.Id
	FROM Affiliate_12Bet.dbo.AffDomainControl b WITH (NOLOCK)
		LEFT JOIN CTE_Language_NoSupport l ON l.Id = b.Id
	WHERE l.Id IS NULL AND b.IsDeleted = 1
),
CTE_Status_NoSupport AS(
	SELECT b.Id
	FROM Affiliate_12Bet.dbo.AffDomainControl b WITH (NOLOCK)
		LEFT JOIN CTE_Be_Deleted l ON l.Id = b.Id
	WHERE l.Id IS NULL AND b.Status = 0
)
INSERT INTO #DomainControlExcluded(Id)
SELECT Id FROM CTE_Language_NoSupport
UNION ALL
SELECT Id FROM CTE_Be_Deleted
UNION ALL
SELECT Id FROM CTE_Status_NoSupport

-- Table: AffDomainControl
SET IDENTITY_INSERT dbo.DomainControl ON;

	INSERT INTO dbo.DomainControl([Id], [AffDomainId], [LicenseeDomainId], [MarketId], [CreateDate], [ModifyDate], [Creator], [Status], [DeviceType], [IsDeleted])
	SELECT ad.Id, ad.AffDomainId, ad.[12BetDomainId] AS LicenseeDomainId
	, CASE ad. MarketId WHEN 'hi-IN' THEN 'en-IN' 
						WHEN 'hi' 	 THEN 'hi-IN'
						ELSE ad. MarketId END AS MarketId
	, ad.CreateDate, ad.ModifyDate, 1000000000 AS Creator, ad.Status, ad.DeviceType, ad.IsDeleted
	FROM Affiliate_12Bet.dbo.AffDomainControl ad WITH (NOLOCK)
		LEFT JOIN dbo.DomainControl dc WITH (NOLOCK) ON dc.Id = ad.Id
	WHERE dc.Id IS NULL
	  AND NOT EXISTS (SELECT 1 FROM #DomainControlExcluded be WHERE be.Id = ad.Id)

SET IDENTITY_INSERT dbo.DomainControl OFF;

-- Insert data
; WITH CTE_Add_DomainControl AS (
	SELECT ad.Id, ad.AffDomainId, ad.[12BetDomainId] AS LicenseeDomainId
	, CASE t. MarketId WHEN 'hi-IN' THEN 'en-IN' ELSE t. MarketId END AS MarketId
	, ad.CreateDate, ad.ModifyDate, 1000000000 AS Creator, ad.Status, ad.DeviceType, ad.IsDeleted
	FROM Affiliate_12Bet.dbo.AffDomainControl ad  WITH (NOLOCK)
		INNER JOIN Affiliate_12Bet.dbo.TargetCountry t WITH (NOLOCK) ON t.CountryCode = ad.TargetCountryCode
		INNER JOIN DomainControl m WITH (NOLOCK) ON m.Id = ad.Id
	WHERE t.CountryCode IN ('IN', 'MY') AND t. MarketId NOT IN ('hi')
)
INSERT INTO dbo.DomainControl([AffDomainId], [LicenseeDomainId], [MarketId], [CreateDate], [ModifyDate], [Creator], [Status], [DeviceType], [IsDeleted])
SELECT aad.AffDomainId, aad.LicenseeDomainId, aad.MarketId, aad.CreateDate, aad.ModifyDate, aad.Creator, aad.Status, aad.DeviceType, aad.IsDeleted
FROM CTE_Add_DomainControl aad
	LEFT JOIN DomainControl ac WITH (NOLOCK) ON ac.Id = aad.Id
											AND ac.AffDomainId = aad.AffDomainId
											AND ac.LicenseeDomainId = aad.LicenseeDomainId
											AND ac.MarketId = aad.MarketId
WHERE ac.Id IS NULL
   OR ac.AffDomainId IS NULL
   OR ac.LicenseeDomainId IS NULL
   OR ac.MarketId IS NULL


-- Table: AffDomain
SET IDENTITY_INSERT dbo.AffDomain ON;
	
	; WITH CTE_AffDMC AS(
		SELECT AffDomainId AS DomainId
		FROM DomainControl WITH (NOLOCK)
		GROUP BY AffDomainId
		UNION ALL
		SELECT DomainId AS DomainId
		FROM Affiliate_12Bet.dbo.AffDomain ad WITH (NOLOCK)
		WHERE DomainName IN ('join.best5689.com', 'go.12real.com', 'go.5689fun.com', 'go.6789sutzo.com', 'go.12fifa18.com', '12aff.best5689.com', 'go.9012ijk.com', 'go.sbc31.com', 'go.tha88.com', 'go.apa56.com', 'go.12qiuball.com', 'go.all2356.com', 'go.amo38.com', 'go.12winball.com')
	)
	INSERT INTO dbo.AffDomain([DomainId], [DomainName], [CreateDate], [ModifyDate], [Creator], [IsDeleted], [IsSSL])
	SELECT ad.DomainId, ad.DomainName, ad.CreateDate, ad.ModifyDate, 1000000000 AS Creator, ad.IsDeleted, CONVERT(BIT, ISNULL(ad.IsSSL, 0)) AS IsSSL
	FROM Affiliate_12Bet.dbo.AffDomain ad WITH (NOLOCK)
		LEFT JOIN dbo.AffDomain af WITH (NOLOCK) ON af.DomainId = ad.DomainId
	WHERE af.DomainId IS NULL 
	  AND ad.IsDeleted = 0
	  AND EXISTS(SELECT 1 FROM CTE_AffDMC a WHERE a.DomainId = ad.DomainID)

SET IDENTITY_INSERT dbo.AffDomain OFF;


-- Table: [12BetDomain]
SET IDENTITY_INSERT dbo.LicenseeDomain ON;
	
	; WITH CTE_AffDMC AS(
		SELECT LicenseeDomainId
		FROM DomainControl WITH (NOLOCK)
		GROUP BY LicenseeDomainId
	)
	INSERT INTO dbo.LicenseeDomain([DomainId], [DomainName], [CreateDate], [ModifyDate], [Creator], [DeviceType], [IsDeleted], [W3Prefix], [IsSSL])
	SELECT ad.DomainId, ad.DomainName, ad.CreateDate, ad.ModifyDate, 1000000000 AS Creator, ad.DeviceType, ad.IsDeleted, ad.W3Prefix, CONVERT(BIT, ISNULL(ad.IsSSL, 0)) AS IsSSL
	FROM Affiliate_12Bet.dbo.[12BetDomain] ad WITH (NOLOCK)
		LEFT JOIN dbo.LicenseeDomain l WITH (NOLOCK) ON l.DomainId = ad.DomainId
	WHERE l.DomainId IS NULL 
	  AND ad.IsDeleted = 0
	  AND EXISTS(SELECT 1 FROM CTE_AffDMC a WHERE a.LicenseeDomainId = ad.DomainID)

SET IDENTITY_INSERT dbo.LicenseeDomain OFF;


DROP TABLE IF EXISTS #BannerExcluded;
DROP TABLE IF EXISTS #DomainControlExcluded;