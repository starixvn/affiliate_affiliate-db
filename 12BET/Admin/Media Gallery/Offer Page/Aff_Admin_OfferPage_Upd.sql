/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_OfferPage_Upd]
	@UserId			INT
	,@PageId		INT
	,@FileName		NVARCHAR(200)
	,@FileSize		INT
	,@EffectiveFrom	DATETIME
	,@EffectiveTo	DATETIME
	,@Language		NVARCHAR(50)
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20211213@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Offer Page - Update

	Revisions:
		- 20211213@Malcolm: Initialize SP [RedmineID: #165915]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SPName VARCHAR(200), @NewData NVARCHAR(MAX), @OldData NVARCHAR(MAX)

	EXEC dbo.Aff_CheckPermission 
		@CustId = @UserId
		,@FuncName = '[Media]'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Check if offer page have deleted or not
	IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.OfferPage WITH(NOLOCK) WHERE PageId = @PageId)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'The offer page does not exist, please refresh the page and try again.'
		RETURN
	END
	-- Check if file name have exists or not
	IF EXISTS (SELECT TOP 1 1 FROM dbo.OfferPage WITH(NOLOCK) WHERE FileName = @FileName AND PageId <> @PageId)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'The html file name exist already, please choose another name.'
		RETURN
	END

	--Check Size limit of file (3MB)
	IF @FileSize > 3 * 1024 * 1024
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg ='The file size exceeds 3MB, please check again.'
		RETURN
	END

	SELECT @OldData = CONVERT(NVARCHAR(MAX),
					  (
							SELECT	PageId AS '@PageId',
									FileName AS '@FileName',
									FileSize AS '@FileSize',
									CONVERT(VARCHAR(20), EffectiveFromDate, 120) AS '@EffectiveFromDate',
									CONVERT(VARCHAR(20), EffectiveToDate, 120) AS '@EffectiveToDate',
									Language AS '@Language'
							FROM dbo.OfferPage WITH(NOLOCK)
							WHERE PageId = @PageId
							FOR XML PATH('row'), ROOT('root')
					  ))

	BEGIN TRY
		UPDATE dbo.OfferPage WITH(ROWLOCK)
		SET FileName = @FileName
			,FileSize = @FileSize
			,EffectiveFromDate = @EffectiveFrom
			,EffectiveToDate = @EffectiveTo
			,Language = @Language
		WHERE PageId = @PageId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 104, @ErrMsg = 'Error occurs. Update unsucessfully.'
		RETURN
	END CATCH

	SELECT @NewData = CONVERT(NVARCHAR(MAX),
				  (
						SELECT  @PageId AS '@PageId',
								@FileName AS '@FileName',
								@FileSize AS '@FileSize',
								CONVERT(VARCHAR(20), @EffectiveFrom, 120) AS '@EffectiveFrom',
								CONVERT(VARCHAR(20), @EffectiveTo, 120) AS '@EffectiveTo',
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
