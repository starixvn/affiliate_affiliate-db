/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251001@Lewis
    DB: DBAFF12B-Affiliate_12B
    Task: INIT Data for CPA
    RedmineID: #235601
    
    Purpose: Add IsSubCommRate bit column to support commission calculation logic
*/
USE Affiliate_12B;
GO

UPDATE dbo.CommGroup WITH (ROWLOCK,UPDLOCK)
SET IsSubCommRate = 0, SubCommRate = 0
WHERE GroupTypeId = 3;
GO

UPDATE cgh 
SET IsSubCommRate = 0, SubCommRate = 0
FROM dbo.CommGroupHistory cgh WITH (ROWLOCK,UPDLOCK)
WHERE EXISTS (SELECT TOP 1 1 FROM CommGroup cg WITH (NOLOCK) WHERE cg.GroupId = cgh.GroupId AND cg.GroupTypeId = 3);
GO

UPDATE dbo.CPAGroupSetting WITH (ROWLOCK,UPDLOCK)
SET IsSubCommRate = 0, SubCommRate = 0
WHERE GroupTypeId = 3;
GO
