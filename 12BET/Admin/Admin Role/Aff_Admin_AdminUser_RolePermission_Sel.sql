/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_RolePermission_Sel]
	@RoleId SMALLINT = NULL
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - View role's permission

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	-- Policy: 0: Not allow, 1: Read, 3: Host
	SELECT r.RoleId,r.RoleName,f.AllParentIds,f.ParentId,f.FuncId,f.FuncName,rf.Policy
	FROM dbo.Roles r WITH (NOLOCK)
		INNER JOIN dbo.RoleFunction rf WITH (NOLOCK) ON r.RoleId = rf.RoleId
		INNER JOIN dbo.Functions f WITH (NOLOCK) ON rf.FuncId = f.FuncId
	WHERE ISNULL(@RoleId, 0) = 0 OR r.RoleId = @RoleId
	ORDER BY r.RoleId,f.ParentId,f.FuncId
END
GO