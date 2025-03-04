/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250220@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Update policy for None Group [RedmineID: #212201]


*/
USE Affiliate_12B
GO
DECLARE @GroupName NVARCHAR(50)  ='None'
	,@GroupId INT			


SELECT @GroupId = GroupId
FROM AffGroupInfo WITH (NOLOCK)
WHERE GroupName = @GroupName 


UPDATE c SET Policy = 0
FROM dbo.AffGroupPolicy c WITH (ROWLOCK, UPDLOCK)
WHERE GroupId = @GroupId
	AND Policy <> 0
