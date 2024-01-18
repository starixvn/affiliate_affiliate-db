/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LandingPage_Ins]
	@UserId					INT
	,@PageName				NVARCHAR(200)
	,@PageCode				NVARCHAR(100)
	,@ExcludedTargetCountry VARCHAR(100)
	,@IP					NVARCHAR(15) = ''
	,@ErrCode				INT = 0 OUTPUT
	,@ErrMsg				NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Media Gallery - Landing Page - Insert

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102399]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20231106@Eddie: Support ExcludedTargetCountry for Landing Page [RedmineID: #181590]

	Param's Explanation:
		- @ExcludedTargetCountry = 'MY,BD,IN,ID,JP,KH,KR,TH,VN,CN'
*/

BEGIN
	SET NOCOUNT ON
	
	SET @ExcludedTargetCountry = ISNULL(@ExcludedTargetCountry, '')

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

	-- Check exists
	IF EXISTS (SELECT 1 FROM dbo.LandingPage WITH (NOLOCK) WHERE PageName = @PageName AND PageCode = @PageCode AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'The landing page is already exists'
		RETURN
	END

	DECLARE @PageId SMALLINT

	BEGIN TRY
	
		INSERT INTO dbo.LandingPage (PageName, PageCode, IsDeleted, BlockTargetCountry)
		VALUES (@PageName, @PageCode, 0, @ExcludedTargetCountry)

		SELECT @PageId = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = 'Insert failed'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200), @NewData NVARCHAR(MAX)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT @NewData = CONVERT(NVARCHAR(MAX),
				   (
						SELECT @PageId 			  	  AS '@PageId'
							 , @PageName 			  AS '@PageName'
							 , @PageCode 			  AS '@PageCode'
							 , @ExcludedTargetCountry AS '@ExcludedTargetCountry'
						FOR XML PATH('row'), ROOT('root')
					))
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
		,@Language	= @Language
END
GO