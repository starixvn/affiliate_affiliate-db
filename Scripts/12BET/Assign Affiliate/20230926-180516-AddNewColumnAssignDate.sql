/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230926@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add New Column AssignDate [RedmineID: #180516]
*/

ALTER TABLE dbo.MemberInfo
	ADD [AssignDate] DATETIME CONSTRAINT [DF_MemberInfo_AssignDate] DEFAULT (GETDATE())
GO



