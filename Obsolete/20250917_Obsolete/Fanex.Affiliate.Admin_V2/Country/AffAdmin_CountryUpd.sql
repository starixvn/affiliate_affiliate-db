/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_CountryUpd]
    @Updatedby int ,
    @CountryID nvarchar(6),
    @CountryName nvarchar(255),    
    @Description nvarchar(100)=NULL,    
    @Icon nvarchar(100)=NULL,
    @DisplayOrder smallint=1,
    @IsEnabled bit=1,
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
 
/*
	Created: 20130122@Joseph
	Task: Update Country
	DB: DBAFF
	Original:

	Revisions:
		- 20151221@Francis: Suppot SSO
		- 20170627@Percy: Remove check permission [RedmineID: #73925]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
  
	IF NOT EXISTS (SELECT 1 FROM dbo.Country WITH(NOLOCK) WHERE CountryID = @CountryID)
	BEGIN
		SELECT @ErrCode = 1001, @ErrMsg = N'Error! This country does not exist!'
		RETURN
	END
	
	UPDATE dbo.Country WITH(ROWLOCK, UPDLOCK)
	SET
		CountryName = @CountryName,
		[Description] = @Description,
		Icon = COALESCE(@Icon, Icon), 
		DisplayOrder = COALESCE(@DisplayOrder, DisplayOrder),
		IsEnabled = @IsEnabled
	WHERE CountryID = @CountryID

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END

	-- Write log
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT @SPName = OBJECT_NAME(@@PROCID), @Detail = 'Update Country. ID= ' + dbo.Aff_ToString(@CountryID) + '. Description=' + ISNULL(@Description, '')

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @Updatedby,
		@AffID = @Updatedby,
		@Typename = 'Country', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
    
END
GO