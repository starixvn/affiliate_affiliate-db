/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20221101@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Support Block Market - Add new column
*/

ALTER TABLE dbo.AffDomain
	ADD BlockMarket VARCHAR(400) NULL
GO

ALTER TABLE dbo.[12BetDomain]
	ADD BlockMarket VARCHAR(400) NULL
GO

UPDATE dbo.AffDomain WITH (ROWLOCK)
SET BlockMarket = ''
WHERE BlockMarket IS NULL

UPDATE dbo.[12BetDomain] WITH (ROWLOCK)
SET BlockMarket = ''
WHERE BlockMarket IS NULL
GO

