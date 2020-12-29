/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_RolePermission_Del]
	@UserId			INT
	,@RoleId		SMALLINT
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - Add role's permission

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

	-- Check exists role
	DECLARE @RoleName VARCHAR(100)
	SELECT  @RoleName = RoleName FROM dbo.Roles WITH (NOLOCK) WHERE RoleId = @RoleId
	
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This role does not exist!'
		RETURN
	END

	DECLARE @OldData NVARCHAR(MAX)
	SELECT  @OldData =
			'RoleId=' + CONVERT(VARCHAR(5), @RoleId) + ',' +
			'RoleName=' + @RoleName + ',' +
			'FunctionPolicy='	+ CONVERT(NVARCHAR(MAX),
									(
										SELECT
											f.FuncId	AS '@FuncId'
											,f.FuncName	AS '@FuncName'
											,rf.Policy	AS '@Policy'
										FROM dbo.RoleFunction rf WITH (NOLOCK)
											INNER JOIN dbo.Functions f WITH (NOLOCK) ON rf.FuncId = f.FuncId
										WHERE rf.RoleId = @RoleId
										ORDER BY f.FuncId
										FOR XML PATH('row'), ROOT('root')
									))

	-- Delete process
	BEGIN TRY
		DELETE dbo.Roles WITH (ROWLOCK, UPDLOCK)
		WHERE RoleId = @RoleId

		DELETE dbo.RoleFunction WITH (ROWLOCK, UPDLOCK)
		WHERE RoleId = @RoleId
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
		,@IP		= @IP
END
GO