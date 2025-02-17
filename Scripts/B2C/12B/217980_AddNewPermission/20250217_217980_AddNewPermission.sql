/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250217@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Add new permission [RedmineID: #212201]
*/

USE Affiliate_12B
GO

-- Add new function
INSERT INTO dbo.AffFunctionInfo (FuncName, FuncNote, FuncDesc, FuncRender, DisplayOrder, Creator, ParentId, FileNames)
SELECT t.FuncName, t.FuncNote, t.FuncDesc, t.FuncRender, t.DisplayOrder, t.Creator, t.ParentId, t.FileNames
FROM (
	VALUES (N'[AffPersonalInfo]', '', N'Full Affiliate Personal Information', 3, '1', 1000000000, NULL, '')
) AS t(FuncName, FuncNote, FuncDesc, FuncRender, DisplayOrder, Creator, ParentId, FileNames)
	LEFT JOIN dbo.AffFunctionInfo ai WITH (NOLOCK) ON ai.FuncName = t.FuncName
WHERE ai.FuncName IS NULL

UPDATE dbo.AffFunctionInfo WITH(ROWLOCK)
SET ParentId = FuncId
WHERE FuncName IN (N'[AffPersonalInfo]')
GO

-- Add new permission
DECLARE @GroupIds TABLE (GroupId INT)
DECLARE @UserIds  TABLE (UserId  INT)
DECLARE @FunctIds TABLE (FunctId INT)

INSERT INTO @GroupIds (GroupId)
SELECT DISTINCT agh.GroupId
FROM dbo.AffGroupPolicy agh WITH (NOLOCK)

INSERT INTO @UserIds (UserId)
SELECT DISTINCT amp.CustId
FROM dbo.AffMemberPolicy amp  WITH (NOLOCK)

INSERT INTO @FunctIds (FunctId)
SELECT afi.FuncId
FROM dbo.AffFunctionInfo afi WITH (NOLOCK)
WHERE afi.FuncName IN (N'[AffPersonalInfo]')

	
INSERT INTO dbo.AffGroupPolicy (GroupId, FuncId, Policy, CreateDate, ModifyDate, Creator)
SELECT t.GroupId
	  ,t.FunctId
	  ,0 AS [Policy]
	  ,SYSDATETIME() AS CreateDate
	  ,SYSDATETIME() AS ModifyDate
	  ,1000000000 AS Creator
FROM (
		SELECT g.GroupId, f.FunctId
		FROM @GroupIds g
			CROSS JOIN @FunctIds f 
)t
	LEFT JOIN dbo.AffGroupPolicy ap WITH (NOLOCK) ON ap.GroupId = t.GroupId AND ap.FuncId = t.FunctId
WHERE ap.GroupId IS NULL

INSERT INTO dbo.AffMemberPolicy (CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
SELECT t.UserId
	  ,t.FunctId
	  ,0 AS [Policy]
	  ,SYSDATETIME() AS CreateDate
	  ,SYSDATETIME() AS ModifyDate
	  ,1000000000 AS Creator
FROM (
		SELECT g.UserId, f.FunctId
		FROM @UserIds g
			CROSS JOIN @FunctIds f 
)t
		LEFT JOIN dbo.AffMemberPolicy ap WITH (NOLOCK) ON ap.CustId = t.UserId AND ap.FuncId = t.FunctId
WHERE ap.CustId IS NULL
GO