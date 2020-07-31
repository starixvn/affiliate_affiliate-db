/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_RoleMarket_Sel]
	@RoleId SMALLINT = NULL
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - View role's market

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	-- Policy: 0: Not allow, 1: Read, 3: Host
	IF ISNULL(@RoleId, 0) = 0
		SELECT r.RoleId, m.MarketId, m.MarketName, CASE WHEN rm.RoleId IS NULL THEN 0 ELSE 1 END AS Status
		FROM dbo.Roles r WITH (NOLOCK)
			CROSS JOIN dbo.Market m WITH (NOLOCK)
			LEFT JOIN dbo.RoleMarket rm WITH (NOLOCK) ON r.RoleId = rm.RoleId AND m.MarketId = rm.MarketId
	ELSE
		SELECT @RoleId AS RoleId, m.MarketId, m.MarketName, CASE WHEN rm.RoleId IS NULL THEN 0 ELSE 1 END AS Status
		FROM dbo.Market m WITH (NOLOCK)
			LEFT JOIN dbo.RoleMarket rm WITH (NOLOCK) ON m.MarketId = rm.MarketId AND rm.RoleId = @RoleId
END
GO