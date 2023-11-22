/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LandingPage_Upd]
	@UserId					INT
	,@PageId				SMALLINT
	,@PageName				NVARCHAR(200)
	,@PageCode				NVARCHAR(100)
	,@ExcludedTargetCountry VARCHAR(100)
	,@IP					VARCHAR(50) = ''
	,@ErrCode	 			INT = 0 OUTPUT
	,@ErrMsg	 			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Media Gallery - Landing Page - Update

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102399]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20231106@Eddie: Support ExcludedTargetCountry for Landing Page [RedmineID: #181590]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]

	Param's Explanation:
		- @ExcludedTargetCountry = 'MY,BD,IN,ID,JP,KH,KR,TH,VN,CN'
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Media]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	
	SELECT @PageName = ISNULL(LTRIM(RTRIM(@PageName)), ''), @PageCode = ISNULL(LTRIM(RTRIM(@PageCode)), '')

	IF @PageName = '' OR @PageCode = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid input'
		RETURN
	END

	DECLARE @OldPageName NVARCHAR(200), @OldPageCode VARCHAR(100), @OldExcludedTargetCountry VARCHAR(100)

	SELECT  @OldPageName 			  = PageName
		   ,@OldPageCode 			  = PageCode
		   ,@OldExcludedTargetCountry = BlockTargetCountry
	FROM dbo.LandingPage WITH (NOLOCK) WHERE PageId = @PageId

	IF @OldPageName IS NULL
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This landing page does not exists'
		RETURN
	END

	IF @OldPageName = @PageName AND @OldPageCode = @PageCode AND @OldExcludedTargetCountry = @ExcludedTargetCountry
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'This landing page does not changes'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.LandingPage WITH (NOLOCK) WHERE PageName = @PageName AND PageCode = @PageCode AND IsDeleted = 0 AND PageId <> @PageId)
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'The landing page is already exists'
		RETURN
	END

	BEGIN TRY
	
		UPDATE dbo.LandingPage WITH (ROWLOCK, UPDLOCK)
		SET PageName  			= @PageName
			,PageCode 			= @PageCode
			,BlockTargetCountry = @ExcludedTargetCountry
		WHERE PageId = @PageId

		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'This landing page does not exists!'
			RETURN
		END

	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 105, @ErrMsg = 'Insert failed'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200), @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @OldData = CONVERT(NVARCHAR(MAX),
					  (
							SELECT @OldPageName 			 AS '@PageName'
								 , @OldPageCode 			 AS '@PageCode'
								 , @OldExcludedTargetCountry AS '@ExcludedTargetCountry'
							FOR XML PATH('row'), ROOT('root')
					   ))
	SELECT	@NewData = CONVERT(NVARCHAR(MAX),
					  (
							SELECT @PageName 			  AS '@PageName'
								 , @PageCode 			  AS '@PageCode'
								 , @ExcludedTargetCountry AS '@ExcludedTargetCountry'
							FOR XML PATH('row'), ROOT('root')
					   ))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
		,@Language	= @Language
END
GO