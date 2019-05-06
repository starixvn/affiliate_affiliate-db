/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_Con_Batch_PolicySel]
	@LicenseeID INT,
	@CustIDs	NVARCHAR(4000),
	@GroupID	INT = NULL OUTPUT	
AS

/*
	DB: DBCUST.bodb_Licensee

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
		- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN

	SET NOCOUNT ON

	SELECT userid, username, groupid
	INTO #AdminUser
	FROM dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID)
	
	SELECT functionid, functionname, functiondesc, functionrender, parentid, displayorder
	INTO #FuncInfo
	FROM dbo.AffAdmin_f_FunctionInfo_Select('',@LicenseeID)
	
	SELECT groupid, functionid, policy
	INTO #GroupPolicy
	FROM dbo.AffAdmin_f_GroupPolicy_Select('','')

	SELECT userid, functionid, policy
	INTO #UserPolicy
	FROM dbo.AffAdmin_f_UserPolicy_Select('',@LicenseeID,'')

	SELECT TOP 1 @GroupID = GroupID FROM #AdminUser WHERE UserID IN (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))

	Declare @Tmp table(funcid int, funcname varchar(50), funcdesc varchar(50), policy tinyint, gpolicy tinyint, parentid int, SubFuncCount int, DisplayOrder int)

	insert into @Tmp
	SELECT fi.functionID,fi.functionname, fi.functiondesc,ISNULL(f.policy,0) AS policy ,ISNULL(gp.policy,0) as gpolicy,fi.parentid ,count(fip.functionID) as SubFuncCount, fi.DisplayOrder
	FROM #FuncInfo fi with(nolock) 
		LEFT JOIN  
			(SELECT functionID,min(policy) as policy,ac.groupid as groupid
			FROM #UserPolicy mp
				inner join #AdminUser ac on ac.userid=mp.userid
			WHERE mp.userid in (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))
			GROUP BY mp.functionID,ac.groupid) f on fi.functionID=f.functionID
		LEFT JOIN #GroupPolicy gp on gp.groupid=@GroupID and gp.functionID=fi.functionID
		left join #FuncInfo fip on fi.functionID = fip.ParentID and fip.parentid <> fip.functionID
	group by fi.functionID,fi.functionname, fi.functiondesc,f.policy ,gp.policy,fi.parentid, fi.DisplayOrder
	ORDER BY fi.parentid, count(fip.functionID) DESC, fi.DisplayOrder

	Declare @GroupIT varchar(50)
	select  @GroupIT = [dbo].AffAdmin_f_GetITGroupID(@LicenseeID)

	if(@GroupID <> @GroupIT)
	Begin
		delete @Tmp
		where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
	End

	Select funcid, funcname, funcdesc, policy, gpolicy, parentid, SubFuncCount, DisplayOrder
	from @Tmp

	DROP TABLE #AdminUser
	DROP TABLE #FuncInfo
	DROP TABLE #GroupPolicy
	DROP TABLE #UserPolicy
END
GO