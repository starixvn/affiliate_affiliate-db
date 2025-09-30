/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_LanguageUpd]
    @Updatedby int ,
    @LanguageID varchar(8),
    @LanguageName nvarchar(50),    
    @CountryID varchar(8),            
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
	Created: 20130122@Joseph
	Task: Update Language
	DB: DBAFF
	Original:

	Revisions:
		- 20151221@Francis: Support SSO
		- 20170627@Percy: Remove check permission [RedmineID: #73925]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1 FROM dbo.[Language] WITH(NOLOCK) WHERE LanguageID = @LanguageID)
	BEGIN
		SELECT
			@ErrCode = 1001,
			@ErrMsg =  N'Error! This Language does not exist!'
		RETURN
	END

	BEGIN TRANSACTION

	UPDATE dbo.[Language] WITH(ROWLOCK, UPDLOCK)
	SET LanguageName = @LanguageName, [CountryID] = @CountryID
	WHERE LanguageID = @LanguageID

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Update Language. ID= ' + @LanguageID + '.LanguageName=' + @LanguageName + '.CountryID=' + @CountryID

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @Updatedby,
		@AffID = @Updatedby,
		@Typename = 'Language', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO