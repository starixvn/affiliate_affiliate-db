/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250918@Sally	
	Task: Update DepositInfo of MemberInfo
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	
	Revisions:
		- 20250922@Sally: Created [RedmineID: #238812]
    
    USE Affiliate_N88
    GO

    USE Affiliate_N8B
    GO

    USE Affiliate_N8G
    GO

*/

UPDATE s SET s.SValue ='2025-09-01 00:00:00'
FROM dbo.SystemSettings s WITH (ROWLOCK,UPDLOCK) 
WHERE SName in ('MemberInfoLastUpdatedTime') 
GO