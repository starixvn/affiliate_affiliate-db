/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AffTypeUpd]
    @Updatedby int ,
    @ID tinyint,
    @Name nvarchar(50),    
    @Description nvarchar(100)=NULL,            
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
	Created: 20130123@Joseph
	Task:
	DB: DBAFF
	Original:

	Revisions:
		- 20170627@Percy: Remove check permission [RedmineID: #73925]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
  
	IF NOT EXISTS (SELECT 1 FROM dbo.AffType WITH(NOLOCK) WHERE TypeID = @ID)
	BEGIN
		SELECT @ErrCode = 1001, @ErrMsg = N'Error! This type does not exist!'
		RETURN
	END

	BEGIN TRANSACTION

	UPDATE dbo.AffType WITH(ROWLOCK, UPDLOCK)
	SET Name = @Name, [Description] = @Description
	WHERE TypeID = @ID

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
			@Detail = 'Update afftype. ID= ' + dbo.Aff_ToString(@ID) 

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @Updatedby,
		@AffID = @Updatedby,
		@Typename = 'AffType', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO