/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_Batch_AdminPolicySel]
	@CustIDs nvarchar(4000),
	@GroupID int = NULL OUTPUT	
AS
/*
DB: DBAFFN88-Affiliate_N88	
Revisions:
 --DB03.bodb02 --> DB052.Affiliate_12BET
 -- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
 -- 20200220@Percy: Initialize SP for DBAFFN88-Affiliate_N88 [RedmineID: #128775]
*/

SET NOCOUNT ON
Select top 1 @GroupID = GroupID From Affiliate_user with(nolock) where Custid in (SELECT val FROM dbo.Aff_f_StringSplit(@CustIDs,','))

SELECT fi.funcid,fi.funcname, fi.funcdesc,f.policy ,gp.policy as gpolicy,fi.parentid ,count(fip.funcID) as SubFuncCount, fi.DisplayOrder
FROM AffFunctionInfo fi with(nolock) 
	INNER JOIN  
		(SELECT funcid,min(policy) as policy,ac.groupid as groupid
		FROM AffMemberPolicy mp with(nolock) inner join Affiliate_user ac with(nolock) on ac.custid=mp.custid
		WHERE mp.custid in (SELECT val FROM dbo.Aff_f_StringSplit(@CustIDs,','))
		GROUP BY mp.funcid,ac.groupid) f on fi.funcid=f.funcid
	INNER JOIN AffGroupPolicy gp with(nolock)	on gp.groupid=f.groupid and gp.funcID=f.funcID
	left join AffFunctionInfo fip with (nolock) on fi.funcID = fip.ParentID and fip.parentid <> fip.funcid
group by fi.funcid,fi.funcname, fi.funcdesc,f.policy ,gp.policy,fi.parentid, fi.DisplayOrder
ORDER BY fi.parentid, count(fip.funcID) DESC, fi.DisplayOrder
GO