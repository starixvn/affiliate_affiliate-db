/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20231031@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new column BlockTargetCountry and initial data into column BlockTargetCountry [RedmineId : #181590]
*/

ALTER TABLE dbo.AffDomain
	ADD BlockTargetCountry VARCHAR(100) NOT NULL CONSTRAINT [DF_AffDomain_BlockTargetCountry] DEFAULT ((''))
GO

ALTER TABLE dbo.[12BetDomain]
	ADD BlockTargetCountry VARCHAR(100) NOT NULL CONSTRAINT [DF_12BetDomain_BlockTargetCountry] DEFAULT ((''))
GO

ALTER TABLE dbo.LandingPage
	ADD BlockTargetCountry VARCHAR(100) NOT NULL CONSTRAINT [DF_LandingPage_BlockTargetCountry] DEFAULT ((''))
GO

/*
	--Initial data
*/

UPDATE ad WITH (ROWLOCK, UPDLOCK) -- 155 rows  AffDomain
SET ad.BlockTargetCountry = ISNULL(oam.BlockTargetCountry, '')
FROM dbo.AffDomain ad
	OUTER APPLY(
		SELECT STRING_AGG(t.CountryCode, ',') AS BlockTargetCountry
		FROM(
			SELECT tc.CountryCode
			FROM dbo.TargetCountry tc WITH (NOLOCK)
				INNER JOIN STRING_SPLIT(ad.BlockMarket, ',') s ON s.value = tc.MarketID
			GROUP BY tc.CountryCode
		) AS t
	) As oam
GO

UPDATE ad WITH (ROWLOCK, UPDLOCK) -- 224 rows  [12BetDomain]
SET ad.BlockTargetCountry = ISNULL(oam.BlockTargetCountry, '')
FROM dbo.[12BetDomain] ad
	OUTER APPLY(
		SELECT STRING_AGG(t.CountryCode, ',') AS BlockTargetCountry
		FROM(
			SELECT tc.CountryCode
			FROM dbo.TargetCountry tc WITH (NOLOCK)
				INNER JOIN STRING_SPLIT(ad.BlockMarket, ',') s ON s.value = tc.MarketID
			GROUP BY tc.CountryCode
		) AS t
	) As oam
GO

UPDATE lp WITH (ROWLOCK, UPDLOCK)
SET lp.BlockTargetCountry = CASE WHEN lp.PageName = 'Cricket' AND lp.PageCode = '12sports/cricket' THEN 'CN,MY,VN,TH,KR,ID,KH'
								 WHEN lp.PageName = 'Exchange' AND lp.PageCode = 'exchange' THEN 'CN,MY,VN,TH,KR,ID,KH'
								 WHEN lp.PageName = 'Playtech' AND lp.PageCode = 'playtech' THEN 'KH'
							ELSE lp.BlockTargetCountry END
FROM dbo.LandingPage lp
WHERE lp.IsDeleted = 0
GO