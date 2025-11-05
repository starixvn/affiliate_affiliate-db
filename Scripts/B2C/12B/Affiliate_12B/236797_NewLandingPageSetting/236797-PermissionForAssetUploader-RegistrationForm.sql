/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250903@Sally	
	Task: Landing Page Builder - Add Permission
	DB: DBAFF12B-Affiliate_12B
	
	Revisions:
		- 20250903@Sally: Created [RedmineID: #236797]

	Description:
		- Landing Page Builder - Add Permission
		- Link Generator - Add Permission
		- All Campaigns - Add Permission
		- Component Management - Add Permission
		- Asset Uploader - Add Permission
		- Registration Form Management - Add Permission
		
*/
USE Affiliate_12B
GO

-- Add new player function
INSERT INTO dbo.AffFunctionInfo (FuncName, FuncNote, FuncDesc, FuncRender, DisplayOrder, Creator, ParentId, FileNames)
SELECT t.FuncName, t.FuncNote, t.FuncDesc, t.FuncRender, t.DisplayOrder, t.Creator, t.ParentId, t.FileNames
FROM (
	VALUES (N'[AssetUploader]', '', N'Asset Management', 3, '1', 1000000000, NULL, ''),
		   (N'[RegistrationFormUploader]', '', N'Registration Form Management', 3, '1', 1000000000, NULL, ''),
		   (N'[PageBuilder]', 'Page Management permission: Cover tab Page Management & Page Builder', N'Page Management', 3, '1', 1000000000, NULL, ''),
		   (N'[LinkGenerator]', 'Link Generator permission: Cover tab Generate Link & Link Management', N'Link Generator', 3, '1', 1000000000, NULL, ''),
		   (N'[AllCampaigns]', '', N'All Campaigns', 3, '1', 1000000000, NULL, ''),
		   (N'[ComponentManagement]', '', N'Component Management', 3, '1', 1000000000, NULL, '')

) AS t(FuncName, FuncNote, FuncDesc, FuncRender, DisplayOrder, Creator, ParentId, FileNames)
	LEFT JOIN dbo.AffFunctionInfo ai WITH (NOLOCK) ON ai.FuncName = t.FuncName
WHERE ai.FuncName IS NULL

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
WHERE afi.FuncName IN (N'[AssetUploader]', N'[RegistrationFormUploader]', N'[PageBuilder]', N'[LinkGenerator]', N'[AllCampaigns]', N'[ComponentManagement]')

	
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