/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250418@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Structure [RedmineID: #223644]
*/
USE Affiliate_12B
GO

UPDATE DomainControl WITH (ROWLOCK,UPDLOCK)
SET isdeleted = 1
WHERE Id IN (
    SELECT d.Id
    FROM DomainControl d WITH (NOLOCK)
    INNER JOIN TargetCountry tc WITH (NOLOCK) 
        ON d.TargetCountryCode = tc.CountryCode 
        AND d.MarketId = tc.MarketID
    WHERE d.isdeleted = 0
      AND (CASE WHEN tc.OrderNo IS NULL THEN 0 ELSE 1 END) = 0
)
