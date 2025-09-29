/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20250801@Eddie
	DB: DBAFFN88-Affiliate_N88
	Task: Delete and Migrate [RedmineID: #227560]
*/
USE Affiliate_N88
GO

ALTER TABLE dbo.Market ADD IsDeleted BIT NOT NULL CONSTRAINT DF_Market_IsDeleted DEFAULT(0)
GO

IF EXISTS (SELECT 1 FROM dbo.Market WITH (NOLOCK) WHERE MarketId = 'en-PH')
BEGIN
	UPDATE dbo.Market WITH (ROWLOCK, UPDLOCK)
	SET IsDeleted = 1
	WHERE MarketId = 'en-PH'
END
GO

IF EXISTS (SELECT 1 FROM dbo.DomainControl WITH (NOLOCK) WHERE MarketId = 'en-PH')
BEGIN
	UPDATE dbo.DomainControl WITH (ROWLOCK, UPDLOCK)
	SET MarketId = 'en-US'
	WHERE MarketId = 'en-PH'
END
GO

IF EXISTS (SELECT 1 FROM dbo.AffDetail WITH (NOLOCK) WHERE PreferredLanguage = 'en-PH')
BEGIN
	UPDATE dbo.AffDetail WITH (ROWLOCK, UPDLOCK)
	SET MarketId = 'en-US'
	WHERE PreferredLanguage = 'en-PH'
END
GO