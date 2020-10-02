/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_RolePermission_Upd]
	@UserId			INT
	,@Permission	XML
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - Update role's permission

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]

	Param's Explanation:
		@Permission:
			<root>
				<r RoleId="1" FuncId="1" Policy="1"/>
				<r RoleId="1" FuncId="1" Policy="0"/>
				<r RoleId="2" FuncId="1" Policy="1"/>
				<r RoleId="2" FuncId="1" Policy="0"/>
			</root>
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

	-- Update process
	DECLARE @tblPermission TABLE (RoleId TINYINT, FuncId SMALLINT, Policy TINYINT)
	INSERT INTO @tblPermission (RoleId, FuncId, Policy)
	SELECT t.c.value('@RoleId', 'TINYINT') AS FuncId
		,t.c.value('@FuncId', 'SMALLINT') AS FuncId
		,t.c.value('@Policy', 'TINYINT') AS Policy
	FROM @Permission.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@Permission = NULL))

	IF EXISTS (SELECT 1 FROM @tblPermission WHERE Policy IS NULL OR Policy NOT IN (0, 1, 3))
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Invalid permission! Please try again.'
		RETURN
	END

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	SELECT  @OldData = CONVERT(NVARCHAR(MAX),
			(
				SELECT
					r.RoleId	AS '@RoleId'
					,r.RoleName AS '@RoleName'
					,f.FuncId	AS '@FuncId'
					,f.FuncName	AS '@FuncName'
					,rf.Policy	AS '@Policy'
				FROM dbo.RoleFunction rf WITH (NOLOCK)
					INNER JOIN @tblPermission p ON rf.FuncId = p.FuncId AND rf.RoleId = p.RoleId
					INNER JOIN dbo.Functions f WITH (NOLOCK) ON rf.FuncId = f.FuncId
					INNER JOIN dbo.Roles r WITH (NOLOCK) ON r.RoleId = rf.RoleId
				ORDER BY r.RoleId, f.FuncId
				FOR XML PATH('row'), ROOT('root')
			))
			,@NewData = CONVERT(NVARCHAR(MAX),
			(
				SELECT
					r.RoleId	AS '@RoleId'
					,r.RoleName AS '@RoleName'
					,f.FuncId	AS '@FuncId'
					,f.FuncName	AS '@FuncName'
					,p.Policy	AS '@Policy'
				FROM dbo.RoleFunction rf WITH (NOLOCK)
					INNER JOIN @tblPermission p ON rf.FuncId = p.FuncId AND rf.RoleId = p.RoleId
					INNER JOIN dbo.Functions f WITH (NOLOCK) ON rf.FuncId = f.FuncId
					INNER JOIN dbo.Roles r WITH (NOLOCK) ON r.RoleId = rf.RoleId
				ORDER BY r.RoleId, f.FuncId
				FOR XML PATH('row'), ROOT('root')
			))

	IF ISNULL(@OldData, '') = ISNULL(@NewData, '')
		RETURN

	BEGIN TRY
		UPDATE rf WITH (ROWLOCK)
		SET rf.Policy = p.Policy
		FROM dbo.RoleFunction rf
			INNER JOIN @tblPermission p ON rf.FuncId = p.FuncId AND rf.RoleId = p.RoleId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
END
GO