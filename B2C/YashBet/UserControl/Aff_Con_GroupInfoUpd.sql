/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_GroupInfoUpd]
	@GroupID int,
	@GroupName nvarchar(50)=null,
	@GroupDesc nvarchar(50)=null,
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int,
	@IP varchar(15) = ''
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet

	Revisions:
		-- DB03.BODB02 -->DB052.Affiliate_12BET
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
		- 20240115@Sally: Initialize SP [RedmineID: #198909]	
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

	IF EXISTS (
		SELECT 1
		FROM AffGroupInfo WITH (NOLOCK)
		WHERE GroupName = @GroupName
		AND GroupId <> @GroupID
	)
	BEGIN
		SELECT
			@ErrMsg =
			CASE @Language
				WHEN 'E' THEN N'This group name is already used.'
				WHEN 'CS' THEN N'This group name is already used.'
				ELSE N'This group name is already used.'
			END
		   ,@ErrCode = 101
		RETURN
	END
	ELSE
	BEGIN
		UPDATE AffGroupInfo
		SET GroupName = ISNULL(@GroupName, GroupName)
		   ,GroupDesc = ISNULL(@GroupDesc, GroupDesc)
		   ,ModifyDate = GETDATE()
		   ,Creator = @UserID
		WHERE GroupId = @GroupID

		DECLARE @SPName VARCHAR(50)
			   ,@LogData NVARCHAR(200)

		SELECT @SPName = OBJECT_NAME(@@procid)

		SELECT @LogData = '[AFFILIATE] Update groupinfo:' + dbo.Aff_ToString(@GroupID)
	END
END
GO