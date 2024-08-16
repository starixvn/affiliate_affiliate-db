/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliatePreferredLanguage_Upd]
	@AffID				INT
	,@UserID			INT
	,@PreferredLanguage	VARCHAR(5)
	,@IP				VARCHAR(50)
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20160614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Customer - Left menu - Update Affiliate's Preferred Language

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210223@Percy: Change permission function [RedmineID: #149213]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]
		- 20240819@Eddie: Hide Hindi Market [RedmineID: #209409]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'

	SELECT @ErrCode = 0, @ErrMsg = ''

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[AffMarket]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	-- End check permission

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffID = @AffID)
	BEGIN
		-- Invalid Affiliate!
		SELECT @ErrCode = 1005, @ErrMsg = dbo.Aff_f_GetMessageById(304, @Language)
		RETURN
	END

	-- For Log
	DECLARE @OldData NVARCHAR(4000), @NewData NVARCHAR(4000), @SPName VARCHAR(50)

	SELECT  @OldData	= '<root><row PreferredLanguage="'+ m.MarketName +'"></row></root>'		
			,@SPName	= OBJECT_NAME(@@PROCID)
	FROM dbo.AffDetail a WITH (NOLOCK)
		INNER JOIN dbo.Market m WITH(NOLOCK) ON a.PreferredLanguage = m.MarketID
	WHERE AffID = @AffID AND m.MarketID <> 'hi'

	SELECT @NewData	= '<root><row PreferredLanguage="'+  MarketName +'"></row></root>'
	FROM dbo.Market WITH(NOLOCK)
	WHERE MarketID = @PreferredLanguage AND MarketID <> 'hi'

	IF @OldData = @NewData
		RETURN
	
	BEGIN TRY
		UPDATE dbo.AffDetail WITH (ROWLOCK)
		SET PreferredLanguage = @PreferredLanguage
		WHERE AffID = @AffID
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 1005, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
		RETURN
	END CATCH

	-- Write Log
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffID,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO