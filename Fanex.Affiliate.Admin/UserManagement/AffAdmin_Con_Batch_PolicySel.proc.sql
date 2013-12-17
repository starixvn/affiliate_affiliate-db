ALTER Procedure [dbo].[AffAdmin_Con_Batch_PolicySel]
	@CustIDs nvarchar(4000),
	@GroupID int = NULL OUTPUT	
AS
--DB03.bodb02 --> DB052.Affiliate_MYM
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM

SET NOCOUNT ON
Select top 1 @GroupID = GroupID From AdminUser with(nolock) where Custid in (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))
Declare @Tmp table(funcid int, funcname varchar(50), funcdesc varchar(50), policy tinyint, gpolicy tinyint, parentid int, SubFuncCount int, DisplayOrder int)

insert into @Tmp
SELECT fi.funcid,fi.funcname, fi.funcdesc,f.policy ,gp.policy as gpolicy,fi.parentid ,count(fip.funcID) as SubFuncCount, fi.DisplayOrder
FROM AffFunctionInfo fi with(nolock) 
	INNER JOIN  
		(SELECT funcid,min(policy) as policy,ac.groupid as groupid
		FROM AffMemberPolicy mp with(nolock) inner join AdminUser ac with(nolock) on ac.custid=mp.custid
		WHERE mp.custid in (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))
		GROUP BY mp.funcid,ac.groupid) f on fi.funcid=f.funcid
	INNER JOIN AffGroupPolicy gp with(nolock)	on gp.groupid=f.groupid and gp.funcID=f.funcID
	left join AffFunctionInfo fip with (nolock) on fi.funcID = fip.ParentID and fip.parentid <> fip.funcid
group by fi.funcid,fi.funcname, fi.funcdesc,f.policy ,gp.policy,fi.parentid, fi.DisplayOrder
ORDER BY fi.parentid, count(fip.funcID) DESC, fi.DisplayOrder

Declare @GroupIT varchar(50)

select @GroupIT = [dbo].[Aff_Con_GetGroupItID]()

if(@GroupID <> @GroupIT)
Begin
	delete @Tmp
	where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
End

Select * from @Tmp


