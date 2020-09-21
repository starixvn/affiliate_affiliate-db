/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_GroupPolicySel]
	@Groupid int
AS 
/*
DB: DBAFFN8G-Affiliate_N8G	
Revisions:
	--DB03.BODB02 --> DB052.Affiliate_12BET
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- 20200220@Percy: Initialize SP for DBAFFN8G-Affiliate_N8G [RedmineID: #128775]

*/

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