/*<info serverAlias="DBAFF12B-Affiliate_12B" ></info>*/
/*  
	Created: 20250922@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: step 2 MemberInfo [RedmineID: #239263]
*/


--MemberInfo
USE Affiliate_12B
GO

UPDATE s SET s.SValue ='2025-07-01 00:00:00'
FROM dbo.SystemSettings s WITH (ROWLOCK,UPDLOCK) 
WHERE SName in ('MemberInfoLastUpdatedTime') 
GO