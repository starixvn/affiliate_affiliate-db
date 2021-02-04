/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Newsletter_Del]
	@UserId			INT
	,@NewsletterIds VARCHAR(MAX)
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20210204@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Newsletter - Delete

	Revisions:
		- 20210204@Malcolm: Initialize SP [RedmineID: #145276]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @OldData NVARCHAR(MAX), @SPName NVARCHAR(200), @ID INT = 1

	DECLARE @TmpDelete TABLE (ID INT IDENTITY(1, 1), NewsletterId INT,FileName NVARCHAR(200),FileSize SMALLINT,UploadDate DATETIME,EffectiveFromDate DATETIME,EffectiveToDate DATETIME,Language NVARCHAR(50))
	--Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId = @UserId
		,@FuncName = '[Media]'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	--check if Newsletter have deleted or not
	IF EXISTS(SELECT TOP 1 1 
			  FROM dbo.strSplit(@NewsletterIds, ',') s 
			  WHERE NOT EXISTS(SELECT TOP 1 1 FROM  dbo.Newsletter n WITH(NOLOCK) WHERE n.NewsletterId = s.val))
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Newsletter(s) do not exist, please refresh the page and try again.'
		RETURN
	END

	BEGIN TRY
		DELETE dbo.Newsletter WITH(ROWLOCK, UPDLOCK)
		OUTPUT deleted.NewsletterId, deleted.FileName, deleted.FileSize, deleted.UploadDate, deleted.EffectiveFromDate, deleted.EffectiveToDate, deleted.Language
			INTO @TmpDelete
		WHERE NewsletterId IN (SELECT s.val FROM dbo.strSplit(@NewsletterIds, ',') s)
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Delete unsuccessfully.'
		RETURN
	END CATCH

	--Write Log
	SELECT @SPName = OBJECT_NAME(@@PROCID)

	WHILE 1 = 1
	BEGIN
		IF NOT EXISTS(SELECT TOP 1 1 FROM @TmpDelete WHERE ID = @ID)
			BREAK

		SELECT @OldData  = 'NewsletterId=' + CONVERT(VARCHAR(20), NewsletterId) + ',' +
					       'FileName=' + FileName + ',' + 
						   'FileSize=' + CONVERT(VARCHAR(20), FileSize) + ',' +
						   'UploadDate=' + CONVERT(VARCHAR(20), UploadDate, 121) + ',' +
						   'EffectiveFromDate=' + CONVERT(VARCHAR(20), EffectiveFromDate, 121) + ',' +
						   'EffectiveToDate=' + CONVERT(VARCHAR(20), EffectiveToDate, 121) + ',' +
						   'Language='+ Language 
		FROM @TmpDelete 
		WHERE ID = @ID 

		EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
			@UserId = @UserId
			,@SPName = @SPName
			,@AffId = 0
			,@OldData = @OldData
			,@IP = @IP
			,@Language = 'en-US'

		SET @ID += 1
	END

END
GO