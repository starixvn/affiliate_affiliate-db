ALTER PROCEDURE [dbo].[AffAdmin_Con_Batch_PolicySel]
	@LicenseeID INT,
	@CustIDs nvarchar(4000),
	@GroupID int = NULL OUTPUT	
AS
--DB03.bodb02 --> DB052.Affiliate_MYM
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
-- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site

SET NOCOUNT ON

SELECT * INTO #AdminUser FROM dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID)
SELECT TOP 1 @GroupID = GroupID FROM #AdminUser WHERE UserID IN (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))

SELECT * INTO #FuncInfo FROM dbo.AffAdmin_f_FunctionInfo_Select('',@LicenseeID)
SELECT * INTO #GroupPolicy FROM dbo.AffAdmin_f_GroupPolicy_Select(@GroupID,'')
SELECT * INTO #UserPolicy FROM dbo.AffAdmin_f_UserPolicy_Select('',@LicenseeID,'')

Declare @Tmp table(funcid int, funcname varchar(50), funcdesc varchar(50), policy tinyint, gpolicy tinyint, parentid int, SubFuncCount int, DisplayOrder int)


insert into @Tmp
SELECT fi.functionID,fi.functionname, fi.functiondesc,ISNULL(f.policy,0) AS policy ,ISNULL(gp.policy,0) as gpolicy,fi.parentid ,count(fip.functionID) as SubFuncCount, fi.DisplayOrder
FROM #FuncInfo fi with(nolock) 
	LEFT JOIN  
		(SELECT functionID,min(policy) as policy,ac.groupid as groupid
		FROM #UserPolicy mp with(nolock) 
			inner join #AdminUser ac with(nolock) on ac.userid=mp.userid
		WHERE mp.userid in (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))
		GROUP BY mp.functionID,ac.groupid) f on fi.functionID=f.functionID
	LEFT JOIN #GroupPolicy gp with(nolock)	on gp.groupid=@GroupID and gp.functionID=fi.functionID
	left join #FuncInfo fip with (nolock) on fi.functionID = fip.ParentID and fip.parentid <> fip.functionID
group by fi.functionID,fi.functionname, fi.functiondesc,f.policy ,gp.policy,fi.parentid, fi.DisplayOrder
ORDER BY fi.parentid, count(fip.functionID) DESC, fi.DisplayOrder

Declare @GroupIT varchar(50)

select @GroupIT = [dbo].AffAdmin_f_GetITGroupID(@LicenseeID)

if(@GroupID <> @GroupIT)
Begin
	delete @Tmp
	where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
End

Select * from @Tmp

DROP TABLE #AdminUser
DROP TABLE #FuncInfo
DROP TABLE #GroupPolicy
DROP TABLE #UserPolicy
GO
GRANT EXECUTE ON [dbo].[AffAdmin_Con_Batch_PolicySel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_Con_Batch_PolicySel] TO [vnteam] AS [dbo]