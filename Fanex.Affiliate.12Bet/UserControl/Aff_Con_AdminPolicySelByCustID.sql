ALTER PROCEDURE [dbo].[Aff_Con_AdminPolicySelByCustID]
			   @CustID  INT,
			   @GroupID INT  = NULL OUTPUT
AS
/*
	DB03.bodb02--> DB052.Affiliate_12BET
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
*/
SET NOCOUNT ON
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
	   INNER JOIN affiliate_user ac WITH (nolock)  ON ac.custid = mp.custid
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
FROM   affiliate_user with (nolock) where custid=@CustID


GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminPolicySelByCustID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminPolicySelByCustID] TO [bodbadminnet]