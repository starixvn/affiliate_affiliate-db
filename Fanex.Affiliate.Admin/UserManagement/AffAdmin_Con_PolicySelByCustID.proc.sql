ALTER Procedure [dbo].[AffAdmin_Con_PolicySelByCustID]
               @CustID  INT,
               @GroupID INT  = NULL OUTPUT
AS
/*
	DB03.bodb02--> DB052.Affiliate_MYM
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
*/
SET NOCOUNT ON

Declare @Tmp table(username varchar(50), funcname varchar(50), funcdesc nvarchar(50), funcid int, policy tinyint
	, gpolicy tinyint, actual_policy tinyint, parentid int, subfunccount int, displayorder int)

insert into @Tmp
SELECT   ac.username,
       fi.funcname,
       fi.funcdesc,
       mp.funcid,
       mp.policy,
       gp.policy AS gpolicy,
       (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) AS actual_policy,
       fi.parentid,
       COUNT(fip.funcid) AS subfunccount,
       fi.displayorder
FROM     AffMemberPolicy mp WITH (nolock)
       INNER JOIN AdminUser ac WITH (nolock)  ON ac.custid = mp.custid
       INNER JOIN AffFunctionInfo fi WITH (nolock) ON mp.funcid = fi.funcid        
       INNER JOIN AffGroupPolicy gp WITH (nolock) ON gp.groupid = ac.groupid AND gp.funcid = mp.funcid
       LEFT JOIN AffFunctionInfo fip WITH (nolock) ON fi.funcid = fip.parentid AND fip.parentid <> fip.funcid
WHERE    mp.custid = @CustID
GROUP BY ac.username,fi.funcname,fi.funcdesc,mp.funcid,
       mp.policy,fi.displayorder,gp.policy,fi.funcrender,
       fi.parentid
ORDER BY fi.parentid,
       COUNT(fip.funcid) DESC,
       fi.displayorder

SELECT @GroupID = groupid
FROM   AdminUser with (nolock) where custid=@CustID


Declare @GroupIT varchar(50)

select @GroupIT = [dbo].[Aff_Con_GetGroupItID]()

if(@GroupID <> @GroupIT)
Begin
	--update @Tmp
	--set policy = 0, gpolicy = 0, actual_policy = 0
	--where funcname in ('[Resources]', '[SystemSettings]')
	delete @Tmp
	where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
End

Select * from @Tmp



