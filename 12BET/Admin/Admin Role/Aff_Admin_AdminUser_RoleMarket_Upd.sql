/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_RoleMarket_Upd]
	@UserId		INT
	,@Market	XML
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - Update role's market

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]
		- 20240819@Eddie: Hide Hindi Market [RedmineID: #209409]

	Param's Explanation:
		@Market:
			<root>
				<r RoleId="1" MarketId="en" Status="1"/>
				<r RoleId="1" MarketId="vi" Status="0"/>
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

	DECLARE @RoleMarket TABLE (RoleId TINYINT, MarketId NVARCHAR(10), Status BIT)
	INSERT INTO @RoleMarket (RoleId, MarketId, Status)
	SELECT t.c.value('@RoleId', 'TINYINT') AS RoleId
		,t.c.value('@MarketId', 'NVARCHAR(10)') AS MarketId
		,t.c.value('@Status', 'BIT') AS Status
	FROM @Market.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@Market = NULL))

	IF NOT EXISTS (SELECT 1 FROM @RoleMarket)
		RETURN

	-- Update process
	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	SELECT  @OldData = CONVERT(NVARCHAR(MAX), (
				SELECT	r.RoleId AS '@RoleId'
						,r.RoleName AS '@RoleName'
						,m.MarketId AS '@MarketId'
						,m.MarketName AS '@MarketName'
						,m.DisplayName AS '@DisplayName'
						,CASE WHEN rm.RoleId IS NULL THEN 0 ELSE 1 END AS '@Status'
				FROM dbo.Market m WITH (NOLOCK)
					CROSS JOIN dbo.Roles r WITH (NOLOCK)
					LEFT JOIN dbo.RoleMarket rm WITH (NOLOCK) ON rm.MarketId = m.MarketId AND rm.RoleId = r.RoleId
				WHERE m.MarketId <> 'hi'
				ORDER BY r.RoleId, m.MarketId
				FOR XML PATH('row'), ROOT('root')
			))
			,@NewData = CONVERT(NVARCHAR(MAX), (
				SELECT	r.RoleId AS '@RoleId'
						,r.RoleName AS '@RoleName'
						,m.MarketId AS '@MarketId'
						,m.MarketName AS '@MarketName'
						,m.DisplayName AS '@DisplayName'
						,CASE WHEN rm.RoleId IS NULL THEN 0 ELSE 1 END AS '@Status'
				FROM dbo.Market m WITH (NOLOCK)
					CROSS JOIN dbo.Roles r WITH (NOLOCK)
					LEFT JOIN @RoleMarket rm ON rm.MarketId = m.MarketId AND rm.RoleId = r.RoleId
				WHERE m.MarketId <> 'hi'
				ORDER BY r.RoleId, m.MarketId
				FOR XML PATH('row'), ROOT('root')
			))

	IF ISNULL(@OldData, '') = ISNULL(@NewData, '')
		RETURN

	BEGIN TRY
		DELETE dbo.RoleMarket WITH (ROWLOCK, UPDLOCK)
		WHERE RoleId IN (SELECT RoleId FROM @RoleMarket)

		INSERT INTO dbo.RoleMarket (RoleId, MarketId)
		SELECT RoleId, MarketId FROM @RoleMarket WHERE Status = 1
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