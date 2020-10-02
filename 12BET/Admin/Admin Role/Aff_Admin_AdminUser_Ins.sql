/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_Ins]
	@UserId					INT
	,@UserName				VARCHAR(50)
	,@FirstName				NVARCHAR(50) = NULL
	,@LastName				NVARCHAR(50) = NULL
	,@UserPwd				VARCHAR(100)
	,@RoleId				TINYINT
	,@Closed				BIT
	,@IsRoleFunctionDefault BIT = 0
	,@Function				XML = NULL
	,@IsRoleMarketDefault	BIT = 0
	,@Market				XML = NULL
	,@IP					VARCHAR(50) = ''
	,@ErrCode				INT = 0 OUTPUT
	,@ErrMsg				NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - Add new User

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]

	Param's Explanation:
		@Market:
			<root>
				<r MarketId="en" Status="1"/>
				<r MarketId="vi" Status="0"/>
			</root>
		@Function:
			<root>
				<r FuncId="1" Policy="1"/>
				<r FuncId="1" Policy="0"/>
			</root>
*/

BEGIN
	SET NOCOUNT ON

	SELECT @IsRoleFunctionDefault = ISNULL(@IsRoleFunctionDefault, 0)
			,@IsRoleMarketDefault = ISNULL(@IsRoleMarketDefault, 0)

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[UserControl]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Check exists username
	IF EXISTS (SELECT 1 FROM dbo.Users WITH (NOLOCK) WHERE UserName = @UserName AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This username is already exist!'
		RETURN
	END

	DECLARE @UserFunction TABLE (FuncId SMALLINT, Policy TINYINT)
	DECLARE @UserMarket TABLE (MarketId NVARCHAR(10), Status BIT)

	IF @IsRoleFunctionDefault = 1
	BEGIN
		INSERT INTO @UserFunction (FuncId, Policy)
		SELECT FuncId, Policy
		FROM dbo.RoleFunction WITH (NOLOCK)
		WHERE RoleId = @RoleId
	END
	ELSE IF @Function IS NOT NULL
	BEGIN
		INSERT INTO @UserFunction (FuncId, Policy)
		SELECT t.c.value('@FuncId', 'SMALLINT') AS FuncId
			,t.c.value('@Policy', 'TINYINT') AS Policy
		FROM @Function.nodes('root/r') t(c)
		OPTION (OPTIMIZE FOR (@Function = NULL))

		IF EXISTS (SELECT 1 FROM @UserFunction WHERE Policy IS NULL OR Policy NOT IN (0, 1, 3))
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Function setting is invalid!'
			RETURN
		END
	END

	IF @IsRoleMarketDefault = 1
	BEGIN
		INSERT INTO @UserMarket (MarketId, Status)
		SELECT MarketId, 1
		FROM dbo.RoleMarket WITH (NOLOCK)
		WHERE RoleId = @RoleId
	END
	ELSE IF @Market IS NOT NULL
	BEGIN
		INSERT INTO @UserMarket (MarketId, Status)
		SELECT t.c.value('@MarketId', 'NVARCHAR(10)') AS MarketId
			,t.c.value('@Status', 'BIT') AS Status
		FROM @Market.nodes('root/r') t(c)
		OPTION (OPTIMIZE FOR (@Market = NULL))
	END

	-- Insert process
	DECLARE @CustId INT
	DECLARE @NewFunction XML, @NewMarket XML

	BEGIN TRY
		INSERT INTO dbo.Users (UserName,RoleId,FirstName,LastName,UserPwd,Creator,Closed,IsRoleFunctionDefault,IsRoleMarketDefault)
		VALUES (@UserName,@RoleId,@FirstName,@LastName,@UserPwd,@UserId,@Closed,@IsRoleFunctionDefault,@IsRoleMarketDefault)

		SELECT @CustId = SCOPE_IDENTITY()

		INSERT INTO dbo.UserFunction (CustId,FuncId,Policy,CreatedDate,UpdatedDate,Creator)
		SELECT @CustId,FuncId,Policy,GETDATE(),GETDATE(),@UserId
		FROM @UserFunction

		INSERT INTO dbo.UserMarket (CustId,MarketId,Creator)
		SELECT @CustId,MarketId,@UserId
		FROM @UserMarket
		WHERE Status = 1

		SELECT @NewFunction = (
				SELECT
					f.FuncId	AS '@FuncId'
					,f.FuncName AS '@FuncName'
					,uf.Policy	AS '@Policy'
				FROM dbo.UserFunction uf WITH (NOLOCK)
					INNER JOIN dbo.Functions f WITH (NOLOCK) ON uf.FuncId = f.FuncId
				WHERE CustId = @CustId
				ORDER BY f.FuncId
				FOR XML PATH('row'), ROOT('root')
			)

		SELECT @NewMarket = (
				SELECT
					m.MarketId AS '@MarketId'
					,m.MarketName AS '@MarketName'
					,m.DisplayName AS '@DisplayName'
					,CASE WHEN um.MarketId IS NULL THEN 0 ELSE 1 END AS '@Status'
				FROM dbo.Market m WITH (NOLOCK)
					LEFT JOIN dbo.UserMarket um WITH (NOLOCK) ON um.MarketId = m.MarketId AND um.CustId = @CustId
				ORDER BY m.MarketId
				FOR XML PATH('row'), ROOT('root')
			)
	END TRY
	BEGIN CATCH
		DELETE dbo.Users WHERE CustId = @CustId
		DELETE dbo.UserMarket WHERE CustId = @CustId

		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH
	
	-- Write log
	DECLARE @SPName VARCHAR(200), @NewData NVARCHAR(MAX)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @NewData = CONVERT(NVARCHAR(MAX), (
				SELECT
					u.CustId					AS '@CustId'
					,u.UserName					AS '@UserName'
					,u.FirstName				AS '@FirstName'
					,u.LastName					AS '@LastName'
					,r.RoleId					AS '@RoleId'
					,r.RoleName					AS '@RoleName'
					,u.Closed					AS '@Closed'
					,u.IsRoleFunctionDefault	AS '@IsRoleFunctionDefault'
					,u.IsRoleMarketDefault		AS '@IsRoleMarketDefault'
				FROM dbo.Users u WITH (NOLOCK)
					INNER JOIN dbo.Roles r WITH (NOLOCK) ON u.RoleId = r.RoleId
				WHERE u.CustId = @CustId AND u.IsDeleted = 0
				FOR XML PATH('row'), ROOT('root')
			))

	SELECT @NewData = @NewData  + ',FunctionPolicy=' + CONVERT(VARCHAR(MAX), @NewFunction)
								+ ',MarketPolicy=' + CONVERT(VARCHAR(MAX), @NewMarket)
		
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
END
GO