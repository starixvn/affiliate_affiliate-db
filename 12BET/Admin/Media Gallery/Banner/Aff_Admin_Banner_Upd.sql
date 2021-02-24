/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Banner_Upd]
	@UserId			INT
	,@BannerId		INT
	,@Files			XML
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
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Banner - Update

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200303@Percy: Support multiple sizes and categories on banner [RedmineID: #121974]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Media]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE @tblBanner TABLE (FileName NVARCHAR(200), ImageType VARCHAR(50), Size VARCHAR(50))

	BEGIN TRY
		INSERT INTO @tblBanner (FileName, ImageType, Size)
		SELECT
			FileName	=  t.c.value('@FileName', 'NVARCHAR(200)')
			,ImageType	=  t.c.value('@ImageType', 'VARCHAR(50)')
			,Size		=  t.c.value('@Size', 'VARCHAR(50)')
		FROM @Files.nodes('root/row') AS t(c)
		OPTION (OPTIMIZE FOR (@Files = NULL))
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = 'Error occurs. Invalid input params.'
		RETURN
	END CATCH

	-- Check input params
	IF (SELECT COUNT(1) FROM @tblBanner) > 1
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Invalid input params.'
		RETURN
	END

	DECLARE @FileName NVARCHAR(200), @ImageType VARCHAR(50), @Size VARCHAR(50)
	SELECT  @FileName = FileName, @ImageType = ImageType, @Size= Size FROM @tblBanner

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	SELECT  @OldData = CONVERT(NVARCHAR(MAX),
					   (
							SELECT 
								BannerId AS '@BannerId'
								,FileName AS '@FileName'
								,ImageType AS '@ImageType'
								,Size AS '@Size'
								,Categories AS '@Categories'
								,Language AS '@Language'
								,Currencies AS '@Currencies'
								,AffTypes AS '@AffTypes'
								,DeviceTypes AS '@DeviceTypes'
							FROM dbo.Banners WITH (NOLOCK)
							WHERE BannerId = @BannerId
								AND ImageType <> 'Text'
							FOR XML PATH('row'), ROOT('root')
					   ))
			
	IF @OldData IS NULL
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Error occurs. Banner does not exist.'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.Banners WITH (ROWLOCK)
		SET FileName		= @FileName
			,ImageType		= @ImageType
			,Size			= @Size
			,Categories		= @Categories
			,SubCategories	= @SubCategories
			,Language		= @Language
			,Currencies		= @Currencies
			,AffTypes		= @AffTypes
			,DeviceTypes	= @DeviceTypes
			,UpdatedBy		= @UserId
			,UpdatedDate	= GETDATE()
		WHERE BannerId		= @BannerId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Update unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)
	SELECT  @NewData = CONVERT(NVARCHAR(MAX),
					  (
						SELECT	@BannerId AS '@BannerId', 
								@FileName AS '@FileName',
								@ImageType AS '@ImageType', 
								@Size AS '@Size', 
								@Categories AS '@Categories', 
								@Language AS '@Language', 
								@Currencies AS '@Currencies',
								@AffTypes AS '@AffTypes',
								@DeviceTypes AS '@DeviceTypes'
						FOR XML PATH('row'), ROOT('root')
					  ))
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
		,@Language	= 'en-US'
END
GO