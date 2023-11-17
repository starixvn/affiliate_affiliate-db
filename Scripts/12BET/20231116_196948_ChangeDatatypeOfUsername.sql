/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20231116@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Change Datatype of Username and update Username [RedmineID: #196948]
*/
ALTER TABLE dbo.MemberInfo
	ALTER COLUMN UserName VARCHAR(50)
GO

UPDATE mi WITH (ROWLOCK, UPDLOCK)
SET mi.UserName = '12Bet$Gowthamchannapurthammanna'
FROM dbo.MemberInfo mi
WHERE IBCCustID = 45592391
GO