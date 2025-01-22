/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_AdminUpdClosed]
	@CustID INT,
	@Closed BIT,
	@UserID INT,
	@Language VARCHAR(2) = 'E',
	@IP VARCHAR(50) = '',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT	
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task:

	Revisions:	
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
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