/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250218@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Add new permission: Note, MarketingTeamNote [RedmineID: #212201]
		-  Add new column NoteType
		-  Add new function
*/

USE Affiliate_12B
GO
-- Add new column
ALTER TABLE AdminNotes
ADD NoteType BIT NOT NULL CONSTRAINT DF_AdminNotes_NoteType DEFAULT 0;
GO

-- Add new permission
DECLARE @GroupIds TABLE (GroupId INT)
DECLARE @UserIds  TABLE (UserId  INT)
CREATE TABLE #FunctIds (FunctId INT)

-- Add new function
INSERT INTO dbo.AffFunctionInfo (FuncName, FuncNote, FuncDesc, FuncRender, DisplayOrder, Creator, ParentId, FileNames)
OUTPUT INSERTED.FuncId INTO #FunctIds(FunctId)
SELECT t.FuncName, t.FuncNote, t.FuncDesc, t.FuncRender, t.DisplayOrder, t.Creator, t.ParentId, t.FileNames
FROM (
	VALUES (N'[MarketingTeamNote]', '', N'Marketing Team Note', 3, '1', 1000000000, NULL, '')
) AS t(FuncName, FuncNote, FuncDesc, FuncRender, DisplayOrder, Creator, ParentId, FileNames)
	LEFT JOIN dbo.AffFunctionInfo ai WITH (NOLOCK) ON ai.FuncName = t.FuncName
WHERE ai.FuncName IS NULL


INSERT INTO @GroupIds (GroupId)
SELECT DISTINCT agh.GroupId
FROM dbo.AffGroupPolicy agh WITH (NOLOCK)

INSERT INTO @UserIds (UserId)
SELECT DISTINCT amp.CustId
FROM dbo.AffMemberPolicy amp  WITH (NOLOCK)

	
INSERT INTO dbo.AffGroupPolicy (GroupId, FuncId, Policy, CreateDate, ModifyDate, Creator)
SELECT t.GroupId
	  ,t.FunctId
	  ,0 AS [Policy]
	  ,SYSDATETIME() AS CreateDate
	  ,SYSDATETIME() AS ModifyDate
	  ,1000000000 AS Creator
FROM(
	SELECT g.GroupId, f.FunctId
	FROM #FunctIds f
		CROSS JOIN @GroupIds g
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
			CROSS JOIN #FunctIds f 
)t
		LEFT JOIN dbo.AffMemberPolicy ap WITH (NOLOCK) ON ap.CustId = t.UserId AND ap.FuncId = t.FunctId
WHERE ap.CustId IS NULL
GO