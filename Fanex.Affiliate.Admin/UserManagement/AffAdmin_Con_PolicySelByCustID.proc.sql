ALTER Procedure [dbo].[AffAdmin_Con_PolicySelByCustID]
	@LicenseeID INT,
    @CustID  INT,
    @GroupID INT  = NULL OUTPUT
AS
/*
	DB03.bodb02--> DB052.Affiliate_MYM
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
	-- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
*/
SET NOCOUNT ON

Declare @Tmp table(username varchar(50), funcname varchar(50), funcdesc nvarchar(50), funcid int, policy tinyint
	, gpolicy tinyint, actual_policy tinyint, parentid int, subfunccount int, displayorder int)

SELECT * INTO #AdminUser FROM dbo.AffAdmin_f_AdminUserInfo_Select(@CustID, @LicenseeID)
SELECT * INTO #FuncInfo FROM dbo.AffAdmin_FunctionInfo_Select('', @LicenseeID)
SELECT * INTO #GroupPolicy FROM dbo.AffAdmin_f_GroupPolicy_Select('','')
SELECT * INTO #UserPolicy FROM dbo.AffAdmin_f_UserPolicy_Select(@CustID, @LicenseeID,'')

insert into @Tmp
SELECT   ac.username,
       fi.functionname,
       fi.functiondesc,
       mp.functionid,
       mp.policy,
       gp.policy AS gpolicy,
       (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.functionrender,0) AS actual_policy,
       fi.parentid,
       COUNT(fip.functionid) AS subfunccount,
       fi.displayorder
FROM     #UserPolicy mp WITH (nolock)
       INNER JOIN #AdminUser ac WITH (nolock)  ON ac.userid = mp.userid
       INNER JOIN #FuncInfo fi WITH (nolock) ON mp.functionid = fi.functionid        
       INNER JOIN #GroupPolicy gp WITH (nolock) ON gp.groupid = ac.groupid AND gp.functionid = mp.functionid
       LEFT JOIN #FuncInfo fip WITH (nolock) ON fi.functionid = fip.parentid AND fip.parentid <> fip.functionid
GROUP BY ac.username,fi.functionname,fi.functiondesc,mp.functionid,
       mp.policy,fi.displayorder,gp.policy,fi.functionrender,
       fi.parentid
ORDER BY fi.parentid,
       COUNT(fip.functionid) DESC,
       fi.displayorder

SELECT @GroupID = groupid
FROM   dbo.AffAdmin_f_AdminUserInfo_Select(@CustID, @LicenseeID)


Declare @GroupIT varchar(50)

select @GroupIT = [dbo].AffAdmin_f_GetITGroupID(@LicenseeID)

if(@GroupID <> @GroupIT)
Begin
	--update @Tmp
	--set policy = 0, gpolicy = 0, actual_policy = 0
	--where funcname in ('[Resources]', '[SystemSettings]')
	delete @Tmp
	where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
End

Select * from @Tmp

DROP TABLE #AdminUser
DROP TABLE #FuncInfo
DROP TABLE #GroupPolicy
DROP TABLE #UserPolicy



