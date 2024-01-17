/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_AdminUpd]
	@CustID INT,
	@FirstName NVARCHAR(50),
	@LastName NVARCHAR(50),
	@UserID INT,
	@GroupID INT,
	@IP VARCHAR(15) = '',
	@Language VARCHAR(2)= 'E',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Revisions:
		-- Check permission for account site: @phuc20080213
		-- DB02.BODB02 -->  DB052.Affiliate_12BET
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
	EXEC dbo.Aff_Con_AdminGroupUpd @CustID = @CustID
								  ,@UserID = @UserID
								  ,@GroupID = @GroupID
								  ,@Language = @Language
								  ,@ErrCode = @ErrCode OUTPUT
								  ,@ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	BEGIN TRANSACTION
		UPDATE Affiliate_User WITH (ROWLOCK, UPDLOCK)
		SET FirstName = @FirstName
		   ,LastName = @LastName
		WHERE CustId = @CustID

		IF @@error <> 0
		BEGIN
			ROLLBACK TRANSACTION
			SELECT
				@ErrMsg =
				CASE @Language
					WHEN 'E' THEN 'Error occurs.Update unsuccessfully.'
					WHEN 'CS' THEN N'Error occurs.Update unsuccessfully.'
					WHEN 'J' THEN N'Error occurs.Update unsuccessfully.'
					ELSE N'Error occurs.Update unsuccessfully.'
				END
			   ,@ErrCode = 102
			RETURN
		END
	COMMIT TRANSACTION

	DECLARE @SPName VARCHAR(50), @LogData NVARCHAR(200)

	SELECT @SPName = OBJECT_NAME(@@procid)
	SELECT @LogData = 'AFFILIATE UPDATE AccAdmin custid:' + dbo.Aff_ToString(@CustID) + ' Name:' + dbo.Aff_ToString(@FirstName) + ' ' + dbo.Aff_ToString(@LastName) + ' GroupID:' + dbo.Aff_ToString(@GroupID)
END
GO