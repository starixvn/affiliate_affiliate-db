/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20231030@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new column TargetCountryCode and initial data into column TargetCountryCode [RedmineId : #181590]
*/

ALTER TABLE dbo.AffDomainControl
	ADD TargetCountryCode VARCHAR(2) NOT NULL CONSTRAINT [DF_AffDomainControl_TargetCountryCode] DEFAULT ((''))
GO

/*
	--Initial data
*/
UPDATE adc WITH (ROWLOCK, UPDLOCK) -- 223 rows
SET adc.TargetCountryCode = ISNULL(tc.CountryCode, '')
FROM dbo.AffDomainControl adc
	LEFT JOIN dbo.TargetCountry tc WITH (NOLOCK) ON adc.MarketID = tc.MarketID
GO

