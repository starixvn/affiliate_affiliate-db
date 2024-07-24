/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_OfferPage_Del]
	@UserId			INT
	,@PageIds		VARCHAR(MAX)
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20211213@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Offer Page - delete

	Revisions:
		- 20211213@Malcolm: Initialize SP [RedmineID: #165915]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SPName VARCHAR(200), @OldData NVARCHAR(MAX), @ID INT = 1, @PageId INT, @FileName NVARCHAR(200), @AffId INT

	DECLARE @TmpDelete TABLE 
	(
		ID					INT IDENTITY(1, 1)
		,PageId				INT
		,FileName			NVARCHAR(200)
		,FileSize			INT
		,Language			NVARCHAR(50)
		,UploadDate			DATETIME
		,EffectiveFromDate	DATETIME
		,EffectiveToDate	DATETIME
	)
	
	DECLARE @TmpAff TABLE (PageId INT, AffId INT, Username NVARCHAR(30))

	EXEC dbo.Aff_CheckPermission 
		@CustId = @UserId
		,@FuncName = '[Media]'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Check if offer page have deleted or not
	IF EXISTS (
		SELECT 1
		FROM dbo.strSplit(@PageIds, ',') s
		WHERE NOT EXISTS (SELECT 1 FROM dbo.OfferPage ep WITH(NOLOCK) WHERE ep.PageId = s.val)
	)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Offer Page(s) do not exist, please refresh the page and try again.'
		RETURN
	END

	BEGIN TRY
		DELETE dbo.OfferAffiliate WITH(ROWLOCK, UPDLOCK)
		OUTPUT deleted.AffId, deleted.PageId
			INTO @TmpAff (AffId, PageId)
		WHERE PageId IN (SELECT s.val FROM dbo.strSplit(@PageIds, ',') s)

		DELETE dbo.OfferPage WITH(ROWLOCK, UPDLOCK)
		OUTPUT deleted.PageId, deleted.FileName, deleted.FileSize, deleted.UploadDate, deleted.EffectiveFromDate, deleted.EffectiveToDate, deleted.Language
			INTO @TmpDelete (PageId, FileName, FileSize, UploadDate, EffectiveFromDate, EffectiveToDate, Language)
		WHERE PageId IN (SELECT s.val FROM dbo.strSplit(@PageIds, ',') s)	
	END TRY
	BEGIN CATCH
		--Rollback
		INSERT INTO dbo.OfferAffiliate(AffId, PageId)
		SELECT T.AffId, t.PageId
		FROM @TmpAff t
		WHERE NOT EXISTS (SELECT 1 FROM dbo.OfferAffiliate ea WITH(NOLOCK) WHERE ea.AffId = t.AffId AND ea.PageId = t.PageId)

		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Delete unsucessfully.'
		RETURN
	END CATCH

	UPDATE t
		SET t.Username = ai.UserName
	FROM @TmpAff t
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ai.AffID = t.AffId
		
	SELECT @SPName = OBJECT_NAME(@@PROCID)

	--- Write Log
	
	WHILE 1 =1 
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 1 FROM @TmpDelete WHERE ID = @ID)
			BREAK
		
		SELECT @OldData = CONVERT(NVARCHAR(MAX), 
						  (
								SELECT  PageId AS '@PageId'
										,FileName AS '@FileName'
										,FileSize AS '@FileSize'
										,UploadDate AS '@UploadDate'
										,CONVERT(VARCHAR(20), EffectiveFromDate, 120) AS '@EffectiveFromDate'
										,CONVERT(VARCHAR(20), EffectiveToDate, 120) AS '@EffectiveToDate'
										,Language AS '@Language'
								FOR XML PATH('row'), ROOT('root')
						  ))
				,@PageId = PageId
				,@FileName = FileName
		FROM @TmpDelete
		WHERE ID = @ID

		EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
			@UserId = @UserId
			,@SPName = @SPName
			,@AffId = 0
			,@OldData = @OldData
			,@IP = @IP
			,@Language = 'en-US'

		WHILE 1 = 1
		BEGIN
			SELECT @OldData = ''

			IF NOT EXISTS (SELECT 1 FROM @TmpAff WHERE PageId = @PageId)
				BREAK

			SELECT @OldData = CONVERT(NVARCHAR(MAX), 
							  (
									SELECT  @PageId AS '@PageId'
											,@FileName AS '@FileName'
											,AffId AS '@AffId'
											,Username AS '@AffName'
									FOR XML PATH('row'), ROOT('root')
							  ))
					,@AffId = AffId
			FROM @TmpAff		
			WHERE PageId = @PageId
			ORDER BY AffId ASC

			EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
				@UserId = @UserId
				,@SPName = @SPName
				,@AffId = @AffId
				,@OldData = @OldData
				,@IP = @IP
				,@Language = 'en-US'
			
			DELETE @TmpAff WHERE PageId = @PageId AND AffId = @AffId
		END

		SET @ID += 1
	END
END
GO
