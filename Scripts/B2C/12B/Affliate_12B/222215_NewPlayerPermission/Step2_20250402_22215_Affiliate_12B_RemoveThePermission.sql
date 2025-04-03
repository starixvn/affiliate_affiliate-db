/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250402@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Add new Player permission [RedmineID: #222215]
	-- Step 2: Remove the permission
*/

USE Affiliate_12B
GO

-- Remove the permission

DECLARE @FunctIds TABLE (FunctId INT)

INSERT INTO @FunctIds (FunctId)
SELECT afi.FuncId
FROM dbo.AffFunctionInfo afi WITH (NOLOCK)
WHERE afi.FuncName IN ('[AffEx.Rate]','[ActiveMembers]')

DELETE agh
FROM dbo.AffGroupPolicy agh WITH (ROWLOCK, UPDLOCK)
	INNER JOIN @FunctIds s ON s.FunctId = agh.FuncId


DELETE agh
FROM dbo.AffMemberPolicy agh WITH (ROWLOCK, UPDLOCK)
	INNER JOIN @FunctIds s ON s.FunctId = agh.FuncId


DELETE agh
FROM dbo.AffFunctionInfo agh WITH (ROWLOCK, UPDLOCK)
	INNER JOIN @FunctIds s ON s.FunctId = agh.FuncId
GO
