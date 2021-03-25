/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_RolePermission_Ins]
	@UserId			INT
	,@RoleName		VARCHAR(100)
	,@Description	NVARCHAR(1000) = NULL
	,@Permission	XML
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
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]

	Param's Explanation:
		@Permission:
			<root>
				<r FuncId="1" Policy="1"/>
				<r FuncId="1" Policy="0"/>
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

	-- Check exists role
	IF NOT EXISTS (SELECT 1 FROM dbo.Roles WITH (NOLOCK) WHERE RoleName = @RoleName)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This role already exists!'
		RETURN
	END

	-- Insert process
	DECLARE @tblPermission TABLE (FuncId SMALLINT, Policy TINYINT)
	INSERT INTO @tblPermission (FuncId, Policy)
	SELECT t.c.value('@FuncId', 'SMALLINT') AS FuncId, t.c.value('@Policy', 'TINYINT') AS Policy
	FROM @Permission.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@Permission = NULL))

	IF EXISTS (SELECT 1 FROM @tblPermission WHERE Policy IS NULL OR Policy NOT IN (0, 1, 3))
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Invalid permission! Please try again.'
		RETURN
	END

	DECLARE @RoleId TINYINT

	BEGIN TRY
		INSERT INTO dbo.Roles (RoleName, Description, Creator)
		VALUES (@RoleName, @Description, @UserId)

		SELECT @RoleId = SCOPE_IDENTITY()

		INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy, Creator)
		SELECT @RoleId, f.FuncId, ISNULL(p.Policy, 0), @UserId
		FROM dbo.Functions f WITH (NOLOCK)
			LEFT JOIN @tblPermission p ON f.FuncId = p.FuncId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SELECT  @NewData = CONVERT(NVARCHAR(MAX),
					   (
							SELECT @RoleId	AS '@RoleId'
								   ,@RoleName AS '@RoleName'
								   ,CONVERT(XML, 
								    (
										SELECT
											f.FuncId	AS '@FuncId'
											,f.FuncName	AS '@FuncName'
											,rf.Policy	AS '@Policy'
										FROM dbo.RoleFunction rf WITH (NOLOCK)
											INNER JOIN dbo.Functions f WITH (NOLOCK) ON rf.FuncId = f.FuncId
										WHERE rf.RoleId = @RoleId
										ORDER BY f.FuncId
										FOR XML PATH('row')
									)) AS FunctionPolicy
							FOR XML PATH('row'), ROOT('root')
					    ))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
END
GO