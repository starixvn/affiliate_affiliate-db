/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250224@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Migrate domain with cross-market   [RedmineID: #212201]

*/

USE Affiliate_12B
GO


; WITH CTE_AffDomain AS (
	SELECT TOP 1 WITH TIES AffDomainId, LicenseeDomainId, MarketId, CreateDate, ModifyDate
	FROM dbo.DomainControl WITH (NOLOCK)
	WHERE CreateDate <= '2025-02-13'
		AND IsDeleted = 0
		AND Status = 1
	ORDER BY ROW_NUMBER() OVER(PARTITION BY AffDomainId, LicenseeDomainId, MarketId ORDER BY CreateDate)
),
 CTE_Migrate AS (
	SELECT t.AffDomainId, t.LicenseeDomainId, m.MarketId
	FROM(
		SELECT DISTINCT AffDomainId, LicenseeDomainId FROM CTE_AffDomain 
	)t
		CROSS JOIN dbo.Market m WITH(NOLOCK) 

 )
 INSERT INTO dbo.DomainControl([AffDomainId], [LicenseeDomainId], [MarketId], [CreateDate], [ModifyDate], [Creator], [Status], [DeviceType], [IsDeleted])
 SELECT m.AffDomainId, m.LicenseeDomainId, m.MarketId, h.CreateDate, h.ModifyDate, 1000000000 AS Creator, 1 AS Status, 0 AS DeviceType,0 AS IsDeleted
FROM CTE_Migrate m
	CROSS APPLY(
		SELECT TOP 1 CreateDate, ModifyDate
		FROM CTE_AffDomain t
		WHERE m.AffDomainId = t.AffDomainId
			AND m.LicenseeDomainId = t.LicenseeDomainId
	)h
	LEFT JOIN CTE_AffDomain c WITH (NOLOCK) ON  m.AffDomainId = c.AffDomainId
											AND m.LicenseeDomainId = c.LicenseeDomainId
											AND m.MarketId = c.MarketId
WHERE c.AffDomainId IS NULL
   

