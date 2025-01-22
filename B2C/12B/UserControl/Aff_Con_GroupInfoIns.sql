/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_GroupInfoIns]
	@GroupID INT OUTPUT,
	@GroupName NVARCHAR(50)='',
	@GroupDesc NVARCHAR(50)='',
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
	EXEC [dbo].[Aff_Con_CheckPermission] @CustID = @UserID
										,@FuncName = '[UserControl]'
										,@ErrCode = @ErrCode OUTPUT
										,@ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end
	IF EXISTS (
		SELECT 1
		FROM AffGroupInfo WITH (NOLOCK)
		WHERE GroupName = @GroupName
	)
	BEGIN
		SELECT
			@ErrMsg =
			CASE @Language
				WHEN 'E' THEN N'This group name is already used.'
				WHEN 'CS' THEN N'This group name is already used.'
				ELSE N'This group name is already used.'
			END
		   ,@ErrCode = 102
		RETURN
	END

	BEGIN TRANSACTION
		INSERT INTO AffGroupInfo (GroupName, GroupDesc, CreateDate, ModifyDate, Creator)
		VALUES (@GroupName, @GroupDesc, GETDATE(), GETDATE(), @UserID)

		SELECT @GroupID = @@identity

		INSERT INTO AffGroupPolicy (GroupId, FuncId, Policy, CreateDate, ModifyDate, Creator)
		SELECT @GroupID AS GroupID
			,FuncId
			,0 AS policy
			,GETDATE() AS createdate
			,GETDATE() AS modifydate
			,@UserID AS creator
		FROM AffFunctionInfo WITH (NOLOCK)

		IF @@error <> 0
		BEGIN
			ROLLBACK TRANSACTION
			SELECT
				@ErrMsg =
				CASE @Language
					WHEN 'E' THEN 'Add group failed.'
					WHEN 'CS' THEN N'Add group failed.'
					WHEN 'J' THEN N'Add group failed.'
					ELSE N'Add group failed.'
				END
			   ,@ErrCode = 103
			RETURN
		END
	COMMIT TRANSACTION

	DECLARE @SPName VARCHAR(50)
		   ,@LogData NVARCHAR(200)

	SELECT @SPName = OBJECT_NAME(@@procid)
	SELECT @LogData = '[AFFILIATE] add groupinfo:' + dbo.Aff_ToString(@GroupID)
END	
GO