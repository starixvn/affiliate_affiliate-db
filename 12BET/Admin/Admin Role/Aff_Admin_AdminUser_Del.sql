/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_Del]
	@UserId		INT
	,@CustIds	VARCHAR(MAX)
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - Delete User

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[UserControl]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE @Users TABLE (CustId INT)
	INSERT INTO @Users (CustId)
	SELECT val FROM dbo.Aff_f_StringSplit(@UserId, ',')

	-- Update process
	BEGIN TRY
		UPDATE u WITH (ROWLOCK)
		SET u.IsDeleted = 1
		FROM dbo.Users u
			INNER JOIN @Users t ON u.CustId = t.CustId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200), @OldData NVARCHAR(MAX)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @OldData = CONVERT(NVARCHAR(MAX), (
				SELECT
					u.CustId		AS '@CustId'
					,u.UserName		AS '@UserName'
					,u.FirstName	AS '@FirstName'
					,u.LastName		AS '@LastName'
					,r.RoleId		AS '@RoleId'
					,r.RoleName		AS '@RoleName'
					,u.Closed		AS '@Closed'
				FROM dbo.Users u WITH (NOLOCK)
					INNER JOIN @Users t ON u.CustId = t.CustId
					INNER JOIN dbo.Roles r WITH (NOLOCK) ON u.RoleId = r.RoleId
				WHERE u.IsDeleted = 1
				ORDER BY u.CustId, r.RoleId
				FOR XML PATH('row'), ROOT('root')
			))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@IP		= @IP
END
GO