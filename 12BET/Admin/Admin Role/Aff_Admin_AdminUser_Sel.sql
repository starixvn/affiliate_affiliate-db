/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_Sel]
	@Username VARCHAR(50) = ''
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - User list

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	SELECT u.CustId,u.UserName,u.FirstName,u.LastName,ISNULL(c.UserName, '') AS Creator,u.LastLoginDate,u.LastLoginIP,u.Closed,r.RoleName
	FROM dbo.Users u WITH (NOLOCK)
		INNER JOIN dbo.Roles r WITH (NOLOCK) ON u.RoleId = r.RoleId
		LEFT JOIN dbo.Users c WITH (NOLOCK) ON u.Creator = c.CustId
	WHERE u.UserName LIKE '%' + ISNULL(@Username, '') + '%'
		AND u.IsDeleted = 0
	ORDER BY u.Closed, u.RoleId, u.UserName
END
GO