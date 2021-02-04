/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Newsletter_Ins]
	@UserId			INT
	,@FileName		NVARCHAR(200)
	,@FileSize		SMALLINT
	,@EffectiveFrom DATETIME
	,@EffectiveTo   DATETIME
	,@Language		NVARCHAR(50)
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20210204@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Newsletter - Insert

	Revisions:
		- 20210204@Malcolm: Initialize SP [RedmineID: #145276]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @NewsletterId INT, @SpName VARCHAR(200), @NewData NVARCHAR(MAX)
	--Check permission
	EXEC dbo.Aff_CheckPermission 
		@CustId = @UserId
		,@FuncName = '[Media]'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	--Check if filename have exists
	IF EXISTS(SELECT TOP 1 1 FROM dbo.Newsletter WITH(NOLOCK) WHERE FileName = @FileName)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'The html file name exist already, please choose another name.'
		RETURN
	END
	-- Check size limit of file (3MB)
	IF @FileSize > 3 * 1024
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg ='The file size exceeds 3MB, please check again.'
		RETURN
	END

	BEGIN TRY
		INSERT INTO dbo.Newsletter (FileName, FileSize, EffectiveFromDate, EffectiveToDate, Language)
		VALUES (@FileName, @FileSize, @EffectiveFrom, @EffectiveTo, @Language)

		SET @NewsletterId = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Insert unsuccessfully.'
		RETURN
	END CATCH

	--Write Log
	SELECT @SpName = OBJECT_NAME(@@PROCID)
	SELECT @NewData = 'NewsletterId=' + CONVERT(VARCHAR(20), @NewsletterId) + ',' + 
					  'FileName=' + @FileName + ',' + 
					  'FileSize=' + CONVERT(VARCHAR(20), @FileSize) + ',' + 
					  'EffectiveFromDate=' + CONVERT(VARCHAR(20), @EffectiveFrom, 121) + ',' + 
					  'EffectiveToDate=' + CONVERT(VARCHAR(20), @EffectiveTo, 121) + ',' +
					  'Language=' + @Language

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId = @UserId
		,@SPName = @SPName
		,@AffId = 0
		,@NewData = @NewData
		,@IP = @IP
		,@Language = 'en-US'
	
END
GO