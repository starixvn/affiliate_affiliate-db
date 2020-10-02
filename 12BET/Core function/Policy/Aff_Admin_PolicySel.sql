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
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	SELECT FuncId, FuncName, CASE WHEN Policy = 3 THEN 1 ELSE 0 END AS Host
	FROM (
		SELECT f.FuncId, f.FuncName, uf.Policy
		FROM dbo.Users u WITH (NOLOCK)
			INNER JOIN dbo.UserFunction uf WITH (NOLOCK) ON u.CustId = uf.CustId
			INNER JOIN dbo.Functions f WITH (NOLOCK) ON uf.FuncId = f.FuncId
		WHERE u.CustId = @UserId
	) t
	WHERE Policy > 0
END
GO