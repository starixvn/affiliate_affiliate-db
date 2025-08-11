/*<info serverAlias="DBAFF12B-Affiliate_12B" ></info>*/
/*  
	Created: 20250804@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Cover Abnormal players
		- Add column TagList to MemberInfo
*/
USE Affiliate_12B
GO
ALTER TABLE dbo.MemberInfo
ADD [TagList] nvarchar(MAX) NULL

GO