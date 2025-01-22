/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_PolicySel]
	@UserId	INT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Get user permission on all functions

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/

BEGIN
	SET NOCOUNT ON

	;WITH CTE_Policy AS
	(
		SELECT
				ac.username,
				fi.funcname,
				(Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) AS actual_policy
		FROM	dbo.AffMemberPolicy mp WITH (nolock)
				INNER JOIN dbo.Affiliate_User ac WITH (nolock)  ON ac.custid = mp.custid
				INNER JOIN dbo.AffFunctionInfo fi WITH (nolock) ON mp.funcid = fi.funcid        
				INNER JOIN dbo.AffGroupPolicy gp WITH (nolock) ON gp.groupid = ac.groupid AND gp.funcid = mp.funcid
		WHERE   mp.custid = @UserId
	)
	SELECT
		UserName,
		FuncName,
		CASE WHEN actual_policy = 3 THEN 1 ELSE 0 END AS Host
	FROM CTE_Policy
	WHERE actual_policy <> 0
END
GO