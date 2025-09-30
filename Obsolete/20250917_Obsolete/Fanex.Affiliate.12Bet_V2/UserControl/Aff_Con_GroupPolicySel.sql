ALTER PROCEDURE [dbo].[Aff_Con_GroupPolicySel]
	@Groupid int
AS 
/*DB03.BODB02 --> DB052.Affiliate_12BET*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
SET NOCOUNT ON
SELECT gp.createdate,gp.modifydate,gp.policy,gp.groupid,fi.funcid,gi.groupname,fi.funcname
	,fi.funcdesc,fi.parentid ,count(fip.funcID) as SubFuncCount,fi.DisplayOrder
FROM AffGroupPolicy gp with(nolock) 
INNER JOIN AffGroupInfo gi with(nolock) on gp.groupid=gi.groupid  
INNER JOIN AffFunctionInfo fi with(nolock) on gp.funcid=fi.funcid 
left join AffFunctionInfo fip with (nolock) on fi.funcID = fip.ParentID and fip.parentid <> fip.funcid
WHERE gp.groupid=@Groupid
group by gp.createdate,gp.modifydate,gp.policy,gp.groupid,fi.funcid,gi.groupname,fi.funcname
	,fi.funcdesc,fi.parentid, fi.DisplayOrder
ORDER BY fi.parentid,count(fip.funcID) DESC, fi.DisplayOrder



GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_GroupPolicySel] TO [vnteam]
go
GRANT EXECUTE ON [dbo].[Aff_Con_GroupPolicySel] TO [bodbAdminNet]