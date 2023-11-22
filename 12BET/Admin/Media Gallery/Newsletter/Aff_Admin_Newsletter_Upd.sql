/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Newsletter_Upd]
	@UserId			INT
	,@NewsletterId  INT
	,@FileName		NVARCHAR(200)
	,@FileSize		INT
	,@EffectiveFrom DATETIME
	,@EffectiveTo   DATETIME
	,@Language		NVARCHAR(50)
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20210204@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Newsletter - Update

	Revisions:
		- 20210204@Malcolm: Initialize SP [RedmineID: #145276]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX), @SPName NVARCHAR(200)

	--Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId = @UserId
		,@FuncName = '[Media]'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	--check if Newsletter have deleted or not
	IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.Newsletter WITH(NOLOCK) WHERE NewsletterId = @NewsletterId)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'The newletter does not exist, please refresh the page and try again.'
		RETURN
	END

	--Check if file name have exists or not
	IF EXISTS(SELECT TOP 1 1 FROM dbo.Newsletter WITH(NOLOCK) WHERE FileName = @FileName AND NewsletterId <> @NewsletterId)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'The file name already exists, please check again.'
		RETURN
	END

	-- Check size limit of file (3MB)
	IF @FileSize > 3 * 1024 * 1024
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg ='The file size exceeds 3MB, please check again.'
		RETURN
	END

	SELECT @OldData  = CONVERT(NVARCHAR(MAX), 
					   (
							SELECT 	NewsletterId AS '@NewsletterId'
									,FileName AS '@FileName'
									,FileSize AS '@FileSize'
									,EffectiveFromDate AS '@EffectiveFromDate'
									,EffectiveToDate AS '@EffectiveToDate'
									,Language AS '@Language'
							FROM dbo.Newsletter WITH(NOLOCK)
							WHERE NewsletterId = @NewsletterId
							FOR XML PATH('row'), ROOT('root')
					   ))
	
	BEGIN TRY
		UPDATE dbo.Newsletter WITH(ROWLOCK)
		SET FileName = @FileName
			,FileSize = @FileSize
			,EffectiveFromDate = @EffectiveFrom
			,EffectiveToDate = @EffectiveTo
			,Language = @Language
	WHERE NewsletterId = @NewsletterId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Update unsucessfully.'
		RETURN
	END CATCH

	--Write Log

	SELECT @NewData = CONVERT(NVARCHAR(MAX), 
					  (
							SELECT	@NewsletterId AS '@NewsletterId', 
									@FileName AS '@FileName',
									@FileSize AS '@FileSize', 
									@EffectiveFrom AS '@EffectiveFromDate', 
									@EffectiveTo AS '@EffectiveToDate',  
									@Language AS '@Language'
							FOR XML PATH('row'), ROOT('root')
					  ))

	SELECT @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId = @UserId
		,@SPName = @SPName
		,@AffId = 0
		,@NewData = @NewData
		,@OldData = @OldData
		,@IP = @IP
		,@Language = 'en-US'
END
GO