/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_ProductUpd]
    @Updatedby int ,
    @ProductID tinyint,
    @ProductName varchar(50),    
    @Description nvarchar(100)=NULL,        
    @BettypeList nvarchar(255)=NULL,
    @API_ProductID int = NULL,
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
	Created: 20130122@Joseph
	Task: Update Product
	DB: DBAFF
	Original:

	Revisions:
		- 20151221@Francis: Support SSO
		- 20170627@Percy: Remove check permission [RedmineID: #73925]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
   
	IF NOT EXISTS (SELECT 1 FROM dbo.Product WITH(NOLOCK) WHERE ProductID = @ProductID)
	BEGIN
		SELECT @ErrCode = 1001, @ErrMsg = N'Error! This Product does not exist!'
		RETURN
	END
	
	BEGIN TRANSACTION
	
	UPDATE dbo.Product WITH (ROWLOCK, UPDLOCK)
	SET
		ProductName = @ProductName,
		[Description] = @Description,
		BettypeList = @BettypeList,
		API_ProductID = ISNULL(@API_ProductID, NULL)
	WHERE ProductID = @ProductID

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
			@Detail = 'Update Product. ID= ' + dbo.Aff_ToString(@ProductID) + '.BettypeList=' + @BettypeList

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @Updatedby,
		@AffID = @Updatedby,
		@Typename = 'Product', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO