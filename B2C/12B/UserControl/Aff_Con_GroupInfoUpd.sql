/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_GroupInfoUpd]
	@GroupID INT,
	@GroupName NVARCHAR(50)=null,
	@GroupDesc NVARCHAR(50)=null,
	@Language VARCHAR(2)= 'E', 
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@UserID INT,
	@IP VARCHAR(50) = ''
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