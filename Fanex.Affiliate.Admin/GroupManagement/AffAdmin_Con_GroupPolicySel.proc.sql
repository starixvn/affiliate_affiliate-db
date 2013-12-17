ALTER Procedure [dbo].[AffAdmin_Con_GroupPolicySel]
	@Groupid int
AS 
/*DB03.BODB02 --> DB052.Affiliate_MYM*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
SET NOCOUNT ON

declare @GroupIT int
Select @GroupIt = [dbo].[Aff_Con_GetGroupItID]()

Declare @Tmp table(createdate smalldatetime, modifydate smalldatetime, gpolicy tinyint, groupid int
					, funcid int, groupname nvarchar(50), funcname nvarchar(50), funcdesc nvarchar(50)
					, parentid int, subfuncCount int, DisplayOrder int
					)

Insert into @Tmp
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

If (@Groupid <> @GroupIT)
Begin
	delete @Tmp
	where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
End

Select * from @Tmp



