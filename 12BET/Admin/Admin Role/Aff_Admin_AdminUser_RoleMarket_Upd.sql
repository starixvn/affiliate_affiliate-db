/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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
		,@FuncName	= '[AdminRole]'
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