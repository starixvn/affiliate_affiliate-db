/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20250804@Eddie
	DB: DBAFFN88-Affiliate_N88
	Task: Alter table structure and initialize data [RedmineID: #227560]
*/
USE Affiliate_N88
GO

ALTER TABLE dbo.Market ADD IsDeleted BIT NOT NULL CONSTRAINT DF_Market_IsDeleted DEFAULT(0)
GO
