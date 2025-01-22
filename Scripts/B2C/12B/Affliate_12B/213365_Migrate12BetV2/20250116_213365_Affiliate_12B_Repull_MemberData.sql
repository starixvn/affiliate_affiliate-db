/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250116@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Pull member info for 12B V2  [RedmineId : #212201]

*/

USE Affiliate_12B
GO


Update c set SValue = '2008-03-01 00:00:00'
FROM Affiliate_12B.dbo.SystemSettings c with (NOLOCK)
where c.SName IN ('MemberInfoLastImportedTime', 'MemberInfoLastUpdatedTime')