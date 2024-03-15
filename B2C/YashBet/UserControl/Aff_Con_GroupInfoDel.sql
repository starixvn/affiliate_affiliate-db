/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_GroupInfoDel] 
	@GroupID	INT,
	@Language	VARCHAR(2)		= 'E',
	@ErrCode	INT				= 0 OUTPUT,
	@ErrMsg		NVARCHAR(200)	= '' OUTPUT,
	@UserID		INT,
	@IP			VARCHAR(15)		= ''
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet

	Revisions:
		-- DB03.BODB02 --> DB052.Affiliate_12BET
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
		- 20240115@Sally: Initialize SP for  [RedmineID: #198909]
*/
BEGIN
	SET NOCOUNT ON
	--Check permission for account site: @phuc20080213
	EXEC [dbo].[Aff_Con_CheckPermission] @custid = @UserID
										,@funcname = '[UserControl]'
										,@ErrCode = @ErrCode OUTPUT
										,@ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end

	IF EXISTS(
		SELECT 1
		FROM Affiliate_User WITH (NOLOCK)
		WHERE GroupID = @GroupID
	)
	BEGIN
		SELECT
			@ErrMsg =
			CASE @Language
				WHEN 'E' THEN N' This group has customer belong to, so you cannot delete!'
				WHEN 'CS' THEN N' This group has customer belong to, so you cannot delete!'
				ELSE N' This group has customer belong to, so you can not delete!'
			END
		   ,@ErrCode = 102
		RETURN
	END

	DELETE FROM AffGroupPolicy
	WHERE GroupID = @GroupID

	DELETE FROM AffGroupInfo
	WHERE GroupID = @GroupID

	--Write log
	DECLARE @SPName VARCHAR(50)
		   ,@LogData NVARCHAR(200)

	SELECT @SPName = OBJECT_NAME(@@procid)
	SELECT @LogData = '[AFFILIATE] Delete GroupID:' + dbo.Aff_ToString(@GroupID)
END
GO 