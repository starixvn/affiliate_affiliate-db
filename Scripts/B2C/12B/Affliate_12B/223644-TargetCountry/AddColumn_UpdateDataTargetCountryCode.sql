/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250418@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Structure [RedmineID: #223644]
*/

-- Drop the existing table if it exists (optional, for re-creation)
DROP TABLE IF EXISTS TargetCountry;
-- Create the TargetCountry table with a composite primary key and no TargetCountry column
CREATE TABLE TargetCountry (
    MarketID VARCHAR(50) NOT NULL,
    MarketName VARCHAR(100),
    CountryCode VARCHAR(5) NOT NULL,
    CountryName VARCHAR(100),
    OrderNo INT,
    CONSTRAINT PK_CountryCode_MarketID PRIMARY KEY (CountryCode,MarketID)
);
GO

-- Insert data into the TargetCountry table
INSERT INTO TargetCountry (MarketID, MarketName, CountryCode, CountryName, OrderNo) VALUES
('bn-BD', 'English (Bangladesh)', 'BD', 'Bangladesh', 2),
('en-GB', 'English (Europe)', 'MY', 'Malaysia', NULL),
('en-US', 'English', 'MY', 'Malaysia', 1),
('te-IN', 'Telugu', 'IN', 'India', NULL),
('en-IN', 'English (India)', 'IN', 'India', 3),
('id-ID', 'Indonesian', 'ID', 'Indonesia', 4),
('ja-JP', 'Japanese', 'JP', 'Japan', 5),
('ko-KR', 'Korean', 'KR', 'South Korea', 6),
('th-TH', 'Thai', 'TH', 'Thailand', 7),
('vi-VN', 'Vietnamese', 'VN', 'Vietnam', 8),
('zh-CN', 'Chinese Simplified', 'CN', 'China', 9);
GO


ALTER TABLE AffDetail ADD TargetCountryCode VARCHAR(5);
GO

-- add new column TargetCountryCode for table DomainControl
ALTER TABLE DomainControl ADD TargetCountryCode VARCHAR(5);
GO

-- add new columnn BlockTargetCountry varchar(200) for table AffDomain and LicenseeDomain
ALTER TABLE AffDomain ADD BlockTargetCountry VARCHAR(200); 
GO

-- add new columnn BlockTargetCountry varchar(200) for table LicenseeDomain
ALTER TABLE LicenseeDomain ADD BlockTargetCountry VARCHAR(200);
GO

-- add new columnn BlockTargetCountry varchar(200) for table LandingPage
ALTER TABLE LandingPage Add BlockTargetCountry VARCHAR(200);
GO

--Mapping data MarketID and TargetCountryCode
UPDATE AffDomain WITH (ROWLOCK,UPDLOCK)
SET BlockTargetCountry = (
							SELECT STRING_AGG(t.CountryCode, ',')
							FROM (
									SELECT DISTINCT tc.CountryCode
									FROM Market m WITH (NOLOCK)
									INNER JOIN TargetCountry tc WITH (NOLOCK) ON m.MarketId = tc.MarketID
									WHERE CHARINDEX(m.MarketId, AffDomain.BlockMarket) > 0
								 ) t    
						)
WHERE BlockMarket IS NOT NULL;
GO

-- Update LicenseeDomain.TargetCountryCode by mapping MarketId in Market and TargetCountry
UPDATE LicenseeDomain  WITH (ROWLOCK,UPDLOCK)
SET BlockTargetCountry =  (
							SELECT STRING_AGG(t.CountryCode, ',')
							FROM (
									SELECT DISTINCT tc.CountryCode
									FROM Market m WITH (NOLOCK)
									INNER JOIN TargetCountry tc WITH (NOLOCK) ON m.MarketId = tc.MarketID
									WHERE CHARINDEX(m.MarketId, LicenseeDomain.BlockMarket) > 0
								 ) t    
						)
WHERE BlockMarket IS NOT NULL;
GO

-- Update AffDetail.TargetCountryCode by mapping MarketId in Market and TargetCountry
UPDATE AffDetail  WITH (ROWLOCK,UPDLOCK)
SET TargetCountryCode = (
    SELECT TOP 1 tc.CountryCode -- Get the corresponding CountryCode
    FROM Market m WITH (NOLOCK)
    INNER JOIN TargetCountry tc WITH (NOLOCK) ON m.MarketId = tc.MarketID
    WHERE m.MarketId = AffDetail.PreferredLanguage
)
WHERE PreferredLanguage IS NOT NULL;
GO

-- Update DomainControl.MarketId = 'hi-IN' --> 'te-IN'
UPDATE DomainControl  WITH (ROWLOCK,UPDLOCK)
SET MarketId = 'te-IN'
WHERE MarketId = 'hi-IN' 
	AND NOT EXISTS (
					SELECT TOP 1 1 
					FROM DomainControl d WITH (NOLOCK) 
					WHERE d.MarketId = 'te-IN' 
					and d.AffDomainId = DomainControl.AffDomainId 
					And d.LicenseeDomainId = DomainControl.LicenseeDomainId
					)
GO

-- Update DomainControl.TargetCountry by mapping MarketId in Market and TargetCountry
UPDATE DomainControl  WITH (ROWLOCK,UPDLOCK)
SET TargetCountryCode = (
    SELECT TOP 1 tc.CountryCode -- Get the corresponding CountryCode
    FROM Market m WITH (NOLOCK)
    INNER JOIN TargetCountry tc WITH (NOLOCK) ON m.MarketId = tc.MarketID
    WHERE m.MarketId = DomainControl.MarketId
)
WHERE MarketId IS NOT NULL;
GO

-- Delete marketid = hi-in
UPDATE d SET d.IsDeleted = 1
FROM DomainControl d WITH (ROWLOCK,UPDLOCK)
WHERE MarketId = 'hi-IN' AND TargetCountryCode IS NULL
GO