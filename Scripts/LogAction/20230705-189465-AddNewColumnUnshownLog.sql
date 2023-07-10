/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230705@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new column for table 'UserLog_RunSP_Detail' to unshown log [RedmineID: #189465]
*/

ALTER TABLE dbo.UserLog_RunSP_Detail
	ADD IsShow BIT CONSTRAINT [DF_UserLog_RunSP_Detail_IsShow] DEFAULT (1)
GO

UPDATE dbo.[UserLog_RunSP_Detail] WITH (ROWLOCK)
SET IsShow = 1
WHERE IsShow IS NULL
GO

