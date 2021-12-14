/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_ExclusivePage_Ins]
	@UserId			INT
	,@FileName		NVARCHAR(200)
	,@FileSize		INT
	,@EffectiveFrom DATETIME
	,@EffectiveTo	DATETIME
	,@Language		NVARCHAR(50)
	,@IP			VARCHAR(20)= ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20211213@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Exclusive Page - Insert

	Revisions:
		- 20211213@Malcolm: Initialize SP [RedmineID: #165915]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @PageId INT, @SPName VARCHAR(200), @NewData NVARCHAR(MAX)

	EXEC dbo.Aff_CheckPermission 
		@CustId = @UserId
		,@FuncName = '[Media]'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	--Check if filename have exists
	IF EXISTS (SELECT 1 FROM dbo.ExclusivePage WITH(NOLOCK) WHERE FileName = @FileName)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'The html file name exist already, please choose another name.'
		RETURN
	END

	--Check Size limit of file (3MB)
	IF @FileSize > 3 * 1024 * 1024
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg ='The file size exceeds 3MB, please check again.'
		RETURN
	END

	BEGIN TRY
		INSERT INTO dbo.ExclusivePage (FileName, FileSize, Language, UploadDate, EffectiveFromDate, EffectiveToDate)
		VALUES (@FileName, @FileSize, @Language, GETDATE(), @EffectiveFrom, @EffectiveTo)

		SET @PageId = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = 'Error occurs. Insert unsuccessfully.'
		RETURN
	END CATCH

	SELECT @SPName = OBJECT_NAME(@@PROCID)

	SELECT @NewData = CONVERT(NVARCHAR(MAX),
					  (
							SELECT  @PageId AS '@PageId',
									@FileName AS '@FileName',
									@FileSize AS '@FileSize',
									CONVERT(VARCHAR(20), @EffectiveFrom, 120) AS '@EffectiveFrom',
									CONVERT(VARCHAR(20), @EffectiveTo, 120) AS '@EffectiveTo',
									@Language  AS '@Language'
							FOR XML PATH('row'), ROOT('root')
					  ))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId = @UserId
		,@SPName = @SPName
		,@AffId = 0
		,@NewData = @NewData
		,@IP = @IP
		,@Language = 'en-US'
END
GO
