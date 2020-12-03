/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_PolicySel]
	@UserId	INT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Get user permission on all functions

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	;WITH CTE_Policy AS
	(
		SELECT
				ac.username,
				fi.funcname,
				(Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) AS actual_policy
		FROM	AffMemberPolicy mp WITH (nolock)
				INNER JOIN affiliate_user ac WITH (nolock)  ON ac.custid = mp.custid
				INNER JOIN AffFunctionInfo fi WITH (nolock) ON mp.funcid = fi.funcid        
				INNER JOIN AffGroupPolicy gp WITH (nolock) ON gp.groupid = ac.groupid AND gp.funcid = mp.funcid
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