/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_AdminUpdClosed]
	@CustID INT,
	@Closed BIT,
	@UserID INT,
	@Language VARCHAR(2) = 'E',
	@IP VARCHAR(15) = '',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT	
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet

	Revisions:
		--DB03.bodb02(Move this SP from DB02.bodb02 to DB03.bodb02) --> DB052.Affiliate_12BET
		-- VinhTrinh@20100507: update closed field in table affiliate_user(instead of CustInfo)
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET	
		- 20240115@Sally: Initialize SP for Affiliate_YashBet [RedmineID: #198909]
*/
BEGIN
	SET NOCOUNT ON

	EXEC [dbo].[Aff_Con_CheckPermission] @CustID = @UserID
										,@FuncName = '[UserControl]'
										,@ErrCode = @ErrCode OUTPUT
										,@ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end

	UPDATE Affiliate_User WITH (ROWLOCK)
	SET Closed = @Closed
	WHERE CustId = @CustID

	DECLARE @SPName VARCHAR(50)
		   ,@LogData NVARCHAR(200)

	SELECT @SPName = OBJECT_NAME(@@procid)
	SELECT
		@LogData = 'Update AFFILIATE for CustID: ' + dbo.Aff_ToString(@CustID) + ' closed: ' +
		CASE @Closed
			WHEN 0 THEN 'open'
			ELSE 'closed'
		END
END
GO