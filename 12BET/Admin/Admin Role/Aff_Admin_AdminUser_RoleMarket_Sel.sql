/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_RoleMarket_Sel]
	@RoleId SMALLINT = NULL
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - View role's market

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]
		- 20230330@Eddie: Change order of Bangladesh Language [RedmineID: #186108]
		- 20240820@Eddie: Hide Hindi Market [RedmineID: #209409]
	Note: Order of English always is 1st
*/

BEGIN
	SET NOCOUNT ON

	-- Policy: 0: Not allow, 1: Read, 3: Host
	IF ISNULL(@RoleId, 0) = 0
	BEGIN
		;WITH CTE_Language AS(
			SELECT MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName,
				   CASE WHEN MarketId = 'en-US' THEN 1 ELSE 2 END AS TypeId
			FROM dbo.Market WITH (NOLOCK)
			WHERE MarketId <> 'hi'
		)		
		SELECT r.RoleId, m.MarketId, m.MarketName, CASE WHEN rm.RoleId IS NULL THEN 0 ELSE 1 END AS Status
		FROM dbo.Roles r WITH (NOLOCK)
			CROSS JOIN CTE_Language m 
			LEFT JOIN dbo.RoleMarket rm WITH (NOLOCK) ON r.RoleId = rm.RoleId AND m.MarketId = rm.MarketId
		ORDER BY r.RoleId, m.TypeId, m.MarketId ASC
	END
	ELSE
	BEGIN
		;WITH CTE_Language AS(
			SELECT MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName,
				   CASE WHEN MarketId = 'en-US' THEN 1 ELSE 2 END AS TypeId
			FROM dbo.Market WITH (NOLOCK)
			WHERE MarketId <> 'hi'
		)
		SELECT @RoleId AS RoleId, m.MarketId, m.MarketName, CASE WHEN rm.RoleId IS NULL THEN 0 ELSE 1 END AS Status
		FROM CTE_Language m
			LEFT JOIN dbo.RoleMarket rm WITH (NOLOCK) ON m.MarketId = rm.MarketId AND rm.RoleId = @RoleId
		ORDER BY m.TypeId, m.MarketId ASC
	END
END
GO