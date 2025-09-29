/*<info serverAlias="DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250910@Eddie
	DB: DBAFFN88-Affiliate_N88
	Task: Check data [RedmineID: #227560]
*/
USE Affiliate_N8G
GO

SELECT AffDomainId, MarketId
FROM dbo.DomainControl WITH (NOLOCK)
WHERE IsDeleted = 0
GROUP BY AffDomainId, MarketId
HAVING COUNT(1) > 1
/*
	No need to recheck if the query returns no results. Otherwise, check again.
*/
GO