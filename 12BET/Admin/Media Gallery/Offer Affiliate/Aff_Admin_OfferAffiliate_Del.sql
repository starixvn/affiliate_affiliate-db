/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_OfferAffiliate_Del]
	@UserId			INT
	,@AffIds		VARCHAR(MAX)
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20211213@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Offer Affilitate Page - Unassign

	Revisions:
		- 20211213@Malcolm: Initialize SP [RedmineID: #165915]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]
		- 20240820@Eddie: STRING_SPLIT replace for strSplit function [RedmineID: #209409]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SPName VARCHAR(200), @OldData NVARCHAR(MAX), @ID INT = 1, @AffId  INT
	
	DECLARE @TmpAff TABLE (ID INT IDENTITY(1, 1), PageId INT, AffId INT, FileName NVARCHAR(200), Username NVARCHAR(30))

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
		FROM STRING_SPLIT(@AffIds, ',') s
			LEFT JOIN dbo.AffDetail d WITH(NOLOCK) ON s.value = d.AffID
			LEFT JOIN dbo.OfferAffiliate ea WITH(NOLOCK) ON ea.AffId = d.AffID
			LEFT JOIN dbo.UserMarket m WITH(NOLOCK) ON m.MarketId = d.PreferredLanguage AND m.CustId = @UserId
		WHERE ea.AffId IS NULL OR  m.CustId IS NULL
	)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Offer - affiliate assignment(s) do not exist, please refresh the page and try again.'
		RETURN
	END

	BEGIN TRY
		DELETE dbo.OfferAffiliate WITH(ROWLOCK, UPDLOCK)
		OUTPUT deleted.AffId, deleted.PageId
			INTO @TmpAff (AffId, PageId)
		WHERE AffId IN (SELECT s.value FROM STRING_SPLIT(@AffIds, ',') s)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Delete unsucessfully.'
		RETURN
	END CATCH

	UPDATE t
		SET t.Username = ai.UserName, t.FileName = ep.FileName
	FROM @TmpAff t
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ai.AffID = t.AffId
		INNER JOIN dbo.OfferPage ep WITH(NOLOCK) ON ep.PageId = t.PageId
		
	SELECT @SPName = OBJECT_NAME(@@PROCID)

	--- Write Log
	
	WHILE 1 =1 
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 1 FROM @TmpAff WHERE ID = @ID)
			BREAK
		
		SELECT @OldData = CONVERT(NVARCHAR(MAX), 
						  (
								SELECT  PageId AS '@PageId'
										,FileName AS '@FileName'
										,AffId AS '@AffId'
										,Username AS '@AffName'
								FOR XML PATH('row'), ROOT('root')
						  ))
				,@AffId = AffId
		FROM @TmpAff
		WHERE ID = @ID

		EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
			@UserId = @UserId
			,@SPName = @SPName
			,@AffId = @AffId
			,@OldData = @OldData
			,@IP = @IP
			,@Language = 'en-US'

		SET @ID += 1
	END
END
GO
