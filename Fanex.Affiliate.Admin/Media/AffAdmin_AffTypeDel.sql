/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AffTypeDel]
    @Updatedby int ,
    @IDList varchar(max),
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

	BEGIN TRANSACTION

	DELETE [dbo].[AffType] WITH(ROWLOCK, UPDLOCK)
	WHERE TypeID IN (SELECT val FROM dbo.strsplit(@IDList, ','))

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
			@Detail = 'Delete AffType. IDList=' + ISNULL(@IDList, 0)


	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @Updatedby,
		@AffID = @Updatedby,
		@Typename = 'AffType', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO