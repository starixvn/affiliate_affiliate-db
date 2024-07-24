/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_Affiliate_Favorite_Upd]
	@UserId		INT,
	@AffId		INT,
	@IsFavorite	BIT = 0,
	@IP			VARCHAR(50) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Affiliate - Affiliate Info - Set on/off favorite on an affiliate

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'

	-- Remove favorite
	IF @IsFavorite = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.AdminFavorite WITH (NOLOCK) WHERE AdminId = @UserId AND AffId = @AffId)
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(403, @Language)

			RETURN
		END

		BEGIN TRY
			DELETE dbo.AdminFavorite WITH (ROWLOCK, UPDLOCK) WHERE AdminId = @UserId AND AffId = @AffId
		END TRY
		BEGIN CATCH
			SELECT @ErrCode = 201, @ErrMsg = dbo.Aff_f_GetMessageById(404, @Language)

			RETURN
		END CATCH
	END
	-- Add favorite
	ELSE IF @IsFavorite = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.AdminFavorite WITH (NOLOCK) WHERE AdminId = @UserId AND AffId = @AffId)
		BEGIN
			SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(401, @Language)

			RETURN
		END

		BEGIN TRY
			INSERT INTO dbo.AdminFavorite (AdminId, AffId)
			VALUES (@UserId, @AffId)
		END TRY
		BEGIN CATCH
			SELECT @ErrCode = 202, @ErrMsg = dbo.Aff_f_GetMessageById(402, @Language)

			RETURN
		END CATCH
	END

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT @OldData = '<root><row IsFavorite="'+ CASE WHEN @IsFavorite = 1 THEN '0' ELSE '1' END +'"></row></root>'
		   ,@NewData = '<root><row IsFavorite="'+ CASE WHEN @IsFavorite = 1 THEN '1' ELSE '0' END +'"></row></root>'
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO