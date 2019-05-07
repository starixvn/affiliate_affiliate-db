/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_Con_GroupPolicySel]
	@Groupid INT
AS

/*
	DB: DBAFF.Affiliate_XXX

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
		- 20151113@Victor: Implement SSO from Internal Admin to Affiliate Admin [Redmine: #41437]
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_GroupInfo_Select
							AffAdmin_f_FunctionInfo_Select
							AffAdmin_f_GroupPolicy_Select
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @LicenseeID INT
	SELECT  @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'LicenseeID'

	DECLARE @sql NVARCHAR(MAX)
	DECLARE @tblGroups TABLE (LicenseeID INT, GroupID INT, GroupName NVARCHAR(50))

	SELECT @sql = 'SELECT LicenseeID, GroupID, GroupName FROM OPENQUERY(DBCUST,
								''SELECT LicenseeID, GroupID, GroupName FROM bodb_Licensee.dbo.AffAdmin_f_GroupInfo_Select(' + CONVERT(VARCHAR(10), @GroupID) + ','''''''')'')'

	INSERT INTO @tblGroups (LicenseeID, GroupID, GroupName)
	EXEC (@sql)

	DECLARE @IsIT BIT
	SELECT  @IsIT = CASE WHEN GroupName LIKE 'Aff_IT_Dept' THEN 1 ELSE 0 END
			,@LicenseeID = LicenseeID
	FROM @tblGroups

	DECLARE @FuncList TABLE (FunctionID INT, LicenseeID INT, FunctionName NVARCHAR(50), FunctionNote NVARCHAR(2000), FunctionDesc NVARCHAR(50), FunctionRender TINYINT, 
							CreateDate DATETIME, ModifyDate DATETIME, DisplayOrder TINYINT, Creator INT, ParentID INT, Filenames VARCHAR(2000))

	SELECT @sql = 'SELECT FunctionID, LicenseeID, FunctionName, FunctionNote, FunctionDesc, FunctionRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentID, Filenames
					FROM OPENQUERY(DBCUST,
								''SELECT FunctionID, LicenseeID, FunctionName, FunctionNote, FunctionDesc, FunctionRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentID, Filenames
								FROM bodb_Licensee.dbo.AffAdmin_f_FunctionInfo_Select('''''''',' + CONVERT(VARCHAR(10), @LicenseeID) + ')'')'

	INSERT INTO @FuncList (FunctionID, LicenseeID, FunctionName, FunctionNote, FunctionDesc, FunctionRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentID, Filenames)
	EXEC (@sql)

	DECLARE @tblGroupPolicy TABLE (FunctionID INT, policy TINYINT, createdate DATETIME, modifydate DATETIME)

	SELECT @sql = 'SELECT FunctionID, policy, createdate, modifydate FROM OPENQUERY(DBCUST,
								''SELECT FunctionID, policy, createdate, modifydate FROM bodb_Licensee.dbo.AffAdmin_f_GroupPolicy_Select(' + CONVERT(VARCHAR(10), @GroupID) + ','''''''')'')'

	INSERT INTO @tblGroupPolicy (FunctionID, policy, createdate, modifydate)
	EXEC (@sql)

	Declare @Tmp table(createdate smalldatetime, modifydate smalldatetime, gpolicy tinyint, groupid int
						, funcid int, groupname nvarchar(50), funcname nvarchar(50), funcdesc nvarchar(50)
						, parentid int, subfuncCount int, DisplayOrder int
						)

	Insert into @Tmp
	SELECT gp.createdate,gp.modifydate,ISNULL(gp.policy,0) AS policy,gi.groupid,fi.FunctionID,gi.groupname,fi.functionname
		,fi.functiondesc,fi.parentid ,count(fip.functionid) as SubFuncCount,fi.DisplayOrder
	FROM @FuncList fi
		left join @FuncList fip on fi.FunctionID = fip.ParentID and fip.parentid <> fip.functionid
		CROSS JOIN @tblGroups gi
		LEFT JOIN @tblGroupPolicy gp ON gp.FunctionID = fi.FunctionID
	group by gp.createdate,gp.modifydate,gp.policy,gi.groupid,fi.FunctionID,gi.groupname,fi.functionname
		,fi.functiondesc,fi.parentid, fi.DisplayOrder
	ORDER BY fi.parentid,count(fip.functionid) DESC, fi.DisplayOrder


	If (@IsIT = 0)
	Begin
		delete @Tmp
		where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
	End

	Select createdate, modifydate, gpolicy, groupid, funcid, groupname, funcname, funcdesc, parentid, subfuncCount, DisplayOrder
	from @Tmp
END
GO