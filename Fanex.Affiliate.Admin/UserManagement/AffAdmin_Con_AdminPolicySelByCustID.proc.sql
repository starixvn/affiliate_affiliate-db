/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_Con_AdminPolicySelByCustID] 
	@LicenseeID INT,
	@CustID		INT,  
    @GroupID	INT  = NULL OUTPUT  
AS

/*
	DB: DBCUST.bodb_Licensee

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
		- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SET NOCOUNT ON

	Declare @Tmp table(username varchar(50), funcname varchar(50), funcdesc nvarchar(50), funcid int, policy tinyint  
	 , gpolicy tinyint, actual_policy tinyint, parentid int, subfunccount int, displayorder int)  

	SELECT userid, username, groupid
	INTO #AdminUser
	FROM dbo.AffAdmin_f_AdminUserInfo_Select(@CustID, @LicenseeID)
	
	SELECT functionid, functionname, functiondesc, functionrender, parentid, displayorder
	INTO #FuncInfo
	FROM dbo.AffAdmin_f_FunctionInfo_Select('',@LicenseeID)
	
	SELECT groupid, functionid, policy
	INTO #GroupPolicy
	FROM dbo.AffAdmin_f_GroupPolicy_Select('','')

	SELECT userid, functionid, policy
	INTO #UserPolicy
	FROM dbo.AffAdmin_f_UserPolicy_Select(@CustID,@LicenseeID,'')

	insert into @Tmp  
	SELECT   ac.username,
		   fi.functionname,
		   fi.functiondesc,
		   fi.functionid,
		   ISNULL(mp.policy,0) AS policy,
		   ISNULL(gp.policy,0) AS gpolicy,
		   (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.functionrender,0) AS actual_policy,
		   fi.parentid,
		   COUNT(fip.functionid) AS subfunccount,
		   fi.displayorder
	FROM    #AdminUser ac WITH (nolock)
			CROSS JOIN #FuncInfo fi WITH (nolock)
			LEFT JOIN #FuncInfo fip WITH (nolock) ON fi.functionid = fip.parentid AND fip.parentid <> fip.functionid
			LEFT JOIN #UserPolicy mp WITH (nolock) ON mp.userid = ac.userid AND mp.functionID = fi.functionID
			LEFT JOIN #GroupPolicy gp WITH (nolock) ON gp.groupid = ac.groupid AND gp.functionid = fi.functionid
	GROUP BY ac.username,fi.functionname,fi.functiondesc,fi.functionid,
		   mp.policy,fi.displayorder,gp.policy,fi.functionrender,
		   fi.parentid
	ORDER BY fi.parentid,
		   COUNT(fip.functionid) DESC,
		   fi.displayorder
  
	SELECT @GroupID = groupid
	FROM   dbo.AffAdmin_f_AdminUserInfo_Select(@CustID, @LicenseeID)
  
  
	DECLARE @GroupIT VARCHAR(50)  
	SELECT  @GroupIT = dbo.AffAdmin_f_GetITGroupID(@LicenseeID)  
  
	if(@GroupID <> @GroupIT)
	Begin
		delete @Tmp
		where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')  
	End
  
	Select username, funcname, funcdesc, funcid, policy  
		,gpolicy, actual_policy, parentid, subfunccount, displayorder
	from @Tmp

	DROP TABLE #AdminUser
	DROP TABLE #FuncInfo
	DROP TABLE #GroupPolicy
	DROP TABLE #UserPolicy
END
GO