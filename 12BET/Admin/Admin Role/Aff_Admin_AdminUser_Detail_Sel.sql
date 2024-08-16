/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_Detail_Sel]
	@CustId INT
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - User detail
	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]
		- 20230330@Eddie: Change order of Bangladesh Language [RedmineID: #186108]
		- 20240819@Eddie: Hide Hindi Market [RedmineID: #209409]
	Note: Order of English always is 1st
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @RoleId SMALLINT
	SELECT  @RoleId = RoleId FROM dbo.Users u WITH (NOLOCK) WHERE CustId = @CustId

	-- General
	SELECT u.CustId,u.UserName,u.FirstName,u.LastName,u.Closed,r.RoleId,r.RoleName,u.IsRoleFunctionDefault,u.IsRoleMarketDefault
	FROM dbo.Users u WITH (NOLOCK)
		INNER JOIN dbo.Roles r WITH (NOLOCK) ON u.RoleId = r.RoleId
	WHERE CustId = @CustId

	-- Language
	;WITH CTE_Language AS(
		SELECT MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName,
			   CASE WHEN MarketId = 'en-US' THEN 1 ELSE 2 END AS TypeId
		FROM dbo.Market WITH (NOLOCK)
		WHERE MarketId <> 'hi'
	)
	SELECT m.MarketId, m.MarketName, CASE WHEN um.MarketId IS NULL THEN 0 ELSE 1 END AS Status
	FROM CTE_Language m
		LEFT JOIN dbo.UserMarket um WITH (NOLOCK) ON m.MarketId = um.MarketId AND um.CustId = @CustId
	ORDER BY m.TypeId, m.MarketId ASC

	-- Function
	SELECT f.AllParentIds, f.ParentId, f.FuncId, f.FuncName, f.DisplayName, ISNULL(rf.Policy, 0) AS RolePolicy, ISNULL(uf.Policy, 0) AS UserPolicy
	FROM dbo.Functions f WITH (NOLOCK)
		LEFT JOIN dbo.UserFunction uf WITH (NOLOCK) ON f.FuncId = uf.FuncId AND uf.CustId = @CustId
		LEFT JOIN dbo.RoleFunction rf WITH (NOLOCK) ON f.FuncId = rf.FuncId AND rf.RoleId = @RoleId
	ORDER BY f.OrderId
END
GO