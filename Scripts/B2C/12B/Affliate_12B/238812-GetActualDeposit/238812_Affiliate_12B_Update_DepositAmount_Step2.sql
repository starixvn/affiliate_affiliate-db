/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250918@Sally	
	Task: Update DepositInfo of MemberInfo
	DB: DBAFF12B-Affiliate_12B
	
	Revisions:
		- 20250922@Sally: Created [RedmineID: #238812]

*/
USE Affiliate_12B
GO

UPDATE s SET s.SValue ='2025-09-01 00:00:00'
FROM dbo.SystemSettings s WITH (ROWLOCK,UPDLOCK) 
WHERE SName in ('MemberInfoLastUpdatedTime') 
GO