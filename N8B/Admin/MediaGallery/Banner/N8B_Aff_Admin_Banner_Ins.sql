/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Banner_Ins]
	@UserId			INT
	,@Files			XML
	,@TargetId		TINYINT
	,@Categories	VARCHAR(MAX)
	,@SubCategories	VARCHAR(MAX)
	,@Language		VARCHAR(50)
	,@Currencies	VARCHAR(MAX)
	,@AffTypes		VARCHAR(MAX)
	,@DeviceTypes	VARCHAR(MAX)
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Admin - Media Gallery - Banner - Insert

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]

	Param's Explanation:
		- @TargetId:
			1: Member banner
			2: Affiliate banner
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Media]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE @tblBanner TABLE (FileName NVARCHAR(200), Size VARCHAR(50))

	BEGIN TRY
		INSERT INTO @tblBanner (FileName, Size)
		SELECT
			FileName	=  t.c.value('@FileName', 'NVARCHAR(200)')
			,Size		=  t.c.value('@Size', 'VARCHAR(50)')
		FROM @Files.nodes('root/row') AS t(c)
		OPTION (OPTIMIZE FOR (@Files = NULL))
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = 'Error occurs. Invalid input params.'
		RETURN
	END CATCH

	-- Check input params
	IF (SELECT COUNT(1) FROM @tblBanner) > 10
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Maximum files: 10.'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM @tblBanner GROUP BY FileName HAVING COUNT(1) > 1)
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Error occurs. Duplicate FileName.'
		RETURN
	END

	DECLARE @ExistedFileName NVARCHAR(MAX)
	SELECT  @ExistedFileName = COALESCE(@ExistedFileName + ',', '') + f.FileNameNoPath
	FROM dbo.MediaGallery m WITH (NOLOCK)
		INNER JOIN @tblBanner b ON b.FileName = m.FileName
		CROSS APPLY (
			SELECT TOP 1 val AS FileNameNoPath FROM dbo.Aff_f_StringSplit(b.FileName, '/')
			ORDER BY Id DESC
		) f
	WHERE m.TargetId = @TargetId
		AND m.ImageType = 'Image'

	IF ISNULL(@ExistedFileName, '') <> ''
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'Error occurs. FileNames have already been existed: ' + @ExistedFileName + '.'
		RETURN
	END

	BEGIN TRY
		INSERT INTO dbo.MediaGallery (FileName,TargetId,ImageType,Size,Categories,SubCategories,Language,Currencies,AffTypes,DeviceTypes,Creator,CreatedDate,UpdatedDate)
		SELECT FileName,@TargetId,'Image',Size,@Categories,@SubCategories,@Language,@Currencies,@AffTypes,@DeviceTypes,@UserId,GETDATE(),GETDATE()
		FROM @tblBanner t
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 105, @ErrMsg = 'Error occurs. Insert unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SELECt  @NewData = COALESCE(@NewData + ',' ,'') + 'FileName:' + FileName + '-Size' + Size
	FROM @tblBanner

	SELECT  @NewData = 'Files=' + ISNULL(@NewData, '')
					+ ',' + 'TargetId=' + ISNULL(CONVERT(VARCHAR(5), @TargetId), '')
					+ ',' + 'Categories=' + ISNULL(@Categories, '')
					+ ',' + 'Language=' + ISNULL(@Language, '')
					+ ',' + 'Currencies=' + ISNULL(@Currencies, '')
					+ ',' + 'AffTypes=' + ISNULL(@AffTypes, '')
					+ ',' + 'DeviceTypes=' + ISNULL(@DeviceTypes, '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= 'en-US'
END
GO