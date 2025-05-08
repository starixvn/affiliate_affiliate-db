/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250418@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Structure [RedmineID: #223644]
*/

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