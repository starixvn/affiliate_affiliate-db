/*<info serverAlias="DBCUST-bodb_Licensee" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Con_GroupPolicySel]
	@GroupId INT,
	@LicenseeID INT
AS
/*
	Created: 20240802@Sally
	DB: DBCUST-bodb_Licensee
	Task: Remove linked server to DBCust
	Orig: DBAFF-Affiliate_Athena000/dbo.AffAdmin_Con_GroupPolicySel

	Revisions:
		- 20240805@Sally: Initialize SP [RedmineID: #206891]

*/

BEGIN
	SET NOCOUNT ON;	

	DECLARE @IsIT BIT	
	DECLARE @tblGroups TABLE (LicenseeID INT, GroupID INT, GroupName NVARCHAR(50))

	INSERT INTO @tblGroups (LicenseeID, GroupID, GroupName)
	SELECT LicenseeID, GroupID, GroupName 
	FROM dbo.AffAdmin_f_GroupInfo_Select(@GroupID, '')

	SELECT @IsIT = CASE WHEN GroupName LIKE 'Aff_IT_Dept' THEN 1 ELSE 0 END
	FROM @tblGroups

	DECLARE @FuncList TABLE (FunctionID INT, LicenseeID INT, FunctionName NVARCHAR(50), FunctionNote NVARCHAR(2000), FunctionDesc NVARCHAR(50), FunctionRender TINYINT, 
							CreateDate DATETIME, ModifyDate DATETIME, DisplayOrder TINYINT, Creator INT, ParentID INT, Filenames VARCHAR(2000))

	INSERT INTO @FuncList (FunctionID, LicenseeID, FunctionName, FunctionNote, FunctionDesc, FunctionRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentID, Filenames)
	SELECT FunctionID, LicenseeID, FunctionName, FunctionNote, FunctionDesc, FunctionRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentID, Filenames 
	FROM dbo.AffAdmin_f_FunctionInfo_Select('', @LicenseeID)

	DECLARE @tblGroupPolicy TABLE (FunctionID INT, policy TINYINT, CreateDate DATETIME, ModifyDate DATETIME)

	INSERT INTO @tblGroupPolicy (FunctionID, policy, CreateDate, ModifyDate)
	SELECT FunctionID, policy, CreateDate, ModifyDate 
	FROM dbo.AffAdmin_f_GroupPolicy_Select(@GroupID, '')

	DECLARE @Tmp TABLE(CreateDate SMALLDATETIME, ModifyDate SMALLDATETIME,GPolicy TINYINT, GroupID INT
						,FuncId INT, GroupName NVARCHAR(50), FuncName NVARCHAR(50), FuncDesc NVARCHAR(50)
						,ParentId INT, SubFuncCount INT, DisplayOrder INT
					)

	INSERT INTO @Tmp (CreateDate, ModifyDate, gPolicy, GroupID, FuncId, GroupName, FuncName, FuncDesc, ParentId, SubFuncCount, DisplayOrder)
	SELECT gp.CreateDate, gp.ModifyDate, ISNULL(gp.policy,0) AS policy, gi.GroupID
		,fi.FunctionID, gi.GroupName, fi.FunctionName
		,fi.FunctionDesc, fi.ParentID, COUNT(fip.FunctionID) AS SubFuncCount, fi.DisplayOrder
	FROM @FuncList fi
		LEFT JOIN @FuncList fip ON fi.FunctionID = fip.ParentID AND fip.ParentID <> fip.FunctionID
		CROSS JOIN @tblGroups gi
		LEFT JOIN @tblGroupPolicy gp ON gp.FunctionID = fi.FunctionID
	GROUP BY gp.CreateDate, gp.ModifyDate, gp.policy, gi.GroupID
		,fi.FunctionID, gi.GroupName, fi.FunctionName
		,fi.FunctionDesc, fi.ParentID, fi.DisplayOrder
	ORDER BY fi.ParentID, COUNT(fip.FunctionID) DESC, fi.DisplayOrder

	IF (@IsIT = 0)
	BEGIN
		DELETE @Tmp
		WHERE FuncName IN ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
	END

	SELECT CreateDate, ModifyDate, gPolicy, GroupID, FuncId, GroupName, FuncName, FuncDesc, ParentId, SubFuncCount, DisplayOrder
	FROM @Tmp

END
GO